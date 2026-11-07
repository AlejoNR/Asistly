import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../util/date_format.dart';
import '../../viewmodels/student_history_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/attendance_legend.dart';
import '../widgets/load_error.dart';
import '../widgets/percent_ring.dart';
import '../widgets/status_chip.dart';

/// Historial del estudiante (mockup 31): todas sus asistencias, con filtro por curso.
class StudentHistoryView extends StatelessWidget {
  const StudentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudentHistoryViewModel>(context);

    if (vm.isLoading) return const Center(child: CircularProgressIndicator());

    final children = <Widget>[];
    if (vm.error != null) {
      children.add(LoadError(message: vm.error!, onRetry: vm.load));
    } else if (vm.courseFilters.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              const Icon(Icons.history, size: 48, color: AppColors.outline),
              const SizedBox(height: 12),
              Text('Aún no tienes asistencias',
                  textAlign: TextAlign.center, style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 6),
              Text('Aquí verás cada clase de tus cursos, como presente o ausente.',
                  textAlign: TextAlign.center, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    } else {
      children.add(_Filters(vm: vm));
      children.add(const SizedBox(height: 16));
      children.add(_SummaryCard(vm: vm));
      for (final month in vm.months) {
        children.add(const SizedBox(height: 20));
        children.add(_MonthHeader(month: month));
        for (final record in month.records) {
          children.add(const SizedBox(height: 10));
          children.add(_RecordTile(record: record, now: DateTime.now()));
        }
      }
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children),
    );
  }
}

/// Chips para filtrar por curso. Se desplazan de lado si no caben.
class _Filters extends StatelessWidget {
  final StudentHistoryViewModel vm;
  const _Filters({required this.vm});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _FilterChip(label: 'Todos los cursos', selected: vm.selectedCourseId == null, onTap: () => vm.selectCourse(null)),
    ];
    vm.courseFilters.forEach((id, name) {
      chips.add(const SizedBox(width: 8));
      chips.add(_FilterChip(label: name, selected: vm.selectedCourseId == id, onTap: () => vm.selectCourse(id)));
    });
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: chips));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryContainer : AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: AppText.labelMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final StudentHistoryViewModel vm;
  const _SummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final ringColor = vm.isAtRisk ? AppColors.absent : AppColors.primaryContainer;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.tertiaryFixedDim, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('DESEMPEÑO SEMESTRAL',
                          style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Asistencia General', style: AppText.titleLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text('${vm.percent}%',
                        style: AppText.headlineLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    Text('de cumplimiento', style: AppText.bodySm.copyWith(color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 6),
                AttendanceLegend(present: vm.presentCount, absent: vm.absentCount),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PercentRing(
            percent: vm.percent,
            size: 96,
            strokeWidth: 10,
            color: ringColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(vm.isAtRisk ? Icons.warning_amber_rounded : Icons.verified_outlined, color: ringColor, size: 24),
                const SizedBox(height: 2),
                Text(vm.isAtRisk ? 'En riesgo' : 'Óptimo',
                    style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final HistoryMonth month;
  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    final count = month.records.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(month.title.toUpperCase(),
                style: AppText.labelLg.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.6)),
          ),
          Text('$count ${count == 1 ? 'registro' : 'registros'}',
              style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  final DateTime now;
  const _RecordTile({required this.record, required this.now});

  @override
  Widget build(BuildContext context) {
    final present = record.present;
    final dateText = DateFormatEs.relative(record.date, now);
    final Widget statusChip = present ? const StatusChip.present() : const StatusChip.absent();

    // En celulares angostos el chip va debajo del texto, para no partir el nombre del curso.
    // El LayoutBuilder va por fuera de AppCard: AppCard usa IntrinsicHeight, que no lo admite adentro.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        return AppCard(
          accentColor: present ? AppColors.primaryContainer : AppColors.error,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: present ? AppColors.primaryFixed : AppColors.absentContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_outlined, color: present ? AppColors.primaryContainer : AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.courseName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                    const SizedBox(height: 2),
                    // Si faltó no hay hora de registro: solo se muestra la fecha.
                    Text(present ? '$dateText · ${DateFormatEs.time(record.date)}' : dateText,
                        style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    if (narrow || record.manual) const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (narrow) statusChip,
                        if (record.manual) const StatusChip.manual(),
                      ],
                    ),
                  ],
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: 8),
                statusChip,
              ],
            ],
          ),
        );
      },
    );
  }
}
