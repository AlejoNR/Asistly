import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/course_students_viewmodel.dart';
import '../widgets/request_card.dart';
import '../widgets/load_error.dart';
import '../widgets/common.dart';

/// Solicitudes pendientes (mockup 15): estudiantes que se unieron con el código
/// pero no están en la lista oficial. El docente los acepta o los rechaza.
class PendingRequestsView extends StatelessWidget {
  const PendingRequestsView({super.key});

  /// Espera una acción y, si devolvió un error, lo muestra abajo.
  Future<void> _run(BuildContext context, Future<String?> action) async {
    final error = await action;
    if (error != null && context.mounted) showAppSnackBar(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CourseStudentsViewModel>(context);
    final course = vm.course;
    final pending = vm.pending;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solicitudes pendientes', style: AppText.titleLg.copyWith(color: AppColors.onPrimary)),
            if (course != null)
              Text(course.fullName, style: AppText.labelMd.copyWith(color: AppColors.onPrimaryContainer)),
          ],
        ),
      ),
      body: vm.isLoading && course == null
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
          ? Center(child: LoadError(message: vm.error!, onRetry: vm.load))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // Wrap: si los dos chips no caben en una línea, el segundo baja.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (course != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${course.group} · ${course.room}',
                          style: AppText.labelMd.copyWith(color: AppColors.primary),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        pending.length == 1 ? '1 pendiente' : '${pending.length} pendientes',
                        style: AppText.labelMd.copyWith(color: AppColors.onTertiaryFixed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _InfoBanner(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text('Solicitudes recibidas', style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
                    ),
                    if (pending.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _run(context, vm.acceptAll()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondaryContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.done_all, size: 20),
                        label: const Text('Aceptar todas'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (pending.isEmpty)
                  const _AllDone()
                else
                  for (final student in pending) ...[
                    RequestCard(
                      student: student,
                      onAccept: () => _run(context, vm.accept(student)),
                      onReject: () => _run(context, vm.reject(student)),
                    ),
                    const SizedBox(height: 16),
                  ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Al aceptar a un estudiante, se incluirá automáticamente en la lista de '
                        'asistencia y tendrá acceso al registro de clases en vivo.',
                        style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: AppColors.tertiaryFixedDim),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.tertiaryFixed, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.onTertiaryFixed),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estudiantes agregados por código',
                            style: AppText.titleLg.copyWith(color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estos estudiantes ingresaron el código del curso, pero no están en la '
                            'lista oficial. Requieren tu autorización para ser incorporados al '
                            'registro de asistencia.',
                            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDone extends StatelessWidget {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.task_alt, size: 56, color: AppColors.present),
          const SizedBox(height: 12),
          Text('¡Todo al día!', style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text(
            'No hay más solicitudes pendientes de ingreso para este grupo.',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
