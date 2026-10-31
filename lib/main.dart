import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_repository.dart';
import 'theme/app_theme.dart';
import 'viewmodels/check_email_viewmodel.dart';
import 'viewmodels/forgot_password_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/role_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'viewmodels/verify_email_viewmodel.dart';
import 'views/check_email_view.dart';
import 'views/forgot_password_view.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/role_view.dart';
import 'views/splash_view.dart';
import 'views/verify_email_view.dart';

void main() async {
  // Firebase debe iniciarse antes de mostrar la app.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppState());
}

/// Registra lo que comparte toda la app: el repositorio de cuentas (Modelo).
class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
      ],
      child: const MyApp(),
    );
  }
}

/// Arquitectura MVVM: cada ruta crea su Vista junto con su ViewModel.
/// El ViewModel recibe el repositorio y se destruye al salir de la pantalla.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: 'splash',
      routes: {
        'splash': (context) => ChangeNotifierProvider(
              create: (context) => SplashViewModel(_repo(context)),
              child: const SplashView(),
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
        'home': (context) => ChangeNotifierProvider(
              create: (context) => HomeViewModel(_repo(context)),
              child: const HomeView(),
            ),
      },
    );
  }

  /// Busca el repositorio registrado en [AppState].
  AuthRepository _repo(BuildContext context) {
    return Provider.of<AuthRepository>(context, listen: false);
  }
}
