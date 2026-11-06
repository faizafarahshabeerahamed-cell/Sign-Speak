from collections import Counter
import json
import re
import urllib.request
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
from sklearn.model_selection import GroupShuffleSplit


# This is the folder containing the numbered Amrita sign folders,
# such as "9.hello" and "24.help".
DATASET_DIR = Path(
    r"C:\Users\HP\Downloads\Amrita SLR Dataset\sign project"
)

# The script and its output stay inside isl_model_training.
TRAINING_DIR = Path(__file__).resolve().parent
MODELS_DIR = TRAINING_DIR / "models"
OUTPUT_DIR = TRAINING_DIR / "output"

HAND_MODEL = MODELS_DIR / "hand_landmarker.task"
POSE_MODEL = MODELS_DIR / "pose_landmarker_lite.task"

HAND_MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/"
    "hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task"
)
POSE_MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/"
    "pose_landmarker/pose_landmarker_lite/float16/1/"
    "pose_landmarker_lite.task"
)

SEQUENCE_LENGTH = 20
FEATURE_COUNT = 226
def normalize_hand(hand_values):
    """
    Make hand landmarks independent of camera position and size.
    """

    if np.all(hand_values == 0):
        return hand_values

    wrist = hand_values[0]

    hand_values = hand_values - wrist

    reference = np.linalg.norm(
        hand_values[9] - hand_values[0]
    )

    if reference > 1e-6:
        hand_values = hand_values / reference

    return hand_values


def normalize_pose(pose_values):
    """
    Make pose landmarks independent of body position.
    """

    if np.all(pose_values == 0):
        return pose_values

    left_shoulder = pose_values[11, :3]
    right_shoulder = pose_values[12, :3]

    center = (left_shoulder + right_shoulder) / 2

    pose_values[:, :3] = pose_values[:, :3] - center

    shoulder_width = np.linalg.norm(
        left_shoulder - right_shoulder
    )

    if shoulder_width > 1e-6:
        pose_values[:, :3] = (
            pose_values[:, :3] / shoulder_width
        )

    return pose_values


def augment_sequence(sequence):
    """
    Small safe augmentation.
    """

    augmented = sequence.copy()

    noise = np.random.normal(
        0,
        0.005,
        augmented.shape
    )

    augmented += noise.astype(np.float32)

    scale = np.random.uniform(
        0.95,
        1.05
    )

    augmented *= scale

    return augmented.astype(np.float32)


def download_model_if_needed(model_path, model_url):
    """Download a MediaPipe model the first time the script runs."""
    if model_path.exists():
        return

    model_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {model_path.name} ...")
    urllib.request.urlretrieve(model_url, model_path)
    print(f"Saved: {model_path}")


def find_mp4_files(folder):
    """Find MP4 files, including ones inside subfolders."""
    return sorted(
        path
        for path in folder.rglob("*")
        if path.is_file() and path.suffix.lower() == ".mp4"
    )


def get_folder_label(folder_name):
    """Turn a folder such as '9.hello' into the label 'hello'."""
    if "." in folder_name:
        return folder_name.split(".", 1)[1].strip().lower()

    return folder_name.strip().lower()


def get_signer_group(video_path, label):
    """Infer a signer group from the dataset's filename conventions."""
    stem = re.sub(r"[^a-z0-9]", "", video_path.stem.lower())
    label_key = re.sub(r"[^a-z0-9]", "", label.lower())

    if label_key and label_key in stem:
        stem = stem.replace(label_key, "", 1)

    # Keep takes with generic filenames together as an anonymous signer group.
    signer = re.sub(r"\d+", "", stem)
    return signer or "anonymous"


def get_frame_features(rgb_frame, timestamp_ms, hand_detector, pose_detector):
    """Convert one video frame into hand and body landmark numbers."""
    mp_image = mp.Image(
        image_format=mp.ImageFormat.SRGB,
        data=rgb_frame,
    )

    hand_result = hand_detector.detect_for_video(mp_image, timestamp_ms)
    pose_result = pose_detector.detect_for_video(mp_image, timestamp_ms)

    # Two hands x 21 points x (x, y, z) = 126 numbers.
    hand_values = np.zeros((2, 21, 3), dtype=np.float32)

    for hand_index, landmarks in enumerate(hand_result.hand_landmarks[:2]):
        hand_slot = hand_index

        # Keep left and right hands in consistent slots when MediaPipe
        # provides the handedness label.
        if hand_index < len(hand_result.handedness):
            categories = hand_result.handedness[hand_index]
            if categories:
                hand_name = categories[0].category_name.lower()
                if hand_name == "left":
                    hand_slot = 0
                elif hand_name == "right":
                    hand_slot = 1

        hand_values[hand_slot] = np.array(
            [[point.x, point.y, point.z] for point in landmarks],
            dtype=np.float32,
        )

    # The first 25 body points cover the face, shoulders, arms, and hands.
    # Each point stores x, y, z, and visibility: 25 x 4 = 100 numbers.
    pose_values = np.zeros((25, 4), dtype=np.float32)

    if pose_result.pose_world_landmarks:
        pose_landmarks = pose_result.pose_world_landmarks[0]

        for point_index, point in enumerate(pose_landmarks[:25]):
            visibility = getattr(point, "visibility", 1.0)
            if visibility is None:
                visibility = 1.0

            pose_values[point_index] = [
                point.x,
                point.y,
                point.z,
                float(visibility),
            ]

    # Match the exact normalization used by api.py at prediction time.
    # Without this, training sees raw camera coordinates while prediction
    # sees wrist- and shoulder-normalized landmarks.
    hand_values[0] = normalize_hand(hand_values[0])
    hand_values[1] = normalize_hand(hand_values[1])
    pose_values = normalize_pose(pose_values)

    # 126 hand numbers + 100 body numbers = 226 numbers per frame.
    features = np.concatenate(
        [hand_values.flatten(), pose_values.flatten()]
    )

    return features.astype(np.float32)


