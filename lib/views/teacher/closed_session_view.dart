import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../util/date_format.dart';
import '../../viewmodels/closed_session_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';

/// Asistencia cerrada (mockup 19): porcentaje, gráfica y listas de presentes y ausentes.
class ClosedSessionView extends StatelessWidget {
  const ClosedSessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ClosedSessionViewModel>(context);
    final course = vm.course;

    if (vm.isLoading) {
      return const Scaffold(
        appBar: DetailAppBar(title: 'Asistencia cerrada'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final group = course != null ? '${course.group} · ${course.room}' : '';

    return Scaffold(
      appBar: const DetailAppBar(title: 'Asistencia cerrada'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Clase #${vm.session.number} concluida',
                                style: AppText.labelMd.copyWith(color: AppColors.primaryContainer)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(vm.dateLabel,
                                style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(course?.name ?? '', style: AppText.headlineSm.copyWith(color: AppColors.onSurface)),
                      Text(group, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock_outline, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Balance de asistencia', style: AppText.titleLg.copyWith(color: AppColors.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${vm.percentLabel} de asistencia',
                          style: AppText.labelMd.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Dona: la parte azul son los presentes y la roja los ausentes.
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: vm.percent / 100,
                              strokeWidth: 16,
                              color: AppColors.primaryContainer,
                              backgroundColor: AppColors.error,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${vm.total}', style: AppText.headlineLg.copyWith(color: AppColors.onSurface)),
                              Text('ALUMNOS',
                                  style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _LegendRow(
                            color: AppColors.primaryContainer,
                            label: 'Presentes',
                            value: vm.present.length,
                            total: vm.total,
                          ),
                          const SizedBox(height: 8),
                          _LegendRow(
                            color: AppColors.error,
                            label: 'Ausentes',
                            value: vm.absent.length,
                            total: vm.total,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Tabs(vm: vm),
          const SizedBox(height: 12),
          if (vm.currentTab == 0) ...[
            for (final record in vm.present) ...[
              AppCard(
                child: Row(
                  children: [
                    InitialsAvatar(initials: record.initials, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.name, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                          Text(group, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                          if (record.isManual) ...[
                            const SizedBox(height: 4),
                            const StatusChip.manual(),
                          ],
                        ],
                      ),
                    ),
                    Text(DateFormatEs.time(record.markedAt),
                        style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Mostrando ${vm.present.length} alumnos presentes',
              textAlign: TextAlign.center,
              style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ] else ...[
            for (final student in vm.absent) ...[
              AppCard(
                child: Row(
                  children: [
                    InitialsAvatar(initials: student.initials, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                          Text(group, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const StatusChip.absent(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (vm.absent.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('¡Asistieron todos los inscritos!',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton.dark(
            label: 'Finalizar',
            leadingIcon: Icons.check_circle_outline,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int total;

  const _LegendRow({required this.color, required this.label, required this.value, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppText.bodyMd.copyWith(color: AppColors.onSurface))),
          Text.rich(
            TextSpan(
              text: '$value',
              style: AppText.titleLg.copyWith(color: color, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: ' /$total', style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestañas Presentes / Ausentes con forma de "interruptor" (como en el mockup).
class _Tabs extends StatelessWidget {
  final ClosedSessionViewModel vm;
  const _Tabs({required this.vm});

  @override
  Widget build(BuildContext context) {
    Widget tab(int index, String label, int count, Color badgeColor, Color badgeText) {
      final selected = vm.currentTab == index;
      return Expanded(
        child: InkWell(
          onTap: () => vm.selectTab(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: AppText.labelLg.copyWith(
                      color: selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                    )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
                  child: Text('$count', style: AppText.labelMd.copyWith(color: badgeText)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          tab(0, 'Presentes', vm.present.length, AppColors.primaryFixed, AppColors.primaryContainer),
          tab(1, 'Ausentes', vm.absent.length, AppColors.errorContainer, AppColors.error),
        ],
      ),
    );
  }
}
