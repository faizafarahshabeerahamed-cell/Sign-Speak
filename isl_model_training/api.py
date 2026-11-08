import json
import shutil
import tempfile
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

# Find the trained model and label list.
BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "output"
MODEL_DIR = BASE_DIR / "models"

MODEL_PATH = OUTPUT_DIR / "isl_sign_model.keras"
LABELS_PATH = OUTPUT_DIR / "labels.json"
HAND_MODEL_PATH = MODEL_DIR / "hand_landmarker.task"
POSE_MODEL_PATH = MODEL_DIR / "pose_landmarker_lite.task"

SEQUENCE_LENGTH = 20
FEATURE_COUNT = 226
MIN_CONFIDENCE = 0.60


def normalize_hand(hand_values):
    if np.all(hand_values == 0):
        return hand_values

    wrist = hand_values[0]
    hand_values = hand_values - wrist

    scale = np.linalg.norm(
        hand_values[9] - hand_values[0]
    )

    if scale > 1e-6:
        hand_values = hand_values / scale

    return hand_values


def normalize_pose(pose_values):
    if np.all(pose_values == 0):
        return pose_values

    left_shoulder = pose_values[11, :3]
    right_shoulder = pose_values[12, :3]

    center = (left_shoulder + right_shoulder) / 2

    pose_values[:, :3] = (
        pose_values[:, :3] - center
    )

    shoulder_width = np.linalg.norm(
        left_shoulder - right_shoulder
    )

    if shoulder_width > 1e-6:
        pose_values[:, :3] = (
            pose_values[:, :3] / shoulder_width
        )

    return pose_values


# Stop with a clear message if a training output is missing.
needed_files = [
    MODEL_PATH,
    LABELS_PATH,
    HAND_MODEL_PATH,
    POSE_MODEL_PATH,
]

for needed_file in needed_files:
    if not needed_file.exists():
        raise FileNotFoundError(
            f"Required file is missing: {needed_file}"
        )

# Load the trained model and its labels once when the service starts.
with LABELS_PATH.open(
    "r",
    encoding="utf-8"
) as file:
    label_data = json.load(file)

CLASS_NAMES = label_data["classes"]

model = tf.keras.models.load_model(
    MODEL_PATH
)

if model.output_shape[-1] != len(CLASS_NAMES):
    raise ValueError(
        "The model output does not match the saved label list."
    )

app = FastAPI(
    title="SignSpeak local sign recognition service"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://resilient-macaron-81ae77.netlify.app",
        "http://localhost:3000",
        "http://localhost:8080",
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)



def get_frame_features(
    rgb_frame,
    timestamp_ms,
    hand_detector,
    pose_detector,
):
    mp_image = mp.Image(
        image_format=mp.ImageFormat.SRGB,
        data=rgb_frame,
    )

    hand_result = hand_detector.detect_for_video(
        mp_image,
        timestamp_ms,
    )

    pose_result = pose_detector.detect_for_video(
        mp_image,
        timestamp_ms,
    )

    hand_values = np.zeros(
        (2, 21, 3),
        dtype=np.float32,
    )

    for hand_index, landmarks in enumerate(
        hand_result.hand_landmarks[:2]
    ):
        hand_slot = hand_index

        if hand_index < len(hand_result.handedness):
            categories = hand_result.handedness[
                hand_index
            ]

            if categories:
                hand_name = (
                    categories[0]
                    .category_name
                    .lower()
                )

                if hand_name == "left":
                    hand_slot = 0

                elif hand_name == "right":
                    hand_slot = 1

        hand_values[hand_slot] = np.array(
            [
                [point.x, point.y, point.z]
                for point in landmarks
            ],
            dtype=np.float32,
        )

    pose_values = np.zeros(
        (25, 4),
        dtype=np.float32,
    )

    if pose_result.pose_world_landmarks:
        pose_landmarks = (
            pose_result.pose_world_landmarks[0]
        )

        for point_index, point in enumerate(
            pose_landmarks[:25]
        ):
            visibility = getattr(
                point,
                "visibility",
                1.0,
            )

            if visibility is None:
                visibility = 1.0

            pose_values[point_index] = [
                point.x,
                point.y,
                point.z,
                float(visibility),
            ]

    hand_values[0] = normalize_hand(
        hand_values[0]
    )

    hand_values[1] = normalize_hand(
        hand_values[1]
    )

    pose_values = normalize_pose(
        pose_values
    )

    features = np.concatenate(
        [
            hand_values.flatten(),
            pose_values.flatten(),
        ]
    )

    return (
        features.astype(np.float32),
        bool(hand_result.hand_landmarks),
    )


