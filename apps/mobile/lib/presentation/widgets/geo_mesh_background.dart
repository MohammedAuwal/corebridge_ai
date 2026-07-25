import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Faint low-poly mesh + soft gradient glows behind auth/home/chat
/// screens, matching the reference design's decorative background.
class GeoMeshBackground extends StatelessWidget {
  const GeoMeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.canvas),
          Positioned(
            top: -80,
            left: -60,
            child: _glow(220, AppColors.accentBlue.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _glow(280, AppColors.accentViolet.withValues(alpha: 0.14)),
          ),
          CustomPaint(painter: _MeshPainter(), size: Size.infinite),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
    );
  }
}

class _MeshPainter extends CustomPainter {
  static final _random = Random(42); // fixed seed — consistent look every build

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final points = List.generate(18, (_) {
      return Offset(_random.nextDouble() * size.width, _random.nextDouble() * size.height);
    });

    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < size.width * 0.22) {
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }

    final dotPaint = Paint()..color = AppColors.accentViolet.withValues(alpha: 0.25);
    for (final p in points) {
      canvas.drawCircle(p, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
