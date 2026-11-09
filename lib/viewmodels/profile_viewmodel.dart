import '../models/app_user.dart';
import '../services/auth_repository.dart';
import 'base_viewmodel.dart';

/// Lo que comparten los perfiles del docente y del estudiante:
/// sus datos, cambiar la contraseña y cerrar sesión.
class ProfileViewModel extends BaseViewModel {
  final AuthRepository authRepo;

  ProfileViewModel(this.authRepo);

  bool isSendingReset = false;

  AppUser? get user => authRepo.user;

  /// "Carlos Ramírez" -> "CR".
  String get initials {
    final parts = (user?.fullName ?? '').trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Envía al correo el enlace para cambiar la contraseña
  /// (el mismo correo de "¿Olvidaste tu contraseña?").
  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> sendPasswordChange() async {
    final email = user?.email;
    if (email == null) return 'No hay una sesión iniciada.';
    isSendingReset = true;
    notify();
    String? error;
    try {
      await authRepo.sendPasswordReset(email);
    } on AuthException catch (e) {
      error = e.message;
    }
    isSendingReset = false;
    notify();
    return error;
  }

  Future<void> signOut() => authRepo.signOut();
}
