import '../models/attendance_record.dart';
import '../models/course.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel del Detalle del curso del estudiante (mockup 24).
class StudentCourseDetailViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final Course course;

  StudentCourseDetailViewModel(this._repo, this.course) {
    load();
  }

  bool isLoading = true;
  bool isLeaving = false;
  String? error;
  List<AttendanceRecord> records = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notify();
    try {
      records = await _repo.getStudentCourseRecords(course);
    } catch (e) {
      error = errorMessage(e);
    }
    isLoading = false;
    notify();
  }

  int get presentCount {
    var count = 0;
    for (final record in records) {
      if (record.present) count++;
    }
    return count;
  }

  int get absentCount => records.length - presentCount;

  int get percent {
    if (records.isEmpty) return 0;
    return (presentCount * 100 / records.length).round();
  }

  /// Las 3 clases más recientes.
  List<AttendanceRecord> get recentRecords {
    if (records.length <= 3) return records;
    return records.sublist(0, 3);
  }

  /// Salir del curso. Devuelve null si salió bien, o el mensaje de error.
  Future<String?> leave() async {
    isLeaving = true;
    notify();
    String? message;
    try {
      await _repo.leaveCourse(course.id);
    } catch (e) {
      message = errorMessage(e);
    }
    isLeaving = false;
    notify();
    return message;
  }
}
