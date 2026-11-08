import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

// ---------------------------------------------------------------------------
// Motion helpers (effects only - these never change the layout or colours)
// ---------------------------------------------------------------------------

Duration _ms(int value) => Duration(milliseconds: value);

/// Smooth fade + slide transition used when opening another page.
Route<T> _softRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: _ms(450),
    reverseTransitionDuration: _ms(300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Fades and slides its child in. It starts when the widget is on screen, so
/// the top of the page animates when the site opens and lower sections
/// animate as the user scrolls down to them.
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.dx = 0,
    this.dy = 28,
    this.scale = 1,
    this.blur = 0,
    this.wipe = false,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dx;
  final double dy;
  final double scale;
  final double blur;
  final bool wipe;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  ScrollPosition? _position;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    if (top > viewportHeight * 0.92) return;

    _started = true;
    // Wait for the opening curtain to lift before the first items animate.
    final introWait = _introEnd.difference(DateTime.now());
    final wait =
        widget.delay + (introWait.isNegative ? Duration.zero : introWait);
    Future<void>.delayed(wait, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final v = _curve.value;
        final content = widget.wipe
            ? ClipRect(clipper: _WipeClipper(v), child: child)
            : child;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(widget.dx * (1 - v), widget.dy * (1 - v)),
            child: Transform.scale(
              scale: widget.scale + (1 - widget.scale) * v,
              child: widget.blur > 0
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: widget.blur * (1 - v) + 0.001,
                        sigmaY: widget.blur * (1 - v) + 0.001,
                      ),
                      child: content,
                    )
                  : content,
            ),
          ),
        );
      },
    );
  }
}

/// Quick pop-in used for results, messages and feedback that appear later.
class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _ms(420),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.94 + 0.06 * value, child: child),
        );
      },
    );
  }
}

/// Gentle up-and-down floating motion.
class _Floating extends StatefulWidget {
  const _Floating({
    required this.child,
    this.distance = 8,
    this.duration = const Duration(milliseconds: 3400),
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, (t - 0.5) * 2 * widget.distance),
          child: child,
        );
      },
    );
  }
}

/// Lifts, enlarges and (optionally) 3D-tilts its child toward the mouse.
class _HoverLift extends StatefulWidget {
  const _HoverLift({
    required this.child,
    this.lift = 4,
    this.scale = 1.0,
    this.tilt = 0,
  });

  final Widget child;
  final double lift;
  final double scale;
  final double tilt;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hover = false;
  Offset _tilt = Offset.zero;

  void _onHover(PointerEvent event) {
    if (widget.tilt <= 0) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final p = event.localPosition;
    setState(() {
      _tilt = Offset(
        ((p.dx / box.size.width) - 0.5) * 2,
        ((p.dy / box.size.height) - 0.5) * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _hover ? widget.scale : 1.0;
    final dy = _hover ? -widget.lift : 0.0;
    var m = Matrix4.translationValues(0, dy, 0) *
        Matrix4.diagonal3Values(s, s, 1);
    if (widget.tilt > 0 && _hover) {
      final r = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(-_tilt.dy * widget.tilt)
        ..rotateY(_tilt.dx * widget.tilt);
      m = m * r;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onHover: _onHover,
      onExit: (_) => setState(() {
        _hover = false;
        _tilt = Offset.zero;
      }),
      child: AnimatedContainer(
        duration: _ms(170),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: m,
        child: widget.child,
      ),
    );
  }
}

class _WipeClipper extends CustomClipper<Rect> {
  const _WipeClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _WipeClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

/// Title whose letters flip up one after another.
class _SplitTitle extends StatefulWidget {
  const _SplitTitle({required this.size});

  final double size;

  @override
  State<_SplitTitle> createState() => _SplitTitleState();
}

class _SplitTitleState extends State<_SplitTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    final wait = _introEnd.difference(DateTime.now()) + _ms(250);
    Future<void>.delayed(wait.isNegative ? Duration.zero : wait, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _letter(String ch, Color color, int index) {
    return AnimatedBuilder(
      animation: _c,
      child: Text(
        ch,
        style: TextStyle(
          color: color,
          height: 0.91,
          fontSize: widget.size,
          fontWeight: FontWeight.w900,
          letterSpacing: -4.2,
        ),
      ),
      builder: (context, child) {
        final p = Curves.easeOutCubic.transform(
          ((_c.value - index * 0.05) / 0.45).clamp(0.0, 1.0),
        );
        final m = Matrix4.translationValues(0, 70 * (1 - p), 0) *
            (Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(-1.3 * (1 - p)));
        return Opacity(
          opacity: p,
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          ),
        );
      },
    );
  }

  Widget _line(String text, Color color, int offset) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          _letter(text[i], color, offset + i),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_line('BEYOND', ivory, 0), _line('WORDS.', gold, 6)],
    );
  }
}

