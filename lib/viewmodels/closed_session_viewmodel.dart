import '../models/active_session.dart';
import '../models/class_session.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../services/course_repository.dart';
import '../services/session_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Asistencia cerrada": resumen de una clase ya terminada.
class ClosedSessionViewModel extends BaseViewModel {
  final SessionRepository _sessionRepo;
  final CourseRepository _courseRepo;
  final ClassSession session;

  ClosedSessionViewModel(this._sessionRepo, this._courseRepo, this.session) {
    load();
  }

  bool isLoading = true;
  String? error;
  Course? course;
  List<SessionAttendance> present = [];
  List<CourseStudent> absent = [];
  int currentTab = 0; // 0 Presentes, 1 Ausentes

  Future<void> load() async {
    isLoading = true;
    error = null;
    notify();
    try {
      course = await _courseRepo.getCourse(session.courseId);
      present = await _sessionRepo.getClosedAttendance(session);
      absent = await _sessionRepo.getClosedAbsents(session);
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  int get total => present.length + absent.length;

  double get percent {
    if (total == 0) return 0;
    return present.length * 100 / total;
  }

  /// "87.5%" (un decimal solo si hace falta).
  String get percentLabel {
    final value = percent;
    if (value == value.roundToDouble()) return '${value.round()}%';
    return '${value.toStringAsFixed(1)}%';
  }

  /// "Hoy, 8:12 a. m." o "Lun 21 Sep, 8:00 a. m.".
  String get dateLabel {
    final now = DateTime.now();
    final date = session.date;
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final day = isToday ? 'Hoy' : DateFormatEs.short(date);
    return '$day, ${DateFormatEs.time(date)}';
  }

  void selectTab(int index) {
    currentTab = index;
    notify();
  }
}
