import '../models/active_session.dart';
import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import '../services/session_repository.dart';
import '../util/session_codes.dart';
import 'base_viewmodel.dart';

/// Lo que pasó al leer un QR. La vista decide a qué pantalla ir.
enum ScanResult { ignored, success, failed }

/// ViewModel de "Escanear QR" (mockup 28).
class ScanQrViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final CourseRepository _courseRepo;
  final SessionRepository _sessionRepo;
  final OpenClass openClass;

  ScanQrViewModel(this._authRepo, this._courseRepo, this._sessionRepo, this.openClass);

  bool isSubmitting = false;
  String? hint; // Aviso sobre la cámara: "Ese código no es de Asistly"
  String failure = ''; // El motivo, cuando el resultado es failed

  bool get isDemo => _courseRepo.isDemo;

  /// Texto de un QR válido para el botón "Simular lectura" del modo demo.
  String get demoQrText => 'asistly:${openClass.sessionId}:DEMO';

  /// QR de otra clase, para ver la pantalla de error en el modo demo.
  String get demoWrongQrText => 'asistly:otra-clase:DEMO';

  Future<ScanResult> onQrRead(String text) async {
    if (isSubmitting) return ScanResult.ignored;

    // Un QR ajeno (un cartel, un menú...) no es un error: se sigue escaneando.
    if (SessionCodes.parseQr(text) == null) {
      hint = 'Ese código no es de Asistly. Apunta al QR de tu docente.';
      notify();
      return ScanResult.ignored;
    }

    final user = _authRepo.user;
    if (user == null) return ScanResult.ignored;

    isSubmitting = true;
    hint = null;
    notify();
    try {
      await _sessionRepo.markWithQr(openClass, text, user);
      return ScanResult.success;
    } catch (e) {
      failure = errorMessage(e);
      return ScanResult.failed;
    } finally {
      isSubmitting = false;
      notify();
    }
  }
}
