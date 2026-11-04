import '../models/course.dart';
import '../models/course_student.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Estudiantes del curso" y de "Solicitudes pendientes".
class CourseStudentsViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final String courseId;

  CourseStudentsViewModel(this._repo, this.courseId) {
    load();
  }

  bool isLoading = true;
  String? error;
  Course? course;
  List<CourseStudent> _all = [];

  // Pestaña abierta: 0 Inscritos, 1 Sin unirse, 2 Pendientes, 3 Retirados.
  int currentTab = 0;
  String query = '';
  bool sortByAttendance = false; // false = orden alfabético

  Future<void> load() async {
    isLoading = true;
    error = null;
    notify();
    try {
      course = await _repo.getCourse(courseId);
      _all = await _repo.getCourseStudents(courseId);
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  List<CourseStudent> _withStatus(EnrollmentStatus status) {
    final result = <CourseStudent>[];
    for (final student in _all) {
      if (student.status == status) result.add(student);
    }
    return result;
  }

  List<CourseStudent> get enrolled => _withStatus(EnrollmentStatus.enrolled);
  List<CourseStudent> get notJoined => _withStatus(EnrollmentStatus.notJoined);
  List<CourseStudent> get pending => _withStatus(EnrollmentStatus.pending);
  List<CourseStudent> get withdrawn => _withStatus(EnrollmentStatus.withdrawn);

  /// Estudiantes de la pestaña abierta, filtrados por la búsqueda y ordenados.
  List<CourseStudent> get visibleStudents {
    List<CourseStudent> list;
    if (currentTab == 0) {
      list = enrolled;
    } else if (currentTab == 1) {
      list = notJoined;
    } else if (currentTab == 2) {
      list = pending;
    } else {
      list = withdrawn;
    }

    final text = query.trim().toLowerCase();
    final filtered = <CourseStudent>[];
    for (final student in list) {
      if (text.isEmpty || student.name.toLowerCase().contains(text) || student.code.contains(text)) {
        filtered.add(student);
      }
    }

    if (sortByAttendance) {
      filtered.sort((a, b) => a.attendancePercent.compareTo(b.attendancePercent));
    } else {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }
    return filtered;
  }

  /// Explicación corta de cada pestaña (como en el mockup).
  String get tabHint {
    if (currentTab == 0) return 'Inscritos: estudiantes que ya se unieron al curso.';
    if (currentTab == 1) return 'Sin unirse: están en la lista oficial pero aún no ingresan el código.';
    if (currentTab == 2) return 'Pendientes: se unieron con el código pero no están en la lista oficial.';
    return 'Retirados: ya no ven el curso; su historial de asistencia se conserva.';
  }

  void selectTab(int index) {
    currentTab = index;
    notify();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  void setSortByAttendance(bool value) {
    sortByAttendance = value;
    notify();
  }

  // ---------- Acciones ----------
  // Cada acción devuelve null si salió bien, o el mensaje de error para mostrarlo.

  Future<String?> accept(CourseStudent student) async {
    try {
      await _repo.setStudentStatus(courseId, student.uid, EnrollmentStatus.enrolled);
    } catch (e) {
      return errorMessage(e);
    }
    await load();
    return null;
  }

  Future<String?> reject(CourseStudent student) async {
    try {
      await _repo.rejectRequest(courseId, student.uid);
    } catch (e) {
      return errorMessage(e);
    }
    await load();
    return null;
  }

  Future<String?> acceptAll() async {
    try {
      for (final student in pending) {
        await _repo.setStudentStatus(courseId, student.uid, EnrollmentStatus.enrolled);
      }
    } catch (e) {
      await load();
      return errorMessage(e);
    }
    await load();
    return null;
  }

  /// Retirar: la inscripción pasa a "retirado"; nunca se borran sus asistencias.
  Future<String?> withdraw(CourseStudent student) async {
    try {
      await _repo.setStudentStatus(courseId, student.uid, EnrollmentStatus.withdrawn);
    } catch (e) {
      return errorMessage(e);
    }
    await load();
    return null;
  }
}
