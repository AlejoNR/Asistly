import '../models/class_session.dart';
import '../models/course.dart';
import '../services/course_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// ViewModel del Detalle del curso (docente).
class CourseDetailViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final String courseId;

  CourseDetailViewModel(this._repo, this.courseId) {
    load();
  }

  bool isLoading = true;
  String? error;
  Course? course;
  List<ClassSession> sessions = [];

  /// Las 3 clases más recientes para la sección "Clases anteriores".
  List<ClassSession> get recentSessions {
    if (sessions.length <= 3) return sessions;
    return sessions.sublist(0, 3);
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notify();
    try {
      course = await _repo.getCourse(courseId);
      sessions = await _repo.getCourseSessions(courseId);
      if (course == null) error = 'No se encontró el curso.';
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  // ---------- Configuración de la sesión ----------

  /// Botones − y + del "Tiempo para registrarse" (de 5 en 5, entre 5 y 60 min).
  void changeRegistrationMinutes(int delta) {
    final current = course;
    if (current == null) return;
    final minutes = current.registrationMinutes + delta;
    if (minutes < 5 || minutes > 60) return;
    course = current.copyWith(registrationMinutes: minutes);
    _save(current);
    notify();
  }

  void setValidateBluetooth(bool value) {
    final current = course;
    if (current == null) return;
    course = current.copyWith(validateBluetooth: value);
    _save(current);
    notify();
  }

  /// Guarda la configuración. Si falla, vuelve al valor anterior y avisa.
  String? saveError;

  Future<void> _save(Course previous) async {
    try {
      await _repo.updateCourse(course!);
      saveError = null;
    } catch (e) {
      course = previous;
      saveError = errorMessage(e);
      notify();
    }
  }

  // ---------- Botón "Iniciar clase" ----------

  /// Convierte "08:00" en un DateTime de ese día.
  DateTime _atTime(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Regla de la especificación: solo en un día de clase,
  /// desde 15 minutos antes de la hora de inicio hasta la hora de fin.
  bool get canStartClass {
    final c = course;
    if (c == null || c.hasActiveSession) return false;
    final now = DateTime.now();
    if (!c.days.contains(now.weekday)) return false;
    final opens = _atTime(now, c.startTime).subtract(const Duration(minutes: 15));
    final closes = _atTime(now, c.endTime);
    return now.isAfter(opens) && now.isBefore(closes);
  }

  /// "Próxima clase: hoy 14:00" o "Próxima clase: Lun 08:00".
  String get nextClassLabel {
    final c = course;
    if (c == null) return '';
    final now = DateTime.now();
    // Busca, desde hoy, el primer día de clase cuya clase no haya terminado.
    for (var i = 0; i < 8; i++) {
      final day = now.add(Duration(days: i));
      if (!c.days.contains(day.weekday)) continue;
      if (i == 0 && now.isAfter(_atTime(day, c.endTime))) continue;
      if (i == 0) return 'Próxima clase: hoy ${c.startTime}';
      final dayName = DateFormatEs.short(day).split(' ').first; // "Lun"
      return 'Próxima clase: $dayName ${c.startTime}';
    }
    return '';
  }

  /// Texto bajo el porcentaje de asistencia promedio.
  String get attendanceComment {
    final average = course?.averageAttendance ?? 0;
    if (average >= 85) return 'Ritmo sobresaliente en el periodo';
    if (average >= 75) return 'Asistencia dentro de lo esperado';
    return 'Asistencia por debajo de la meta del 75 %';
  }
}
