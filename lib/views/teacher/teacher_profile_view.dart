import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/teacher_profile_viewmodel.dart';
import '../widgets/profile_parts.dart';

/// Perfil del docente. Sigue el mockup 32 (perfil del estudiante) sin campana
/// ni "Ayuda" (no están en la especificación). En vez de asistencia global,
/// el resumen muestra sus cursos y estudiantes.
class TeacherProfileView extends StatelessWidget {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TeacherProfileViewModel>(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ProfileCard(
          vm: vm,
          stats: [
            ProfileStat(value: '${vm.courseCount}', label: 'Cursos\nactivos'),
            ProfileStat(value: '${vm.studentCount}', label: 'Estudiantes\ninscritos'),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Preferencias y Seguridad',
              style: AppText.titleMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        ProfileAccountOptions(vm: vm),
        const SizedBox(height: 24),
        Text('Asistly v1.0 · Universidad de la Amazonia',
            textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.outline)),
      ],
    );
  }
}
