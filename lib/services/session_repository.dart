import 'dart:math';

import '../models/active_session.dart';
import '../models/class_session.dart';
import '../models/course_student.dart';
import 'course_repository.dart';

/// Repositorio de las sesiones de asistencia (parte del Modelo en MVVM).
///
/// POR AHORA ES DE PRUEBA: guarda todo en memoria y SIMULA que los
/// estudiantes van registrando su asistencia cada pocos segundos.
/// Cuando se conecte Firestore, la vista escuchará `sesiones/{id}/asistencias`
/// en tiempo real y nada de esta simulación hará falta.
class SessionRepository {
  final CourseRepository _courseRepo;
  SessionRepository(this._courseRepo);

  final Map<String, ActiveSession> _activeByCourse = {}; // courseId -> sesión abierta
  final Map<String, List<SessionAttendance>> _records = {}; // sessionId -> asistencias
  final Map<String, List<FailReport>> _reports = {}; // sessionId -> reportes de falla
  final Map<String, DateTime> _lastSimulated = {};

  Future<void> _fakeDelay() => Future.delayed(const Duration(milliseconds: 300));

  Future<List<CourseStudent>> _enrolled(String courseId) async {
    final all = await _courseRepo.getCourseStudents(courseId);
    final enrolled = <CourseStudent>[];
    for (final student in all) {
      if (student.status == EnrollmentStatus.enrolled) enrolled.add(student);
    }
    return enrolled;
  }

  String _newSecret() {
    final random = Random.secure();
    var secret = '';
    for (var i = 0; i < 32; i++) {
      secret += random.nextInt(16).toRadixString(16);
    }
    return secret;
  }

  /// Abre la sesión del curso, o devuelve la que ya está abierta.
  Future<ActiveSession> startOrResume(String courseId) async {
    await _fakeDelay();
    final existing = _activeByCourse[courseId];
    if (existing != null) return existing;

    final course = (await _courseRepo.getCourse(courseId))!;
    final past = await _courseRepo.getCourseSessions(courseId);
    final enrolled = await _enrolled(courseId);

    // El curso de ejemplo que ya está "en curso" arranca con 5 minutos y algunos registros.
    final alreadyLive = course.hasActiveSession;
    final now = DateTime.now();
    final session = ActiveSession(
      id: '$courseId-${past.length + 1}',
      course: course.copyWith(hasActiveSession: true),
      number: past.length + 1,
      startedAt: alreadyLive ? now.subtract(const Duration(minutes: 5)) : now,
      registrationMinutes: alreadyLive ? 11 : course.registrationMinutes,
      secret: _newSecret(),
    );
    _activeByCourse[courseId] = session;
    _records[session.id] = [];
    _reports[session.id] = [];

    if (alreadyLive) {
      const secondsAgo = [12, 38, 60, 120];
      for (var i = 0; i < 4 && i < enrolled.length; i++) {
        _records[session.id]!.add(SessionAttendance(
          uid: enrolled[i].uid,
          name: enrolled[i].name,
          code: enrolled[i].code,
          markedAt: now.subtract(Duration(seconds: secondsAgo[i])),
          method: 'ble_qr',
        ));
      }
      // Los dos últimos inscritos "reportaron falla".
      for (var i = enrolled.length - 2; i < enrolled.length && i >= 0; i++) {
        _reports[session.id]!.add(FailReport(
          uid: enrolled[i].uid,
          reportedAt: now.subtract(const Duration(minutes: 2)),
        ));
      }
    } else {
      await _courseRepo.updateCourse(course.copyWith(hasActiveSession: true));
    }
    _lastSimulated[session.id] = now;
    return session;
  }

  /// Asistencias de la sesión, de la más reciente a la más antigua.
  /// SIMULACIÓN: cada ~8 s se registra otro estudiante (dejando 2 sin registrar,
  /// para poder probar la asistencia manual).
  Future<List<SessionAttendance>> getAttendance(String sessionId) async {
    await _fakeDelay();
    final records = _records[sessionId] ?? [];
    ActiveSession? session;
    for (final s in _activeByCourse.values) {
      if (s.id == sessionId) session = s;
    }

    final last = _lastSimulated[sessionId];
    if (session != null && last != null && DateTime.now().difference(last).inSeconds >= 8) {
      final enrolled = await _enrolled(session.course.id);
      final reported = <String>{};
      for (final report in _reports[sessionId] ?? <FailReport>[]) {
        reported.add(report.uid);
      }
      final marked = <String>{};
      for (final record in records) {
        marked.add(record.uid);
      }
      for (final student in enrolled) {
        final waiting = enrolled.length - marked.length;
        if (waiting <= 2) break;
        if (!marked.contains(student.uid) && !reported.contains(student.uid)) {
          records.add(SessionAttendance(
            uid: student.uid,
            name: student.name,
            code: student.code,
            markedAt: DateTime.now(),
            method: session.course.validateBluetooth ? 'ble_qr' : 'qr',
          ));
          break;
        }
      }
      _lastSimulated[sessionId] = DateTime.now();
    }

    final sorted = List.of(records);
    sorted.sort((a, b) => b.markedAt.compareTo(a.markedAt));
    return sorted;
  }

