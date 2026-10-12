import 'dart:math' as math;

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _waveController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _textSlideAnimation;

  static const Color deepTeal = Color(0xFF075E54);
  static const Color oceanGreen = Color(0xFF0F8B78);
  static const Color mint = Color(0xFF7DE2D1);

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _getStarted() {
    // TODO: Navigate to the signup/login screen when we build it.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Next: we will connect this to the Sign Up screen.'),
        behavior: SnackBarBehavior.floating,
      ),
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
                  colors: [Color(0xFF064C46), deepTeal, Color(0xFF087568)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(progress: _waveController.value),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const _ResWaveLogo(),
                    ),
                  ),
                  const SizedBox(height: 34),
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Where Researchers',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Find Their Community.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFB9F3E9),
                              fontSize: 25,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Connect with researchers, share ideas,\\nand find the support you need.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFE0F2EF),
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _getStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB9F3E9),
                              foregroundColor: deepTeal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'A community built around shared growth',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD0E9E5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResWaveLogo extends StatelessWidget {
  const _ResWaveLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Icon(Icons.waves_rounded, color: Colors.white, size: 58),
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'ResWave',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas,
      size,
      amplitude: 18,
      baseline: size.height * 0.70,
      phase: progress * 2 * math.pi,
      color: const Color(0xFF2AAE9A).withValues(alpha: 0.16),
    );
    _drawWave(
      canvas,
      size,
      amplitude: 13,
      baseline: size.height * 0.76,
      phase: progress * 2 * math.pi + 1.8,
      color: const Color(0xFF9CEBDD).withValues(alpha: 0.11),
    );
    _drawWave(
      canvas,
      size,
      amplitude: 10,
      baseline: size.height * 0.82,
      phase: -progress * 2 * math.pi + 0.8,
      color: const Color(0xFF003F39).withValues(alpha: 0.12),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double baseline,
    required double phase,
    required Color color,
  }) {
    final path = Path()..moveTo(0, baseline);

    for (double x = 0; x <= size.width; x += 4) {
      final y =
          baseline +
          math.sin((x / size.width * 2 * math.pi) + phase) * amplitude;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
