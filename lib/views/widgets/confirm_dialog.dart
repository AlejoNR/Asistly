import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Muestra un diálogo de confirmación ("¿Retirar a este estudiante?").
/// Devuelve true si la persona tocó el botón de confirmar.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false, // true = botón rojo (retirar, salir del curso)
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: AppText.headlineSm.copyWith(color: AppColors.primary)),
      content: Text(message, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: AppText.labelLg.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.absent : AppColors.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // Si cierran el diálogo tocando afuera, result es null: se toma como "no".
  return result ?? false;
}
