import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/attendance_error_viewmodel.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';

/// "No pudimos registrar tu asistencia" (mockup 30). "Informar al docente" no marca
/// asistencia: solo le avisa, y es él quien decide (especificación, sección 8).
class AttendanceErrorView extends StatelessWidget {
  const AttendanceErrorView({super.key});

  void _close(BuildContext context) {
    Navigator.popUntil(context, ModalRoute.withName('student_home'));
  }

  /// Vuelve al paso que falló, que sigue debajo de esta pantalla. El true le dice
  /// que debe intentar de nuevo; se regresa en vez de abrir otra pantalla para que
  /// el Inicio se entere al final de todo el flujo y se actualice.
  void _retry(BuildContext context) {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AttendanceErrorViewModel>(context);
    final info = vm.info;
    final course = info.openClass.course;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _close(context),
                    tooltip: 'Cerrar',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Center(
                      child: StatusChip(
                        label: info.isSignalError ? 'SEÑAL NO DETECTADA' : 'CÓDIGO NO VÁLIDO',
                        background: AppColors.errorContainer,
                        foreground: AppColors.error,
                        dotColor: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Compensa el botón de cerrar para centrar el chip
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle),
                  child: Icon(
                    info.isSignalError ? Icons.wifi_off : Icons.qr_code_2,
                    size: 72,
                    color: AppColors.absent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('No pudimos registrar tu asistencia',
                  textAlign: TextAlign.center,
                  style: AppText.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                info.isSignalError
                    ? 'No detectamos la señal del docente. Acércate al salón e inténtalo de nuevo.'
                    : 'No se pudo validar el código. Inténtalo de nuevo con el que muestra tu docente.',
                textAlign: TextAlign.center,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_input_antenna, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('DETALLES DEL ESCANEO',
                              style: AppText.labelMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoBox(label: 'Materia en curso', value: '${course.name} · ${course.room}', dot: true),
                    const SizedBox(height: 10),
                    _InfoBox(label: 'Causa detectada', value: info.cause, warning: true),
                  ],
                ),
              ),
              if (info.isSignalError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth_searching, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verifica tu Bluetooth', style: AppText.titleMd.copyWith(color: AppColors.primary)),
                            Text('Asegúrate de tenerlo activado',
                                style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Reintentar',
                leadingIcon: Icons.refresh,
                radius: 16,
                onPressed: () => _retry(context),
              ),
              const SizedBox(height: 12),
              if (vm.reported)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.present, size: 20),
                    const SizedBox(width: 6),
                    Text('Reporte enviado', style: AppText.labelLg.copyWith(color: AppColors.present)),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: vm.isSending ? null : vm.report,
                  icon: const Icon(Icons.chat_outlined, size: 20),
                  label: Text(vm.isSending ? 'Enviando...' : 'Informar al docente'),
                ),
              if (vm.error != null) ...[
                const SizedBox(height: 4),
                Text(vm.error!, textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.absent)),
              ],
              const SizedBox(height: 8),
              Text('Tu docente verá tu reporte y podrá registrarte manualmente si estás en el salón.',
                  textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final bool warning;
  final bool dot;
  const _InfoBox({required this.label, required this.value, this.warning = false, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warning) ...[
                const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.absent),
                const SizedBox(width: 6),
              ],
              if (dot) ...[
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ],
              Expanded(child: Text(value, style: AppText.titleMd.copyWith(color: AppColors.primary))),
            ],
          ),
        ],
      ),
    );
  }
}
