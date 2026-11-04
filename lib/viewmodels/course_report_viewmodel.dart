import '../models/class_session.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel del Reporte del curso: todo se calcula aquí, en la app,
/// a partir de las clases cerradas y de los estudiantes inscritos (especificación 9).
class CourseReportViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final String courseId;

  CourseReportViewModel(this._repo, this.courseId) {
    load();
  }

  /// Meta de asistencia: por debajo de esto el estudiante está "en riesgo".
  static const goal = 75;

  bool isLoading = true;
  String? error;
  Course? course;
  List<ClassSession> sessions = []; // De la más antigua a la más reciente (C1, C2...)
  List<CourseStudent> students = []; // De menor a mayor asistencia
  bool ascending = true;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notify();
    List<ClassSession> allSessions;
    List<CourseStudent> allStudents;
    try {
      course = await _repo.getCourse(courseId);
      allSessions = await _repo.getCourseSessions(courseId);
      allStudents = await _repo.getCourseStudents(courseId);
    } catch (e) {
      error = errorMessage(e);
      isLoading = false;
      notify();
      return;
    }

    // El repositorio las da de la más reciente a la más antigua; la gráfica va al revés.
    sessions = allSessions.reversed.toList();

    // Solo cuentan los inscritos (no los pendientes, retirados ni "sin unirse").
    students = [];
    for (final student in allStudents) {
      if (student.status == EnrollmentStatus.enrolled) students.add(student);
    }
    _sortStudents();

    isLoading = false;
    notify();
  }

  void _sortStudents() {
    students.sort((a, b) {
      if (ascending) return a.attendancePercent.compareTo(b.attendancePercent);
      return b.attendancePercent.compareTo(a.attendancePercent);
    });
  }

  /// Botón "Ascendente / Descendente" de la lista de estudiantes.
  void toggleOrder() {
    ascending = !ascending;
    _sortStudents();
    notify();
  }

  /// Promedio de asistencia de todas las clases (0 a 100).
  int get averageAttendance {
    if (sessions.isEmpty) return 0;
    var sum = 0.0;
    for (final session in sessions) {
      sum += session.attendancePercent;
    }
    return (sum / sessions.length).round();
  }

  int get classesDone => sessions.length;

  int get atRiskCount {
    var count = 0;
    for (final student in students) {
      if (student.isAtRisk) count++;
    }
    return count;
  }

  int get regularCount => students.length - atRiskCount;

  /// Parte azul de la dona (0 a 1).
  double get regularFraction {
    if (students.isEmpty) return 0;
    return regularCount / students.length;
  }
}