def extract_video_sequence(
    video_path,
    timestamp_start,
    hand_detector,
    pose_detector,
):
    """Sample up to 20 frames from a video and extract their landmarks."""
    capture = cv2.VideoCapture(str(video_path))

    if not capture.isOpened():
        print(f"Could not open video: {video_path.name}")
        return None

    frame_count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))

    if frame_count <= 0:
        capture.release()
        print(f"Video has no readable frames: {video_path.name}")
        return None

    frame_numbers = np.linspace(
        0,
        frame_count - 1,
        num=min(SEQUENCE_LENGTH, frame_count),
        dtype=int,
    )

    sequence = []

    try:
        for sample_index, frame_number in enumerate(frame_numbers):
            capture.set(cv2.CAP_PROP_POS_FRAMES, int(frame_number))
            success, frame = capture.read()

            if not success:
                continue

            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # MediaPipe VIDEO mode requires increasing timestamps.
            timestamp_ms = timestamp_start + sample_index * 40

            features = get_frame_features(
                rgb_frame,
                timestamp_ms,
                hand_detector,
                pose_detector,
            )
            sequence.append(features)
    finally:
        capture.release()

    if not sequence:
        print(f"No frames could be read from: {video_path.name}")
        return None

    # Make every clip the same length by repeating its last sampled frame.
    while len(sequence) < SEQUENCE_LENGTH:
        sequence.append(sequence[-1].copy())

    return np.asarray(sequence[:SEQUENCE_LENGTH], dtype=np.float32)


