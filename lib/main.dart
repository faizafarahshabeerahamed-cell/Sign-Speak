import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

@JS('signSpeakDetectHands')
external JSPromise<JSNumber> _signSpeakDetectHands(String imageUrl);

@JS('signSpeakSpeakText')
external void _signSpeakSpeakText(String text);

const Color ink = Color(0xFF090908);
const Color inkSoft = Color(0xFF11110F);
const Color panel = Color(0xFF171613);
const Color gold = Color(0xFFD8B86C);
const Color goldLight = Color(0xFFF0DDA9);
const Color ivory = Color(0xFFF5F0E5);
const Color muted = Color(0xFFA8A294);

void main() {
  runApp(const SignSpeakApp());
}

class SignSpeakApp extends StatelessWidget {
  const SignSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSpeak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: goldLight,
          surface: inkSoft,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openMedia(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MediaPage()));
  }

  void _openQuest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MediaPage(startInQuest: true)),
    );
  }

  void _showVision(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(26, 28, 26, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A more connected world',
                  style: TextStyle(
                    color: ivory,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'SignSpeak is being built to help people explore '
                  'communication through Indian Sign Language. The current '
                  'prototype can select media and detect hands in an image. '
                  'ISL sign recognition is still being developed.',
                  style: TextStyle(color: muted, height: 1.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ink, Color(0xFF11100C), ink],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          const Positioned(
            top: -190,
            right: -140,
            child: _GoldGlow(size: 420, opacity: 0.12),
          ),
          const Positioned(
            top: 620,
            left: -240,
            child: _GoldGlow(size: 440, opacity: 0.07),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final padding = viewport.maxWidth > 760 ? 48.0 : 22.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(padding, 22, padding, 42),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Header(),
                          const SizedBox(height: 78),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final hero = _HeroSection(
                                onStart: () => _openMedia(context),
                                onQuest: () => _openQuest(context),
                                onVision: () => _showVision(context),
                              );

                              if (constraints.maxWidth > 790) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(flex: 6, child: hero),
                                    const SizedBox(width: 52),
                                    const Expanded(
                                      flex: 5,
                                      child: _HeroArtwork(),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  hero,
                                  const SizedBox(height: 44),
                                  const _HeroArtwork(),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 82),
                          const _SignAvatarShowcase(),
                          const SizedBox(height: 72),
                          const _StatRail(),
                          const SizedBox(height: 96),
                          const _StorySection(),
                          const SizedBox(height: 92),
                          const _ProcessSection(),
                          const SizedBox(height: 92),
                          const _PrinciplesSection(),
                          const SizedBox(height: 78),
                          _ClosingBanner(onStart: () => _openMedia(context)),
                          const SizedBox(height: 48),
                          const _Footer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(color: Color(0x443D3016), blurRadius: 25),
            ],
          ),
          child: const Icon(Icons.waves_rounded, color: ink, size: 26),
        ),
        const SizedBox(width: 12),
        const Text(
          'SignSpeak',
          style: TextStyle(
            color: ivory,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF15140F),
            border: Border.all(color: const Color(0xFF4B4029)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: gold, size: 7),
              SizedBox(width: 8),
              Text(
                'INDIAN SIGN LANGUAGE',
                style: TextStyle(
                  color: goldLight,
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onStart,
    required this.onQuest,
    required this.onVision,
  });

  final VoidCallback onStart;
  final VoidCallback onQuest;
  final VoidCallback onVision;

  @override
  Widget build(BuildContext context) {
    final titleSize = MediaQuery.sizeOf(context).width < 500 ? 58.0 : 78.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'A NEW LANGUAGE OF CONNECTION'),
        const SizedBox(height: 27),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'BEYOND\n',
                style: TextStyle(color: ivory),
              ),
              const TextSpan(
                text: 'WORDS.',
                style: TextStyle(color: gold),
              ),
            ],
          ),
          style: TextStyle(
            height: 0.91,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -4.2,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Meaning lives in every movement.',
          style: TextStyle(
            color: Color(0xFFE7DFCE),
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'SignSpeak is exploring a more natural way to understand '
          'Indian Sign Language. A gesture, a glance, a movement of the '
          'hands—each can be part of a conversation.',
          style: TextStyle(color: muted, fontSize: 15, height: 1.8),
        ),
        const SizedBox(height: 29),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('EXPLORE SIGNSPEAK'),
              style: FilledButton.styleFrom(
                foregroundColor: ink,
                backgroundColor: gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 17,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                  fontSize: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onQuest,
              icon: const Icon(Icons.emoji_events_rounded, size: 17),
              label: const Text('SIGN QUEST'),
              style: OutlinedButton.styleFrom(
                foregroundColor: goldLight,
                side: const BorderSide(color: gold),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: onVision,
              style: OutlinedButton.styleFrom(
                foregroundColor: ivory,
                side: const BorderSide(color: Color(0xFF554A32)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'OUR VISION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 14, color: gold),
            SizedBox(width: 8),
            Text(
              'A prototype in progress, built around ISL.',
              style: TextStyle(color: Color(0xFF888374), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 454,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xE512110E),
        border: Border.all(color: const Color(0xFF4A402C)),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x223E321A), blurRadius: 60, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'THE LANGUAGE OF MOVEMENT',
                style: TextStyle(
                  color: Color(0xFFB8AE96),
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF292216),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PROTOTYPE',
                  style: TextStyle(
                    color: goldLight,
                    fontSize: 8,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x223E392D)),
                  ),
                ),
                Container(
                  width: 242,
                  height: 242,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x444E432D)),
                  ),
                ),
                Container(
                  width: 184,
                  height: 184,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF3A2F1B), Color(0xFF191710)],
                    ),
                    border: Border.all(color: const Color(0xFF9E8143)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x334E3B19),
                        blurRadius: 48,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pan_tool_alt_rounded,
                    color: goldLight,
                    size: 76,
                  ),
                ),
                const Positioned(
                  top: 54,
                  right: 55,
                  child: _GoldPoint(size: 9),
                ),
                const Positioned(
                  bottom: 68,
                  left: 48,
                  child: _GoldPoint(size: 7),
                ),
                const Positioned(
                  top: 120,
                  left: 31,
                  child: _GoldPoint(size: 6),
                ),
                const Positioned(
                  bottom: 39,
                  right: 83,
                  child: _GoldPoint(size: 5),
                ),
                const Positioned(
                  bottom: 31,
                  child: Text(
                    'GESTURE  •  PRESENCE  •  MEANING',
                    style: TextStyle(
                      color: Color(0xFF9E947E),
                      fontSize: 8,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0C0A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF352F22)),
            ),
            child: const Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: gold, size: 23),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A MESSAGE, WAITING TO BE UNDERSTOOD',
                        style: TextStyle(
                          color: Color(0xFF8F8877),
                          fontSize: 8,
                          letterSpacing: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Every voice deserves a way through.',
                        style: TextStyle(
                          color: ivory,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRail extends StatelessWidget {
  const _StatRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF12110E),
        border: Border.all(color: const Color(0xFF302A1E)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Wrap(
        spacing: 38,
        runSpacing: 20,
        children: [
          _StatItem(
            number: '01',
            label: 'LANGUAGE',
            value: 'Indian Sign Language',
          ),
          _StatItem(number: '02', label: 'INPUT', value: 'Images and video'),
          _StatItem(
            number: '03',
            label: 'PURPOSE',
            value: 'Shared understanding',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.number,
    required this.label,
    required this.value,
  });

  final String number;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF847D6D),
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFE1DACB),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = const Text(
          'A world that listens\nwith its eyes.',
          style: TextStyle(
            color: ivory,
            fontSize: 38,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        );

        final body = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication is more than sound. Sign language carries '
              'meaning through movement, expression, and shared attention.',
              style: TextStyle(
                color: Color(0xFFB0AA9A),
                fontSize: 15,
                height: 1.8,
              ),
            ),
            SizedBox(height: 15),
            Text(
              'SignSpeak is being shaped around that idea. The goal is to '
              'create a welcoming place to explore ISL, with tools that can '
              'help bridge conversations between people who sign and people '
              'who are still learning.',
              style: TextStyle(color: muted, fontSize: 14, height: 1.8),
            ),
          ],
        );

        if (constraints.maxWidth > 740) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 58),
              Expanded(child: body),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 22), body],
        );
      },
    );
  }
}

