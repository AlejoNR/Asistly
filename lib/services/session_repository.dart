import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/active_session.dart';
import '../models/class_session.dart';
import '../models/course_student.dart';
import '../util/session_codes.dart';
import 'course_repository.dart';

/// Error de una sesión de clase, con el mensaje en español.
class SessionException implements Exception {
  final String message;
  SessionException(this.message);

  @override
  String toString() => message;
}

/// Repositorio de las clases (sesiones de asistencia), conectado a Firestore.
///
/// - `sesiones/{cursoId}_{fecha}`: la clase. Como el id lleva la fecha, solo puede
///   haber una clase por curso y por día (especificación, sección 5).
/// - `sesiones/{id}/privado/secreto`: el secreto con el que se generan los códigos.
/// - `sesiones/{id}/privado/tokens`: los códigos vigentes; las reglas los usan para
///   validar la asistencia del estudiante (nadie los lee desde la app).
/// - `sesiones/{id}/asistencias/{uid}`: una asistencia por estudiante.
/// - `sesiones/{id}/reportesFalla/{uid}`: "Informar al docente".
///
/// El modo demo usa [FakeSessionRepository], que tiene estos mismos métodos.
class SessionRepository {
  final CourseRepository _courseRepo;
  SessionRepository(this._courseRepo);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sesiones');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// "2026-11-03": fecha local de hoy, para el id de la sesión.
  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _newSecret() {
    // Random.secure usa el generador seguro del sistema (no se puede predecir).
    final random = Random.secure();
    var secret = '';
    for (var i = 0; i < 32; i++) {
      secret += random.nextInt(16).toRadixString(16);
    }
    return secret;
  }

  Future<List<CourseStudent>> _enrolled(String courseId) async {
    final all = await _courseRepo.getCourseStudents(courseId);
    final enrolled = <CourseStudent>[];
    for (final student in all) {
      if (student.status == EnrollmentStatus.enrolled) enrolled.add(student);
    }
    return enrolled;
  }

