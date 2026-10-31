/// Una clase (sesión de asistencia) de un curso.
///
/// En Firestore irá en `sesiones/{id}`.
class ClassSession {
  final String id;
  final String courseId;
  final int number; // Número de clase: 1, 2, 3...
  final DateTime date;
  final bool isOpen;
  final int presentCount;
  final int absentCount;
  final int manualCount; // Cuántas asistencias marcó el docente a mano

  const ClassSession({
    required this.id,
    required this.courseId,
    required this.number,
    required this.date,
    this.isOpen = false,
    this.presentCount = 0,
    this.absentCount = 0,
    this.manualCount = 0,
  });

  int get totalCount => presentCount + absentCount;

  /// Porcentaje de asistencia de esta clase (0 a 100).
  double get attendancePercent {
    if (totalCount == 0) return 0;
    return presentCount * 100 / totalCount;
  }
}
