import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/attendance_record.dart';
import '../models/class_session.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../models/official_list.dart';
import 'official_list_reader.dart';

/// Repositorio de cursos (parte del Modelo en MVVM), conectado a Firestore.
///
/// Estructura en la base de datos (especificación, sección 10):
/// - `cursos/{cursoId}`: datos del curso y su configuración.
/// - `cursos/{cursoId}/listaOficial/{codigoEstudiante}`: nombre y correo de la lista importada.
/// - `cursos/{cursoId}/inscripciones/{uid}`: estado del estudiante (inscrito, pendiente, retirado).
/// - `sesiones/{sesionId}`: cada clase (ver [SessionRepository]).
///
/// El modo demo usa [FakeCourseRepository], que tiene estos mismos métodos.
class CourseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final OfficialListReader _listReader = OfficialListReader();

  CollectionReference<Map<String, dynamic>> get _courses => _db.collection('cursos');
  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sesiones');

  /// uid del docente que inició sesión.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ---------- Docente: cursos ----------

  Future<List<Course>> getTeacherCourses() async {
    final snapshot = await _courses.where('docenteId', isEqualTo: _uid).get();
    final courses = <Course>[];
    for (final doc in snapshot.docs) {
      courses.add(await _withSummary(Course.fromFirestore(doc)));
    }
    // Orden alfabético (se ordena aquí, en la app, para no tener que crear un índice en Firestore).
    courses.sort((a, b) => a.name.compareTo(b.name));
    return courses;
  }

  Future<Course?> getCourse(String courseId) async {
    final doc = await _courses.doc(courseId).get();
    if (!doc.exists) return null;
    return _withSummary(Course.fromFirestore(doc));
  }

  /// Completa el curso con lo que se calcula: inscritos, pendientes,
  /// asistencia promedio y si hay una clase abierta.
  Future<Course> _withSummary(Course course) async {
    final enrollments = await _courses.doc(course.id).collection('inscripciones').get();
    var enrolled = 0;
    var pending = 0;
    for (final doc in enrollments.docs) {
      final status = doc.data()['estado'];
      if (status == 'inscrito') enrolled++;
      if (status == 'pendiente') pending++;
    }

    final sessions = await _sessions.where('cursoId', isEqualTo: course.id).get();
    var hasOpen = false;
    var sum = 0.0;
    var closed = 0;
    for (final doc in sessions.docs) {
      final session = ClassSession.fromFirestore(doc);
      if (session.isOpen) {
        hasOpen = true;
      } else if (session.totalCount > 0) {
        sum += session.attendancePercent;
        closed++;
      }
    }

    return course.copyWith(
      enrolledCount: enrolled,
      pendingCount: pending,
      averageAttendance: closed == 0 ? 0 : sum / closed,
      hasActiveSession: hasOpen,
    );
  }

  /// Crea un curso y le genera su código de inscripción (que no se repita).
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
    var code = _generateCode(name, group);
    for (var i = 0; i < 5; i++) {
      final same = await _courses.where('codigoInscripcion', isEqualTo: code).limit(1).get();
      if (same.docs.isEmpty) break;
      code = _generateCode(name, group); // Muy raro: se intenta con otro.
    }

    final ref = await _courses.add({
      'nombre': name,
      'grupo': group,
      'semestre': semester,
      'dias': days,
      'horaInicio': startTime,
      'horaFin': endTime,
      'aula': room,
      'codigoInscripcion': code,
      'docenteId': _uid,
      'docenteNombre': teacherName,
      'tiempoRegistro': 10,
      'validarBluetooth': true,
      'listaCantidad': 0,
      'listaImportadaEn': null,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    final doc = await ref.get();
    return Course.fromFirestore(doc);
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
    final random = Random.secure();
    var suffix = '';
    for (var i = 0; i < 4; i++) {
      suffix += chars[random.nextInt(chars.length)];
    }
    return '$prefix$groupNumber-$suffix';
  }

  /// Guarda la configuración de la sesión (lo único que se edita desde el Detalle).
  Future<void> updateCourse(Course updated) async {
    await _courses.doc(updated.id).update({
      'tiempoRegistro': updated.registrationMinutes,
      'validarBluetooth': updated.validateBluetooth,
    });
  }

  // ---------- Docente: estudiantes ----------

  /// Inscritos, pendientes y retirados (de `inscripciones`) más los de la lista
  /// oficial que aún no se unen ("Sin unirse").
  Future<List<CourseStudent>> getCourseStudents(String courseId) async {
    final courseRef = _courses.doc(courseId);
    final enrollments = await courseRef.collection('inscripciones').get();
    final list = await courseRef.collection('listaOficial').get();
    final closed = await _closedSessions(courseId);

    final students = <CourseStudent>[];
    final joinedCodes = <String>{};
    final joinedEmails = <String>{};

    for (final doc in enrollments.docs) {
      final data = doc.data();
      final code = data['codigo'] as String? ?? '';
      final email = (data['correo'] as String? ?? '').toLowerCase();
      joinedCodes.add(code);
      joinedEmails.add(email);

      // Asistencia: en cuántas clases cerradas aparece su uid entre los presentes.
      var attended = 0;
      for (final session in closed) {
        final present = session.data()['presentesUids'] as List<dynamic>? ?? [];
        if (present.contains(doc.id)) attended++;
      }
      final total = closed.length;

      students.add(
        CourseStudent(
          uid: doc.id,
          name: data['nombre'] as String? ?? '',
          code: code,
          email: email,
          status: _statusFrom(data['estado'] as String?),
          // Sin clases todavía no hay ausencias: se muestra 100 %.
          attendancePercent: total == 0 ? 100 : attended * 100 / total,
          absences: total - attended,
        ),
      );
    }

    for (final doc in list.docs) {
      final data = doc.data();
      final email = (data['correo'] as String? ?? '').toLowerCase();
      if (joinedCodes.contains(doc.id) || joinedEmails.contains(email)) continue;
      students.add(
        CourseStudent(
          uid: 'lista-${doc.id}',
          name: data['nombre'] as String? ?? '',
          code: doc.id,
          email: email,
          status: EnrollmentStatus.notJoined,
        ),
      );
    }
    return students;
  }

  EnrollmentStatus _statusFrom(String? value) {
    if (value == 'inscrito') return EnrollmentStatus.enrolled;
    if (value == 'retirado') return EnrollmentStatus.withdrawn;
    return EnrollmentStatus.pending;
  }

  /// Aceptar (pendiente → inscrito) o retirar (→ retirado). Las asistencias nunca se borran.
  Future<void> setStudentStatus(String courseId, String uid, EnrollmentStatus status) async {
    final ref = _courses.doc(courseId).collection('inscripciones').doc(uid);
    if (status == EnrollmentStatus.enrolled) {
      await ref.update({'estado': 'inscrito', 'origen': 'aprobado'});
    } else if (status == EnrollmentStatus.withdrawn) {
      await ref.update({'estado': 'retirado', 'retiradoPor': 'docente'});
    }
  }

  /// Rechazar una solicitud: se borra la inscripción pendiente.
  Future<void> rejectRequest(String courseId, String uid) async {
    await _courses.doc(courseId).collection('inscripciones').doc(uid).delete();
  }

  // ---------- Docente: lista oficial ----------

  /// Abre el selector de archivos y lee el Excel/CSV. null si se cancela.
  Future<ImportPreview?> readOfficialListFile() => _listReader.pickAndRead();

  /// Guarda la lista oficial. Actualizarla agrega a los nuevos y no retira a nadie
  /// (especificación). Devuelve cuántos estudiantes nuevos se agregaron.
  Future<int> importOfficialList(String courseId, List<OfficialListEntry> entries) async {
    final listRef = _courses.doc(courseId).collection('listaOficial');
    final existing = await listRef.get();
    final existingCodes = <String>{};
    for (final doc in existing.docs) {
      existingCodes.add(doc.id);
    }

    // Un "batch" junta varias escrituras y las envía de una vez (máximo 500 por batch).
    var added = 0;
    var batch = _db.batch();
    var inBatch = 0;
    for (final entry in entries) {
      if (!existingCodes.contains(entry.code)) added++;
      existingCodes.add(entry.code);
      // El código va como id del documento: así no se repite el mismo estudiante.
      batch.set(listRef.doc(entry.code), {'nombre': entry.name, 'correo': entry.email});
      inBatch++;
      if (inBatch == 450) {
        await batch.commit();
        batch = _db.batch();
        inBatch = 0;
      }
    }
    batch.update(_courses.doc(courseId), {
      'listaCantidad': existingCodes.length,
      'listaImportadaEn': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return added;
  }

  // ---------- Docente: clases dictadas ----------

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _closedSessions(String courseId) async {
    final snapshot = await _sessions.where('cursoId', isEqualTo: courseId).get();
    final closed = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in snapshot.docs) {
      if (doc.data()['abierta'] != true) closed.add(doc);
    }
    return closed;
  }

  /// Clases ya cerradas, de la más reciente a la más antigua.
  Future<List<ClassSession>> getCourseSessions(String courseId) async {
    final sessions = <ClassSession>[];
    for (final doc in await _closedSessions(courseId)) {
      sessions.add(ClassSession.fromFirestore(doc));
    }
    sessions.sort((a, b) => b.number.compareTo(a.number));
    return sessions;
  }

  /// En Firestore la clase cerrada ya quedó guardada en `sesiones` al cerrarla:
  /// no hay nada más que hacer. (El repositorio de prueba sí la necesita.)
  Future<void> addClosedSession(ClassSession session) async {}

  // ---------- Estudiante (Fase 2) ----------
  // Las pantallas del estudiante todavía no existen; estos métodos se
  // conectarán cuando se construyan.

  Future<List<Course>> getStudentCourses() async => [];

  Future<Course?> getActiveCourseForStudent() async => null;

  Future<List<AttendanceRecord>> getStudentHistory() async => [];
}
