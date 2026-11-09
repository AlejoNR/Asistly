import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/student_profile_viewmodel.dart';
import '../widgets/profile_parts.dart';

/// Perfil del estudiante (mockup 32). La especificación pide además el celular
/// vinculado, y no tiene campana ni "Ayuda".
class StudentProfileView extends StatelessWidget {
  const StudentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudentProfileViewModel>(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ProfileCard(
          vm: vm,
          stats: [
            ProfileStat(value: vm.hasClasses ? '${vm.globalPercent}%' : '—', label: 'Asistencia\nglobal'),
            ProfileStat(
              value: vm.isAtRisk ? 'En riesgo' : 'Regular',
              label: 'Estado\nalumno',
              valueColor: vm.isAtRisk ? AppColors.absent : AppColors.present,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Preferencias y Seguridad',
              style: AppText.titleMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        ProfileOptionTile(
          icon: Icons.smartphone_outlined,
          title: 'Dispositivo vinculado',
          subtitle: '${vm.deviceLabel}. Para cambiarlo, solicítalo al administrador.',
        ),
        const SizedBox(height: 12),
        ProfileAccountOptions(vm: vm),
        const SizedBox(height: 24),
        Text('Asistly v1.0 · Universidad de la Amazonia',
            textAlign: TextAlign.center, style: AppText.bodySm.copyWith(color: AppColors.outline)),
      ],
    );
  }
}
