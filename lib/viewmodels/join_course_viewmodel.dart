import 'dart:async';

import '../models/course.dart';
import '../models/course_student.dart';
import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Unirme a un curso" (mockup 23): busca el curso mientras se
/// escribe el código y muestra la vista previa "Curso encontrado".
class JoinCourseViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final CourseRepository _courseRepo;

  JoinCourseViewModel(this._authRepo, this._courseRepo);

  /// Lo escrito, en mayúsculas y sin guion: "PM24X7K".
  String typed = '';
  Course? found;
  bool isSearching = false;
  bool isJoining = false;
  String? message; // "No encontramos..." o el error al unirse

  Timer? _debounce;

  /// Código con el guion en su sitio: los últimos 4 caracteres van después ("PM2-4X7K").
  String get formattedCode {
    if (typed.length < 5) return typed;
    final split = typed.length - 4;
    return '${typed.substring(0, split)}-${typed.substring(split)}';
  }

  void onTextChanged(String text) {
    typed = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    found = null;
    message = null;
    _debounce?.cancel();

    // Se espera a que deje de escribir para no consultar por cada letra.
    if (typed.length >= 5) {
      isSearching = true;
      _debounce = Timer(const Duration(milliseconds: 400), _search);
    } else {
      isSearching = false;
    }
    notify();
  }

  Future<void> _search() async {
    final code = formattedCode;
    try {
      final course = await _courseRepo.findCourseByCode(code);
      if (code != formattedCode) return; // Mientras tanto siguió escribiendo
      found = course;
      // Los códigos más cortos tienen 6 caracteres: antes de eso aún puede estar escribiendo.
      if (course == null && typed.length >= 6) {
        message = 'No encontramos un curso con ese código. Revísalo con tu docente.';
      }
    } catch (e) {
      if (code != formattedCode) return;
      message = errorMessage(e);
    }
    isSearching = false;
    notify();
  }

  /// Devuelve cómo quedó (inscrito o pendiente), o null si falló y hay que leer [message].
  Future<EnrollmentStatus?> join() async {
    final course = found;
    final user = _authRepo.user;
    if (course == null || user == null || isJoining) return null;
    isJoining = true;
    message = null;
    notify();
    EnrollmentStatus? status;
    try {
      status = await _courseRepo.joinCourse(course, user);
    } catch (e) {
      message = errorMessage(e);
    }
    isJoining = false;
    notify();
    return status;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
