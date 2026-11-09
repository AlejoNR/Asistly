import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../util/date_format.dart';
import '../../viewmodels/attendance_done_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/percent_ring.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';

/// "¡Asistencia registrada!" (mockup 29). Sin "Ver comprobante": la especificación no
/// incluye exportar archivos. Solo aparece el método que de verdad se validó (el QR).
class AttendanceDoneView extends StatelessWidget {
  const AttendanceDoneView({super.key});

  void _goHome(BuildContext context) {
    Navigator.popUntil(context, ModalRoute.withName('student_home'));
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AttendanceDoneViewModel>(context);
    final course = vm.openClass.course;

    // El botón "atrás" del celular también vuelve al inicio, no a la cámara.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.school_outlined, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Flexible(
                    flex: 3,
                    child: StatusChip(
                      label: 'Semestre ${course.semester}',
                      background: AppColors.surfaceContainerLow,
                      foreground: AppColors.onSurfaceVariant,
                      dotColor: AppColors.tertiaryFixedDim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 48, color: AppColors.onPrimary),
                      ),
                      // Punto amarillo del mockup.
                      Positioned(
                        right: -8,
                        bottom: -8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: AppColors.tertiaryFixedDim, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: StatusChip(
                  label: 'REGISTRO CONFIRMADO',
                  background: AppColors.surfaceContainer,
                  foreground: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text('¡Asistencia registrada!',
                  textAlign: TextAlign.center,
                  style: AppText.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Tu docente ya te ve como presente en esta clase.',
                  textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 20),
              AppCard(
                accentColor: AppColors.primaryContainer,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ASIGNATURA', style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(course.name,
                                  style: AppText.titleLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatusChip.present(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${course.teacherName} · ${course.room}',
                        style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Fecha',
                            value: '${DateFormatEs.long(vm.markedAt)} de ${vm.markedAt.year}',
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            icon: Icons.schedule,
                            label: 'Hora de registro',
                            value: DateFormatEs.time(vm.markedAt),
                            big: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const StatusChip(
                      label: 'Validado con código QR',
                      background: AppColors.surfaceContainer,
                      foreground: AppColors.primaryContainer,
                    ),
                  ],
                ),
              ),
              if (vm.hasStats) ...[
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
                        child: const Icon(Icons.bar_chart, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${vm.percent}% de asistencia en el curso',
                                style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                            Text('${vm.present} de ${vm.total} ${vm.total == 1 ? 'clase asistida' : 'clases asistidas'}',
                                style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PercentRing(
                        percent: vm.percent,
                        size: 56,
                        strokeWidth: 5,
                        child: Text('${vm.percent}',
                            style: AppText.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton.dark(
                label: 'Volver al inicio',
                leadingIcon: Icons.home_outlined,
                radius: 16,
                onPressed: () => _goHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool big; // La hora va más grande, como en el mockup
  const _DetailRow({required this.icon, required this.label, required this.value, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryContainer),
        const SizedBox(width: 8),
        // Wrap: el valor va a la derecha si cabe; si no, baja completo a la línea siguiente.
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            children: [
              Text(label, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              Text(
                value,
                style: big
                    ? AppText.titleLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)
                    : AppText.labelLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
