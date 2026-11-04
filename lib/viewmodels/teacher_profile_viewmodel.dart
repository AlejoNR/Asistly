import '../models/app_user.dart';
import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel del Perfil del docente: sus datos, un resumen de sus cursos,
/// cambiar contraseña y cerrar sesión.
class TeacherProfileViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final CourseRepository _courseRepo;

  TeacherProfileViewModel(this._authRepo, this._courseRepo) {
    load();
  }

  int courseCount = 0;
  int studentCount = 0;
  bool isSendingReset = false;

  AppUser? get user => _authRepo.user;

  /// "Carlos Ramírez" -> "CR".
  String get initials {
    final parts = (user?.fullName ?? '').trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> load() async {
    // Si falla, el perfil se muestra igual con los contadores en 0.
    try {
      final courses = await _courseRepo.getTeacherCourses();
      courseCount = courses.length;
      studentCount = 0;
      for (final course in courses) {
        studentCount += course.enrolledCount;
      }
    } catch (e) {
      errorMessage(e);
    }
    notify();
  }

  /// Envía al correo del docente el enlace para cambiar la contraseña
  /// (el mismo correo de "¿Olvidaste tu contraseña?").
  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> sendPasswordChange() async {
    final email = user?.email;
    if (email == null) return 'No hay una sesión iniciada.';
    isSendingReset = true;
    notify();
    String? error;
    try {
      await _authRepo.sendPasswordReset(email);
    } on AuthException catch (e) {
      error = e.message;
    }
    isSendingReset = false;
    notify();
    return error;
  }

  Future<void> signOut() => _authRepo.signOut();
}
