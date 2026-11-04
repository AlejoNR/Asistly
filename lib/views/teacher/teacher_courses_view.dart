import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/teacher_courses_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/load_error.dart';

/// Pestaña "Cursos" del docente (sin mockup propio): lista compacta de todos
/// sus cursos con buscador, en el mismo estilo de las tarjetas del Home.
class TeacherCoursesView extends StatelessWidget {
  const TeacherCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TeacherCoursesViewModel>(context);

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text('Mis cursos', style: AppText.headlineSm.copyWith(color: AppColors.primary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
            child: Text(
              vm.totalCourses == 1 ? '1 materia' : '${vm.totalCourses} materias',
              style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        onChanged: vm.setQuery,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, grupo o código',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (vm.isLoading) {
      children.add(
        const Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (vm.error != null) {
      children.add(LoadError(message: vm.error!, onRetry: vm.loadCourses));
    } else if (vm.courses.isEmpty) {
      children.add(_EmptyState(searching: vm.query.trim().isNotEmpty));
    } else {
      for (final course in vm.courses) {
        children.add(_CourseRow(course: course, onReturn: vm.loadCourses));
        children.add(const SizedBox(height: 12));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: vm.loadCourses,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: children),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // El Home también tiene un botón flotante y las dos pestañas viven a la vez
        // (IndexedStack): sin esto Flutter falla con "multiple heroes share the same tag".
        heroTag: null,
        onPressed: () async {
          await Navigator.pushNamed(context, 'new_course');
          vm.loadCourses(); // Al volver, recarga para mostrar el curso nuevo.
        },
        backgroundColor: AppColors.tertiaryFixed,
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: Text('Nuevo curso', style: AppText.labelLg),
      ),
    );
  }
}

/// Renglón de un curso: nombre, grupo · semestre, horario, inscritos y pendientes.
class _CourseRow extends StatelessWidget {
  final Course course;
  final Future<void> Function() onReturn;
  const _CourseRow({required this.course, required this.onReturn});

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
                    Text(course.name, style: AppText.titleMd.copyWith(color: AppColors.primary)),
                    Text(
                      '${course.group} · ${course.semester}',
                      style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    // El chip va debajo del nombre para no apretarlo en pantallas angostas.
                    if (isLive) ...[const SizedBox(height: 6), const StatusChip.live()],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(course.scheduleLabel, style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Wrap: si no cabe el chip de pendientes, baja a la siguiente línea
              // en vez de empujar el código fuera de la tarjeta.
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          '${course.enrolledCount} inscritos',
                          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (course.pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          course.pendingCount == 1 ? '1 pendiente' : '${course.pendingCount} pendientes',
                          style: AppText.labelSm.copyWith(color: AppColors.onTertiaryFixed),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                course.enrollCode,
                style: AppText.labelMd.copyWith(color: AppColors.primaryContainer, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(searching ? Icons.search_off : Icons.menu_book_outlined, size: 48, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(
            searching ? 'Ningún curso coincide con la búsqueda.' : 'Aún no tienes cursos. Crea el primero.',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