def extract_video_sequence(video_path):
    capture = cv2.VideoCapture(
        str(video_path)
    )

    if not capture.isOpened():
        raise ValueError(
            "The uploaded video could not be opened."
        )

    frame_count = int(
        capture.get(
            cv2.CAP_PROP_FRAME_COUNT
        )
    )

    if frame_count <= 0:
        capture.release()

        raise ValueError(
            "The uploaded video has no readable frames."
        )

    frame_numbers = np.linspace(
        0,
        frame_count - 1,
        num=min(
            SEQUENCE_LENGTH,
            frame_count
        ),
        dtype=int,
    )

    hand_options = (
        mp.tasks.vision.HandLandmarkerOptions(
            base_options=mp.tasks.BaseOptions(
                model_asset_path=str(
                    HAND_MODEL_PATH
                )
            ),
            running_mode=mp.tasks.vision.RunningMode.VIDEO,
            num_hands=2,
        )
    )

    pose_options = (
        mp.tasks.vision.PoseLandmarkerOptions(
            base_options=mp.tasks.BaseOptions(
                model_asset_path=str(
                    POSE_MODEL_PATH
                )
            ),
            running_mode=mp.tasks.vision.RunningMode.VIDEO,
            num_poses=1,
        )
    )

    sequence = []
    hands_seen = False

    try:
        with (
            mp.tasks.vision.HandLandmarker.create_from_options(
                hand_options
            ) as hand_detector,
            mp.tasks.vision.PoseLandmarker.create_from_options(
                pose_options
            ) as pose_detector,
        ):
            for (
                sample_index,
                frame_number,
            ) in enumerate(
                frame_numbers
            ):
                capture.set(
                    cv2.CAP_PROP_POS_FRAMES,
                    int(frame_number),
                )

                success, frame = capture.read()

                if not success:
                    continue

                rgb_frame = cv2.cvtColor(
                    frame,
                    cv2.COLOR_BGR2RGB,
                )

                timestamp_ms = (
                    sample_index * 40
                )

                (
                    features,
                    found_hands,
                ) = get_frame_features(
                    rgb_frame,
                    timestamp_ms,
                    hand_detector,
                    pose_detector,
                )

                sequence.append(
                    features
                )

                hands_seen = (
                    hands_seen
                    or found_hands
                )

    finally:
        capture.release()

    if not sequence:
        raise ValueError(
            "No frames could be read from this video."
        )

    while len(sequence) < SEQUENCE_LENGTH:
        sequence.append(
            sequence[-1].copy()
        )

    sequence = np.asarray(
        sequence[:SEQUENCE_LENGTH],
        dtype=np.float32,
    )

    return sequence, hands_seen


@app.get("/health")
def health():
    return {
        "status": "ready",
        "sign_labels": len(CLASS_NAMES),
    }


@app.post("/predict")
def predict(
    file: UploadFile = File(...)
):
    filename = file.filename or ""

    if (
        Path(filename)
        .suffix
        .lower()
        != ".mp4"
    ):
        raise HTTPException(
            status_code=400,
            detail="Please upload an MP4 video.",
        )

    temporary_path = None

    try:
        with tempfile.NamedTemporaryFile(
            suffix=".mp4",
            delete=False,
        ) as temporary_file:
            temporary_path = Path(
                temporary_file.name
            )

            shutil.copyfileobj(
                file.file,
                temporary_file,
            )

        (
            sequence,
            hands_seen,
        ) = extract_video_sequence(
            temporary_path
        )

        if not hands_seen:
            return {
                "label": "not_sign",
                "raw_label": None,
                "confidence": 0.0,
                "is_sign": False,
                "message": "No hands were detected in this video.",
            }

        probabilities = model.predict(
            np.expand_dims(
                sequence,
                axis=0,
            ),
            verbose=0,
        )[0]

        best_index = int(
            np.argmax(probabilities)
        )

        raw_label = CLASS_NAMES[
            best_index
        ]

        confidence = float(
            probabilities[best_index]
        )

        if raw_label == "not_sign":
            return {
                "label": "not_sign",
                "raw_label": raw_label,
                "confidence": round(
                    confidence,
                    3,
                ),
                "is_sign": False,
                "message": "The video was classified as non-sign.",
            }

        if confidence < MIN_CONFIDENCE:
            return {
                "label": "uncertain",
                "raw_label": raw_label,
                "confidence": round(confidence, 3),
                "is_sign": False,
                "message": "The model is not confident enough to translate this clip.",
            }

        return {
            "label": raw_label,
            "raw_label": raw_label,
            "confidence": round(
                confidence,
                3,
            ),
            "is_sign": True,
            "message": "Sign prediction complete.",
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Could not process this video: {error}",
        ) from error

    finally:
        file.file.close()

        if temporary_path is not None:
            temporary_path.unlink(
                missing_ok=True
            )
