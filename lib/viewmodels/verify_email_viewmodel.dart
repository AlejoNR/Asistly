import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_repository.dart';
import '../util/app_config.dart';
import '../util/validators.dart';

/// ViewModel de "Verifica tu correo".
///
/// Tiene dos temporizadores:
/// - uno revisa cada 4 s si el estudiante ya tocó el enlace del correo;
/// - otro cuenta los segundos que faltan para poder reenviar el correo.
class VerifyEmailViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  VerifyEmailViewModel(this._repo) {
    _startCooldown(); // El correo se acaba de enviar al registrarse.
    _checkTimer = Timer.periodic(const Duration(seconds: 4), (timer) => _autoCheck());
  }

  Timer? _checkTimer;
  Timer? _cooldownTimer;
  bool _disposed = false;

  int secondsLeft = 0;
  bool isChecking = false;

  /// Cuando pasa a true, la vista navega al Home.
  bool isVerified = false;

  bool get canResend => secondsLeft == 0;
  String get countdown => '00:${secondsLeft.toString().padLeft(2, '0')}';
  String get maskedEmail => maskEmail(_repo.currentEmail);

  /// Botón "Ya verifiqué mi correo". Devuelve un mensaje para mostrar, o null.
  Future<String?> checkNow() async {
    isChecking = true;
    _notify();
    try {
      isVerified = await _repo.checkEmailVerified();
      if (!isVerified) return 'Aún no detectamos la verificación. Revisa tu correo.';
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      isChecking = false;
      _notify();
    }
  }

  /// Botón "Reenviar correo". Devuelve el mensaje para mostrar.
  Future<String> resend() async {
    try {
      await _repo.resendVerificationEmail();
      _startCooldown();
      return 'Te enviamos un nuevo correo de verificación.';
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() => _repo.signOut();

  /// Revisión silenciosa en segundo plano.
  Future<void> _autoCheck() async {
    if (isChecking || isVerified) return;
    try {
      if (await _repo.checkEmailVerified()) {
        isVerified = true;
        _notify();
      }
    } on AuthException {
      // Se vuelve a intentar en la próxima vuelta.
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    secondsLeft = AppConfig.verificationResendCooldown;
    _notify();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        secondsLeft = 0;
        timer.cancel();
      }
      _notify();
    });
  }

  /// Avisa a la vista solo si la pantalla sigue abierta
  /// (una respuesta de Firebase puede llegar después de salir de ella).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
