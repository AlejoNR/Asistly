import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../models/course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../util/date_format.dart';
import '../../viewmodels/class_history_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/status_chip.dart';
import '../widgets/load_error.dart';

/// Historial de clases (no tiene mockup; sigue el estilo de "Clases anteriores"
/// del Detalle del curso). Agrupado por mes; tocar una clase abre su Asistencia cerrada.
class ClassHistoryView extends StatelessWidget {
  const ClassHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ClassHistoryViewModel>(context);
    final course = vm.course;

    if (vm.isLoading || course == null) {
      return Scaffold(
        appBar: const DetailAppBar(title: 'Historial de clases'),
        body: Center(
          child: vm.isLoading
              ? const CircularProgressIndicator()
              : LoadError(message: vm.error ?? 'No se encontró el curso.', onRetry: vm.load),
        ),
      );
    }

    final children = <Widget>[
      Text(course.name, style: AppText.headlineSm.copyWith(color: AppColors.onSurface)),
      const SizedBox(height: 2),
      Text(
        '${course.group} · ${vm.totalSessions == 1 ? '1 clase dictada' : '${vm.totalSessions} clases dictadas'}',
        style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
    ];

    if (vm.hasLiveSession) {
      children.add(_LiveCard(course: course, onReturn: vm.load));
      children.add(const SizedBox(height: 16));
    }

    if (vm.sessionsByMonth.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              const Icon(Icons.history, size: 48, color: AppColors.outline),
              const SizedBox(height: 12),
              Text('Aún no hay clases cerradas.', style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    for (final month in vm.sessionsByMonth.keys) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            month.toUpperCase(),
            style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1),
          ),
        ),
      );
      for (final session in vm.sessionsByMonth[month]!) {
        children.add(_HistoryCard(session: session, course: course));
        children.add(const SizedBox(height: 8));
      }
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Historial de clases'),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children),
      ),
    );
  }
}

/// Tarjeta amarilla "En curso": abre la Sesión activa.
class _LiveCard extends StatelessWidget {
  final Course course;
  final Future<void> Function() onReturn;
  const _LiveCard({required this.course, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: AppColors.tertiaryFixedDim,
      onTap: () => Navigator.pushNamed(context, 'active_session', arguments: course.id).then((value) => onReturn()),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sensors, color: AppColors.onTertiaryFixed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(
                  label: 'En curso',
                  background: AppColors.tertiaryFixed,
                  foreground: AppColors.onTertiaryFixed,
                  dotColor: AppColors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hoy · ${course.timeLabel} · ${course.room}',
                  style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text('Ver', style: AppText.labelLg.copyWith(color: AppColors.primary)),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
    );
  }
}

/// Una clase cerrada: número, fecha, horario, aula, presentes/ausentes,
/// barra de proporción y cantidad de registros manuales.
class _HistoryCard extends StatelessWidget {
  final ClassSession session;
  final Course course;
  const _HistoryCard({required this.session, required this.course});

  @override
  Widget build(BuildContext context) {
    final percent = session.attendancePercent.round();
    final isLow = percent < 75;

    return AppCard(
      onTap: () => Navigator.pushNamed(context, 'closed_session', arguments: session),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '#${session.number}',
                  style: AppText.titleMd.copyWith(color: AppColors.primaryContainer, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // El número ya está en el cuadro de la izquierda; aquí va la fecha.
                    Text(DateFormatEs.short(session.date), style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                    Text(
                      '${course.timeLabel} · ${course.room}',
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLow ? AppColors.absentContainer : AppColors.presentContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent%',
                  style: AppText.labelLg.copyWith(color: isLow ? AppColors.absent : AppColors.present),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de proporción: azul presentes, roja ausentes.
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: session.attendancePercent / 100,
              minHeight: 6,
              color: AppColors.primaryContainer,
              backgroundColor: AppColors.absent,
            ),
          ),
          const SizedBox(height: 8),
          // Wrap: presentes, ausentes y manuales bajan de línea si no caben.
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Count(
                color: AppColors.primaryContainer,
                text: session.presentCount == 1 ? '1 presente' : '${session.presentCount} presentes',
              ),
              _Count(
                color: AppColors.absent,
                text: session.absentCount == 1 ? '1 ausente' : '${session.absentCount} ausentes',
              ),
              if (session.manualCount > 0)
                Text(
                  session.manualCount == 1 ? '1 manual' : '${session.manualCount} manuales',
                  style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final Color color;
  final String text;
  const _Count({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: AppText.labelMd.copyWith(color: AppColors.onSurface)),
      ],
    );
  }
}
