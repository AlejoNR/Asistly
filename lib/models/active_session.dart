import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Lee una asistencia de `sesiones/{id}/asistencias/{uid}`.
  factory SessionAttendance.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return SessionAttendance(
      uid: doc.id,
      name: data['nombre'] as String? ?? '',
      code: data['codigo'] as String? ?? '',
      markedAt: (data['hora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: data['metodo'] as String? ?? 'qr',
      reason: data['motivo'] as String?,
    );
  }

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

  factory FailReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return FailReport(uid: doc.id, reportedAt: (data['hora'] as Timestamp?)?.toDate() ?? DateTime.now());
  }
}
