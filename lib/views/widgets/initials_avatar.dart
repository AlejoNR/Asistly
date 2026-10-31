import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Círculo con las iniciales de una persona ("SM"), usado en las listas.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const InitialsAvatar({super.key, required this.initials, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppText.titleMd.copyWith(color: AppColors.primaryContainer, fontSize: size * 0.38),
      ),
    );
  }
}
