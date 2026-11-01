import '../models/class_session.dart';
import '../models/course.dart';
import '../services/course_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// ViewModel del Historial de clases: las clases cerradas agrupadas por mes,
/// de la más reciente a la más antigua (especificación 9).
class ClassHistoryViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final String courseId;

  ClassHistoryViewModel(this._repo, this.courseId) {
    load();
  }

  bool isLoading = true;
  Course? course;
  int totalSessions = 0;

  /// "Septiembre 2026" -> clases de ese mes. Un Map de Dart conserva el orden
  /// en que se agregan las claves, así que los meses quedan del más reciente al más antiguo.
  Map<String, List<ClassSession>> sessionsByMonth = {};

  Future<void> load() async {
    isLoading = true;
    notify();
    course = await _repo.getCourse(courseId);
    final sessions = await _repo.getCourseSessions(courseId); // Ya vienen de la más reciente a la más antigua
    totalSessions = sessions.length;

    sessionsByMonth = {};
    for (final session in sessions) {
      final month = DateFormatEs.monthYear(session.date);
      if (!sessionsByMonth.containsKey(month)) sessionsByMonth[month] = [];
      sessionsByMonth[month]!.add(session);
    }

    isLoading = false;
    notify();
  }

  /// Si hay una clase abierta, se muestra arriba como "En curso".
  bool get hasLiveSession => course?.hasActiveSession ?? false;
}
