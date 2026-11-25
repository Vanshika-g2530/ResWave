import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// ResWave Official Logo (Section I)
/// Minimal open-book / research-pages motif combined with interconnected researcher nodes
/// and a subtle flowing teal wave.
class ResWaveLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;

  const ResWaveLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ResWaveLogoPainter(),
      ),
    );

    if (!showWordmark) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 12),
        const Text(
          'ResWave',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.darkTextPrimary,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          const Text(
            'Discover. Connect. Collaborate.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.brightTeal,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResWaveLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle glowing background circle/rounded rect
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.deepTeal, AppColors.primaryTeal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.26));
    canvas.drawRRect(rrect, bgPaint);

    // 2. Open Research Pages Motif (Left & Right curves)
    final pagePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final leftPage = Path()
      ..moveTo(w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.32, h * 0.72, w * 0.22, h * 0.58)
      ..lineTo(w * 0.22, h * 0.38)
      ..quadraticBezierTo(w * 0.32, h * 0.52, w * 0.5, h * 0.48);
    canvas.drawPath(leftPage, pagePaint);

    final rightPage = Path()
      ..moveTo(w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.68, h * 0.72, w * 0.78, h * 0.58)
      ..lineTo(w * 0.78, h * 0.38)
      ..quadraticBezierTo(w * 0.68, h * 0.52, w * 0.5, h * 0.48);
    canvas.drawPath(rightPage, pagePaint);

    // 3. Central Spine Line
    final spinePaint = Paint()
      ..color = AppColors.brightTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.44), Offset(w * 0.5, h * 0.70), spinePaint);

    // 4. Collaboration Nodes (Connected researchers)
    final nodePaint = Paint()
      ..color = AppColors.brightTeal
      ..style = PaintingStyle.fill;
    final nodeBorder = Paint()
      ..color = AppColors.darkBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;

    // Node 1 (Top Left)
    canvas.drawCircle(Offset(w * 0.28, h * 0.32), w * 0.055, nodePaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.32), w * 0.055, nodeBorder);

    // Node 2 (Center Top)
    canvas.drawCircle(Offset(w * 0.50, h * 0.22), w * 0.065, nodePaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.22), w * 0.065, nodeBorder);

    // Node 3 (Top Right)
    canvas.drawCircle(Offset(w * 0.72, h * 0.32), w * 0.055, nodePaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.32), w * 0.055, nodeBorder);

    // Connecting Network Lines
    final netLinePaint = Paint()
      ..color = AppColors.brightTeal.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawLine(Offset(w * 0.28, h * 0.32), Offset(w * 0.50, h * 0.22), netLinePaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.22), Offset(w * 0.72, h * 0.32), netLinePaint);

    // 5. Flowing ResWave Teal Line at the bottom
    final wavePaint = Paint()
      ..color = AppColors.brightTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final wavePath = Path()
      ..moveTo(w * 0.18, h * 0.78)
      ..cubicTo(w * 0.35, h * 0.72, w * 0.55, h * 0.88, w * 0.82, h * 0.80);
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
