import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_repository.dart';
import '../../services/course_repository.dart';
import '../../viewmodels/main_viewmodel.dart';
import '../../viewmodels/teacher_home_viewmodel.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/coming_soon.dart';
import '../widgets/temporary_profile.dart';
import 'teacher_home_view.dart';

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
          // Cada pestaña tiene su propio ViewModel.
          ChangeNotifierProvider(
            create: (context) => TeacherHomeViewModel(
              Provider.of<AuthRepository>(context, listen: false),
              Provider.of<CourseRepository>(context, listen: false),
            ),
            child: const TeacherHomeView(),
          ),
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
