import 'package:cloud_firestore/cloud_firestore.dart';

/// Un curso (materia + grupo) con su horario semanal (puede cambiar según el día).
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
  final String startTime; // "08:00": horario de los días que no están en [startByDay]
  final String endTime; // "10:00"
  final Map<int, String> startByDay; // Hora de inicio por día, ej. {1: "08:00", 3: "14:00"}
  final Map<int, String> endByDay;
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
    this.startByDay = const {},
    this.endByDay = const {},
    required this.room,
    required this.enrollCode,
    required this.teacherName,
    this.enrolledCount = 0,
    this.pendingCount = 0,
    this.averageAttendance = 0,
    this.officialListCount = 0,
    this.officialListImportedAt,
    this.registrationMinutes = 10,
    this.validateBluetooth = false,
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
      startByDay: startByDay,
      endByDay: endByDay,
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
    // "horarios": {"1": {"inicio": "08:00", "fin": "10:00"}, ...}. Los cursos viejos no lo tienen.
    final startByDay = <int, String>{};
    final endByDay = <int, String>{};
    final schedules = data['horarios'] as Map<String, dynamic>? ?? {};
    schedules.forEach((day, value) {
      final times = value as Map<String, dynamic>;
      startByDay[int.parse(day)] = times['inicio'] as String;
      endByDay[int.parse(day)] = times['fin'] as String;
    });
    return Course(
      id: doc.id,
      name: data['nombre'] as String? ?? '',
      group: data['grupo'] as String? ?? '',
      semester: data['semestre'] as String? ?? '',
      days: days,
      startTime: data['horaInicio'] as String? ?? '00:00',
      endTime: data['horaFin'] as String? ?? '00:00',
      startByDay: startByDay,
      endByDay: endByDay,
      room: data['aula'] as String? ?? '',
      enrollCode: data['codigoInscripcion'] as String? ?? '',
      teacherName: data['docenteNombre'] as String? ?? '',
      officialListCount: (data['listaCantidad'] as num?)?.toInt() ?? 0,
      officialListImportedAt: (data['listaImportadaEn'] as Timestamp?)?.toDate(),
      registrationMinutes: (data['tiempoRegistro'] as num?)?.toInt() ?? 10,
      validateBluetooth: data['validarBluetooth'] as bool? ?? false,
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

  /// Hora de inicio y de fin de la clase de ese día (1 = lunes ... 7 = domingo).
  String startOf(int weekday) => startByDay[weekday] ?? startTime;
  String endOf(int weekday) => endByDay[weekday] ?? endTime;

  /// "08:00 – 10:00" para ese día.
  String timeLabelOn(int weekday) => '${startOf(weekday)} – ${endOf(weekday)}';

  /// "Lun y Mié · 08:00 – 10:00 · Aula 101" (como lo pide la especificación).
  /// Si los días tienen horas distintas: "Lun 08:00 – 10:00, Mié 14:00 – 16:00 · Aula 101".
  String get scheduleLabel {
    if (days.isEmpty) return room;
    final labels = days.map(timeLabelOn).toSet();
    if (labels.length == 1) return '$daysLabel · ${labels.first} · $room';
    final parts = days.map((day) => '${_dayNames[day - 1]} ${timeLabelOn(day)}');
    return '${parts.join(', ')} · $room';
  }

  /// "Programación Móvil – Grupo 2"
  String get fullName => '$name – $group';

  /// Próximo inicio de clase a partir de [now]. Una clase que ya empezó pero no
  /// ha terminado cuenta como la próxima. Devuelve null si el curso no tiene días.
  DateTime? nextClassAfter(DateTime now) {
    for (var i = 0; i < 8; i++) {
      final day = now.add(Duration(days: i));
      if (!days.contains(day.weekday)) continue;
      final start = _atTime(day, startOf(day.weekday));
      if (now.isBefore(_atTime(day, endOf(day.weekday)))) return start;
    }
    return null;
  }

  /// Convierte "08:00" en un DateTime de ese día.
  DateTime _atTime(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
