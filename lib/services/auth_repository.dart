import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/email_service.dart';
import '../services/user_service.dart';

/// Error con un mensaje en español listo para mostrar en pantalla.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Parte del Modelo (MVVM): reúne las reglas de las cuentas y usa los services.
///
/// Iniciar sesión, registrarse, verificar el correo, recuperar la contraseña
/// y cerrar sesión. Los ViewModels llaman a estos métodos dentro de un
/// `try / catch`: si algo falla, se lanza un [AuthException] con el mensaje
/// para el usuario. Guarda el perfil de quien inició sesión en [user].
class AuthRepository {
  final _authService = AuthService();
  final _userService = UserService();
  final _deviceService = DeviceService();
  final _emailService = EmailService();

  /// Perfil de quien inició sesión (null si no hay sesión).
  AppUser? user;

  String get currentEmail => _authService.currentUser?.email ?? '';

  /// Cada rol tiene su propio Home: 'teacher_home' o 'student_home'.
  String get homeRoute {
    if (user?.role == UserRole.teacher) return 'teacher_home';
    return 'student_home';
  }

  /// Al abrir la app: decide a qué pantalla ir según la sesión guardada.
  /// Devuelve el nombre de la ruta: 'role', 'verify_email' o el Home del rol.
  Future<String> restoreSession() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return 'role';

    try {
      final profile = await _userService.getUser(firebaseUser.uid);
      if (profile == null || !await _isThisDevice(profile)) {
        await signOut();
        return 'role';
      }
      user = profile;

      final verified = await _authService.reloadAndCheckVerified();
      if (verified) return homeRoute;
      return 'verify_email';
    } catch (e) {
      // Sin internet u otro problema: se pide iniciar sesión otra vez.
      return 'role';
    }
  }

  /// Inicia sesión y revisa que el rol y el celular coincidan.
  /// Devuelve la ruta a la que hay que ir: el Home del rol o 'verify_email'.
  Future<String> login(String email, String password, UserRole role) async {
    try {
      final firebaseUser = await _authService.signIn(_clean(email), password);
      final profile = await _userService.getUser(firebaseUser.uid);

      if (profile == null) {
        await signOut();
        throw AuthException('No encontramos tu perfil. Regístrate nuevamente.');
      }
      if (profile.role != role) {
        await signOut();
        throw AuthException(
          'Esta cuenta está registrada como ${profile.role.label.toLowerCase()}. '
          'Vuelve y elige ese rol.',
        );
      }
      if (!await _isThisDevice(profile)) {
        await signOut();
        throw AuthException(
          'Tu cuenta está vinculada a otro dispositivo. '
          'Solicita el cambio al administrador.',
        );
      }

      user = profile;
      if (firebaseUser.emailVerified) return homeRoute;
      return 'verify_email';
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Crea la cuenta de un estudiante y vincula este celular.
  /// (Los docentes no se registran en la app: los crea el administrador.)
  Future<void> registerStudent({
    required String fullName,
    required String code,
    required String email,
    required String password,
  }) async {
    try {
      // Se pide el ID del celular antes de crear la cuenta,
      // para no dejar cuentas a medias si esto falla.
      final deviceId = await _deviceService.getDeviceId();
      final firebaseUser = await _authService.createAccount(_clean(email), password);

      final profile = AppUser(
        uid: firebaseUser.uid,
        fullName: fullName.trim(),
        code: code.trim(),
        email: _clean(email),
        role: UserRole.student,
        deviceId: deviceId,
      );

      try {
        await _userService.createUser(profile);
      } catch (e) {
        // Si el perfil no se pudo guardar, se borra la cuenta recién creada
        // para que pueda intentarlo otra vez con el mismo correo.
        await _authService.deleteCurrentUser();
        rethrow;
      }

      user = profile;

      try {
        await _emailService.sendVerification();
      } catch (e) {
        // No es grave: puede reenviarlo desde la pantalla "Verifica tu correo".
      }
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _emailService.sendVerification();
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      return await _authService.reloadAndCheckVerified();
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _emailService.sendPasswordReset(_clean(email));
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// SOLO PARA EL MODO DEMO (lib/main_demo.dart): entra con un usuario de
  /// ejemplo sin pasar por Firebase, para revisar las pantallas sin iniciar sesión.
  void startDemo(UserRole role) {
    if (role == UserRole.teacher) {
      user = const AppUser(
        uid: 'demo-docente',
        fullName: 'Carlos Ramírez',
        code: 'DOC-0142',
        email: 'carlos.ramirez@udla.edu.co',
        role: UserRole.teacher,
      );
    } else {
      user = const AppUser(
        uid: 'demo-estudiante',
        fullName: 'Aldo Encarnación',
        code: '2024-1156',
        email: 'ald.encarnacion@udla.edu.co',
        role: UserRole.student,
        deviceId: 'demo',
      );
    }
  }

  Future<void> signOut() async {
    user = null;
    await _authService.signOut();
  }

  // ---------- Ayudas privadas ----------

  String _clean(String email) => email.trim().toLowerCase();

  /// Los docentes no tienen celular vinculado; los estudiantes sí.
  Future<bool> _isThisDevice(AppUser profile) async {
    if (profile.role != UserRole.student) return true;
    final thisDevice = await _deviceService.getDeviceId();
    return profile.deviceId == thisDevice;
  }

  /// Convierte cualquier error técnico en un mensaje claro en español.
  AuthException _toAuthException(Object error) {
    if (error is AuthException) return error;

    if (error is DeviceAlreadyLinkedException) {
      return AuthException('Este celular ya está vinculado a otra cuenta de estudiante.');
    }

    if (error is FirebaseAuthException) {
      return AuthException(_authMessage(error.code));
    }

    if (error is FirebaseFunctionsException) {
      // Las Cloud Functions ya responden con mensajes en español.
      if (error.code == 'unavailable') {
        return AuthException('Sin conexión. Revisa tu internet e inténtalo de nuevo.');
      }
      return AuthException(error.message ?? 'No pudimos enviar el correo.');
    }

    if (error is FirebaseException && error.code == 'unavailable') {
      return AuthException('Sin conexión. Revisa tu internet e inténtalo de nuevo.');
    }

    return AuthException('Ocurrió un error inesperado. Inténtalo de nuevo.');
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada. Contacta al administrador.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No pudimos completar la operación ($code).';
    }
  }
}
