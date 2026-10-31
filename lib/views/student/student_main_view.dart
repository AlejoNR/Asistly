import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/main_viewmodel.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/coming_soon.dart';
import '../widgets/temporary_profile.dart';

/// Pantalla principal del estudiante con su barra inferior: Inicio, Historial, Perfil.
class StudentMainView extends StatelessWidget {
  const StudentMainView({super.key});

  static const _tabs = [
    NavItem(Icons.home_outlined, 'Inicio'),
    NavItem(Icons.history, 'Historial'),
    NavItem(Icons.account_circle_outlined, 'Perfil'),
  ];

  Future<void> _signOut(BuildContext context, MainViewModel vm) async {
    await vm.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, 'role', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);

    return Scaffold(
      appBar: AppTopBar(title: 'Asistly', subtitle: _tabs[vm.currentTab].label),
      body: IndexedStack(
        index: vm.currentTab,
        children: [
          const ComingSoon(icon: Icons.home_outlined, title: 'Inicio del estudiante'),
          const ComingSoon(icon: Icons.history, title: 'Historial de asistencias'),
          TemporaryProfile(user: vm.user, onSignOut: () => _signOut(context, vm)),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _tabs,
        currentIndex: vm.currentTab,
        onTap: vm.selectTab,
      ),
    );
  }
}