class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'THE JOURNEY'),
        const SizedBox(height: 15),
        const Text(
          'From a gesture to a connection.',
          style: TextStyle(
            color: ivory,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'We’re building each part carefully, with a clear view of what '
          'works today and what still needs to be created.',
          style: TextStyle(color: muted, fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 25),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 760
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: const _ProcessCard(
                    number: '01',
                    icon: Icons.photo_library_outlined,
                    state: 'AVAILABLE',
                    title: 'Choose your media',
                    detail: 'Select an image or video to begin exploring.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _ProcessCard(
                    number: '02',
                    icon: Icons.center_focus_strong_rounded,
                    state: 'WORKING',
                    title: 'Find the hands',
                    detail:
                        'The current prototype can detect hands in an image.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _ProcessCard(
                    number: '03',
                    icon: Icons.translate_rounded,
                    state: 'IN DEVELOPMENT',
                    title: 'Understand the sign',
                    detail:
                        'A custom ISL model will be needed to recognize signs.',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard({
    required this.number,
    required this.icon,
    required this.state,
    required this.title,
    required this.detail,
  });

  final String number;
  final IconData icon;
  final String state;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF332E23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(icon, color: goldLight, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            state,
            style: const TextStyle(
              color: Color(0xFFB69A5C),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: ivory,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            detail,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _PrinciplesSection extends StatelessWidget {
  const _PrinciplesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1913), Color(0xFF100F0C)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF403622)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;

          const heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(text: 'WHAT MATTERS'),
              SizedBox(height: 15),
              Text(
                'Designed around\nreal communication.',
                style: TextStyle(
                  color: ivory,
                  fontSize: 31,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          );

          const details = Column(
            children: [
              _PrincipleRow(
                icon: Icons.people_alt_outlined,
                title: 'Respect the language',
                text: 'ISL is a language, not a collection of random gestures.',
              ),
              SizedBox(height: 18),
              _PrincipleRow(
                icon: Icons.explore_outlined,
                title: 'Grow with care',
                text: 'Recognition should expand through examples and testing.',
              ),
              SizedBox(height: 18),
              _PrincipleRow(
                icon: Icons.question_mark_rounded,
                title: 'Be honest when unsure',
                text: 'The app should say when it cannot recognize a sign.',
              ),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 5, child: heading),
                const SizedBox(width: 45),
                const Expanded(flex: 6, child: details),
              ],
            );
          }

          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, SizedBox(height: 28), details],
          );
        },
      ),
    );
  }
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF292216),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: goldLight, size: 19),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ivory,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text,
                style: const TextStyle(color: muted, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClosingBanner extends StatelessWidget {
  const _ClosingBanner({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x223E321A), blurRadius: 38, spreadRadius: 2),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THE NEXT CONVERSATION STARTS HERE',
                style: TextStyle(
                  color: Color(0xFF594721),
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your hands have something to say.',
                style: TextStyle(
                  color: ink,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore the SignSpeak prototype and see what is being built.',
                style: TextStyle(color: Color(0xFF594721), fontSize: 13),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('GET STARTED'),
            style: FilledButton.styleFrom(
              foregroundColor: goldLight,
              backgroundColor: ink,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          if (constraints.maxWidth > 720) {
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 20),
                button,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [content, const SizedBox(height: 20), button],
          );
        },
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 1, color: gold),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: goldLight,
            fontSize: 9,
            letterSpacing: 1.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GoldPoint extends StatelessWidget {
  const _GoldPoint({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: goldLight,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x88D8B86C), blurRadius: 12)],
      ),
    );
  }
}