def main():
    if not DATASET_DIR.exists():
        print("I could not find the Amrita dataset folder.")
        print(f"Please check this path in the script:\n{DATASET_DIR}")
        return

    class_folders = [
        folder for folder in DATASET_DIR.iterdir() if folder.is_dir()
    ]

    if not class_folders:
        print(f"No sign folders were found inside:\n{DATASET_DIR}")
        return

    # Read the numbered Amrita folders, for example "9.hello".
    video_records = []

    demo_labels = {
        "hello",
        "help",
        "sorry",
        "thankyou",
        "welcome",
        "good",
        "stop",
        "work",
        "today",
        "study",
    }

    for class_folder in sorted(class_folders):
        label = get_folder_label(class_folder.name)

        if label not in demo_labels:
            continue

        for video_path in find_mp4_files(class_folder):
            video_records.append((label, video_path))

    # Also include your project's not_sign folder if it contains videos.
    # Still images are not used by this video-training script.
    project_root = TRAINING_DIR.parent
    extra_not_sign_folder = (
        project_root / "isl_training_data" / "not_sign"
    )

    if extra_not_sign_folder.exists():
        for video_path in find_mp4_files(extra_not_sign_folder):
            video_records.append(("not_sign", video_path))

    if not video_records:
        print("No MP4 videos were found in the dataset folders.")
        return

    print(f"Found {len(video_records)} video clips.")
    print("The first run may download two MediaPipe model files.")

    download_model_if_needed(HAND_MODEL, HAND_MODEL_URL)
    download_model_if_needed(POSE_MODEL, POSE_MODEL_URL)

    hand_options = mp.tasks.vision.HandLandmarkerOptions(
        base_options=mp.tasks.BaseOptions(
            model_asset_path=str(HAND_MODEL)
        ),
        running_mode=mp.tasks.vision.RunningMode.VIDEO,
        num_hands=2,
    )

    pose_options = mp.tasks.vision.PoseLandmarkerOptions(
        base_options=mp.tasks.BaseOptions(
            model_asset_path=str(POSE_MODEL)
        ),
        running_mode=mp.tasks.vision.RunningMode.VIDEO,
        num_poses=1,
    )

    sequences = []
    labels = []
    signer_groups = []
    timestamp_cursor = 0

    with (
        mp.tasks.vision.HandLandmarker.create_from_options(
            hand_options
        ) as hand_detector,
        mp.tasks.vision.PoseLandmarker.create_from_options(
            pose_options
        ) as pose_detector,
    ):
        for index, (label, video_path) in enumerate(video_records, start=1):
            print(
                f"[{index}/{len(video_records)}] "
                f"Reading {label}: {video_path.name}"
            )

            sequence = extract_video_sequence(
                video_path,
                timestamp_cursor,
                hand_detector,
                pose_detector,
            )

            # Leave a gap before the next clip's timestamps.
            timestamp_cursor += (SEQUENCE_LENGTH + 1) * 40

            if sequence is not None:
                sequences.append(sequence)
                labels.append(label)
                signer_groups.append(get_signer_group(video_path, label))

    if not sequences:
        print("No usable video clips were processed.")
        return

    counts = Counter(labels)
    usable_labels = {
        label for label, count in counts.items() if count >= 2
    }

    kept_items = [
        (sequence, label, signer)
        for sequence, label, signer in zip(
            sequences,
            labels,
            signer_groups,
        )
        if label in usable_labels
    ]

    if not kept_items:
        print("Each sign needs at least two readable videos.")
        return

    sequences = [item[0] for item in kept_items]
    labels = [item[1] for item in kept_items]
    signer_groups = [item[2] for item in kept_items]

    class_names = sorted(set(labels))
    label_numbers = {name: number for number, name in enumerate(class_names)}

    X = np.asarray(sequences, dtype=np.float32)
    y = np.asarray([label_numbers[label] for label in labels], dtype=np.int32)

    print("\nVideos per label:")
    for label in class_names:
        print(f"  {label}: {Counter(labels)[label]}")

    if "not_sign" not in class_names:
        print(
            "\nWARNING: There are no not_sign videos. "
            "This model will always choose one of the sign labels."
        )

    # Hold out complete signer groups so validation measures performance
    # on people whose clips were not used to fit the first model.
    all_class_numbers = set(range(len(class_names)))
    split_indices = None
    splitter = GroupShuffleSplit(
        n_splits=100,
        test_size=0.20,
        random_state=42,
    )

    for train_indices, validation_indices in splitter.split(
        X,
        y,
        groups=signer_groups,
    ):
        if (
            set(y[train_indices]) == all_class_numbers
            and set(y[validation_indices]) == all_class_numbers
        ):
            split_indices = (train_indices, validation_indices)
            break

    if split_indices is None:
        print(
            "\nCould not hold out signer groups while keeping every label "
            "in both sets. More signers are needed for the affected labels."
        )
        return

    train_indices, validation_indices = split_indices
    held_out_groups = sorted(
        {signer_groups[index] for index in validation_indices}
    )
    print(
        "\nValidation signer group(s) held out from training: "
        + ", ".join(held_out_groups)
    )

    X_train = X[train_indices]
    y_train = y[train_indices]
    X_validation = X[validation_indices]
    y_validation = y[validation_indices]

    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(
                shape=(SEQUENCE_LENGTH, FEATURE_COUNT)
            ),
            tf.keras.layers.Masking(mask_value=0.0),
            tf.keras.layers.Bidirectional(
                tf.keras.layers.LSTM(64)
            ),
            tf.keras.layers.Dropout(0.30),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dense(
                len(class_names),
                activation="softmax",
            ),
        ]
    )

    model.compile(
        optimizer="adam",
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor="val_accuracy",
        patience=8,
        restore_best_weights=True,
    )

    print("\nTraining the first prototype...")
    model.fit(
        X_train,
        y_train,
        validation_data=(X_validation, y_validation),
        epochs=40,
        batch_size=16,
        callbacks=[early_stopping],
        verbose=1,
    )

    validation_loss, validation_accuracy = model.evaluate(
        X_validation,
        y_validation,
        verbose=0,
    )

    # Keep that held-out score as the evaluation. Then refit a fresh app model
    # on all Amrita training clips; a separate random test video stays unseen.
    best_epoch_count = int(getattr(early_stopping, "best_epoch", 0)) + 1
    final_model = tf.keras.models.clone_model(model)
    final_model.compile(
        optimizer="adam",
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    final_model.fit(
        X,
        y,
        epochs=best_epoch_count,
        batch_size=16,
        verbose=0,
    )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    model_path = OUTPUT_DIR / "isl_sign_model.keras"
    labels_path = OUTPUT_DIR / "labels.json"

    final_model.save(model_path)

    with labels_path.open("w", encoding="utf-8") as file:
        json.dump(
            {
                "classes": class_names,
                "sequence_length": SEQUENCE_LENGTH,
                "feature_count": FEATURE_COUNT,
            },
            file,
            indent=2,
        )

    print("\nTraining finished.")
    print(f"Model saved to: {model_path}")
    print(f"Labels saved to: {labels_path}")
    print(f"Signer-held-out validation accuracy: {validation_accuracy:.1%}")
    print("The saved app model was then refit using all training videos.")


if __name__ == "__main__":
    main()
