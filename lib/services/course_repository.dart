import 'dart:math';

import '../models/attendance_record.dart';
import '../models/class_session.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../models/official_list.dart';

/// Repositorio de cursos, sesiones y asistencias (parte del Modelo en MVVM).
///
/// POR AHORA ES DE PRUEBA: devuelve datos inventados guardados en memoria,
/// para poder construir y probar todas las pantallas sin Firebase.
/// Cuando se conecte Firestore, solo cambia el interior de estos métodos;
/// los ViewModels y las Vistas siguen igual.
class CourseRepository {
  /// Simula el tiempo que tarda internet, para ver los estados de carga.
  Future<void> _fakeDelay() => Future.delayed(const Duration(milliseconds: 400));

  final List<Course> _courses = [
    const Course(
      id: 'pm2',
      name: 'Programación Móvil',
      group: 'Grupo 2',
      semester: '2026-2',
      days: [1, 3],
      startTime: '08:00',
      endTime: '10:00',
      room: 'Aula 101',
      enrollCode: 'PM2-4X7K',
      teacherName: 'Prof. Ramírez',
      enrolledCount: 32,
      pendingCount: 2,
      averageAttendance: 87,
      hasActiveSession: true,
    ),
    const Course(
      id: 'as1',
      name: 'Arquitectura de Software',
      group: 'Grupo 1',
      semester: '2026-2',
      days: [2, 4],
      startTime: '10:00',
      endTime: '12:00',
      room: 'Lab 204',
      enrollCode: 'AS1-9QW2',
      teacherName: 'Prof. Gómez',
      enrolledCount: 28,
      averageAttendance: 88,
      officialListCount: 30,
    ),
    const Course(
      id: 'bd3',
      name: 'Bases de Datos Avanzadas',
      group: 'Grupo 3',
      semester: '2026-2',
      days: [5],
      startTime: '14:00',
      endTime: '18:00',
      room: 'Aula 102',
      enrollCode: 'BD3-7MPL',
      teacherName: 'Prof. Morales',
      enrolledCount: 30,
      averageAttendance: 95,
      officialListCount: 30,
    ),
  ];

