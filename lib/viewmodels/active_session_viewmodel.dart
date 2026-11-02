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
/// y lista de asistencias que se actualiza sola.
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

  /// Cuando la asistencia se cierra (a mano o sola), aquí queda el resumen
  /// y la vista navega a "Asistencia cerrada".
  ClassSession? closedSession;

  Timer? _clockTimer; // cada segundo
  Timer? _refreshTimer; // cada 3 segundos

  Future<void> _start() async {
    // Mantiene la pantalla encendida mientras la sesión está abierta.
    WakelockPlus.enable();

    session = await _sessionRepo.startOrResume(courseId);
    final students = await _courseRepo.getCourseStudents(courseId);
    enrolledCount = 0;
    for (final student in students) {
      if (student.status == EnrollmentStatus.enrolled) enrolledCount++;
    }
    await refresh();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) => refresh());
  }

  /// Trae las asistencias y los reportes de falla más recientes.
  Future<void> refresh() async {
    final current = session;
    if (current == null || closedSession != null) return;
    records = await _sessionRepo.getAttendance(current.id);
    final reports = await _sessionRepo.getFailReports(current.id);
    // Solo cuentan los reportes de quienes aún no tienen asistencia.
    failReportCount = 0;
    for (final report in reports) {
      var alreadyMarked = false;
      for (final record in records) {
        if (record.uid == report.uid) alreadyMarked = true;
      }
      if (!alreadyMarked) failReportCount++;
    }
    notify();
  }

  void _tick() {
    now = DateTime.now();
    // Cierre automático al acabar el tiempo de registro.
    if (session != null && remaining.inSeconds <= 0 && !isClosing && closedSession == null) {
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
    notify();
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    closedSession = await _sessionRepo.close(courseId);
    WakelockPlus.disable();
    isClosing = false;
    notify();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
