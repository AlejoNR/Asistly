import '../models/active_session.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de "¡Asistencia registrada!" (mockup 29).
class AttendanceDoneViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final OpenClass openClass;

  AttendanceDoneViewModel(this._repo, this.openClass) {
    _load();
  }

  final DateTime markedAt = DateTime.now();
  int present = 0;
  int total = 0;
  bool hasStats = false;

  int get percent => total == 0 ? 0 : (present * 100 / total).round();

  Future<void> _load() async {
    // Si esto falla no pasa nada: la asistencia ya quedó guardada; solo no se ve el porcentaje.
    try {
      final records = await _repo.getStudentCourseRecords(openClass.course);
      present = 0;
      for (final record in records) {
        if (record.present) present++;
      }
      total = records.length;
      hasStats = true;
    } catch (e) {
      errorMessage(e);
    }
    notify();
  }
}
