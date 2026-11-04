import 'package:cloud_firestore/cloud_firestore.dart';

/// Un curso (materia + grupo) con su horario único.
///
/// En Firestore está en `cursos/{id}` (nombres de campos en español, como la
/// especificación). Los contadores (inscritos, pendientes, promedio) no se
/// guardan: el repositorio los calcula al leer el curso.
class Course {
  final String id;
  final String name; // Ej. "Programación Móvil"
  final String group; // Ej. "Grupo 2"
  final String semester; // Ej. "2026-2"
  final List<int> days; // Días de clase: 1 = lunes ... 7 = domingo
  final String startTime; // "08:00"
  final String endTime; // "10:00"
  final String room; // "Aula 101"
  final String enrollCode; // Código para unirse, ej. "PM2-4X7K"
  final String teacherName;

  // Resumen para las pantallas (en Firestore se calcularán).
  final int enrolledCount;
  final int pendingCount;
  final double averageAttendance; // 0 a 100
  final int officialListCount; // 0 = no se ha importado la lista
  final DateTime? officialListImportedAt;

  // Configuración de la sesión.
  final int registrationMinutes;
  final bool validateBluetooth;

  /// Hay una sesión de asistencia abierta ahora mismo.
  final bool hasActiveSession;

  const Course({
    required this.id,
    required this.name,
    required this.group,
    required this.semester,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.enrollCode,
    required this.teacherName,
    this.enrolledCount = 0,
    this.pendingCount = 0,
    this.averageAttendance = 0,
    this.officialListCount = 0,
    this.officialListImportedAt,
    this.registrationMinutes = 10,
    this.validateBluetooth = true,
    this.hasActiveSession = false,
  });

  /// Devuelve una copia del curso cambiando solo los campos que se pasen.
  /// Ej.: course.copyWith(validateBluetooth: false)
  Course copyWith({
    int? enrolledCount,
    double? averageAttendance,
    int? pendingCount,
    int? officialListCount,
    DateTime? officialListImportedAt,
    int? registrationMinutes,
    bool? validateBluetooth,
    bool? hasActiveSession,
  }) {
    return Course(
      id: id,
      name: name,
      group: group,
      semester: semester,
      days: days,
      startTime: startTime,
      endTime: endTime,
      room: room,
      enrollCode: enrollCode,
      teacherName: teacherName,
      averageAttendance: averageAttendance ?? this.averageAttendance,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      pendingCount: pendingCount ?? this.pendingCount,
      officialListCount: officialListCount ?? this.officialListCount,
      officialListImportedAt: officialListImportedAt ?? this.officialListImportedAt,
      registrationMinutes: registrationMinutes ?? this.registrationMinutes,
      validateBluetooth: validateBluetooth ?? this.validateBluetooth,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
    );
  }

  /// Lee un curso de Firestore.
  factory Course.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final days = <int>[];
    for (final day in (data['dias'] as List<dynamic>? ?? [])) {
      days.add((day as num).toInt());
    }
    return Course(
      id: doc.id,
      name: data['nombre'] as String? ?? '',
      group: data['grupo'] as String? ?? '',
      semester: data['semestre'] as String? ?? '',
      days: days,
      startTime: data['horaInicio'] as String? ?? '00:00',
      endTime: data['horaFin'] as String? ?? '00:00',
      room: data['aula'] as String? ?? '',
      enrollCode: data['codigoInscripcion'] as String? ?? '',
      teacherName: data['docenteNombre'] as String? ?? '',
      officialListCount: (data['listaCantidad'] as num?)?.toInt() ?? 0,
      officialListImportedAt: (data['listaImportadaEn'] as Timestamp?)?.toDate(),
      registrationMinutes: (data['tiempoRegistro'] as num?)?.toInt() ?? 10,
      validateBluetooth: data['validarBluetooth'] as bool? ?? true,
    );
  }

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// "Lun y Mié", "Lun, Mié y Vie" o "Vie".
  String get daysLabel {
    final names = <String>[];
    for (final day in days) {
      names.add(_dayNames[day - 1]);
    }
    if (names.length == 1) return names.first;
    final last = names.removeLast();
    return '${names.join(', ')} y $last';
  }

  /// "08:00 – 10:00"
  String get timeLabel => '$startTime – $endTime';

  /// "Lun y Mié · 08:00 – 10:00 · Aula 101" (como lo pide la especificación).
  String get scheduleLabel => '$daysLabel · $timeLabel · $room';

  /// "Programación Móvil – Grupo 2"
  String get fullName => '$name – $group';
}
