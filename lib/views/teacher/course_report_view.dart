import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../models/course_student.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/course_report_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/initials_avatar.dart';

/// Reporte del curso (mockup 20): promedio, clases hechas, estudiantes en riesgo,
/// dona de distribución, barras por clase y lista de estudiantes. Sin exportación.
class CourseReportView extends StatelessWidget {
  const CourseReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CourseReportViewModel>(context);
    final course = vm.course;

    if (vm.isLoading || course == null) {
      return Scaffold(
        appBar: const DetailAppBar(title: 'Reporte del curso'),
        body: Center(child: vm.isLoading ? const CircularProgressIndicator() : const Text('No se encontró el curso.')),
      );
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Reporte del curso'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Encabezado "REPORTE ACADÉMICO" con franja azul a la izquierda.
          AppCard(
            accentColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'REPORTE ACADÉMICO',
                        style: AppText.labelMd.copyWith(color: AppColors.primaryContainer, letterSpacing: 1),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_outlined, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Docente', style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(course.name, style: AppText.headlineSm.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(
                  '${course.group} · Semestre ${course.semester}',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_outlined, size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        '${vm.students.length} estudiantes inscritos',
                        style: AppText.labelMd.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Las tres tarjetas de resumen.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Asistencia prom.',
                    value: '${vm.averageAttendance}%',
                    footer: 'General del curso',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(title: 'Clases hechas', value: '${vm.classesDone}', footer: 'Realizadas'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'En riesgo',
                    value: '${vm.atRiskCount}',
                    footer: '<${CourseReportViewModel.goal}% mín.',
                    isAlert: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DistributionCard(vm: vm),
          const SizedBox(height: 12),
          _BarsCard(sessions: vm.sessions),
          const SizedBox(height: 12),
          _StudentsCard(vm: vm),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estados de asistencia calculados según régimen oficial (Presente / Ausente).',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta pequeña con un número grande (promedio, clases, en riesgo).
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String footer;
  final bool isAlert; // Roja: estudiantes en riesgo

  const _StatCard({required this.title, required this.value, required this.footer, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? AppColors.absent : AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelMd.copyWith(color: isAlert ? AppColors.absent : AppColors.onSurfaceVariant),
                ),
              ),
              if (isAlert)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.absent, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.headlineMd.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (isAlert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.absentContainer, borderRadius: BorderRadius.circular(4)),
              child: Text(footer, style: AppText.labelSm.copyWith(color: AppColors.absent)),
            )
          else
            Text(
              footer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// "Distribución de estudiantes": dona azul (regular) y roja (en riesgo) con su leyenda.
class _DistributionCard extends StatelessWidget {
  final CourseReportViewModel vm;
  const _DistributionCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Distribución de estudiantes', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
              ),
              Text(
                '${vm.students.length} en total',
                style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Igual que en Asistencia cerrada: un CircularProgressIndicator grueso hace de dona.
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: vm.regularFraction,
                    strokeWidth: 14,
                    color: AppColors.primaryContainer,
                    backgroundColor: vm.students.isEmpty ? AppColors.surfaceContainer : AppColors.absent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${vm.students.length}',
                      style: AppText.headlineMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
                    ),
                    Text('estudiantes', style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _LegendRow(
            color: AppColors.primaryContainer,
            background: AppColors.surfaceContainerLow,
            label: 'Asistencia regular (≥${CourseReportViewModel.goal}%)',
            value: vm.regularCount,
          ),
          const SizedBox(height: 8),
          _LegendRow(
            color: AppColors.absent,
            background: AppColors.absentContainer,
            label: 'En riesgo (<${CourseReportViewModel.goal}%)',
            value: vm.atRiskCount,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final Color background;
  final String label;
  final int value;

  const _LegendRow({required this.color, required this.background, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppText.bodyMd.copyWith(color: color)),
          ),
          Text(
            '$value',
            style: AppText.titleMd.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// "Asistencia por clase": una barra por clase y una línea punteada en la meta del 75 %.
/// Se dibuja con Containers (sin paquetes de gráficas): la altura de cada barra
/// es su porcentaje de la altura total.
class _BarsCard extends StatelessWidget {
  final List<ClassSession> sessions;
  const _BarsCard({required this.sessions});

  static const plotHeight = 140.0; // Altura que equivale al 100 %
  static const labelSpace = 14.0; // Espacio arriba para el % de las barras rojas
  static const totalHeight = plotHeight + labelSpace;
  static const minSlotWidth = 20.0; // Si no caben así, la gráfica se desplaza de lado

  @override
  Widget build(BuildContext context) {
    const goal = CourseReportViewModel.goal;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Asistencia por clase', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 2, color: AppColors.absent),
                    const SizedBox(width: 4),
                    Text('Meta $goal%', style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'Porcentaje de asistencia en cada sesión',
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aún no hay clases cerradas.',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eje Y: 100 %, 75 %, 50 %, 0 %, a la misma altura que las barras.
                SizedBox(
                  width: 34,
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none, // Que no se corten "100%" ni "0%"
                    children: [
                      for (final mark in [100, 75, 50, 0])
                        Positioned(
                          top: labelSpace + plotHeight * (1 - mark / 100) - 7,
                          left: 0,
                          child: Text(
                            '$mark%',
                            style: AppText.labelSm.copyWith(
                              color: mark == goal ? AppColors.absent : AppColors.outline,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // LayoutBuilder dice cuánto ancho hay: las barras se reparten
                // todo el espacio, y solo si son muchas se desplazan de lado.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      var slotWidth = constraints.maxWidth / sessions.length;
                      if (slotWidth < minSlotWidth) slotWidth = minSlotWidth;
                      return _bars(slotWidth);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bars(double slotWidth) {
    const goal = CourseReportViewModel.goal;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: sessions.length * slotWidth,
        child: Column(
          children: [
            SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final session in sessions) _Bar(percent: session.attendancePercent, slotWidth: slotWidth),
                    ],
                  ),
                  // Línea de la meta del 75 %.
                  Positioned(
                    top: labelSpace + plotHeight * (1 - goal / 100),
                    left: 0,
                    right: 0,
                    child: const _DashedLine(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final session in sessions)
                  SizedBox(
                    width: slotWidth,
                    child: Text(
                      'C${session.number}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppText.labelSm.copyWith(
                        fontSize: 9,
                        color: session.attendancePercent < goal ? AppColors.absent : AppColors.onSurfaceVariant,
                        fontWeight: session.attendancePercent < goal ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Una barra: azul si llega a la meta, roja (con su porcentaje encima) si no.
class _Bar extends StatelessWidget {
  final double percent;
  final double slotWidth;
  const _Bar({required this.percent, required this.slotWidth});

  @override
  Widget build(BuildContext context) {
    final isLow = percent < CourseReportViewModel.goal;
    return SizedBox(
      width: slotWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isLow)
            Text(
              '${percent.round()}%',
              maxLines: 1,
              style: AppText.labelSm.copyWith(color: AppColors.absent, fontSize: 8, fontWeight: FontWeight.w700),
            ),
          Container(
            width: slotWidth * 0.65,
            height: _BarsCard.plotHeight * percent / 100,
            decoration: BoxDecoration(
              color: isLow ? AppColors.absent : AppColors.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea punteada horizontal hecha con pequeños rectángulos.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: Row(
        children: [
          for (var i = 0; i < 60; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                color: i.isEven ? AppColors.absent : Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Estudiantes" ordenados por asistencia, con chip "En riesgo" y barra de progreso.
class _StudentsCard extends StatelessWidget {
  final CourseReportViewModel vm;
  const _StudentsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
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
                    Text('Estudiantes', style: AppText.titleMd.copyWith(color: AppColors.onSurface)),
                    Text(
                      vm.ascending ? 'Ordenados de menor a mayor asistencia' : 'Ordenados de mayor a menor asistencia',
                      style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: vm.toggleOrder,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AppText.labelMd,
                ),
                icon: const Icon(Icons.sort, size: 16),
                label: Text(vm.ascending ? 'Ascendente' : 'Descendente'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aún no hay estudiantes inscritos.',
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          for (final student in vm.students) ...[_StudentRow(student: student), const SizedBox(height: 8)],
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final CourseStudent student;
  const _StudentRow({required this.student});

  @override
  Widget build(BuildContext context) {
    final atRisk = student.isAtRisk;
    final color = atRisk ? AppColors.absent : AppColors.primaryContainer;
    final absences = student.absences == 1 ? '1 ausencia' : '${student.absences} ausencias';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(
                initials: student.initials,
                size: 40,
                background: atRisk ? AppColors.absentContainer : AppColors.primaryFixed,
                foreground: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleMd.copyWith(color: AppColors.onSurface),
                    ),
                    if (atRisk)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('En riesgo', style: AppText.labelSm.copyWith(color: AppColors.absent)),
                      ),
                    Text('Código: ${student.code}', style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${student.attendancePercent.round()}%',
                    style: AppText.titleLg.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                  Text(absences, style: AppText.labelSm.copyWith(color: color)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: student.attendancePercent / 100,
              minHeight: 5,
              color: color,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}
