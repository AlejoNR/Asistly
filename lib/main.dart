import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_repository.dart';
import 'services/bluetooth_service.dart';
import 'services/course_repository.dart';
import 'services/fake_course_repository.dart';
import 'services/fake_session_repository.dart';
import 'services/permission_service.dart';
import 'services/session_repository.dart';
import 'theme/app_theme.dart';
import 'models/active_session.dart';
import 'models/class_session.dart';
import 'models/course.dart';
import 'viewmodels/active_session_viewmodel.dart';
import 'viewmodels/attendance_done_viewmodel.dart';
import 'viewmodels/attendance_error_viewmodel.dart';
import 'viewmodels/check_email_viewmodel.dart';
import 'viewmodels/class_history_viewmodel.dart';
import 'viewmodels/closed_session_viewmodel.dart';
import 'viewmodels/course_created_viewmodel.dart';
import 'viewmodels/course_detail_viewmodel.dart';
import 'viewmodels/course_report_viewmodel.dart';
import 'viewmodels/course_students_viewmodel.dart';
import 'viewmodels/demo_viewmodel.dart';
import 'viewmodels/forgot_password_viewmodel.dart';
import 'viewmodels/import_list_viewmodel.dart';
import 'viewmodels/join_course_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/main_viewmodel.dart';
import 'viewmodels/manual_attendance_viewmodel.dart';
import 'viewmodels/new_course_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/role_viewmodel.dart';
import 'viewmodels/scan_qr_viewmodel.dart';
import 'viewmodels/signal_search_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'viewmodels/student_course_detail_viewmodel.dart';
import 'viewmodels/student_history_viewmodel.dart';
import 'viewmodels/student_main_viewmodel.dart';
import 'viewmodels/verify_email_viewmodel.dart';
import 'views/check_email_view.dart';
import 'views/demo_view.dart';
import 'views/forgot_password_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/role_view.dart';
import 'views/splash_view.dart';
import 'views/student/attendance_done_view.dart';
import 'views/student/attendance_error_view.dart';
import 'views/student/join_course_view.dart';
import 'views/student/scan_qr_view.dart';
import 'views/student/signal_search_view.dart';
import 'views/student/student_course_detail_view.dart';
import 'views/student/student_history_view.dart';
import 'views/student/student_main_view.dart';
import 'views/teacher/active_session_view.dart';
import 'views/teacher/class_history_view.dart';
import 'views/teacher/closed_session_view.dart';
import 'views/teacher/course_created_view.dart';
import 'views/teacher/course_detail_view.dart';
import 'views/teacher/course_report_view.dart';
import 'views/teacher/course_students_view.dart';
import 'views/teacher/import_list_view.dart';
import 'views/teacher/manual_attendance_view.dart';
import 'views/teacher/pending_requests_view.dart';
import 'views/teacher/new_course_view.dart';
import 'views/teacher/teacher_main_view.dart';
import 'views/verify_email_view.dart';
import 'views/widgets/coming_soon.dart';
import 'views/widgets/detail_app_bar.dart';

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

  /// true en el modo demo: usa los repositorios de prueba (datos inventados en memoria)
  /// en vez de Firestore.
  final bool demo;

  const AppState({super.key, this.initialRoute = 'splash', this.demo = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        // <CourseRepository>: las pantallas siempre piden un CourseRepository,
        // sin saber si es el real o el de prueba (los dos tienen los mismos métodos).
        Provider<CourseRepository>(
          create: (_) => demo ? FakeCourseRepository() : CourseRepository(),
        ),
        // El de sesiones usa el de cursos (para los estudiantes y el historial).
        Provider<SessionRepository>(
          create: (context) {
            final courses = Provider.of<CourseRepository>(context, listen: false);
            return demo ? FakeSessionRepository(courses) : SessionRepository(courses);
          },
        ),
        Provider<BluetoothService>(
          create: (_) => demo ? FakeBluetoothService() : BluetoothService(),
        ),
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
      // Quita el efecto de Android 12+ que "estira" la pantalla al llegar al borde del scroll.
      scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      theme: AppTheme.light,
      initialRoute: initialRoute,
      // Mientras se construyen las pantallas, las rutas que aún no existen
      // muestran "en construcción" en vez de cerrar la app con un error.
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: const ComingSoon(
            icon: Icons.construction,
            title: 'Próximamente',
          ),
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
          create: (context) =>
              NewCourseViewModel(_repo(context), _courses(context)),
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
            create: (context) =>
                CourseDetailViewModel(_courses(context), courseId),
            child: const CourseDetailView(),
          );
        },
        'course_report': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) =>
                CourseReportViewModel(_courses(context), courseId),
            child: const CourseReportView(),
          );
        },
        'class_history': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) =>
                ClassHistoryViewModel(_courses(context), courseId),
            child: const ClassHistoryView(),
          );
        },
        'import_list': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) =>
                ImportListViewModel(_courses(context), courseId),
            child: const ImportListView(),
          );
        },
        'course_students': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) =>
                CourseStudentsViewModel(_courses(context), courseId),
            child: const CourseStudentsView(),
          );
        },
        'pending_requests': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) =>
                CourseStudentsViewModel(_courses(context), courseId),
            child: const PendingRequestsView(),
          );
        },
        'active_session': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) => ActiveSessionViewModel(
              _sessions(context),
              _courses(context),
              courseId,
            ),
            child: const ActiveSessionView(),
          );
        },
        'manual_attendance': (context) {
          final session =
              ModalRoute.of(context)!.settings.arguments as ActiveSession;
          return ChangeNotifierProvider(
            create: (context) =>
                ManualAttendanceViewModel(_sessions(context), session),
            child: const ManualAttendanceView(),
          );
        },
        'closed_session': (context) {
          final session =
              ModalRoute.of(context)!.settings.arguments as ClassSession;
          return ChangeNotifierProvider(
            create: (context) => ClosedSessionViewModel(
              _sessions(context),
              _courses(context),
              session,
            ),
            child: const ClosedSessionView(),
          );
        },
        // ---------- Estudiante ----------
        'student_home': (context) => ChangeNotifierProvider(
          create: (context) => StudentMainViewModel(_repo(context), PermissionService()),
          child: const StudentMainView(),
        ),
        'join_course': (context) => ChangeNotifierProvider(
          create: (context) => JoinCourseViewModel(_repo(context), _courses(context)),
          child: const JoinCourseView(),
        ),
        'student_course_detail': (context) {
          final course = ModalRoute.of(context)!.settings.arguments as Course;
          return ChangeNotifierProvider(
            create: (context) => StudentCourseDetailViewModel(_courses(context), course),
            child: const StudentCourseDetailView(),
          );
        },
        'student_course_history': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String;
          return ChangeNotifierProvider(
            create: (context) => StudentHistoryViewModel(_courses(context), selectedCourseId: courseId),
            child: const Scaffold(
              appBar: DetailAppBar(title: 'Historial del curso'),
              body: StudentHistoryView(),
            ),
          );
        },
        'signal_search': (context) => ChangeNotifierProvider(
          create: (context) => SignalSearchViewModel(Provider.of<BluetoothService>(context, listen: false)),
          child: const SignalSearchView(),
        ),
        'scan_qr': (context) {
          final open = ModalRoute.of(context)!.settings.arguments as OpenClass;
          return ChangeNotifierProvider(
            create: (context) => ScanQrViewModel(_repo(context), _courses(context), _sessions(context), open),
            child: const ScanQrView(),
          );
        },
        'attendance_done': (context) {
          final open = ModalRoute.of(context)!.settings.arguments as OpenClass;
          return ChangeNotifierProvider(
            create: (context) => AttendanceDoneViewModel(_courses(context), open),
            child: const AttendanceDoneView(),
          );
        },
        'attendance_error': (context) {
          final info = ModalRoute.of(context)!.settings.arguments as AttendanceErrorInfo;
          return ChangeNotifierProvider(
            create: (context) => AttendanceErrorViewModel(_repo(context), _sessions(context), info),
            child: const AttendanceErrorView(),
          );
        },
      },
    );
  }

  /// Busca el repositorio de cuentas registrado en [AppState].
  AuthRepository _repo(BuildContext context) {
    return Provider.of<AuthRepository>(context, listen: false);
  }

  /// Busca el repositorio de sesiones registrado en [AppState].
  SessionRepository _sessions(BuildContext context) {
    return Provider.of<SessionRepository>(context, listen: false);
  }

  /// Busca el repositorio de cursos registrado en [AppState].
  CourseRepository _courses(BuildContext context) {
    return Provider.of<CourseRepository>(context, listen: false);
  }
}
