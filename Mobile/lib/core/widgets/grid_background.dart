import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GridBackground extends StatelessWidget {
  final Widget child;
  final double spacing;

  const GridBackground({
    super.key,
    required this.child,
    this.spacing = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Faint drafting paper grid color
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.015)
        : AppColors.primary.withValues(alpha: 0.035);

    return CustomPaint(
      painter: _GridPainter(
        gridColor: gridColor,
        spacing: spacing,
      ),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;

  const _GridPainter({
    required this.gridColor,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor || oldDelegate.spacing != spacing;
  }
}