class _GoldGlow extends StatelessWidget {
  const _GoldGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: opacity),
              blurRadius: 145,
              spreadRadius: 38,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignAvatarShowcase extends StatefulWidget {
  const _SignAvatarShowcase();

  @override
  State<_SignAvatarShowcase> createState() => _SignAvatarShowcaseState();
}

class _SignAvatarShowcaseState extends State<_SignAvatarShowcase>
    with SingleTickerProviderStateMixin {
  static const List<String> _topics = [
    'Handshape',
    'Movement',
    'Location & direction',
    'Face & body',
  ];

  static const List<IconData> _topicIcons = [
    Icons.back_hand_rounded,
    Icons.gesture_rounded,
    Icons.open_with_rounded,
    Icons.face_rounded,
  ];

  static const List<String> _topicDetails = [
    'The shape of the hand and fingers can distinguish one sign from another. '
        'A clear view of the fingers helps a viewer follow the gesture.',
    'Direction, path, and repetition can carry meaning. A still photo cannot '
        'show the full movement of a dynamic sign.',
    'Signs can be formed near the face, torso, or in signing space. Palm '
        'orientation and direction may also matter.',
    'Facial expression and body posture can contribute grammar and tone. '
        'Sign languages communicate through more than hands alone.',
  ];

  int _selectedTopic = 0;

  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF11100D),
        border: Border.all(color: const Color(0xFF574A2B)),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x224D421F), blurRadius: 34, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: gold, size: 19),
              SizedBox(width: 10),
              Expanded(child: _Eyebrow(text: 'SIGN LANGUAGE, IN MOTION')),
              Text(
                '3D-STYLE GUIDE',
                style: TextStyle(
                  color: goldLight,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;
              final stageHeight = wide ? 390.0 : 330.0;
              return Container(
                height: stageHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.25),
                    radius: 0.9,
                    colors: [Color(0xFF302718), Color(0xFF15130F)],
                  ),
                  border: Border.all(color: const Color(0xFF3B3323)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _motion,
                        builder: (context, _) => CustomPaint(
                          painter: _AlignedSignerPainter(
                            _motion.value,
                            _selectedTopic,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 16,
                      child: _AvatarTag(
                        icon: Icons.motion_photos_on_rounded,
                        text: 'EXPRESSIVE MOTION',
                      ),
                    ),
                    const Positioned(
                      right: 16,
                      bottom: 16,
                      child: _AvatarTag(
                        icon: Icons.pan_tool_alt_rounded,
                        text: 'ISL INSPIRED',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 23),
          const Text(
            'Explore the building blocks of a sign.',
            style: TextStyle(
              color: ivory,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Tap a topic to explore it and see the signer animate that cue.',
            style: TextStyle(color: muted, height: 1.65, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: List.generate(_topics.length, (index) {
              final selected = _selectedTopic == index;
              return ChoiceChip(
                avatar: Icon(
                  _topicIcons[index],
                  size: 16,
                  color: selected ? ink : goldLight,
                ),
                label: Text(_topics[index]),
                selected: selected,
                onSelected: (_) => setState(() => _selectedTopic = index),
                labelStyle: TextStyle(
                  color: selected ? ink : ivory,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: gold,
                backgroundColor: const Color(0xFF191711),
                side: BorderSide(
                  color: selected ? gold : const Color(0xFF51452A),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                showCheckmark: false,
              );
            }),
          ),
          const SizedBox(height: 13),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(_selectedTopic),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF191711),
                border: Border.all(color: const Color(0xFF51452A)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_topicIcons[_selectedTopic], color: gold, size: 21),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _topics[_selectedTopic],
                          style: const TextStyle(
                            color: goldLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _topicDetails[_selectedTopic],
                          style: const TextStyle(
                            color: ivory,
                            height: 1.55,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Learning note: these are general visual cues, not instructions '
            'for performing a specific ISL sign. Sign forms vary; learn them '
            'from qualified ISL teachers and trusted references. This '
            'animated guide is decorative and does not demonstrate verified '
            'ISL signs.',
            style: TextStyle(
              color: Color(0xFF817C70),
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarTag extends StatelessWidget {
  const _AvatarTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD90D0C0A),
        border: Border.all(color: const Color(0x665F5438)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: goldLight, size: 14),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: ivory,
              fontSize: 9,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignedSignerPainter extends CustomPainter {
  const _AlignedSignerPainter(this.phase, this.activeTopic);

  final double phase;
  final int activeTopic;

  @override
  void paint(Canvas canvas, Size size) {
    const designWidth = 360.0;
    const designHeight = 370.0;
    final scale = math.min(
      size.width / designWidth,
      size.height / designHeight,
    );
    final origin = Offset(
      (size.width - designWidth * scale) / 2,
      (size.height - designHeight * scale) / 2,
    );
    final motion = math.sin(phase * math.pi * 2);
    final breath = math.cos(phase * math.pi * 2);
    final movementBoost = activeTopic == 1 ? 2.1 : 1.0;
    final locationLift = activeTopic == 2
        ? 27 + 25 * (0.5 + 0.5 * breath)
        : 0.0;
    final fingerSpread = activeTopic == 0 ? 2.5 * (0.5 + 0.5 * motion) : 0.0;
    final fingerCurl = activeTopic == 0 ? 5.0 * (0.5 + 0.5 * breath) : 0.0;
    final expression = activeTopic == 3 ? 0.5 + 0.5 * motion : 0.0;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);

    final halo = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x334D3A1D), Color(0x004D3A1D)],
      ).createShader(Rect.fromCircle(center: Offset(180, 180), radius: 178));
    canvas.drawRect(const Rect.fromLTWH(0, 0, designWidth, designHeight), halo);

    final orbit = Paint()
      ..color = gold.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      const Rect.fromLTWH(47, 36, 266, 266),
      -math.pi * 0.78 + phase * math.pi * 2,
      math.pi * 0.66,
      false,
      orbit,
    );
    canvas.drawArc(
      const Rect.fromLTWH(29, 58, 302, 254),
      math.pi * 0.1 - phase * math.pi * 2,
      math.pi * 0.48,
      false,
      orbit..color = gold.withValues(alpha: 0.11),
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(180, 355), width: 164, height: 17),
      Paint()..color = Colors.black.withValues(alpha: 0.43),
    );

    // Neck joins the head and shoulders before the shirt is painted over its base.
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(164, 103, 32, 55),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      neck,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9B624C), Color(0xFFFFD0A5), Color(0xFFB7785B)],
        ).createShader(neck.outerRect),
    );

    final torso = Path()
      ..moveTo(133, 145)
      ..quadraticBezierTo(180, 125, 227, 145)
      ..quadraticBezierTo(246, 153, 253, 194)
      ..lineTo(270, 346)
      ..quadraticBezierTo(180, 364, 90, 346)
      ..lineTo(107, 194)
      ..quadraticBezierTo(114, 153, 133, 145)
      ..close();
    final torsoBounds = const Rect.fromLTRB(90, 125, 270, 364);
    canvas.drawPath(
      torso,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF53626A), Color(0xFF202D32), Color(0xFF11191C)],
        ).createShader(torsoBounds),
    );
    canvas.drawPath(
      torso,
      Paint()
        ..color = gold.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // A restrained neckline gives the chest and shoulders clearer structure.
    final neckline = Path()
      ..moveTo(157, 139)
      ..lineTo(180, 165)
      ..lineTo(203, 139);
    canvas.drawPath(
      neckline,
      Paint()
        ..color = const Color(0xFF9D8A65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final leftShoulder = Offset(137, 154 + breath * 1.5);
    final rightShoulder = Offset(223, 154 + breath * 1.5);
    final leftElbow = Offset(
      111 - motion * 5 * movementBoost,
      199 + motion * 4 * movementBoost,
    );
    final rightElbow = Offset(
      249 + motion * 5 * movementBoost,
      199 - motion * 4 * movementBoost,
    );
    final leftWrist = Offset(
      146 - motion * 7 * movementBoost,
      220 - locationLift + breath * 6 * movementBoost,
    );
    final rightWrist = Offset(
      214 + motion * 7 * movementBoost,
      220 - locationLift - breath * 6 * movementBoost,
    );

    _drawForearm(canvas, leftShoulder, leftElbow, leftWrist);
    _drawForearm(canvas, rightShoulder, rightElbow, rightWrist);

    // The palms sit directly on the forearm endpoints, keeping each hand attached.
    _drawOpenHand(
      canvas,
      leftWrist,
      -0.15 + motion * 0.11 * movementBoost,
      true,
      fingerSpread,
      fingerCurl,
    );
    _drawOpenHand(
      canvas,
      rightWrist,
      0.15 - motion * 0.11 * movementBoost,
      false,
      fingerSpread,
      fingerCurl,
    );

    final headCenter = Offset(
      180,
      72 + breath * (activeTopic == 3 ? 2.5 : 1.1),
    );
    final headRect = Rect.fromCircle(center: headCenter, radius: 38);
    canvas.drawOval(
      headRect.shift(const Offset(1, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.42),
          colors: [Color(0xFFFFD6B4), Color(0xFFD99670), Color(0xFF8B5545)],
          stops: [0, 0.7, 1],
        ).createShader(headRect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter.translate(-38, 1),
        width: 11,
        height: 19,
      ),
      Paint()..color = const Color(0xFFC98262),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter.translate(38, 1),
        width: 11,
        height: 19,
      ),
      Paint()..color = const Color(0xFFC98262),
    );

    final hair = Path()
      ..moveTo(143, 74)
      ..quadraticBezierTo(135, 28, 177, 29)
      ..quadraticBezierTo(218, 25, 218, 69)
      ..quadraticBezierTo(206, 54, 191, 52)
      ..quadraticBezierTo(171, 53, 154, 43)
      ..quadraticBezierTo(154, 60, 143, 74)
      ..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xFF191414));
    canvas.drawPath(
      hair,
      Paint()
        ..color = const Color(0xFF665044).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final featurePaint = Paint()
      ..color = const Color(0xFF4B3029)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final browLift = expression * 3.2;
    canvas.drawLine(
      Offset(163, 68 - browLift),
      Offset(171, 68 - browLift),
      featurePaint,
    );
    canvas.drawLine(
      Offset(189, 68 - browLift),
      Offset(197, 68 - browLift),
      featurePaint,
    );
    canvas.drawCircle(
      const Offset(167, 75),
      1.7,
      Paint()..color = const Color(0xFF30201C),
    );
    canvas.drawCircle(
      const Offset(193, 75),
      1.7,
      Paint()..color = const Color(0xFF30201C),
    );
    canvas.drawLine(const Offset(180, 78), const Offset(179, 88), featurePaint);
    if (expression > 0.68) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(180, 96), width: 12, height: 7),
        Paint()..color = const Color(0xFF75463D),
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(180, 95), width: 8, height: 2.2),
        Paint()..color = const Color(0xFFFFD3AE),
      );
    } else {
      final smile = Path()
        ..moveTo(171, 94)
        ..quadraticBezierTo(180, 98 + expression * 4, 189, 94);
      canvas.drawPath(smile, featurePaint);
    }

    canvas.restore();
  }

  void _drawForearm(
    Canvas canvas,
    Offset shoulder,
    Offset elbow,
    Offset wrist,
  ) {
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(elbow.dx, elbow.dy - 12, elbow.dx, elbow.dy)
      ..quadraticBezierTo(elbow.dx, elbow.dy + 22, wrist.dx, wrist.dy);
    final bounds = Rect.fromLTRB(
      math.min(shoulder.dx, wrist.dx) - 18,
      math.min(shoulder.dy, wrist.dy) - 12,
      math.max(shoulder.dx, wrist.dx) + 18,
      math.max(shoulder.dy, wrist.dy) + 24,
    );
    canvas.drawPath(
      path.shift(const Offset(1, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFAC7055), Color(0xFFFFD0A5), Color(0xFFD28E6D)],
        ).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFE0C4).withValues(alpha: 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawOpenHand(
    Canvas canvas,
    Offset wrist,
    double angle,
    bool leftHand,
    double spread,
    double curl,
  ) {
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(angle);

    final centers = <double>[
      -10.5 - spread,
      -3.5 - spread / 3,
      3.5 + spread / 3,
      10.5 + spread,
    ];
    final tips = <double>[-52, -59, -58, -51].map((y) => y + curl).toList();
    final hand = Path()
      ..moveTo(-12, 8)
      ..lineTo(-14, -24)
      ..quadraticBezierTo(-15, -32, -11, -33);

    for (var i = 0; i < centers.length; i++) {
      final center = centers[i];
      final left = center - 3.1;
      final right = center + 3.1;
      if (i > 0) hand.lineTo(left, -31);
      hand
        ..quadraticBezierTo(left, tips[i] + 7, center, tips[i])
        ..quadraticBezierTo(right, tips[i] + 7, right, -30);
    }
    hand
      ..lineTo(14, -23)
      ..quadraticBezierTo(15, -12, 13, -4)
      ..quadraticBezierTo(11, 6, 0, 8)
      ..close();

    final direction = leftHand ? -1.0 : 1.0;
    final thumb = Path()
      ..moveTo(direction * 10, -7)
      ..quadraticBezierTo(direction * 24, -9, direction * 24, -19)
      ..quadraticBezierTo(direction * 24, -27, direction * 18, -28)
      ..quadraticBezierTo(direction * 14, -27, direction * 11, -19)
      ..close();
    final skin = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFC27E60), Color(0xFFFFD2AA), Color(0xFFD18E6E)],
      ).createShader(const Rect.fromLTRB(-28, -66, 28, 10));

    // The thumb overlaps the palm; one connected outline contains all four fingers.
    canvas.drawPath(
      thumb.shift(const Offset(1, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawPath(thumb, skin);
    canvas.drawPath(
      hand.shift(const Offset(1, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawPath(hand, skin);

    final creases = Paint()
      ..color = const Color(0xFFAE7258).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < centers.length - 1; i++) {
      final gap = (centers[i] + centers[i + 1]) / 2;
      canvas.drawLine(Offset(gap, -27), Offset(gap, -13), creases);
    }
    canvas.drawArc(
      const Rect.fromLTWH(-8, -4, 16, 10),
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      creases,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AlignedSignerPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.activeTopic != activeTopic;
}

class MediaPage extends StatefulWidget {
  const MediaPage({super.key, this.startInQuest = false});

  final bool startInQuest;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  final ImagePicker _picker = ImagePicker();
  final math.Random _random = math.Random();

  static const List<String> _questWords = [
    'good',
    'hello',
    'help',
    'sorry',
    'stop',
    'study',
    'thankyou',
    'today',
    'welcome',
    'work',
  ];

  Uint8List? _imageBytes;
  String? _videoName;
  XFile? _videoFile;
  String? _imageUrl;
  String? _detectionMessage;
  bool _checkingHands = false;
  bool _recognizingVideo = false;
  String? _recognizedText;
  bool _practiceMode = false;
  String? _targetWord;
  String? _questFeedback;
  bool _roundComplete = false;
  bool _roundWasCorrect = false;
  int _questRound = 1;
  int _questScore = 0;
  int _questStreak = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startInQuest) {
      _practiceMode = true;
      _targetWord = _questWords[_random.nextInt(_questWords.length)];
    }
  }

  void _startQuest() {
    setState(() {
      _practiceMode = true;
      _targetWord = _questWords[_random.nextInt(_questWords.length)];
      _questRound = 1;
      _questScore = 0;
      _questStreak = 0;
      _questFeedback = null;
      _roundComplete = false;
      _videoName = null;
      _videoFile = null;
      _imageBytes = null;
      _imageUrl = null;
      _detectionMessage = null;
      _recognizedText = null;
    });
  }

  void _exitQuest() {
    setState(() {
      _practiceMode = false;
      _targetWord = null;
      _questFeedback = null;
      _roundComplete = false;
      _videoName = null;
      _videoFile = null;
      _recognizedText = null;
      _detectionMessage = null;
    });
  }

  void _startNextQuestRound() {
    final options = _questWords.where((word) => word != _targetWord).toList();
    setState(() {
      _targetWord = options[_random.nextInt(options.length)];
      _questRound++;
      _questFeedback = null;
      _roundComplete = false;
      _videoName = null;
      _videoFile = null;
      _recognizedText = null;
      _detectionMessage = null;
    });
  }

  String _canonicalWord(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');

  Widget _buildQuestCard() {
    final target = _targetWord ?? 'hello';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF282316), Color(0xFF171613)],
        ),
        border: Border.all(color: gold),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x224D421F), blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: gold),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'SIGN QUEST',
                  style: TextStyle(
                    color: goldLight,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'ROUND $_questRound',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'SIGN THIS WORD',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _friendlyLabel(target).toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldLight,
              fontSize: 42,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _QuestStat(label: 'SCORE', value: '$_questScore'),
              _QuestStat(label: 'STREAK', value: '$_questStreak 🔥'),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => _signSpeakSpeakText(_friendlyLabel(target)),
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Hear the word'),
              style: TextButton.styleFrom(foregroundColor: goldLight),
            ),
          ),
          if (_questFeedback != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _roundWasCorrect
                    ? const Color(0x2234C78A)
                    : const Color(0x22D8B86C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _roundWasCorrect
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: _roundWasCorrect ? const Color(0xFF65D6A4) : gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _questFeedback!,
                      style: const TextStyle(color: ivory, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Choose a short video of someone signing this word, then let SignSpeak check it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.45),
            ),
          ],
          if (_roundComplete) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _startNextQuestRound,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next sign'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _videoName = null;
      _videoFile = null;
      _imageUrl = file.path;
      _detectionMessage = null;
      _recognizedText = null;
      if (_practiceMode && !_roundComplete) _questFeedback = null;
    });
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _videoName = file.name;
      _videoFile = file;
      _imageBytes = null;
      _imageUrl = null;
      _detectionMessage = null;
      _recognizedText = null;
      if (_practiceMode && !_roundComplete) _questFeedback = null;
    });
  }

  Future<void> _checkForHands() async {
    if (_imageUrl == null) return;

    setState(() {
      _checkingHands = true;
      _detectionMessage = null;
    });

    try {
      final result = await _signSpeakDetectHands(_imageUrl!).toDart;
      final handCount = result.toDartInt;

      if (!mounted) return;

      setState(() {
        _checkingHands = false;
        _detectionMessage = handCount == 0
            ? 'No hands detected in this image.'
            : '$handCount hand(s) detected. Choose a video.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingHands = false;
        _detectionMessage = 'Could not check this image. Please try again.';
      });
    }
  }

  Future<void> _recognizeVideo() async {
    final video = _videoFile;
    if (video == null) return;

    setState(() {
      _recognizingVideo = true;
      _detectionMessage = null;
      _recognizedText = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8001/predict'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await video.readAsBytes(),
          filename: video.name,
        ),
      );

      final response = await request.send().timeout(const Duration(minutes: 3));

      final responseText = await response.stream.bytesToString().timeout(
        const Duration(minutes: 3),
      );

      final decoded = jsonDecode(responseText);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map ? decoded['detail'] : null;
        throw Exception(detail ?? 'The Python service returned an error.');
      }

      if (decoded is! Map) {
        throw const FormatException('Unexpected response from the service.');
      }

      final result = Map<String, dynamic>.from(decoded);
      final rawLabel = (result['label'] ?? 'uncertain').toString().replaceAll(
        '_',
        ' ',
      );
      final label = _friendlyLabel(rawLabel);
      final scoreValue = result['confidence'];
      final score = scoreValue is num ? scoreValue.toDouble() : 0.0;
      final isSign = result['is_sign'] == true;

      if (!mounted) return;

      setState(() {
        _recognizedText = isSign ? label : null;
        _detectionMessage = isSign
            ? 'Possible sign: ${label.toUpperCase()} '
                  '(${(score * 100).round()}% model score).'
            : '${result['message'] ?? 'No confident sign prediction.'} '
                  '(${(score * 100).round()}% model score).';

        if (_practiceMode && _targetWord != null) {
          if (isSign && _canonicalWord(label) == _canonicalWord(_targetWord!)) {
            _roundWasCorrect = true;
            _roundComplete = true;
            _questScore += 10;
            _questStreak++;
            _questFeedback =
                'Correct! You earned 10 points. Keep your streak going.';
          } else if (isSign) {
            _roundWasCorrect = false;
            _roundComplete = true;
            _questStreak = 0;
            _questFeedback =
                'The model predicted “${label.toUpperCase()}”. '
                'The target was “${_friendlyLabel(_targetWord!).toUpperCase()}”.';
          } else {
            _roundWasCorrect = false;
            _roundComplete = false;
            _questFeedback =
                'The model was unsure. Try another clear clip of this sign.';
          }
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _detectionMessage =
            'Recognition failed. Check that the Python service is running. $error';
        if (_practiceMode) {
          _roundWasCorrect = false;
          _roundComplete = false;
          _questFeedback = 'Could not check this clip. Your score is unchanged; try again when the service is available.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _recognizingVideo = false;
        });
      }
    }
  }

  String _friendlyLabel(String label) {
    final normalized = label.toLowerCase().trim();
    const displayLabels = <String, String>{
      'thankyou': 'thank you',
      'goodmorning': 'good morning',
      'youareperfect': 'you are perfect',
    };
    return displayLabels[normalized] ?? normalized;
  }

  void _speakRecognized() {
    final text = _recognizedText;
    if (text == null || text.isEmpty) return;
    _signSpeakSpeakText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_practiceMode ? 'Sign Quest' : 'ISL Media'),
        backgroundColor: const Color(0xFF080B16),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: _practiceMode ? _exitQuest : _startQuest,
              icon: Icon(
                _practiceMode
                    ? Icons.close_rounded
                    : Icons.emoji_events_outlined,
              ),
              label: Text(_practiceMode ? 'Exit Quest' : 'Sign Quest'),
              style: TextButton.styleFrom(foregroundColor: goldLight),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _practiceMode
                      ? 'Ready for a challenge?'
                      : 'Choose signing media',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _practiceMode
                      ? 'Sign the target word and submit a short video to earn points.'
                      : 'Select a photo or a short video of someone signing.',
                  style: const TextStyle(color: Color(0xFF929DB4), height: 1.5),
                ),
                if (_practiceMode) ...[
                  const SizedBox(height: 20),
                  _buildQuestCard(),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (!_practiceMode)
                      FilledButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Choose image'),
                      ),
                    OutlinedButton.icon(
                      onPressed: (_roundComplete || _recognizingVideo)
                          ? null
                          : _pickVideo,
                      icon: const Icon(Icons.video_library_outlined),
                      label: Text(
                        _practiceMode ? 'Choose signing clip' : 'Choose video',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(minHeight: 240),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101727),
                    border: Border.all(color: const Color(0xFF293349)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : _videoName != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.video_file_outlined,
                                  size: 54,
                                  color: Color(0xFF58E8F7),
                                ),
                                const SizedBox(height: 12),
                                Text(_videoName!, textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                const Text(
                                  'Choose Recognize sign video below to process this clip.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF929DB4)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Your selected media will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF929DB4)),
                            ),
                          ),
                        ),
                ),
                if (_recognizedText != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171613),
                      border: Border.all(color: gold),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x334D421F),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TRANSLATED WORD',
                          style: TextStyle(
                            color: Color(0xFFB5AA8B),
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognizedText!.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: goldLight,
                            fontSize: 42,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _speakRecognized,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text('Read aloud'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: goldLight,
                            side: const BorderSide(color: gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_imageUrl != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _checkingHands ? null : _checkForHands,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      _checkingHands ? 'Checking…' : 'Check for hands',
                    ),
                  ),
                ],
                if (_videoFile != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: (_recognizingVideo || _roundComplete)
                        ? null
                        : _recognizeVideo,
                    icon: const Icon(Icons.translate_rounded),
                    label: Text(
                      _recognizingVideo
                          ? 'Recognizing…'
                          : _practiceMode
                          ? 'Check my sign'
                          : 'Recognize sign video',
                    ),
                  ),
                ],
                if (_detectionMessage != null &&
                    _recognizedText == null &&
                    !_practiceMode) ...[
                  const SizedBox(height: 12),
                  Text(
                    _detectionMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF929DB4)),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  _practiceMode
                      ? 'A correct, confident match earns 10 points. A streak earns bragging rights.'
                      : 'Image hand-checking is separate. Sign predictions use short videos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF929DB4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestStat extends StatelessWidget {
  const _QuestStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF11100D),
        border: Border.all(color: const Color(0xFF574A2B)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            value,
            style: const TextStyle(
              color: goldLight,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF403925))),
      ),
      child: const Row(
        children: [
          Icon(Icons.waves_rounded, color: gold, size: 17),
          SizedBox(width: 9),
          Text(
            'SIGNSPEAK • INDIAN SIGN LANGUAGE',
            style: TextStyle(
              color: Color(0xFF9C947F),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Text(
            'A PROTOTYPE IN PROGRESS',
            style: TextStyle(
              color: Color(0xFF777263),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
