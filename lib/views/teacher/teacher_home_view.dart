import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/teacher_home_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';

/// Home del docente (mockup 09): saludo, cursos activos y botón "+" para crear un curso.
class TeacherHomeView extends StatelessWidget {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TeacherHomeViewModel>(context);

    final children = <Widget>[
      _WelcomeCard(name: vm.greetingName, date: vm.todayLabel),
      const SizedBox(height: 24),
      _SectionHeader(count: vm.courses.length),
      const SizedBox(height: 16),
    ];

    if (vm.isLoading) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else {
      for (final course in vm.courses) {
        children.add(_TeacherCourseCard(course: course, onReturn: vm.loadCourses));
        children.add(const SizedBox(height: 16));
      }
    }

    // Scaffold propio para poner el botón flotante solo en esta pestaña.
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: vm.loadCourses, // Deslizar hacia abajo recarga los cursos.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: children,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, 'new_course');
          vm.loadCourses(); // Al volver, recarga para mostrar el curso nuevo.
        },
        tooltip: 'Agregar nuevo curso',
        backgroundColor: AppColors.tertiaryFixed,
        foregroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

/// Tarjeta azul de bienvenida: "PANEL DOCENTE · Hola, Prof. Ramírez".
class _WelcomeCard extends StatelessWidget {
  final String name;
  final String date;

  const _WelcomeCard({required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Stack(
        children: [
          // Círculo decorativo en la esquina, como en el mockup.
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANEL DOCENTE',
                  style: AppText.labelMd.copyWith(color: AppColors.secondaryFixed, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hola, $name',
                  style: AppText.headlineMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(date, style: AppText.bodyMd.copyWith(color: AppColors.onPrimaryContainer)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cursos activos" con el contador de materias a la derecha.
class _SectionHeader extends StatelessWidget {
  final int count;
  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.view_timeline_outlined, size: 20, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text('Cursos activos', style: AppText.titleLg.copyWith(color: AppColors.primary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count == 1 ? '1 materia' : '$count materias',
            style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de un curso del docente. Franja amarilla y chip si la clase está en curso.
class _TeacherCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onReturn; // Recarga los cursos al volver
  const _TeacherCourseCard({required this.course, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final isLive = course.hasActiveSession;

    return AppCard(
      accentColor: isLive ? AppColors.tertiaryFixedDim : AppColors.primary,
      onTap: () => Navigator.pushNamed(context, 'course_detail', arguments: course.id).then((value) => onReturn()),
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
                    Text(course.name, style: AppText.titleLg.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(course.group, style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (isLive) const StatusChip.live(),
            ],
          ),
          const SizedBox(height: 16),
          _InfoLine(icon: Icons.schedule, text: course.scheduleLabel),
          const SizedBox(height: 4),
          _InfoLine(icon: Icons.group_outlined, text: '${course.enrolledCount} estudiantes'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              // Si hay clase en curso se abre la sesión; si no, el detalle para iniciarla.
              onPressed: () {
                if (isLive) {
                  Navigator.pushNamed(context, 'active_session', arguments: course.id).then((value) => onReturn());
                } else {
                  Navigator.pushNamed(context, 'course_detail', arguments: course.id).then((value) => onReturn());
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: AppText.labelLg,
              ),
              icon: Icon(isLive ? Icons.visibility_outlined : Icons.play_arrow, size: 20),
              label: Text(isLive ? 'Ver clase' : 'Iniciar clase'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renglón con ícono gris azulado y texto secundario.
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
