import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/active_session.dart';
import '../models/class_session.dart';
import '../models/course_student.dart';
import '../services/course_repository.dart';
import '../services/session_repository.dart';
import '../util/session_codes.dart';
import 'base_viewmodel.dart';

/// ViewModel de la Sesión activa del docente: QR rotativo, cuenta regresiva
/// y lista de asistencias que se actualiza sola (en tiempo real con Firestore).
class ActiveSessionViewModel extends BaseViewModel {
  final SessionRepository _sessionRepo;
  final CourseRepository _courseRepo;
  final String courseId;

  ActiveSessionViewModel(this._sessionRepo, this._courseRepo, this.courseId) {
    _start();
  }

  ActiveSession? session;
  List<SessionAttendance> records = [];
  int failReportCount = 0;
  int enrolledCount = 0;
  DateTime now = DateTime.now();

  bool isClosing = false;

  /// Error al abrir la clase (por ejemplo, si ya se dictó hoy) o al cerrarla.
  String? error;

  /// Cuando la asistencia se cierra (a mano o sola), aquí queda el resumen
  /// y la vista navega a "Asistencia cerrada".
  ClassSession? closedSession;

  Timer? _clockTimer; // cada segundo

  // Suscripciones a los Streams de Firestore. Un StreamSubscription es "estar
  // escuchando": cada vez que cambian los datos se ejecuta la función. Hay que
  // cancelarlas al salir de la pantalla (ver dispose).
  StreamSubscription<List<SessionAttendance>>? _attendanceSub;
  StreamSubscription<List<FailReport>>? _reportsSub;
  List<FailReport> _reports = [];

  int _publishedWindow = -1; // Ventana de 15 s cuyos códigos ya se guardaron

  Future<void> _start() async {
    // Mantiene la pantalla encendida mientras la sesión está abierta.
    WakelockPlus.enable();

    try {
      session = await _sessionRepo.startOrResume(courseId);
      final students = await _courseRepo.getCourseStudents(courseId);
      enrolledCount = 0;
      for (final student in students) {
        if (student.status == EnrollmentStatus.enrolled) enrolledCount++;
      }
    } catch (e) {
      error = errorMessage(e);
      WakelockPlus.disable();
      notify();
      return;
    }

    final current = session!;
    _attendanceSub = _sessionRepo.watchAttendance(current.id).listen((list) {
      records = list;
      _countReports();
      notify();
    });
    _reportsSub = _sessionRepo.watchFailReports(current.id).listen((list) {
      _reports = list;
      _countReports();
      notify();
    });

    _tick();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
  }

  /// Solo cuentan los reportes de falla de quienes aún no tienen asistencia.
  void _countReports() {
    failReportCount = 0;
    for (final report in _reports) {
      var alreadyMarked = false;
      for (final record in records) {
        if (record.uid == report.uid) alreadyMarked = true;
      }
      if (!alreadyMarked) failReportCount++;
    }
  }

  void _tick() {
    now = DateTime.now();
    final current = session;
    if (current == null || closedSession != null) return;

    // Cada vez que empieza una ventana de 15 s se guardan los códigos nuevos,
    // para que las reglas de Firestore puedan validar al estudiante.
    final window = SessionCodes.windowAt(now);
    if (window != _publishedWindow) {
      _publishedWindow = window;
      _sessionRepo.publishTokens(current, now).catchError((e) {
        _publishedWindow = -1; // Se reintenta en el siguiente segundo
      });
    }

    // Cierre automático al acabar el tiempo de registro. Si falló (error != null),
    // no se reintenta solo cada segundo: el docente toca "Cerrar asistencia".
    if (remaining.inSeconds <= 0 && !isClosing && error == null) {
      closeSession();
    }
    notify();
  }

  // ---------- Datos para la vista ----------

  int get presentCount => records.length;

  int get presentPercent {
    if (enrolledCount == 0) return 0;
    return (presentCount * 100 / enrolledCount).round();
  }

  Duration get remaining {
    final current = session;
    if (current == null) return Duration.zero;
    final left = current.endsAt.difference(now);
    if (left.isNegative) return Duration.zero;
    return left;
  }

  /// "05:51"
  String get remainingLabel {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Texto del QR; cambia cada 15 segundos.
  String get qrData {
    final current = session;
    if (current == null) return '';
    return SessionCodes.qrPayload(current.id, current.secret, now);
  }

  int get secondsToNewCode => SessionCodes.secondsToNextWindow(now);

  /// Los 4 registros más recientes.
  List<SessionAttendance> get recentRecords {
    if (records.length <= 4) return records;
    return records.sublist(0, 4);
  }

  /// "Hace 12 s", "Hace 2 min".
  String timeAgo(DateTime time) {
    final seconds = now.difference(time).inSeconds;
    if (seconds < 60) return 'Hace ${seconds < 1 ? 1 : seconds} s';
    return 'Hace ${seconds ~/ 60} min';
  }

  // ---------- Acciones ----------

  Future<void> closeSession() async {
    if (isClosing || closedSession != null) return;
    isClosing = true;
    error = null;
    notify();
    try {
      closedSession = await _sessionRepo.close(courseId);
    } catch (e) {
      // No se pudo cerrar (por ejemplo, sin internet): la clase sigue abierta y se puede reintentar.
      error = errorMessage(e);
      isClosing = false;
      notify();
      return;
    }
    _clockTimer?.cancel();
    _attendanceSub?.cancel();
    _reportsSub?.cancel();
    WakelockPlus.disable();
    isClosing = false;
    notify();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _attendanceSub?.cancel();
    _reportsSub?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
