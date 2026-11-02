import '../models/course.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de la pestaña "Cursos" del docente: todos sus cursos, con búsqueda.
class TeacherCoursesViewModel extends BaseViewModel {
  final CourseRepository _repo;

  TeacherCoursesViewModel(this._repo) {
    loadCourses();
  }

  bool isLoading = true;
  List<Course> _courses = [];
  String query = '';

  Future<void> loadCourses() async {
    isLoading = true;
    notify();
    _courses = await _repo.getTeacherCourses();
    isLoading = false;
    notify();
  }

  int get totalCourses => _courses.length;

  /// Cursos que coinciden con lo escrito en el buscador (nombre, grupo o código).
  List<Course> get courses {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return _courses;
    final result = <Course>[];
    for (final course in _courses) {
      if (course.name.toLowerCase().contains(text) ||
          course.group.toLowerCase().contains(text) ||
          course.enrollCode.toLowerCase().contains(text)) {
        result.add(course);
      }
    }
    return result;
  }

  void setQuery(String value) {
    query = value;
    notify();
  }
}
