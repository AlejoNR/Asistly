import 'course.dart';
import 'course_student.dart';

/// Un curso tal como lo ve el estudiante: el curso, su estado de inscripción
/// y cuántas clases lleva como presente y como ausente.
class StudentCourse {
  final Course course;
  final EnrollmentStatus status;
  final int presentCount;
  final int absentCount;

  const StudentCourse({
    required this.course,
    required this.status,
    this.presentCount = 0,
    this.absentCount = 0,
  });

  int get totalCount => presentCount + absentCount;

  /// Todavía no tiene clases: no se muestra un porcentaje.
  bool get hasClasses => totalCount > 0;

  /// De 0 a 100.
  int get percent {
    if (!hasClasses) return 0;
    return (presentCount * 100 / totalCount).round();
  }

  bool get isPending => status == EnrollmentStatus.pending;

  /// En riesgo si su asistencia es menor al 75 %.
  bool get isAtRisk => hasClasses && percent < 75;
}
