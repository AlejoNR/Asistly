import 'package:flutter/material.dart';

import '../../models/course_student.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'initials_avatar.dart';

/// Hoja inferior "¿Retirar a ... del curso?" (mockup 16).
/// Devuelve true si el docente confirmó el retiro.
Future<bool> showWithdrawSheet(BuildContext context, CourseStudent student) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => _WithdrawSheet(student: student),
  );
  return result ?? false;
}

class _WithdrawSheet extends StatelessWidget {
  final CourseStudent student;
  const _WithdrawSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    final firstName = student.name.split(' ').first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Agarradera" gris de la hoja.
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle),
              child: const Icon(Icons.person_remove_outlined, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Retirar a ${student.name} del curso?',
              textAlign: TextAlign.center,
              style: AppText.headlineSm.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  InitialsAvatar(initials: student.initials, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                        Text(student.code, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pie_chart_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${student.attendancePercent.round()}% Asist.',
                          style: AppText.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: '$firstName dejará de ver el curso. Su historial de asistencia se conserva '
                    'en los reportes como ',
                children: const [
                  TextSpan(text: '"Retirado"', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: '. Si intenta volver a unirse, necesitará tu aprobación.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: AppText.labelLg,
                ),
                icon: const Icon(Icons.person_remove_outlined, size: 20),
                label: const Text('Retirar estudiante'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, false),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.onSurfaceVariant,
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
