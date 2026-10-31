/// Un curso (materia + grupo) con su horario único.
///
/// En Firestore irá en `cursos/{id}`. Por ahora los datos vienen del
/// repositorio de prueba ([CourseRepository]).
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
