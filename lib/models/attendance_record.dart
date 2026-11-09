/// Lo que le pasó a un estudiante en una clase: presente o ausente.
///
/// Se arma con `sesiones/{id}` (presentes y ausentes de la clase cerrada)
/// y `sesiones/{id}/asistencias/{uid}` (hora y método de su registro).
class AttendanceRecord {
  final String sessionId;
  final String courseId;
  final String courseName;
  final int number; // Número de clase
  final DateTime date; // Hora del registro; si faltó, la hora de la clase
  final bool present; // Solo hay dos estados: presente o ausente
  final bool manual; // true si el docente la marcó a mano

  const AttendanceRecord({
    required this.sessionId,
    required this.courseId,
    required this.courseName,
    required this.number,
    required this.date,
    required this.present,
    this.manual = false,
  });
}
