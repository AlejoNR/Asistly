import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_record.dart';
import '../../models/course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../util/date_format.dart';
import '../../viewmodels/student_course_detail_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/attendance_legend.dart';
import '../widgets/common.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/leave_course_sheet.dart';
import '../widgets/load_error.dart';
import '../widgets/percent_ring.dart';
import '../widgets/status_chip.dart';

/// Detalle del curso del estudiante (mockup 24). El mockup dice que al salir se pierde
/// el registro; la especificación dice que nunca se borra, y manda la especificación.
class StudentCourseDetailView extends StatelessWidget {
  const StudentCourseDetailView({super.key});

  Future<void> _leave(BuildContext context, StudentCourseDetailViewModel vm) async {
    final confirmed = await showLeaveCourseSheet(context, vm.course);
    if (!confirmed || !context.mounted) return;
    final error = await vm.leave();
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    showAppSnackBar(context, 'Saliste de ${vm.course.name}.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudentCourseDetailViewModel>(context);

    final Widget attendance;
    if (vm.isLoading) {
      attendance = const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    } else if (vm.error != null) {
      attendance = LoadError(message: vm.error!, onRetry: vm.load);
    } else {
      attendance = _AttendanceCard(vm: vm);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DetailAppBar(title: 'Detalle del curso'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _HeroCard(course: vm.course),
          const SizedBox(height: 16),
          _ScheduleCard(course: vm.course),
          const SizedBox(height: 16),
          attendance,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: vm.isLeaving ? null : () => _leave(context, vm),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.absentContainer,
                foregroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: AppText.labelLg,
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(vm.isLeaving ? 'Saliendo...' : 'Salir del curso'),
            ),
          ),
          const SizedBox(height: 8),
          Text('Si sales del curso, tus asistencias se conservan.',
              textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Course course;
  const _HeroCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: 'Semestre ${course.semester} · Código: ${course.enrollCode}',
            background: AppColors.surfaceContainer,
            foreground: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(course.fullName, style: AppText.headlineSm.copyWith(color: AppColors.onSurface)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: const Icon(Icons.school_outlined, size: 22, color: AppColors.primaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(course.teacherName, style: AppText.titleMd.copyWith(color: AppColors.onSurface))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un solo horario para todos los días del curso (especificación, sección 5).
class _ScheduleCard extends StatelessWidget {
  final Course course;
  const _ScheduleCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final day in course.days) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(DateFormatEs.shortDay(day).toUpperCase(),
                    style: AppText.labelMd.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              // Wrap: el aula va a la derecha si cabe; si no, baja completa y no parte la hora.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(course.timeLabel, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                    StatusChip(
                      label: course.room,
                      background: AppColors.surfaceContainerHigh,
                      foreground: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Horario', style: AppText.titleLg.copyWith(color: AppColors.onSurface))),
              StatusChip(
                label: '${course.days.length} ${course.days.length == 1 ? 'clase' : 'clases'} / sem',
                background: AppColors.primaryFixed,
                foreground: AppColors.primaryContainer,
              ),
            ],
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final StudentCourseDetailViewModel vm;
  const _AttendanceCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final record in vm.recentRecords) {
      rows.add(_SessionRow(record: record));
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox + Wrap: el chip baja de línea si no cabe, en vez de partir "asistencia".
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primaryContainer),
                    const SizedBox(width: 10),
                    Text('Mi asistencia', style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
                  ],
                ),
                StatusChip(
                  label: '${vm.records.length} ${vm.records.length == 1 ? 'clase cursada' : 'clases cursadas'}',
                  background: AppColors.surfaceContainer,
                  foreground: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: vm.records.isEmpty
                ? Text('Todavía no hay clases registradas en este curso.',
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant))
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${vm.percent}%',
                                style: AppText.headlineLg.copyWith(
                                    color: AppColors.primaryContainer, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            AttendanceLegend(present: vm.presentCount, absent: vm.absentCount),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PercentRing(
                        percent: vm.percent,
                        child: const Icon(Icons.done_all, color: AppColors.primaryContainer),
                      ),
                    ],
                  ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // SizedBox a todo el ancho: sin él, el Wrap se encoge y el enlace no queda a la derecha.
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text('ÚLTIMAS SESIONES',
                      style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.6)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, 'student_course_history', arguments: vm.course.id),
                    child: const Text('Historial completo'),
                  ),
                ],
              ),
            ),
            ...rows,
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final AttendanceRecord record;
  const _SessionRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
            child: Text('${record.number}',
                style: AppText.labelMd.copyWith(color: AppColors.primaryContainer, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sesión #${record.number}', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                Text(DateFormatEs.short(record.date),
                    style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                if (record.manual) ...[
                  const SizedBox(height: 4),
                  const StatusChip.manual(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          record.present ? const StatusChip.present() : const StatusChip.absent(),
        ],
      ),
    );
  }
}
