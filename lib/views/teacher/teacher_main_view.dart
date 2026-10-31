import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/main_viewmodel.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/coming_soon.dart';
import '../widgets/temporary_profile.dart';

/// Pantalla principal del docente con su barra inferior: Inicio, Cursos, Perfil.
class TeacherMainView extends StatelessWidget {
  const TeacherMainView({super.key});

  static const _tabs = [
    NavItem(Icons.home_outlined, 'Inicio'),
    NavItem(Icons.menu_book_outlined, 'Cursos'),
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

    // IndexedStack mantiene vivas las tres pestañas: al volver a una,
    // conserva su estado (por ejemplo, la posición del scroll).
    return Scaffold(
      appBar: AppTopBar(title: 'Asistly', subtitle: _tabs[vm.currentTab].label),
      body: IndexedStack(
        index: vm.currentTab,
        children: [
          const ComingSoon(icon: Icons.home_outlined, title: 'Inicio del docente'),
          const ComingSoon(icon: Icons.menu_book_outlined, title: 'Mis cursos'),
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
