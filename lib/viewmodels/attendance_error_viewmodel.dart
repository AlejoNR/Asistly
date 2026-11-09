import '../models/active_session.dart';
import '../services/auth_repository.dart';
import '../services/session_repository.dart';
import 'base_viewmodel.dart';

/// Datos que recibe la pantalla de error.
class AttendanceErrorInfo {
  final OpenClass openClass;
  final String cause;
  final bool isSignalError; // true: falló el Bluetooth. false: falló el QR.

  const AttendanceErrorInfo({required this.openClass, required this.cause, this.isSignalError = false});
}

/// ViewModel de "No pudimos registrar tu asistencia" (mockup 30).
class AttendanceErrorViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final SessionRepository _sessionRepo;
  final AttendanceErrorInfo info;

  AttendanceErrorViewModel(this._authRepo, this._sessionRepo, this.info) {
    _load();
  }

  bool isSending = false;
  bool reported = false;
  String? error;

  Future<void> _load() async {
    try {
      reported = await _sessionRepo.hasReportedFailure(info.openClass.sessionId);
      notify();
    } catch (e) {
      // Si no se pudo revisar, el botón sigue disponible: las reglas evitan el doble reporte.
      errorMessage(e);
    }
  }

  /// "Informar al docente": una vez por clase y solo con la clase abierta.
  Future<void> report() async {
    final user = _authRepo.user;
    if (user == null || isSending || reported) return;
    isSending = true;
    error = null;
    notify();
    try {
      await _sessionRepo.reportFailure(info.openClass.sessionId, user);
      reported = true;
    } catch (e) {
      error = errorMessage(e);
    }
    isSending = false;
    notify();
  }
}
