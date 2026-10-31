import '../models/attendance_record.dart';
import '../models/class_session.dart';
import '../models/course.dart';
import '../models/course_student.dart';

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

  final List<CourseStudent> _students = const [
    CourseStudent(uid: 's1', name: 'Sofía Morales', code: '2021-0492', email: 'sofia.morales@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 96, absences: 1),
    CourseStudent(uid: 's2', name: 'Carlos Mendoza', code: '2020-8114', email: 'carlos.mendoza@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 92, absences: 2),
    CourseStudent(uid: 's3', name: 'Andrea Rivas', code: '2021-1053', email: 'andrea.rivas@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 88, absences: 3),
    CourseStudent(uid: 's4', name: 'Daniel Ortega', code: '2019-3420', email: 'daniel.ortega@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 71, absences: 6),
    CourseStudent(uid: 's5', name: 'Valeria Gómez', code: '2022-0187', email: 'valeria.gomez@udla.edu.co', status: EnrollmentStatus.enrolled, attendancePercent: 64, absences: 8),
    CourseStudent(uid: 's6', name: 'Julián Castro', code: '2022-0311', email: 'julian.castro@udla.edu.co', status: EnrollmentStatus.pending),
    CourseStudent(uid: 's7', name: 'Mariana López', code: '2022-0455', email: 'mariana.lopez@udla.edu.co', status: EnrollmentStatus.pending),
    CourseStudent(uid: 's8', name: 'Felipe Rojas', code: '2021-0778', email: 'felipe.rojas@udla.edu.co', status: EnrollmentStatus.notJoined),
    CourseStudent(uid: 's9', name: 'Laura Peña', code: '2020-0921', email: 'laura.pena@udla.edu.co', status: EnrollmentStatus.withdrawn, attendancePercent: 50, absences: 5),
  ];

  // ---------- Docente ----------

  Future<List<Course>> getTeacherCourses() async {
    await _fakeDelay();
    return List.of(_courses);
  }

  Future<Course?> getCourse(String courseId) async {
    await _fakeDelay();
    for (final course in _courses) {
      if (course.id == courseId) return course;
    }
    return null;
  }

  Future<List<CourseStudent>> getCourseStudents(String courseId) async {
    await _fakeDelay();
    return List.of(_students);
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
