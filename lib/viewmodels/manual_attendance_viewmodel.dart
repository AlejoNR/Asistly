import '../models/active_session.dart';
import '../models/course_student.dart';
import '../services/session_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Marcar manualmente": elegir estudiantes sin registro y un motivo.
class ManualAttendanceViewModel extends BaseViewModel {
  final SessionRepository _repo;
  final ActiveSession session;

  ManualAttendanceViewModel(this._repo, this.session) {
    load();
  }

  static const reasons = ['Falla de Bluetooth', 'Celular sin batería', 'Otro'];

  bool isLoading = true;
  bool isSaving = false;
  String? error;
  List<CourseStudent> pending = [];
  final Map<String, DateTime> _reportTimes = {}; // uid -> hora del reporte de falla
  final Set<String> selected = {};
  String query = '';
  String reason = reasons.first;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notify();
    try {
      pending = await _repo.getPendingStudents(session.id, session.course.id);
      final reports = await _repo.getFailReports(session.id);
      _reportTimes.clear();
      for (final report in reports) {
        _reportTimes[report.uid] = report.reportedAt;
      }
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  bool reported(CourseStudent student) => _reportTimes.containsKey(student.uid);

  /// "Reportó falla · 8:06 a. m."
  String reportLabel(CourseStudent student) {
    final time = _reportTimes[student.uid];
    if (time == null) return 'Sin señal';
    return 'Reportó falla · ${DateFormatEs.time(time)}';
  }

  List<CourseStudent> _filtered(bool wantReported) {
    final text = query.trim().toLowerCase();
    final result = <CourseStudent>[];
    for (final student in pending) {
      if (reported(student) != wantReported) continue;
      if (text.isEmpty || student.name.toLowerCase().contains(text) || student.code.contains(text)) {
        result.add(student);
      }
    }
    return result;
  }

  List<CourseStudent> get reportedStudents => _filtered(true);
  List<CourseStudent> get otherStudents => _filtered(false);

  void setQuery(String value) {
    query = value;
    notify();
  }

  void toggle(CourseStudent student) {
    if (selected.contains(student.uid)) {
      selected.remove(student.uid);
    } else {
      selected.add(student.uid);
    }
    notify();
  }

  bool get allSelected => pending.isNotEmpty && selected.length == pending.length;

  void toggleAll() {
    if (allSelected) {
      selected.clear();
    } else {
      for (final student in pending) {
        selected.add(student.uid);
      }
    }
    notify();
  }

  void setReason(String value) {
    reason = value;
    notify();
  }

  /// Guarda la asistencia manual de los seleccionados. Devuelve cuántos se marcaron.
  Future<int> save() async {
    final chosen = <CourseStudent>[];
    for (final student in pending) {
      if (selected.contains(student.uid)) chosen.add(student);
    }
    if (chosen.isEmpty) return 0;
    isSaving = true;
    error = null;
    notify();
    try {
      await _repo.markManual(session.id, chosen, reason);
    } catch (e) {
      error = errorMessage(e);
      isSaving = false;
      notify();
      return 0;
    }
    isSaving = false;
    notify();
    return chosen.length;
  }
}
