import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/active_session.dart';
import '../models/app_user.dart';
import '../models/class_session.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../util/session_codes.dart';
import 'course_repository.dart';
import 'device_service.dart';

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
class SessionRepository {
  final CourseRepository _courseRepo;
  SessionRepository(this._courseRepo);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DeviceService _deviceService = DeviceService();

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
      // validateBluetooth sale de la sesión, no del curso: si el docente cambió el
      // interruptor con la clase ya abierta, manda lo que se guardó al abrirla.
      course: course.copyWith(
        hasActiveSession: true,
        validateBluetooth: data['validarBluetooth'] as bool? ?? false,
      ),
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
      // El estudiante capta la señal y después lee el QR, lo que puede tomarle
      // un rato: se aceptan los códigos Bluetooth del último minuto (4 ventanas).
      'bleRecientes': [
        for (var i = 0; i < 4; i++) SessionCodes.code(session.secret, 'ble', window - i),
      ],
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
    // Se guardan también los ausentes: así un estudiante que se une después
    // no aparece como ausente en las clases anteriores a su inscripción.
    final absentIds = <String>[];
    for (final uid in enrolledIds) {
      if (!presentIds.contains(uid)) absentIds.add(uid);
    }
    final absent = absentIds.length;

    await sessionDoc.reference.update({
      'abierta': false,
      'fin': FieldValue.serverTimestamp(),
      'presentes': presentIds.length,
      'ausentes': absent,
      'manuales': manual,
      'presentesUids': presentIds,
      'ausentesUids': absentIds,
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

  // ---------- Estudiante ----------

  /// Las clases abiertas de sus cursos, en TIEMPO REAL (especificación, sección 7).
  /// `asyncMap` permite hacer otra lectura por cada cambio: aquí, mirar si el
  /// estudiante ya tiene asistencia en cada clase abierta.
  Stream<List<OpenClass>> watchOpenClasses(List<Course> courses) {
    if (courses.isEmpty) return Stream.value(<OpenClass>[]);

    final byId = <String, Course>{};
    for (final course in courses) {
      byId[course.id] = course;
    }
    // Firestore permite buscar hasta 30 valores con whereIn.
    final ids = byId.keys.take(30).toList();

    return _sessions
        .where('cursoId', whereIn: ids)
        .where('abierta', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final classes = <OpenClass>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final course = byId[data['cursoId']];
            final startedAt = (data['inicio'] as Timestamp?)?.toDate();
            if (course == null || startedAt == null) continue;
            final own = await doc.reference.collection('asistencias').doc(_uid).get();
            classes.add(
              OpenClass(
                sessionId: doc.id,
                course: course,
                startedAt: startedAt,
                registrationMinutes: (data['tiempoRegistro'] as num?)?.toInt() ?? course.registrationMinutes,
                validateBluetooth: data['validarBluetooth'] as bool? ?? false,
                alreadyMarked: own.exists,
              ),
            );
          }
          return classes;
        });
  }

  /// Registra la asistencia con el texto del QR leído. Quien valida de verdad son las
  /// reglas de Firestore: comparan el código con los vigentes, que la app no puede leer.
  ///
  /// Si la clase valida por Bluetooth, [signal] es la señal del docente que se captó
  /// antes de leer el QR; las reglas comprueban que su código sea reciente.
  Future<void> markWithQr(OpenClass openClass, String qrText, AppUser user, {SignalCapture? signal}) async {
    final qr = SessionCodes.parseQr(qrText);
    if (qr == null) throw SessionException('Ese código no es un QR de asistencia de Asistly.');
    if (qr[0] != openClass.sessionId) {
      throw SessionException('Ese QR es de otra clase. Lee el que está mostrando tu docente.');
    }

    // Se puede iniciar sesión desde cualquier celular, pero marcar solo desde el vinculado.
    // Las reglas también lo exigen: esto es para explicar el motivo en vez de un rechazo general.
    final deviceId = await _deviceService.getDeviceId();
    if (deviceId != user.deviceId) {
      throw SessionException('Solo puedes marcar asistencia desde el celular vinculado a tu cuenta.');
    }

    if (openClass.validateBluetooth && signal == null) {
      throw SessionException('Primero debes captar la señal Bluetooth de la clase.');
    }

    final ref = _sessions.doc(openClass.sessionId).collection('asistencias').doc(_uid);
    final data = <String, dynamic>{
      'estado': 'presente',
      'hora': FieldValue.serverTimestamp(),
      'metodo': 'qr',
      'qr': qr[1],
      'deviceId': deviceId,
      'nombre': user.fullName,
      'codigo': user.code,
    };
    if (openClass.validateBluetooth && signal != null) {
      data['metodo'] = 'ble_qr';
      data['ble'] = signal.code;
      data['rssi'] = signal.rssi;
    }

    try {
      await _write(ref, data);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // Justo al cambiar la ventana de 15 s, el QR nuevo puede llegar antes que los
      // códigos que publica el docente: se espera un momento y se intenta otra vez.
      await Future.delayed(const Duration(seconds: 2));
      try {
        await _write(ref, data);
      } on FirebaseException catch (retryError) {
        if (retryError.code != 'permission-denied') rethrow;
        throw SessionException(await _rejectionReason(openClass, ref));
      }
    }
  }

  /// Escritura con límite de tiempo: sin internet, Firestore esperaría para siempre
  /// a que vuelva la conexión. La asistencia necesita la respuesta del servidor ahora.
  Future<void> _write(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
    try {
      await ref.set(data).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw SessionException('Sin conexión. Revisa tu internet e intenta de nuevo.');
    }
  }

  /// Las reglas solo responden "no": aquí se averigua el motivo para explicarlo.
  Future<String> _rejectionReason(OpenClass openClass, DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final own = await ref.get(const GetOptions(source: Source.server));
      if (own.exists) return 'Ya tienes tu asistencia registrada en esta clase.';
      final session = await _sessions.doc(openClass.sessionId).get(const GetOptions(source: Source.server));
      if (session.data()?['abierta'] != true) return 'El docente ya cerró esta clase.';
      if (DateTime.now().isAfter(openClass.endsAt)) return 'Se acabó el tiempo para registrarse.';
    } catch (e) {
      // Si esto también falla, se muestra el motivo general.
    }
    if (openClass.validateBluetooth) {
      return 'El código QR o la señal Bluetooth vencieron. Vuelve a buscar la señal y lee el QR otra vez.';
    }
    return 'El código QR venció o no es válido. Intenta de nuevo con el que está en pantalla.';
  }

  /// "Informar al docente": no marca asistencia, solo le avisa (una vez por clase).
  Future<void> reportFailure(String sessionId, AppUser user) async {
    final ref = _sessions.doc(sessionId).collection('reportesFalla').doc(_uid);
    await _write(ref, {
      'hora': FieldValue.serverTimestamp(),
      'nombre': user.fullName,
      'codigo': user.code,
    });
  }

  Future<bool> hasReportedFailure(String sessionId) async {
    final doc = await _sessions.doc(sessionId).collection('reportesFalla').doc(_uid).get();
    return doc.exists;
  }
}
