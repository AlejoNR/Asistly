import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course_student.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/course_students_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/request_card.dart';
import '../widgets/withdraw_sheet.dart';

/// Estudiantes del curso (mockup 14): búsqueda, pestañas y acciones por estudiante.
class CourseStudentsView extends StatelessWidget {
  const CourseStudentsView({super.key});

  Future<void> _openImport(BuildContext context, CourseStudentsViewModel vm) async {
    await Navigator.pushNamed(context, 'import_list', arguments: vm.courseId);
    vm.load(); // Al volver, aparecen los de la lista en "Sin unirse".
  }

  Future<void> _withdraw(BuildContext context, CourseStudentsViewModel vm, CourseStudent student) async {
    final confirmed = await showWithdrawSheet(context, student);
    if (!confirmed) return;
    await vm.withdraw(student);
    if (context.mounted) showAppSnackBar(context, '${student.name} fue retirado del curso.');
  }

  /// Menú de los tres puntos de cada estudiante.
  void _showStudentMenu(BuildContext context, CourseStudentsViewModel vm, CourseStudent student) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: const Text('Ver historial'),
              onTap: () {
                Navigator.pop(sheetContext);
                showAppSnackBar(context, 'Historial de ${student.name}: ${student.absences} ausencias.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: const Text('Retirar del curso', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _withdraw(context, vm, student);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Opciones de orden del botón "Filtrar".
  void _showSortMenu(BuildContext context, CourseStudentsViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(vm.sortByAttendance ? Icons.radio_button_off : Icons.radio_button_checked,
                  color: AppColors.primary),
              title: const Text('Orden alfabético'),
              onTap: () {
                vm.setSortByAttendance(false);
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: Icon(vm.sortByAttendance ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: AppColors.primary),
              title: const Text('Menor asistencia primero'),
              onTap: () {
                vm.setSortByAttendance(true);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CourseStudentsViewModel>(context);
    final course = vm.course;
    final students = vm.visibleStudents;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Estudiantes del curso'),
      body: vm.isLoading && course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estudiantes', style: AppText.headlineLg.copyWith(color: AppColors.onSurface)),
                          Text(
                            '${course?.name ?? ''} · ${vm.enrolled.length} inscritos',
                            style: AppText.titleMd.copyWith(color: AppColors.primaryContainer),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openImport(context, vm),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        side: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      icon: const Icon(Icons.upload_file_outlined, size: 20),
                      label: const Text('Importar lista'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: vm.setQuery,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o matrícula',
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
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => _showSortMenu(context, vm),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLow,
                          foregroundColor: AppColors.onSurfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.tune, size: 20),
                        label: const Text('Filtrar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Tabs(vm: vm),
                const SizedBox(height: 12),
                Text(vm.tabHint, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 16),
                if (vm.currentTab == 2 && students.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(context, 'pending_requests', arguments: vm.courseId);
                          vm.load();
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver solicitudes'),
                      ),
                      TextButton.icon(
                        onPressed: vm.acceptAll,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Aceptar todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (students.isEmpty)
                  const _EmptyResult()
                else
                  for (final student in students) ...[
                    if (vm.currentTab == 2)
                      RequestCard(
                        student: student,
                        onAccept: () => vm.accept(student),
                        onReject: () => vm.reject(student),
                      )
                    else
                      _StudentRow(
                        student: student,
                        showPercent: vm.currentTab == 0 || vm.currentTab == 3,
                        onMenu: vm.currentTab == 0 ? () => _showStudentMenu(context, vm, student) : null,
                      ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
    );
  }
}

/// Pestañas Inscritos / Sin unirse / Pendientes / Retirados (se desplazan de lado).
class _Tabs extends StatelessWidget {
  final CourseStudentsViewModel vm;
  const _Tabs({required this.vm});

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Inscritos (${vm.enrolled.length})',
      'Sin unirse (${vm.notJoined.length})',
      'Pendientes',
      'Retirados (${vm.withdrawn.length})',
    ];

    final tabs = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final selected = vm.currentTab == i;
      tabs.add(InkWell(
        onTap: () => vm.selectTab(i),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryContainer : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                labels[i],
                style: AppText.labelLg.copyWith(
                  color: selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                ),
              ),
              // Burbuja amarilla con el número de pendientes.
              if (i == 2 && vm.pending.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixedDim,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${vm.pending.length}',
                      style: AppText.labelMd.copyWith(color: AppColors.onTertiaryFixed)),
                ),
              ],
            ],
          ),
        ),
      ));
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tabs),
      ),
    );
  }
}

/// Fila de un estudiante: avatar, nombre, código y porcentaje (rojo si está en riesgo).
class _StudentRow extends StatelessWidget {
  final CourseStudent student;
  final bool showPercent;
  final VoidCallback? onMenu;

  const _StudentRow({required this.student, required this.showPercent, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final atRisk = showPercent && student.isAtRisk;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: atRisk ? AppColors.errorContainer : AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Text(
              student.initials,
              style: AppText.titleMd.copyWith(color: atRisk ? AppColors.onErrorContainer : AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(student.code, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          if (showPercent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: atRisk ? AppColors.errorContainer : AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  if (atRisk)
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error)
                  else
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '${student.attendancePercent.round()}%',
                    style: AppText.labelLg.copyWith(color: atRisk ? AppColors.error : AppColors.secondary),
                  ),
                ],
              ),
            ),
          if (onMenu != null)
            IconButton(onPressed: onMenu, icon: const Icon(Icons.more_vert), tooltip: 'Opciones')
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.person_search_outlined, size: 48, color: AppColors.outline),
          const SizedBox(height: 12),
          Text('No se encontraron estudiantes', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Revisa el nombre o la matrícula ingresada e inténtalo de nuevo.',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
