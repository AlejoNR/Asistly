import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_repository.dart';
import '../../services/course_repository.dart';
import '../../viewmodels/main_viewmodel.dart';
import '../../viewmodels/teacher_courses_viewmodel.dart';
import '../../viewmodels/teacher_home_viewmodel.dart';
import '../../viewmodels/teacher_profile_viewmodel.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'teacher_courses_view.dart';
import 'teacher_home_view.dart';
import 'teacher_profile_view.dart';

/// Pantalla principal del docente con su barra inferior: Inicio, Cursos, Perfil.
class TeacherMainView extends StatelessWidget {
  const TeacherMainView({super.key});

  static const _tabs = [
    NavItem(Icons.home_outlined, 'Inicio'),
    NavItem(Icons.menu_book_outlined, 'Cursos'),
    NavItem(Icons.account_circle_outlined, 'Perfil'),
  ];

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
          ChangeNotifierProvider(
            create: (context) => TeacherCoursesViewModel(
              Provider.of<CourseRepository>(context, listen: false),
            ),
            child: const TeacherCoursesView(),
          ),
          ChangeNotifierProvider(
            create: (context) => TeacherProfileViewModel(
              Provider.of<AuthRepository>(context, listen: false),
              Provider.of<CourseRepository>(context, listen: false),
            ),
            child: const TeacherProfileView(),
          ),
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
