/// Estado de un estudiante dentro de un curso.
/// - enrolled: inscrito.
/// - pending: pidió unirse y el docente debe aceptarlo o rechazarlo.
/// - withdrawn: retirado (no se borran sus asistencias).
/// - notJoined: está en la lista oficial pero aún no se ha unido.
enum EnrollmentStatus { enrolled, pending, withdrawn, notJoined }

/// Un estudiante tal como se ve en las listas de un curso.
class CourseStudent {
  final String uid;
  final String name;
  final String code;
  final String email;
  final EnrollmentStatus status;
  final double attendancePercent; // 0 a 100
  final int absences;

  const CourseStudent({
    required this.uid,
    required this.name,
    required this.code,
    required this.email,
    required this.status,
    this.attendancePercent = 0,
    this.absences = 0,
  });

  /// Iniciales para el avatar: "Sofía Morales" -> "SM".
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// En riesgo si su asistencia es menor al 75 %.
  bool get isAtRisk => attendancePercent < 75;
}
