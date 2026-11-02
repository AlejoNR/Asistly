/// Un registro de asistencia de un estudiante en una clase.
///
/// En Firestore irá en `sesiones/{id}/asistencias/{uid}`.
class AttendanceRecord {
  final String sessionId;
  final String courseId;
  final String courseName;
  final DateTime date;
  final bool present; // Solo hay dos estados: presente o ausente
  final bool manual; // true si el docente la marcó a mano

  const AttendanceRecord({
    required this.sessionId,
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.present,
    this.manual = false,
  });
}
