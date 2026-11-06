import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Anillo de porcentaje con algo en el centro (un ícono o el número).
class PercentRing extends StatelessWidget {
  final int percent; // 0 a 100
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? child;

  const PercentRing({
    super.key,
    required this.percent,
    this.size = 72,
    this.strokeWidth = 7,
    this.color = AppColors.primaryContainer,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: strokeWidth,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
          if (child != null) Center(child: child),
        ],
      ),
    );
  }
}
