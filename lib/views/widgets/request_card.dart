import 'package:flutter/material.dart';

import '../../models/course_student.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'app_card.dart';
import 'initials_avatar.dart';

/// Tarjeta de una solicitud pendiente con los botones Rechazar y Aceptar (mockup 15).
class RequestCard extends StatelessWidget {
  final CourseStudent student;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RequestCard({super.key, required this.student, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(initials: student.initials, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${student.code}',
                        style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            student.email,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySm.copyWith(color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botones con altura mínima (no fija) y poco relleno lateral, para que
          // "Rechazar" quepa en una línea en pantallas angostas.
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReject,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorContainer,
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppText.labelLg,
                  ),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppText.labelLg,
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
