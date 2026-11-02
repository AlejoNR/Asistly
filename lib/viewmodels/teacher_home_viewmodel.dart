import '../models/course.dart';
import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// ViewModel del Home del docente: saludo y lista de cursos activos.
class TeacherHomeViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final CourseRepository _courseRepo;

  TeacherHomeViewModel(this._authRepo, this._courseRepo) {
    loadCourses();
  }

  bool isLoading = true;
  List<Course> courses = [];

  /// "Prof. Ramírez": usa el primer apellido (la segunda palabra del nombre).
  String get greetingName {
    final parts = (_authRepo.user?.fullName ?? '').trim().split(' ');
    if (parts.length >= 2) return 'Prof. ${parts[1]}';
    return 'Prof. ${parts.first}';
  }

  String get todayLabel => DateFormatEs.long(DateTime.now());

  Future<void> loadCourses() async {
    isLoading = true;
    notify();
    courses = await _courseRepo.getTeacherCourses();
    isLoading = false;
    notify();
  }
}
