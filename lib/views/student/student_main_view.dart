import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_repository.dart';
import '../../services/course_repository.dart';
import '../../services/permission_service.dart';
import '../../services/session_repository.dart';
import '../../viewmodels/permissions_viewmodel.dart';
import '../../viewmodels/student_history_viewmodel.dart';
import '../../viewmodels/student_home_viewmodel.dart';
import '../../viewmodels/student_main_viewmodel.dart';
import '../../viewmodels/student_profile_viewmodel.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'permissions_view.dart';
import 'student_history_view.dart';
import 'student_home_view.dart';
import 'student_profile_view.dart';

/// Pantalla principal del estudiante. Si faltan permisos muestra primero
/// "Antes de empezar"; después, las pestañas: Inicio, Historial y Perfil.
class StudentMainView extends StatelessWidget {
  const StudentMainView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudentMainViewModel>(context);

    if (vm.isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (vm.showPermissions) {
      return ChangeNotifierProvider(
        create: (context) => PermissionsViewModel(PermissionService()),
        child: PermissionsView(onContinue: vm.permissionsDone),
      );
    }

    // Los ViewModels van aquí arriba (no dentro de cada pestaña) para que la barra
    // inferior pueda pedirles que recarguen al volver a la pestaña.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => StudentHomeViewModel(
            Provider.of<AuthRepository>(context, listen: false),
            Provider.of<CourseRepository>(context, listen: false),
            Provider.of<SessionRepository>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => StudentHistoryViewModel(Provider.of<CourseRepository>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) => StudentProfileViewModel(
            Provider.of<AuthRepository>(context, listen: false),
            Provider.of<CourseRepository>(context, listen: false),
          ),
        ),
      ],
      child: const _StudentTabs(),
    );
  }
}

class _StudentTabs extends StatelessWidget {
  const _StudentTabs();

  static const _tabs = [
    NavItem(Icons.home_outlined, 'Inicio'),
    NavItem(Icons.history, 'Historial'),
    NavItem(Icons.account_circle_outlined, 'Perfil'),
  ];

  /// Cambia de pestaña y recarga sus datos: pudieron cambiar en otra pantalla.
  void _selectTab(BuildContext context, int index) {
    Provider.of<StudentMainViewModel>(context, listen: false).selectTab(index);
    if (index == 0) Provider.of<StudentHomeViewModel>(context, listen: false).load();
    if (index == 1) Provider.of<StudentHistoryViewModel>(context, listen: false).load();
    if (index == 2) Provider.of<StudentProfileViewModel>(context, listen: false).load();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudentMainViewModel>(context);

    return Scaffold(
      appBar: AppTopBar(title: 'Asistly', subtitle: _tabs[vm.currentTab].label),
      body: IndexedStack(
        index: vm.currentTab,
        children: const [StudentHomeView(), StudentHistoryView(), StudentProfileView()],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _tabs,
        currentIndex: vm.currentTab,
        onTap: (index) => _selectTab(context, index),
      ),
    );
  }
}
