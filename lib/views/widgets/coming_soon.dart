import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Aviso temporal para las pestañas que todavía no se han construido.
class ComingSoon extends StatelessWidget {
  final IconData icon;
  final String title;

  const ComingSoon({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Esta pantalla está en construcción.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