  /// La clase abierta del curso, o null si no hay.
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _openSession(String courseId) async {
    final snapshot = await _sessions
        .where('cursoId', isEqualTo: courseId)
        .where('abierta', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  /// Abre la clase del curso, o retoma la que ya está abierta
  /// (por ejemplo, si el docente cerró la app sin cerrar la asistencia).
  Future<ActiveSession> startOrResume(String courseId) async {
    final course = await _courseRepo.getCourse(courseId);
    if (course == null) throw SessionException('No se encontró el curso.');

    var sessionDoc = await _openSession(courseId);
    if (sessionDoc == null) {
      final ref = _sessions.doc('${courseId}_${_dateKey(DateTime.now())}');
      final existing = await ref.get();
      if (existing.exists) {
        throw SessionException('Ya se dictó una clase de este curso hoy. Solo se permite una por día.');
      }
      final past = await _courseRepo.getCourseSessions(courseId);

      // La sesión y su secreto se guardan juntos: o se guardan los dos o ninguno.
      final batch = _db.batch();
      batch.set(ref, {
        'cursoId': courseId,
        'docenteId': _uid,
        'fecha': _dateKey(DateTime.now()),
        'numeroClase': past.length + 1,
        'inicio': FieldValue.serverTimestamp(), // Hora del servidor, no la del celular
        'fin': null,
        'abierta': true,
        'tiempoRegistro': course.registrationMinutes,
        'validarBluetooth': course.validateBluetooth,
        'presentes': 0,
        'ausentes': 0,
        'manuales': 0,
      });
      batch.set(ref.collection('privado').doc('secreto'), {'secreto': _newSecret()});
      await batch.commit();
    }

    // Se vuelve a leer para tener la hora de inicio que puso el servidor.
    final opened = await _openSession(courseId);
    if (opened == null) throw SessionException('No se pudo abrir la clase. Intenta de nuevo.');
    final data = opened.data();
    final secretDoc = await opened.reference.collection('privado').doc('secreto').get();

    return ActiveSession(
      id: opened.id,
      course: course.copyWith(hasActiveSession: true),
      number: (data['numeroClase'] as num?)?.toInt() ?? 1,
      startedAt: (data['inicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registrationMinutes: (data['tiempoRegistro'] as num?)?.toInt() ?? course.registrationMinutes,
      secret: secretDoc.data()?['secreto'] as String? ?? '',
    );
  }

  /// Asistencias de la sesión en TIEMPO REAL, de la más reciente a la más antigua.
  /// `snapshots()` es un Stream: Firestore avisa cada vez que alguien registra
  /// su asistencia, sin tener que preguntar cada pocos segundos.
  Stream<List<SessionAttendance>> watchAttendance(String sessionId) {
    return _sessions.doc(sessionId).collection('asistencias').snapshots().map((snapshot) {
      final records = <SessionAttendance>[];
      for (final doc in snapshot.docs) {
        records.add(SessionAttendance.fromFirestore(doc));
      }
      records.sort((a, b) => b.markedAt.compareTo(a.markedAt));
      return records;
    });
  }

  /// Reportes de falla en tiempo real.
  Stream<List<FailReport>> watchFailReports(String sessionId) {
    return _sessions.doc(sessionId).collection('reportesFalla').snapshots().map((snapshot) {
      final reports = <FailReport>[];
      for (final doc in snapshot.docs) {
        reports.add(FailReport.fromFirestore(doc));
      }
      return reports;
    });
  }

  Future<List<FailReport>> getFailReports(String sessionId) async {
    final snapshot = await _sessions.doc(sessionId).collection('reportesFalla').get();
    final reports = <FailReport>[];
    for (final doc in snapshot.docs) {
      reports.add(FailReport.fromFirestore(doc));
    }
    return reports;
  }

  /// Guarda los códigos vigentes (actual y anterior) para que las reglas de Firestore
  /// puedan validar la asistencia del estudiante (especificación, sección 4).
  Future<void> publishTokens(ActiveSession session, DateTime now) async {
    final window = SessionCodes.windowAt(now);
    await _sessions.doc(session.id).collection('privado').doc('tokens').set({
      'ventana': window,
      'qrActual': SessionCodes.code(session.secret, 'qr', window),
      'qrAnterior': SessionCodes.code(session.secret, 'qr', window - 1),
      'bleActual': SessionCodes.code(session.secret, 'ble', window),
      'bleAnterior': SessionCodes.code(session.secret, 'ble', window - 1),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Inscritos que todavía no tienen asistencia en la sesión.
  /// Los que reportaron falla van primero (especificación, sección 8).
  Future<List<CourseStudent>> getPendingStudents(String sessionId, String courseId) async {
    final enrolled = await _enrolled(courseId);
    final marked = <String>{};
    final records = await _sessions.doc(sessionId).collection('asistencias').get();
    for (final doc in records.docs) {
      marked.add(doc.id);
    }
    final reported = <String>{};
    for (final report in await getFailReports(sessionId)) {
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

  /// Asistencia manual: queda guardado quién la marcó, cuándo y el motivo.
  Future<void> markManual(String sessionId, List<CourseStudent> students, String reason) async {
    final batch = _db.batch();
    for (final student in students) {
      batch.set(_sessions.doc(sessionId).collection('asistencias').doc(student.uid), {
        'estado': 'presente',
        'hora': FieldValue.serverTimestamp(),
        'metodo': 'manual',
        'motivo': reason,
        'marcadoPor': _uid,
        'nombre': student.name,
        'codigo': student.code,
      });
    }
    await batch.commit();
  }

  /// Cierra la clase: los inscritos sin registro quedan ausentes.
  /// Se guardan los totales y la lista de presentes para el historial y el reporte.
  Future<ClassSession> close(String courseId) async {
    final sessionDoc = await _openSession(courseId);
    if (sessionDoc == null) throw SessionException('La clase ya estaba cerrada.');

    final records = await sessionDoc.reference.collection('asistencias').get();
    final enrolled = await _enrolled(courseId);
    final enrolledIds = <String>{};
    for (final student in enrolled) {
      enrolledIds.add(student.uid);
    }

    final presentIds = <String>[];
    var manual = 0;
    for (final doc in records.docs) {
      if (!enrolledIds.contains(doc.id)) continue; // Solo cuentan los inscritos
      presentIds.add(doc.id);
      if (doc.data()['metodo'] == 'manual') manual++;
    }
    final absent = enrolled.length - presentIds.length;

    await sessionDoc.reference.update({
      'abierta': false,
      'fin': FieldValue.serverTimestamp(),
      'presentes': presentIds.length,
      'ausentes': absent,
      'manuales': manual,
      'presentesUids': presentIds,
    });

    final data = sessionDoc.data();
    return ClassSession(
      id: sessionDoc.id,
      courseId: courseId,
      number: (data['numeroClase'] as num?)?.toInt() ?? 0,
      date: (data['inicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      presentCount: presentIds.length,
      absentCount: absent,
      manualCount: manual,
    );
  }

  /// Presentes de una clase cerrada, en el orden en que se registraron.
  Future<List<SessionAttendance>> getClosedAttendance(ClassSession session) async {
    final snapshot = await _sessions.doc(session.id).collection('asistencias').get();
    final records = <SessionAttendance>[];
    for (final doc in snapshot.docs) {
      records.add(SessionAttendance.fromFirestore(doc));
    }
    records.sort((a, b) => a.markedAt.compareTo(b.markedAt));
    return records;
  }

  /// Ausentes de una clase cerrada: los inscritos que no registraron asistencia.
  Future<List<CourseStudent>> getClosedAbsents(ClassSession session) async {
    final present = <String>{};
    for (final record in await getClosedAttendance(session)) {
      present.add(record.uid);
    }
    final absents = <CourseStudent>[];
    for (final student in await _enrolled(session.courseId)) {
      if (!present.contains(student.uid)) absents.add(student);
    }
    return absents;
  }
}
