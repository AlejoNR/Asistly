import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Hoja inferior "¿Salir de ...?" (mockup 25). Devuelve true si el estudiante confirmó.
Future<bool> showLeaveCourseSheet(BuildContext context, Course course) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => _LeaveCourseSheet(course: course),
  );
  return result ?? false;
}

class _LeaveCourseSheet extends StatelessWidget {
  final Course course;
  const _LeaveCourseSheet({required this.course});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle),
              child: const Icon(Icons.logout, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text('¿Salir de ${course.name}?',
                textAlign: TextAlign.center, style: AppText.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 10),
            Text(
              'Dejarás de ver este curso. Tu historial de asistencia se conserva y el docente lo seguirá viendo.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Podrás volver a unirte con el código de invitación ',
                        children: [
                          TextSpan(text: course.enrollCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: AppText.labelLg,
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Salir del curso'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, false),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.onSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: AppText.labelLg,
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
