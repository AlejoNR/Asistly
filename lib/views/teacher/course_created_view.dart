import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/course_created_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/primary_button.dart';

/// Curso creado (mockup 11): muestra el código de inscripción para compartirlo.
class CourseCreatedView extends StatelessWidget {
  const CourseCreatedView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CourseCreatedViewModel>(context);
    final course = vm.course;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Curso creado'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SuccessBadge(),
            Text(
              'Curso creado',
              textAlign: TextAlign.center,
              style: AppText.headlineLg.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte el código con tus estudiantes para que se unan al curso.',
              textAlign: TextAlign.center,
              style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _CodeCard(vm: vm),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SIGUIENTE PASO',
                          style: AppText.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Recomendado', style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                        child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Importa la lista oficial',
                              style: AppText.titleLg.copyWith(color: AppColors.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sube el Excel de matriculados para que los estudiantes de la '
                              'lista se inscriban automáticamente al unirse.',
                              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, 'import_list', arguments: course.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: AppText.labelLg,
                    ),
                    icon: const Icon(Icons.upload_file_outlined, size: 20),
                    label: const Text('Importar lista de estudiantes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'HORARIO Y AULA',
                        style: AppText.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final line in vm.scheduleLines)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(line, style: AppText.bodyMd.copyWith(color: AppColors.primaryContainer)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton.dark(
              label: 'Ir al curso',
              trailingIcon: Icons.arrow_forward,
              onPressed: () => Navigator.pushReplacementNamed(context, 'course_detail', arguments: course.id),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: vm.shareCode,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppText.labelLg,
                ),
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text('Compartir código'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculos verdes con el check y la estrella amarilla.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: AppColors.presentDot.withValues(alpha: 0.15), shape: BoxShape.circle),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: AppColors.presentDot.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, size: 44, color: AppColors.present),
            ),
            Positioned(
              top: 22,
              right: 22,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: AppColors.tertiaryFixedDim, shape: BoxShape.circle),
                child: const Icon(Icons.star, size: 18, color: AppColors.onTertiaryFixed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con el grupo, el aula, el nombre del curso y el código grande.
class _CodeCard extends StatelessWidget {
  final CourseCreatedViewModel vm;
  const _CodeCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final course = vm.course;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(height: 12, color: AppColors.primaryContainer),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                // Wrap: si el grupo y el aula no caben en una línea, el aula baja.
                // SizedBox a todo el ancho: sin él, el Wrap se encoge y no los separa a los lados.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(text: course.group),
                      _Pill(text: course.room, icon: Icons.meeting_room_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  course.name,
                  textAlign: TextAlign.center,
                  style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Semestre ${course.semester}',
                      style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'CÓDIGO DE INSCRIPCIÓN',
                  style: AppText.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.key, size: 26, color: AppColors.secondary),
                          const SizedBox(width: 10),
                          // FittedBox(scaleDown): el código se achica un poco si no cabe, sin partirse.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                course.enrollCode,
                                style: AppText.headlineLg.copyWith(
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: vm.copyCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLowest,
                          foregroundColor: AppColors.primary,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: AppText.labelLg,
                        ),
                        icon: Icon(vm.justCopied ? Icons.check : Icons.copy_outlined, size: 20),
                        label: Text(vm.justCopied ? 'Copiado' : 'Copiar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Pill({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: AppColors.onSurfaceVariant), const SizedBox(width: 4)],
          Text(text, style: AppText.labelLg.copyWith(color: AppColors.primaryContainer)),
        ],
      ),
    );
  }
}
