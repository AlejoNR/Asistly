import '../services/course_repository.dart';
import 'profile_viewmodel.dart';

/// ViewModel del Perfil del docente: lo común del perfil más un resumen de sus cursos.
class TeacherProfileViewModel extends ProfileViewModel {
  final CourseRepository _courseRepo;

  TeacherProfileViewModel(super.authRepo, this._courseRepo) {
    load();
  }

  int courseCount = 0;
  int studentCount = 0;

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
}
