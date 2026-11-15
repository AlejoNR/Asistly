import 'dart:async';

import '../models/active_session.dart';
import '../models/course_student.dart';
import '../models/student_course.dart';
import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import '../services/session_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// ViewModel del Home del estudiante (mockups 21 y 22): sus cursos y, en tiempo
/// real, las clases abiertas con la cuenta regresiva.
class StudentHomeViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final CourseRepository _courseRepo;
  final SessionRepository _sessionRepo;

  StudentHomeViewModel(this._authRepo, this._courseRepo, this._sessionRepo) {
    load();
    // Cada segundo avanza la cuenta regresiva, solo si hay una clase abierta.
    _clock = Timer.periodic(const Duration(seconds: 1), (timer) {
      now = DateTime.now();
      if (openClasses.isNotEmpty) notify();
    });
  }

  bool isLoading = true;
  String? error;
  List<StudentCourse> courses = [];
  List<OpenClass> openClasses = [];
  DateTime now = DateTime.now();

  /// false si entró desde otro celular: puede ver todo, pero no marcar asistencia.
  bool isLinkedDevice = true;

  Timer? _clock;
  StreamSubscription<List<OpenClass>>? _openClassesSub;

  Future<void> load() async {
    isLoading = courses.isEmpty; // Si ya hay cursos, se recarga sin borrar la pantalla
    error = null;
    notify();
    try {
      isLinkedDevice = await _authRepo.isLinkedDevice();
      courses = await _courseRepo.getStudentCourses();
      _listenOpenClasses();
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  /// Vuelve a escuchar, porque la lista de cursos pudo cambiar.
  void _listenOpenClasses() {
    _openClassesSub?.cancel();
    final enrolled = <StudentCourse>[];
    for (final item in courses) {
      if (item.status == EnrollmentStatus.enrolled) enrolled.add(item);
    }
    _openClassesSub = _sessionRepo.watchOpenClasses(enrolled.map((item) => item.course).toList()).listen(
      (list) {
        openClasses = list;
        notify();
      },
      onError: (Object e) {
        error = errorMessage(e);
        notify();
      },
    );
  }

  // ---------- Datos para la vista ----------

  String get greetingName => _authRepo.user?.firstName ?? '';

  String get initials {
    final parts = (_authRepo.user?.fullName ?? '').trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get todayLabel => DateFormatEs.long(now);

  /// "Semestre 2026-2", tomado de sus cursos. Vacío si aún no tiene cursos.
  String get semesterLabel {
    if (courses.isEmpty) return '';
    return 'Semestre ${courses.first.course.semester}';
  }

  /// La clase abierta que se muestra en la tarjeta amarilla: primero la que
  /// le falta marcar, para que otra clase ya marcada no la esconda.
  OpenClass? get openClass {
    if (openClasses.isEmpty) return null;
    for (final open in openClasses) {
      if (!open.alreadyMarked) return open;
    }
    return openClasses.first;
  }

  bool isLive(String courseId) {
    for (final open in openClasses) {
      if (open.course.id == courseId) return true;
    }
    return false;
  }

  Duration remaining(OpenClass open) {
    final left = open.endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool timeIsUp(OpenClass open) => remaining(open) == Duration.zero;

  /// "02:25"
  String remainingLabel(OpenClass open) {
    final left = remaining(open);
    final minutes = left.inMinutes.toString().padLeft(2, '0');
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// "Próxima clase: hoy 14:00 · Lab 3": la más cercana entre todos sus cursos.
  String get nextClassLabel {
    DateTime? best;
    StudentCourse? bestCourse;
    for (final item in courses) {
      if (item.status != EnrollmentStatus.enrolled) continue;
      final next = item.course.nextClassAfter(now);
      if (next != null && (best == null || next.isBefore(best))) {
        best = next;
        bestCourse = item;
      }
    }
    if (best == null || bestCourse == null) return '';
    final isToday = best.year == now.year && best.month == now.month && best.day == now.day;
    final day = isToday ? 'hoy' : DateFormatEs.shortDay(best.weekday);
    return 'Próxima clase: $day ${bestCourse.course.startOf(best.weekday)} · ${bestCourse.course.room}';
  }

  /// "(3 inscritas)": los pendientes todavía no cuentan.
  int get enrolledCount {
    var count = 0;
    for (final item in courses) {
      if (item.status == EnrollmentStatus.enrolled) count++;
    }
    return count;
  }

  @override
  void dispose() {
    _clock?.cancel();
    _openClassesSub?.cancel();
    super.dispose();
  }
}
