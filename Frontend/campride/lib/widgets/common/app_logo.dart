import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 80, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accentGold;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(color: c)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  const _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;


    // Bus body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.25, size.width * 0.8, size.height * 0.45),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(bodyRect, paint);

    // Windows
    final windowPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.fill;
    final windowRect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.33, size.width * 0.18, size.height * 0.18),
      Radius.circular(size.width * 0.04),
    );
    final windowRect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.42, size.height * 0.33, size.width * 0.18, size.height * 0.18),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(windowRect1, windowPaint);
    canvas.drawRRect(windowRect2, windowPaint);

    // Wheels
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.76),
      size.width * 0.1,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.76),
      size.width * 0.1,
      paint,
    );

    // Wheel rims
    final rimPaint = Paint()
      ..color = AppColors.primaryGreenDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.76), size.width * 0.05, rimPaint);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.76), size.width * 0.05, rimPaint);

    // Location pin on top
    final pinPaint = Paint()..color = color..style = PaintingStyle.fill;
    final pinPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.18),
        width: size.width * 0.16,
        height: size.width * 0.16,
      ));
    canvas.drawPath(pinPath, pinPaint);
    final dotPaint = Paint()..color = AppColors.primaryGreen..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.18), size.width * 0.04, dotPaint);
    // Pin tail
    final tailPath = Path()
      ..moveTo(size.width * 0.72, size.height * 0.22)
      ..lineTo(size.width * 0.78, size.height * 0.28)
      ..lineTo(size.width * 0.84, size.height * 0.22);
    canvas.drawPath(tailPath, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
