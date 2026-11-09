import 'package:cloud_firestore/cloud_firestore.dart';

/// Una clase (sesión de asistencia) de un curso.
///
/// En Firestore está en `sesiones/{id}`. El id es `{cursoId}_{fecha}`
/// (ej. `abc123_2026-11-03`): así no puede haber dos clases del mismo curso el mismo día.
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

  factory ClassSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ClassSession(
      id: doc.id,
      courseId: data['cursoId'] as String? ?? '',
      number: (data['numeroClase'] as num?)?.toInt() ?? 0,
      // Si la hora del servidor aún no llegó (recién creada), se usa la de ahora.
      date: (data['inicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOpen: data['abierta'] as bool? ?? false,
      presentCount: (data['presentes'] as num?)?.toInt() ?? 0,
      absentCount: (data['ausentes'] as num?)?.toInt() ?? 0,
      manualCount: (data['manuales'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalCount => presentCount + absentCount;

  /// Porcentaje de asistencia de esta clase (0 a 100).
  double get attendancePercent {
    if (totalCount == 0) return 0;
    return presentCount * 100 / totalCount;
  }
}
