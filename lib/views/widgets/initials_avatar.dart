import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Círculo con las iniciales de una persona ("SM"), usado en las listas.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.primaryContainer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: AppText.titleMd.copyWith(color: foreground, fontSize: size * 0.38),
      ),
    );
  }
}
