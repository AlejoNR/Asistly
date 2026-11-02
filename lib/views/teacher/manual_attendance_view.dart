import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course_student.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/manual_attendance_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/primary_button.dart';

/// Marcar manualmente (mockup 18): el docente registra a quienes no pudieron
/// hacerlo con el QR/Bluetooth, eligiendo un motivo. Primero salen los que reportaron falla.
class ManualAttendanceView extends StatelessWidget {
  const ManualAttendanceView({super.key});

  Future<void> _save(BuildContext context, ManualAttendanceViewModel vm) async {
    final count = await vm.save();
    if (!context.mounted || count == 0) return;
    showAppSnackBar(context, count == 1 ? '1 asistencia registrada manualmente.' : '$count asistencias registradas manualmente.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ManualAttendanceViewModel>(context);
    final course = vm.session.course;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          tooltip: 'Cerrar',
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.how_to_reg_outlined, color: AppColors.primaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marcar manualmente', style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
                  Text('${course.name} · ${course.room}',
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                TextField(
                  onChanged: vm.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar estudiante',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Seleccionar estudiantes', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${vm.selected.length}',
                          style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: vm.pending.isEmpty ? null : vm.toggleAll,
                      child: Text(vm.allSelected ? 'Quitar todos' : 'Seleccionar todos'),
                    ),
                  ],
                ),
                if (vm.pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Todos los inscritos ya tienen asistencia registrada.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                if (vm.reportedStudents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionTitle(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.tertiaryContainer,
                    title: 'Reportaron falla (${vm.reportedStudents.length})',
                  ),
                  for (final student in vm.reportedStudents)
                    _SelectRow(vm: vm, student: student, highlighted: true),
                ],
                if (vm.otherStudents.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(
                    icon: Icons.person_off_outlined,
                    color: AppColors.onSurfaceVariant,
                    title: 'Sin registrar (${vm.otherStudents.length})',
                  ),
                  for (final student in vm.otherStudents) _SelectRow(vm: vm, student: student, highlighted: false),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.primaryContainer),
                    const SizedBox(width: 6),
                    Text('Motivo del registro manual', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in ManualAttendanceViewModel.reasons)
                      ChoiceChip(
                        label: Text(reason),
                        selected: vm.reason == reason,
                        onSelected: (value) => vm.setReason(reason),
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: AppText.labelLg.copyWith(
                          color: vm.reason == reason ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                        ),
                        backgroundColor: AppColors.surfaceContainer,
                        showCheckmark: false,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La asistencia manual queda registrada con tu nombre, la hora y el motivo elegido.',
                          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton.dark(
            label: 'Registrar asistencia (${vm.selected.length})',
            leadingIcon: Icons.check_circle_outline,
            isLoading: vm.isSaving,
            onPressed: vm.selected.isEmpty ? null : () => _save(context, vm),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _SectionTitle({required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(title, style: AppText.labelLg.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Fila con casilla para seleccionar a un estudiante.
class _SelectRow extends StatelessWidget {
  final ManualAttendanceViewModel vm;
  final CourseStudent student;
  final bool highlighted; // Fondo amarillo suave para los que reportaron falla

  const _SelectRow({required this.vm, required this.student, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final isSelected = vm.selected.contains(student.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF8E6) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => vm.toggle(student),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => vm.toggle(student),
                activeColor: AppColors.primaryContainer,
              ),
              InitialsAvatar(initials: student.initials, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                    Text(student.code, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          vm.reported(student) ? Icons.report_problem_outlined : Icons.signal_wifi_off,
                          size: 14,
                          color: vm.reported(student) ? AppColors.tertiaryContainer : AppColors.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vm.reportLabel(student),
                          style: AppText.labelSm.copyWith(
                            color: vm.reported(student) ? AppColors.tertiaryContainer : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