  Future<List<FailReport>> getFailReports(String sessionId) async {
    return List.of(_reports[sessionId] ?? []);
  }

  /// Inscritos que todavía no tienen asistencia en la sesión.
  /// Los que reportaron falla van primero (especificación, sección 8).
  Future<List<CourseStudent>> getPendingStudents(String sessionId, String courseId) async {
    final enrolled = await _enrolled(courseId);
    final marked = <String>{};
    for (final record in _records[sessionId] ?? <SessionAttendance>[]) {
      marked.add(record.uid);
    }
    final reported = <String>{};
    for (final report in _reports[sessionId] ?? <FailReport>[]) {
      reported.add(report.uid);
    }
    final first = <CourseStudent>[];
    final rest = <CourseStudent>[];
    for (final student in enrolled) {
      if (marked.contains(student.uid)) continue;
      if (reported.contains(student.uid)) {
        first.add(student);
      } else {
        rest.add(student);
      }
    }
    return [...first, ...rest];
  }

  /// Asistencia manual: el docente marca a varios estudiantes con un motivo.
  Future<void> markManual(String sessionId, List<CourseStudent> students, String reason) async {
    await _fakeDelay();
    final records = _records[sessionId];
    if (records == null) return;
    for (final student in students) {
      records.add(SessionAttendance(
        uid: student.uid,
        name: student.name,
        code: student.code,
        markedAt: DateTime.now(),
        method: 'manual',
        reason: reason,
      ));
    }
  }

  /// Cierra la sesión: los inscritos sin registro quedan ausentes.
  Future<ClassSession> close(String courseId) async {
    await _fakeDelay();
    final session = _activeByCourse.remove(courseId)!;
    final records = _records[session.id] ?? [];
    final enrolled = await _enrolled(courseId);

    var manual = 0;
    for (final record in records) {
      if (record.isManual) manual++;
    }
    final closed = ClassSession(
      id: session.id,
      courseId: courseId,
      number: session.number,
      date: session.startedAt,
      presentCount: records.length,
      absentCount: enrolled.length - records.length,
      manualCount: manual,
    );

    await _courseRepo.addClosedSession(closed);
    final course = await _courseRepo.getCourse(courseId);
    if (course != null) await _courseRepo.updateCourse(course.copyWith(hasActiveSession: false));
    return closed;
  }

  /// Presentes y ausentes de una clase ya cerrada (para "Asistencia cerrada").
  /// Las clases de ejemplo antiguas no tienen registros: se inventan con los inscritos.
  Future<List<SessionAttendance>> getClosedAttendance(ClassSession session) async {
    await _fakeDelay();
    final saved = _records[session.id];
    if (saved != null) {
      final sorted = List.of(saved);
      sorted.sort((a, b) => a.markedAt.compareTo(b.markedAt));
      return sorted;
    }
    final enrolled = await _enrolled(session.courseId);
    final presentCount = (enrolled.length * session.attendancePercent / 100).round();
    final records = <SessionAttendance>[];
    for (var i = 0; i < presentCount && i < enrolled.length; i++) {
      records.add(SessionAttendance(
        uid: enrolled[i].uid,
        name: enrolled[i].name,
        code: enrolled[i].code,
        markedAt: session.date.add(Duration(minutes: 2 + i)),
        method: i < session.manualCount ? 'manual' : 'ble_qr',
      ));
    }
    return records;
  }

  Future<List<CourseStudent>> getClosedAbsents(ClassSession session) async {
    final present = await getClosedAttendance(session);
    final presentIds = <String>{};
    for (final record in present) {
      presentIds.add(record.uid);
    }
    final enrolled = await _enrolled(session.courseId);
    final absents = <CourseStudent>[];
    for (final student in enrolled) {
      if (!presentIds.contains(student.uid)) absents.add(student);
    }
    return absents;
  }
}
