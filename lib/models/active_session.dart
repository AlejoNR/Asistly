import 'course.dart';

/// Una clase abierta en este momento (sesión de asistencia en curso).
///
/// En Firestore irá en `sesiones/{id}` con `abierta: true`.
class ActiveSession {
  final String id;
  final Course course;
  final int number; // Número de clase
  final DateTime startedAt;
  final int registrationMinutes; // Tiempo para registrarse
  final String secret; // Secreto con el que se generan los códigos del QR y del BLE

  const ActiveSession({
    required this.id,
    required this.course,
    required this.number,
    required this.startedAt,
    required this.registrationMinutes,
    required this.secret,
  });

  /// Momento en que se cierra sola la asistencia.
  DateTime get endsAt => startedAt.add(Duration(minutes: registrationMinutes));
}

/// Una asistencia registrada en la sesión.
///
/// En Firestore irá en `sesiones/{id}/asistencias/{uid}`.
class SessionAttendance {
  final String uid;
  final String name;
  final String code;
  final DateTime markedAt;
  final String method; // 'ble_qr', 'qr' o 'manual'
  final String? reason; // Motivo, solo si fue manual

  const SessionAttendance({
    required this.uid,
    required this.name,
    required this.code,
    required this.markedAt,
    required this.method,
    this.reason,
  });

  bool get isManual => method == 'manual';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// Un estudiante que tocó "Informar al docente" porque no pudo registrarse.
///
/// En Firestore irá en `sesiones/{id}/reportesFalla/{uid}`.
class FailReport {
  final String uid;
  final DateTime reportedAt;

  const FailReport({required this.uid, required this.reportedAt});
}