/// Types its text out character by character.
class _Typewriter extends StatefulWidget {
  const _Typewriter({
    required this.text,
    required this.style,
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle style;
  final Duration delay;

  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.text.length * 42),
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final intro = _introEnd.difference(DateTime.now());
    final wait = widget.delay + (intro.isNegative ? Duration.zero : intro);
    Future<void>.delayed(wait, () {
      if (!mounted) return;
      setState(() => _started = true);
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final n = (_c.value * widget.text.length).floor();
        final typing = _started && !_c.isCompleted;
        return Text.rich(
          TextSpan(
            text: widget.text.substring(0, n),
            style: widget.style,
            children: [
              TextSpan(
                text: typing ? '|' : '',
                style: widget.style.copyWith(color: gold),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Intro: gold particles swirl inward, then a circle opens to reveal the page.
class _IrisPainter extends CustomPainter {
  const _IrisPainter(this.t);

  final double t;

  static final List<List<double>> _dots = () {
    final r = math.Random(11);
    return List.generate(
      110,
      (_) => <double>[
        r.nextDouble() * math.pi * 2,
        0.5 + 0.5 * r.nextDouble(),
        1 + r.nextDouble() * 2.4,
        r.nextDouble(),
      ],
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final open = Curves.easeInOutCubic.transform(
      ((t - 0.6) / 0.4).clamp(0.0, 1.0),
    );
    final hole = open * maxR * 1.05;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = ink);
    if (hole > 0) {
      canvas.drawCircle(c, hole, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    if (open > 0 && open < 1) {
      canvas.drawCircle(
        c,
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = gold.withValues(alpha: (1 - open) * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    final conv = Curves.easeInOutCubic.transform((t / 0.5).clamp(0.0, 1.0));
    final fade = 1 - ((t - 0.52) / 0.12).clamp(0.0, 1.0);
    if (fade <= 0) return;
    for (final d in _dots) {
      final angle = d[0] + conv * 1.8;
      final startR = maxR * d[1];
      final endR = 55 + 40 * d[3];
      final r = startR + (endR - startR) * conv;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * r;
      canvas.drawCircle(
        pos,
        d[2],
        Paint()..color = gold.withValues(alpha: (0.3 + 0.7 * d[3]) * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IrisPainter oldDelegate) => oldDelegate.t != t;
}

late DateTime _introEnd;

/// A soft light band that sweeps across its child every few seconds.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final p = Curves.easeInOut.transform(
          (_controller.value / 0.4).clamp(0.0, 1.0),
        );
        final c = -1.6 + 3.2 * p;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(c - 0.6, -0.4),
            end: Alignment(c + 0.6, 0.4),
            colors: const [
              Color(0x00FFFFFF),
              Color(0x99FFFFFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Two rings that expand outward from the centre and fade away.
class _Ripple extends StatefulWidget {
  const _Ripple();

  @override
  State<_Ripple> createState() => _RippleState();
}

class _RippleState extends State<_Ripple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double p) {
    final t = Curves.easeOut.transform(p);
    return Opacity(
      opacity: (1 - t) * 0.55,
      child: Transform.scale(
        scale: 0.9 + 0.55 * t,
        child: Container(
          width: 184,
          height: 184,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final a = _controller.value;
        final b = (_controller.value + 0.5) % 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [_ring(a), _ring(b)],
        );
      },
    );
  }
}

/// A small glowing dot travelling around a circle.
class _OrbitDot extends StatefulWidget {
  const _OrbitDot({
    required this.radius,
    required this.seconds,
    this.reverse = false,
    this.size = 8,
  });

  final double radius;
  final int seconds;
  final bool reverse;
  final double size;

  @override
  State<_OrbitDot> createState() => _OrbitDotState();
}

class _OrbitDotState extends State<_OrbitDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dir = widget.reverse ? -1.0 : 1.0;
        return Transform.rotate(
          angle: dir * _controller.value * math.pi * 2,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: goldLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.9),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft gold light that follows the mouse pointer.
class _SpotPainter extends CustomPainter {
  const _SpotPainter(this.point);

  final Offset point;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            gold.withValues(alpha: 0.13),
            gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: point, radius: 280)),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotPainter oldDelegate) =>
      oldDelegate.point != point;
}

void main() {
  _introEnd = DateTime.now().add(const Duration(milliseconds: 1550));
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);
  bool _showIntro = true;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2700),
  );

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showIntro = false);
      }
    });
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _scroll.dispose();
    _pointer.dispose();
    super.dispose();
  }

  /// Opening: particles swirl in, logo appears, then a circle opens the page.
  Widget _buildIntro() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _intro,
        builder: (context, _) {
          final t = _intro.value;
          final show = Curves.easeOutBack.transform(
            ((t - 0.15) / 0.3).clamp(0.0, 1.0),
          );
          final textShow = Curves.easeOutCubic.transform(
            ((t - 0.3) / 0.28).clamp(0.0, 1.0),
          );
          final fade = 1 - ((t - 0.54) / 0.1).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _IrisPainter(t))),
              Center(
                child: Opacity(
                  opacity: fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: show.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.3 + 0.7 * show,
                          child: Transform.rotate(
                            angle: (1 - show.clamp(0.0, 1.0)) * -1.2,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: gold,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x88D8B86C),
                                    blurRadius: 46,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.waves_rounded,
                                color: ink,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: textShow,
                        child: Text(
                          'SIGNSPEAK',
                          style: TextStyle(
                            color: ivory,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none,
                            letterSpacing: 20 - 16 * textShow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 200 * textShow,
                        height: 1.5,
                        color: gold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openMedia(BuildContext context) {
    Navigator.of(context).push(_softRoute(const MediaPage()));
  }

  void _openQuest(BuildContext context) {
    Navigator.of(context).push(
      _softRoute(const MediaPage(startInQuest: true)),
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
      body: MouseRegion(
        onHover: (event) => _pointer.value = event.localPosition,
        onExit: (_) => _pointer.value = null,
        child: Stack(
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
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<Offset?>(
                valueListenable: _pointer,
                builder: (context, point, _) {
                  if (point == null) return const SizedBox.shrink();
                  return CustomPaint(painter: _SpotPainter(point));
                },
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) {
                final o = _scroll.hasClients ? _scroll.offset : 0.0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -190 - o * 0.25,
                      right: -140,
                      child: const _GoldGlow(size: 420, opacity: 0.12),
                    ),
                    Positioned(
                      top: 620 - o * 0.4,
                      left: -240,
                      child: const _GoldGlow(
                        size: 440,
                        opacity: 0.07,
                        phase: 0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final padding = viewport.maxWidth > 760 ? 48.0 : 22.0;

                return SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(padding, 22, padding, 42),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Reveal(
                            dy: -18,
                            duration: Duration(milliseconds: 700),
                            child: _Header(),
                          ),
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
                                    Expanded(
                                      flex: 5,
                                      child: _Reveal(
                                        delay: _ms(350),
                                        duration: _ms(1100),
                                        dx: 44,
                                        dy: 0,
                                        scale: 0.96,
                                        child: const _HoverLift(lift: 0, tilt: 0.1, child: _HeroArtwork()),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  hero,
                                  const SizedBox(height: 44),
                                  _Reveal(
                                    delay: _ms(500),
                                    duration: _ms(1000),
                                    scale: 0.96,
                                    child: const _HoverLift(lift: 0, tilt: 0.1, child: _HeroArtwork()),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 82),
                          const _Reveal(
                            dy: 40,
                            duration: Duration(milliseconds: 950),
                            child: _SignAvatarShowcase(),
                          ),
                          const SizedBox(height: 72),
                          const _Reveal(child: _StatRail()),
                          const SizedBox(height: 96),
                          const _StorySection(),
                          const SizedBox(height: 92),
                          const _ProcessSection(),
                          const SizedBox(height: 92),
                          const _Reveal(
                            dy: 36,
                            duration: Duration(milliseconds: 900),
                            child: _PrinciplesSection(),
                          ),
                          const SizedBox(height: 78),
                          _Reveal(
                            dy: 30,
                            scale: 0.97,
                            duration: _ms(900),
                            child: _ClosingBanner(
                              onStart: () => _openMedia(context),
                            ),
                          ),
                          const SizedBox(height: 48),
                          const _Reveal(dy: 12, child: _Footer()),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) {
                var p = 0.0;
                if (_scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
                  p = (_scroll.offset / _scroll.position.maxScrollExtent)
                      .clamp(0.0, 1.0);
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: p,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        color: gold,
                        boxShadow: [
                          BoxShadow(color: Color(0x99D8B86C), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showIntro) Positioned.fill(child: _buildIntro()),
        ],
      ),
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
        _Reveal(
          delay: _ms(150),
          dy: 14,
          child: const _Eyebrow(text: 'A NEW LANGUAGE OF CONNECTION'),
        ),
        const SizedBox(height: 27),
        _Shimmer(child: _SplitTitle(size: titleSize)),
        const SizedBox(height: 24),
        _Typewriter(
          delay: _ms(1300),
          text: 'Meaning lives in every movement.',
          style: const TextStyle(
            color: Color(0xFFE7DFCE),
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        _Reveal(
          delay: _ms(1700),
          dy: 22,
          child: const Text(
            'SignSpeak is exploring a more natural way to understand '
            'Indian Sign Language. A gesture, a glance, a movement of the '
            'hands—each can be part of a conversation.',
            style: TextStyle(color: muted, fontSize: 15, height: 1.8),
          ),
        ),
        const SizedBox(height: 29),
        _Reveal(
          delay: _ms(2000),
          dy: 22,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HoverLift(
                lift: 2,
                scale: 1.04,
                child: FilledButton.icon(
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
              ),
              _HoverLift(
                lift: 2,
                scale: 1.04,
                child: OutlinedButton.icon(
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
              ),
              _HoverLift(
                lift: 2,
                scale: 1.04,
                child: OutlinedButton(
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Reveal(
          delay: _ms(2300),
          dy: 10,
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: gold),
              SizedBox(width: 8),
              Text(
                'A prototype in progress, built around ISL.',
                style: TextStyle(color: Color(0xFF888374), fontSize: 12),
              ),
            ],
          ),
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
                const _Ripple(),
                const _OrbitDot(radius: 121, seconds: 9),
                const _OrbitDot(
                  radius: 150,
                  seconds: 14,
                  reverse: true,
                  size: 5,
                ),
                _Floating(
                  distance: 6,
                  child: Container(
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
                ),
                const Positioned(
                  top: 54,
                  right: 55,
                  child: _GoldPoint(size: 9),
                ),
                const Positioned(
                  bottom: 68,
                  left: 48,
                  child: _GoldPoint(size: 7, phase: 0.35),
                ),
                const Positioned(
                  top: 120,
                  left: 31,
                  child: _GoldPoint(size: 6, phase: 0.7),
                ),
                const Positioned(
                  bottom: 39,
                  right: 83,
                  child: _GoldPoint(size: 5, phase: 0.55),
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
      child: Wrap(
        spacing: 38,
        runSpacing: 20,
        children: [
          _Reveal(
            delay: _ms(150),
            dy: 14,
            child: const _StatItem(
              number: '01',
              label: 'LANGUAGE',
              value: 'Indian Sign Language',
            ),
          ),
          _Reveal(
            delay: _ms(300),
            dy: 14,
            child: const _StatItem(
              number: '02',
              label: 'INPUT',
              value: 'Images and video',
            ),
          ),
          _Reveal(
            delay: _ms(450),
            dy: 14,
            child: const _StatItem(
              number: '03',
              label: 'PURPOSE',
              value: 'Shared understanding',
            ),
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
        final wide = constraints.maxWidth > 740;

        final title = _Reveal(
          wipe: true,
          dx: wide ? -34 : 0,
          dy: wide ? 0 : 28,
          duration: _ms(900),
          child: const Text(
            'A world that listens\nwith its eyes.',
            style: TextStyle(
              color: ivory,
              fontSize: 38,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
        );

        final body = _Reveal(
          delay: _ms(180),
          dx: wide ? 34 : 0,
          dy: wide ? 0 : 28,
          duration: _ms(900),
          child: const Column(
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
          ),
        );

        if (wide) {
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
        const _Reveal(dy: 14, child: _Eyebrow(text: 'THE JOURNEY')),
        const SizedBox(height: 15),
        _Reveal(
          wipe: true,
          duration: _ms(1100),
          delay: _ms(100),
          child: const Text(
            'From a gesture to a connection.',
            style: TextStyle(
              color: ivory,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Reveal(
          delay: _ms(200),
          child: const Text(
            'We’re building each part carefully, with a clear view of what '
            'works today and what still needs to be created.',
            style: TextStyle(color: muted, fontSize: 14, height: 1.7),
          ),
        ),
        const SizedBox(height: 25),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final width = wide
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: _Reveal(
                    delay: _ms(0),
                    dy: 36,
                    child: const _HoverLift(
                      lift: 6,
                      tilt: 0.16,
                      child: _ProcessCard(
                        number: '01',
                        icon: Icons.photo_library_outlined,
                        state: 'AVAILABLE',
                        title: 'Choose your media',
                        detail: 'Select an image or video to begin exploring.',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _Reveal(
                    delay: _ms(wide ? 160 : 0),
                    dy: 36,
                    child: const _HoverLift(
                      lift: 6,
                      tilt: 0.16,
                      child: _ProcessCard(
                        number: '02',
                        icon: Icons.center_focus_strong_rounded,
                        state: 'WORKING',
                        title: 'Find the hands',
                        detail:
                            'The current prototype can detect hands in an image.',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _Reveal(
                    delay: _ms(wide ? 320 : 0),
                    dy: 36,
                    child: const _HoverLift(
                      lift: 6,
                      tilt: 0.16,
                      child: _ProcessCard(
                        number: '03',
                        icon: Icons.translate_rounded,
                        state: 'IN DEVELOPMENT',
                        title: 'Understand the sign',
                        detail:
                            'A custom ISL model will be needed to recognize signs.',
                      ),
                    ),
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

          final heading = _Reveal(
            delay: _ms(150),
            dx: wide ? -24 : 0,
            dy: wide ? 0 : 20,
            child: const Column(
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
            ),
          );

          final details = Column(
            children: [
              _Reveal(
                delay: _ms(250),
                dy: 20,
                child: const _PrincipleRow(
                  icon: Icons.people_alt_outlined,
                  title: 'Respect the language',
                  text:
                      'ISL is a language, not a collection of random gestures.',
                ),
              ),
              const SizedBox(height: 18),
              _Reveal(
                delay: _ms(400),
                dy: 20,
                child: const _PrincipleRow(
                  icon: Icons.explore_outlined,
                  title: 'Grow with care',
                  text: 'Recognition should expand through examples and testing.',
                ),
              ),
              const SizedBox(height: 18),
              _Reveal(
                delay: _ms(550),
                dy: 20,
                child: const _PrincipleRow(
                  icon: Icons.question_mark_rounded,
                  title: 'Be honest when unsure',
                  text: 'The app should say when it cannot recognize a sign.',
                ),
              ),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: heading),
                const SizedBox(width: 45),
                Expanded(flex: 6, child: details),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 28), details],
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

          final button = _HoverLift(
            lift: 2,
            scale: 1.05,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('GET STARTED'),
              style: FilledButton.styleFrom(
                foregroundColor: goldLight,
                backgroundColor: ink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        // The small gold line draws itself in.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 24),
          duration: _ms(900),
          curve: Curves.easeOutCubic,
          builder: (context, width, _) {
            return Container(width: width, height: 1, color: gold);
          },
        ),
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

/// A small gold dot that softly pulses.
class _GoldPoint extends StatefulWidget {
  const _GoldPoint({required this.size, this.phase = 0});

  final double size;
  final double phase;

  @override
  State<_GoldPoint> createState() => _GoldPointState();
}

class _GoldPointState extends State<_GoldPoint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _ms(2200),
  );

  @override
  void initState() {
    super.initState();
    _controller.value = widget.phase;
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: goldLight,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x88D8B86C), blurRadius: 12)],
        ),
      ),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: 0.55 + 0.45 * t,
          child: Transform.scale(scale: 0.85 + 0.3 * t, child: child),
        );
      },
    );
  }
}

/// Background glow that slowly "breathes".
class _GoldGlow extends StatefulWidget {
  const _GoldGlow({required this.size, required this.opacity, this.phase = 0});

  final double size;
  final double opacity;
  final double phase;

  @override
  State<_GoldGlow> createState() => _GoldGlowState();
}

class _GoldGlowState extends State<_GoldGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void initState() {
    super.initState();
    _controller.value = widget.phase;
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: widget.opacity),
                blurRadius: 145,
                spreadRadius: 38,
              ),
            ],
          ),
        ),
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Opacity(
            opacity: 0.75 + 0.25 * t,
            child: Transform.scale(scale: 0.95 + 0.1 * t, child: child),
          );
        },
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
              Expanded(child: _Eyebrow(text: 'SIGN LANGUAGE')),
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
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
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
  double _confidence = 0;
  bool _confirmed = false;
  bool _correcting = false;

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
    return AnimatedSize(
      duration: _ms(300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
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
            BoxShadow(
              color: Color(0x224D421F),
              blurRadius: 24,
              spreadRadius: 1,
            ),
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
              _PopIn(
                key: ValueKey<String>(_questFeedback!),
                child: Container(
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
                        color:
                            _roundWasCorrect ? const Color(0xFF65D6A4) : gold,
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
              _PopIn(
                child: FilledButton.icon(
                  onPressed: _startNextQuestRound,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next sign'),
                ),
              ),
            ],
          ],
        ),
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
        Uri.parse('https://sign-speak-2.onrender.com/predict'),
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
        _confidence = score;
        _confirmed = false;
        _correcting = false;
        _detectionMessage = isSign
            ? 'Possible sign: ${label.toUpperCase()}.'
            : '${result['message'] ?? 'No confident sign prediction.'}';

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

  /// Plain-language wording instead of a raw model percentage.
  String _confidenceWord(double score) {
    if (score >= 0.85) return 'Very likely this sign';
    if (score >= 0.65) return 'Probably this sign';
    return 'Not fully sure - please check';
  }

  /// Speech only happens after the signer says the word is right.
  void _confirmAndSpeak() {
    setState(() => _confirmed = true);
    _speakRecognized();
  }

  /// The signer picks the correct word themselves.
  void _chooseWord(String word) {
    setState(() {
      _recognizedText = _friendlyLabel(word);
      _confirmed = true;
      _correcting = false;
    });
    _speakRecognized();
  }

  void _tryAgain() {
    setState(() {
      _recognizedText = null;
      _detectionMessage = null;
      _confirmed = false;
      _correcting = false;
      _videoName = null;
      _videoFile = null;
    });
  }

  /// Small spinner shown inside buttons while something is loading.
  Widget _spinner() {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: _ms(250),
          child: Text(
            _practiceMode ? 'Sign Quest' : 'ISL Media',
            key: ValueKey<bool>(_practiceMode),
          ),
        ),
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
                _Reveal(
                  dy: 18,
                  duration: _ms(650),
                  child: Text(
                    _practiceMode
                        ? 'Ready for a challenge?'
                        : 'Choose signing media',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Reveal(
                  delay: _ms(120),
                  dy: 18,
                  duration: _ms(650),
                  child: Text(
                    _practiceMode
                        ? 'Sign the target word and submit a short video to earn points.'
                        : 'Select a photo or a short video of someone signing.',
                    style:
                        const TextStyle(color: Color(0xFF929DB4), height: 1.5),
                  ),
                ),
                if (_practiceMode) ...[
                  const SizedBox(height: 20),
                  _PopIn(
                    key: ValueKey<String?>('quest-$_targetWord-$_questRound'),
                    child: _buildQuestCard(),
                  ),
                ],
                const SizedBox(height: 24),
                _Reveal(
                  delay: _ms(240),
                  dy: 18,
                  duration: _ms(650),
                  child: Wrap(
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
                          _practiceMode
                              ? 'Choose signing clip'
                              : 'Choose video',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Reveal(
                  delay: _ms(360),
                  dy: 22,
                  duration: _ms(700),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 240),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101727),
                      border: Border.all(color: const Color(0xFF293349)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedSwitcher(
                      duration: _ms(350),
                      switchInCurve: Curves.easeOutCubic,
                      child: _imageBytes != null
                          ? Image.memory(
                              _imageBytes!,
                              key: const ValueKey<String>('image'),
                              fit: BoxFit.contain,
                            )
                          : _videoName != null
                          ? Center(
                              key: ValueKey<String>('video-$_videoName'),
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
                                    Text(
                                      _videoName!,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Choose Recognize sign video below to process this clip.',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Color(0xFF929DB4)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const Center(
                              key: ValueKey<String>('empty'),
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
                  ),
                ),
                if (_recognizedText != null) ...[
                  const SizedBox(height: 18),
                  _PopIn(
                    key: ValueKey<String>('result-$_recognizedText'),
                    child: Container(
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
                          Text(
                            _confirmed ? 'CONFIRMED BY YOU' : 'POSSIBLE SIGN',
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
                          Text(
                            _confirmed
                                ? 'You confirmed this word.'
                                : _confidenceWord(_confidence),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB5AA8B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_confirmed)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _speakRecognized,
                                  icon: const Icon(Icons.volume_up_rounded),
                                  label: const Text('Say it again'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: goldLight,
                                    side: const BorderSide(color: gold),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _tryAgain,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Sign another'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: goldLight,
                                  ),
                                ),
                              ],
                            )
                          else if (_correcting) ...[
                            const Text(
                              'What did you sign? Tap the correct word:',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ivory, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final word in _questWords)
                                  ActionChip(
                                    label: Text(_friendlyLabel(word)),
                                    onPressed: () => _chooseWord(word),
                                    backgroundColor: const Color(0xFF191711),
                                    side: const BorderSide(
                                      color: Color(0xFF51452A),
                                    ),
                                    labelStyle: const TextStyle(
                                      color: ivory,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _tryAgain,
                              icon: const Icon(Icons.videocam_outlined),
                              label: const Text('None of these - try another video'),
                              style: TextButton.styleFrom(
                                foregroundColor: goldLight,
                              ),
                            ),
                          ] else
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: _confirmAndSpeak,
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Yes, say it'),
                                  style: FilledButton.styleFrom(
                                    foregroundColor: ink,
                                    backgroundColor: gold,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _correcting = true),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Not right'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: goldLight,
                                    side: const BorderSide(color: gold),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_imageUrl != null) ...[
                  const SizedBox(height: 16),
                  _PopIn(
                    child: FilledButton.icon(
                      onPressed: _checkingHands ? null : _checkForHands,
                      icon: _checkingHands
                          ? _spinner()
                          : const Icon(Icons.search_rounded),
                      label: Text(
                        _checkingHands ? 'Checking…' : 'Check for hands',
                      ),
                    ),
                  ),
                ],
                if (_videoFile != null) ...[
                  const SizedBox(height: 16),
                  _PopIn(
                    child: FilledButton.icon(
                      onPressed: (_recognizingVideo || _roundComplete)
                          ? null
                          : _recognizeVideo,
                      icon: _recognizingVideo
                          ? _spinner()
                          : const Icon(Icons.translate_rounded),
                      label: Text(
                        _recognizingVideo
                            ? 'Recognizing…'
                            : _practiceMode
                            ? 'Check my sign'
                            : 'Recognize sign video',
                      ),
                    ),
                  ),
                ],
                if (_detectionMessage != null &&
                    _recognizedText == null &&
                    !_practiceMode) ...[
                  const SizedBox(height: 12),
                  _PopIn(
                    key: ValueKey<String>('msg-$_detectionMessage'),
                    child: Text(
                      _detectionMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF929DB4)),
                    ),
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
          // The number briefly "pops" whenever the score or streak changes.
          AnimatedSwitcher(
            duration: _ms(300),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: const TextStyle(
                color: goldLight,
                fontWeight: FontWeight.w800,
              ),
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