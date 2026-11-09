import '../models/attendance_record.dart';
import '../services/course_repository.dart';
import '../util/date_format.dart';
import 'base_viewmodel.dart';

/// Registros de un mes, para los títulos "SEPTIEMBRE 2026".
class HistoryMonth {
  final String title;
  final List<AttendanceRecord> records;
  HistoryMonth(this.title, this.records);
}

/// ViewModel del Historial del estudiante (mockup 31), con filtro por curso.
class StudentHistoryViewModel extends BaseViewModel {
  final CourseRepository _repo;

  /// Curso seleccionado; null = "Todos los cursos".
  String? selectedCourseId;

  StudentHistoryViewModel(this._repo, {this.selectedCourseId}) {
    load();
  }

  bool isLoading = true;
  String? error;
  List<AttendanceRecord> _records = [];

  Future<void> load() async {
    isLoading = _records.isEmpty;
    error = null;
    notify();
    try {
      _records = await _repo.getStudentHistory();
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  void selectCourse(String? courseId) {
    selectedCourseId = courseId;
    notify();
  }

  /// Cursos para los chips del filtro: id -> nombre, sin repetir.
  Map<String, String> get courseFilters {
    final filters = <String, String>{};
    for (final record in _records) {
      filters[record.courseId] = record.courseName;
    }
    return filters;
  }

  List<AttendanceRecord> get visibleRecords {
    if (selectedCourseId == null) return _records;
    final filtered = <AttendanceRecord>[];
    for (final record in _records) {
      if (record.courseId == selectedCourseId) filtered.add(record);
    }
    return filtered;
  }

  int get presentCount {
    var count = 0;
    for (final record in visibleRecords) {
      if (record.present) count++;
    }
    return count;
  }

  int get absentCount => visibleRecords.length - presentCount;

  int get percent {
    if (visibleRecords.isEmpty) return 0;
    return (presentCount * 100 / visibleRecords.length).round();
  }

  bool get isAtRisk => visibleRecords.isNotEmpty && percent < 75;

  /// Registros agrupados por mes (ya vienen del más reciente al más antiguo).
  List<HistoryMonth> get months {
    final result = <HistoryMonth>[];
    for (final record in visibleRecords) {
      final title = DateFormatEs.monthYear(record.date);
      if (result.isEmpty || result.last.title != title) {
        result.add(HistoryMonth(title, []));
      }
      result.last.records.add(record);
    }
    return result;
  }
}
