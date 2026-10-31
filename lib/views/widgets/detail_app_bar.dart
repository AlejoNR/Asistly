import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Barra superior de las pantallas internas (Nuevo curso, Detalle del curso...):
/// flecha para volver, título y avatar.
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;

  const DetailAppBar({
    super.key,
    required this.title,
    this.backgroundColor = AppColors.surface,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 1))],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              ),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleLg.copyWith(color: AppColors.onSurface),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, size: 20, color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