  // No es "const" porque la lista cambia: se aceptan, rechazan y retiran estudiantes.
  final List<CourseStudent> _students = [
    const CourseStudent(uid: 's1', name: 'Sofía Morales Delgado', code: '2024-0842', email: 'sofia.morales@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 96, absences: 1),
    const CourseStudent(uid: 's2', name: 'Carlos Mendoza Rivera', code: '2024-1103', email: 'carlos.mendoza@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 89, absences: 3),
    const CourseStudent(uid: 's3', name: 'Alejandro Romero Cruz', code: '2024-0519', email: 'alejandro.romero@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 68, absences: 8),
    const CourseStudent(uid: 's4', name: 'Mariana Vargas Ortiz', code: '2024-0988', email: 'mariana.vargas@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 94, absences: 2),
    const CourseStudent(uid: 's5', name: 'Diego Castro Peña', code: '2024-1340', email: 'diego.castro@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 91, absences: 2),
    const CourseStudent(uid: 's6', name: 'Lucía Orozco Torres', code: '2024-0231', email: 'lucia.orozco@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 62, absences: 9),
    const CourseStudent(uid: 's7', name: 'Gabriel Toledo Reyes', code: '2024-1774', email: 'gabriel.toledo@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 85, absences: 4),
    const CourseStudent(uid: 's8', name: 'Valeria Navarro Benítez', code: '2024-0412', email: 'valeria.navarro@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 98, absences: 0),
    const CourseStudent(uid: 's9', name: 'Julián Torres', code: '2023-0917', email: 'julian.torres@udla.edu.co', status: EnrollmentStatus.pending),
    const CourseStudent(uid: 's10', name: 'Camila Rojas', code: '2024-1203', email: 'camila.rojas@udla.edu.co', status: EnrollmentStatus.pending),
    const CourseStudent(uid: 's11', name: 'Felipe Rojas Mora', code: '2024-0778', email: 'felipe.rojas@udla.edu.co', status: EnrollmentStatus.notJoined),
    const CourseStudent(uid: 's12', name: 'Paula Gómez Ríos', code: '2024-0655', email: 'paula.gomez@udla.edu.co', status: EnrollmentStatus.notJoined),
    const CourseStudent(uid: 's13', name: 'Laura Peña Silva', code: '2023-0921', email: 'laura.pena@udla.edu.co', status: EnrollmentStatus.withdrawn, attendancePercent: 50, absences: 5),
  ];

  // ---------- Docente ----------

  Future<List<Course>> getTeacherCourses() async {
    await _fakeDelay();
    return List.of(_courses);
  }

  /// Crea un curso y le genera su código de inscripción.
  Future<Course> createCourse({
    required String name,
    required String group,
    required String semester,
    required List<int> days,
    required String startTime,
    required String endTime,
    required String room,
    required String teacherName,
  }) async {
    await _fakeDelay();
    final course = Course(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      group: group,
      semester: semester,
      days: days,
      startTime: startTime,
      endTime: endTime,
      room: room,
      enrollCode: _generateCode(name, group),
      teacherName: teacherName,
    );
    _courses.insert(0, course); // El nuevo aparece de primero en la lista.
    return course;
  }

  /// Código tipo "PM2-4X7K": iniciales del nombre + número del grupo + 4 caracteres al azar.
  /// Se evitan letras que se confunden al leerlas (O/0, I/1).
  String _generateCode(String name, String group) {
    final words = name.trim().split(' ');
    var prefix = '';
    for (final word in words) {
      if (word.length > 2 && prefix.length < 2) prefix += word[0].toUpperCase();
    }
    final groupNumber = group.replaceAll(RegExp(r'[^0-9]'), '');

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    var suffix = '';
    for (var i = 0; i < 4; i++) {
      suffix += chars[random.nextInt(chars.length)];
    }
    return '$prefix$groupNumber-$suffix';
  }

  Future<Course?> getCourse(String courseId) async {
    await _fakeDelay();
    for (final course in _courses) {
      if (course.id == courseId) return course;
    }
    return null;
  }

  /// Reemplaza un curso de la lista por su versión actualizada.
  Future<void> updateCourse(Course updated) async {
    for (var i = 0; i < _courses.length; i++) {
      if (_courses[i].id == updated.id) _courses[i] = updated;
    }
  }

  Future<List<CourseStudent>> getCourseStudents(String courseId) async {
    await _fakeDelay();
    return List.of(_students);
  }

  /// Cambia el estado de un estudiante (aceptar = inscrito, retirar = retirado).
  Future<void> setStudentStatus(String courseId, String uid, EnrollmentStatus status) async {
    await _fakeDelay();
    for (var i = 0; i < _students.length; i++) {
      if (_students[i].uid == uid) _students[i] = _students[i].copyWith(status: status);
    }
    await _refreshCounts(courseId);
  }

  /// Rechazar una solicitud: el estudiante sale de la lista del curso.
  Future<void> rejectRequest(String courseId, String uid) async {
    await _fakeDelay();
    _students.removeWhere((student) => student.uid == uid);
    await _refreshCounts(courseId);
  }

  /// Actualiza en el curso los contadores de inscritos y pendientes.
  Future<void> _refreshCounts(String courseId) async {
    var enrolled = 0;
    var pending = 0;
    for (final student in _students) {
      if (student.status == EnrollmentStatus.enrolled) enrolled++;
      if (student.status == EnrollmentStatus.pending) pending++;
    }
    final course = await getCourse(courseId);
    if (course != null) {
      await updateCourse(course.copyWith(enrolledCount: enrolled, pendingCount: pending));
    }
  }

  /// SIMULA leer el archivo de matriculados (todavía no se lee un Excel real).
  /// Devuelve 32 filas válidas y 2 con error, como en el mockup.
  Future<ImportPreview> readSampleOfficialList() async {
    await _fakeDelay();
    const firstNames = ['Aldo', 'Camila', 'David', 'Elena', 'Fabián', 'Gloria', 'Héctor', 'Isabel'];
    const lastNames = ['García', 'Morales', 'Rivas', 'Suárez'];
    final rows = <OfficialListEntry>[];
    for (var i = 0; i < 32; i++) {
      final first = firstNames[i % firstNames.length];
      final last = lastNames[i % lastNames.length];
      final code = '2024-${(842 + i * 37).toString().padLeft(4, '0')}';
      rows.add(OfficialListEntry(
        code: code,
        name: '$first $last',
        email: '${_withoutAccents(first)}.${_withoutAccents(last)}$i@udla.edu.co',
      ));
    }
    return ImportPreview(
      fileName: 'lista_programacion_movil.xlsx',
      fileSize: '34.2 KB',
      sheetName: 'Matriculados',
      validRows: rows,
      errorRows: const [
        ImportRowError(row: 14, message: 'Falta el código estudiantil en la columna A.'),
        ImportRowError(row: 27, message: 'Formato de correo inválido ("juan.perez_udla").', isEmailError: true),
      ],
    );
  }

  /// Los correos no llevan tildes ni mayúsculas: "García" -> "garcia".
  String _withoutAccents(String text) {
    const withAccent = 'áéíóúñ';
    const plain = 'aeioun';
    var result = text.toLowerCase();
    for (var i = 0; i < withAccent.length; i++) {
      result = result.replaceAll(withAccent[i], plain[i]);
    }
    return result;
  }

  /// Guarda la lista oficial: los que aún no están en el curso quedan "Sin unirse".
  /// Actualizar la lista agrega a los nuevos y no retira a nadie (especificación).
  Future<int> importOfficialList(String courseId, List<OfficialListEntry> entries) async {
    await _fakeDelay();
    var added = 0;
    for (final entry in entries) {
      var exists = false;
      for (final student in _students) {
        if (student.code == entry.code || student.email == entry.email) exists = true;
      }
      if (!exists) {
        _students.add(CourseStudent(
          uid: 'lista-${entry.code}',
          name: entry.name,
          code: entry.code,
          email: entry.email,
          status: EnrollmentStatus.notJoined,
        ));
        added++;
      }
    }
    final course = await getCourse(courseId);
    if (course != null) {
      await updateCourse(course.copyWith(
        officialListCount: entries.length,
        officialListImportedAt: DateTime.now(),
      ));
    }
    return added;
  }

  /// Clases ya dictadas, de la más reciente a la más antigua.
  Future<List<ClassSession>> getCourseSessions(String courseId) async {
    await _fakeDelay();
    final sessions = <ClassSession>[];
    // 14 clases de ejemplo, dos por semana hacia atrás desde el 21 de septiembre.
    var date = DateTime(2026, 9, 21);
    for (var number = 14; number >= 1; number--) {
      final present = 26 + (number * 7) % 6; // Números variados pero creíbles
      sessions.add(ClassSession(
        id: '$courseId-$number',
        courseId: courseId,
        number: number,
        date: date,
        presentCount: present,
        absentCount: 32 - present,
        manualCount: number % 4 == 0 ? 2 : 0,
      ));
      date = date.subtract(Duration(days: number.isEven ? 5 : 2));
    }
    return sessions;
  }

  // ---------- Estudiante ----------

  Future<List<Course>> getStudentCourses() async {
    await _fakeDelay();
    return List.of(_courses);
  }

  /// Curso con una clase abierta ahora mismo, o null si no hay ninguna.
  Future<Course?> getActiveCourseForStudent() async {
    await _fakeDelay();
    for (final course in _courses) {
      if (course.hasActiveSession) return course;
    }
    return null;
  }

  Future<List<AttendanceRecord>> getStudentHistory() async {
    await _fakeDelay();
    return [
      AttendanceRecord(sessionId: 'pm2-14', courseId: 'pm2', courseName: 'Programación Móvil', date: DateTime(2026, 9, 23, 8, 4), present: true),
      AttendanceRecord(sessionId: 'as1-10', courseId: 'as1', courseName: 'Arquitectura de Software', date: DateTime(2026, 9, 22, 10, 14), present: true),
      AttendanceRecord(sessionId: 'pm2-13', courseId: 'pm2', courseName: 'Programación Móvil', date: DateTime(2026, 9, 21, 8, 1), present: true),
      AttendanceRecord(sessionId: 'pm2-12', courseId: 'pm2', courseName: 'Programación Móvil', date: DateTime(2026, 8, 26, 8, 0), present: false),
    ];
  }
}
