import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_repository.dart';
import 'services/course_repository.dart';
import 'theme/app_theme.dart';
import 'models/course.dart';
import 'viewmodels/check_email_viewmodel.dart';
import 'viewmodels/course_created_viewmodel.dart';
import 'viewmodels/course_detail_viewmodel.dart';
import 'viewmodels/course_students_viewmodel.dart';
import 'viewmodels/demo_viewmodel.dart';
import 'viewmodels/forgot_password_viewmodel.dart';
import 'viewmodels/import_list_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/main_viewmodel.dart';
import 'viewmodels/new_course_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/role_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'viewmodels/verify_email_viewmodel.dart';
import 'views/check_email_view.dart';
import 'views/demo_view.dart';
import 'views/forgot_password_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/role_view.dart';
import 'views/splash_view.dart';
import 'views/student/student_main_view.dart';
import 'views/teacher/course_created_view.dart';
import 'views/teacher/course_detail_view.dart';
import 'views/teacher/course_students_view.dart';
import 'views/teacher/import_list_view.dart';
import 'views/teacher/pending_requests_view.dart';
import 'views/teacher/new_course_view.dart';
import 'views/teacher/teacher_main_view.dart';
import 'views/verify_email_view.dart';
import 'views/widgets/coming_soon.dart';

void main() async {
  // Firebase debe iniciarse antes de mostrar la app.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppState());
}

/// Registra lo que comparte toda la app: los repositorios (capa Modelo).
class AppState extends StatelessWidget {
  /// Pantalla con la que arranca la app: 'splash' normalmente, 'demo' en el modo demo.
  final String initialRoute;
  const AppState({super.key, this.initialRoute = 'splash'});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => CourseRepository()),
      ],
      child: MyApp(initialRoute: initialRoute),
    );
  }
}

/// Arquitectura MVVM: cada ruta crea su Vista junto con su ViewModel.
/// El ViewModel recibe el repositorio y se destruye al salir de la pantalla.
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, this.initialRoute = 'splash'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      // Mientras se construyen las pantallas, las rutas que aún no existen
      // muestran "en construcción" en vez de cerrar la app con un error.
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: const ComingSoon(icon: Icons.construction, title: 'Próximamente'),
        ),
      ),
      routes: {
        'splash': (context) => ChangeNotifierProvider(
          create: (context) => SplashViewModel(_repo(context)),
          child: const SplashView(),
        ),
        'demo': (context) => ChangeNotifierProvider(
              create: (context) => DemoViewModel(_repo(context)),
              child: const DemoView(),
            ),
        'role': (context) => ChangeNotifierProvider(
          create: (context) => RoleViewModel(),
          child: const RoleView(),
        ),
        'login': (context) => ChangeNotifierProvider(
          create: (context) => LoginViewModel(_repo(context)),
          child: const LoginView(),
        ),
        'register': (context) => ChangeNotifierProvider(
          create: (context) => RegisterViewModel(_repo(context)),
          child: const RegisterView(),
        ),
        'verify_email': (context) => ChangeNotifierProvider(
          create: (context) => VerifyEmailViewModel(_repo(context)),
          child: const VerifyEmailView(),
        ),
        'forgot_password': (context) => ChangeNotifierProvider(
          create: (context) => ForgotPasswordViewModel(_repo(context)),
          child: const ForgotPasswordView(),
        ),
        'check_email': (context) => ChangeNotifierProvider(
          create: (context) => CheckEmailViewModel(_repo(context)),
          child: const CheckEmailView(),
        ),
        'teacher_home': (context) => ChangeNotifierProvider(
          create: (context) => MainViewModel(_repo(context)),
          child: const TeacherMainView(),
        ),
        // ---------- Docente ----------
        'new_course': (context) => ChangeNotifierProvider(
              create: (context) => NewCourseViewModel(_repo(context), _courses(context)),
              child: const NewCourseView(),
            ),
        'course_created': (context) {
          // El curso recién creado llega como argumento de la ruta. Se lee aquí,
          // antes del provider: dentro de "create" Flutter no permite usar ModalRoute.of.
          final course = ModalRoute.of(context)!.settings.arguments as Course;
          return ChangeNotifierProvider(
            create: (context) => CourseCreatedViewModel(course),
            child: const CourseCreatedView(),
          );
        },
        'course_detail': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) => CourseDetailViewModel(_courses(context), courseId),
            child: const CourseDetailView(),
          );
        },
        'import_list': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) => ImportListViewModel(_courses(context), courseId),
            child: const ImportListView(),
          );
        },
        'course_students': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) => CourseStudentsViewModel(_courses(context), courseId),
            child: const CourseStudentsView(),
          );
        },
        'pending_requests': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) => CourseStudentsViewModel(_courses(context), courseId),
            child: const PendingRequestsView(),
          );
        },
        'student_home': (context) => ChangeNotifierProvider(          create: (context) => MainViewModel(_repo(context)),
          child: const StudentMainView(),
        ),
      },
    );
  }

  /// Busca el repositorio de cuentas registrado en [AppState].
  AuthRepository _repo(BuildContext context) {
    return Provider.of<AuthRepository>(context, listen: false);
  }

  /// Busca el repositorio de cursos registrado en [AppState].
  CourseRepository _courses(BuildContext context) {
    return Provider.of<CourseRepository>(context, listen: false);
  }
}
