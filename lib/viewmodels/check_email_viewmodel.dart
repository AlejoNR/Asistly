import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_repository.dart';
import '../util/app_config.dart';

/// ViewModel de "Revisa tu correo": permite reenviar el enlace de recuperación
/// con una espera entre envíos.
class CheckEmailViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  CheckEmailViewModel(this._repo);

  Timer? _cooldownTimer;
  bool _disposed = false;

  int secondsLeft = 0;
  bool isLoading = false;
  bool justResent = false;
  String? error;

  bool get canResend => !isLoading && secondsLeft == 0;

  String get resendLabel {
    if (isLoading) return 'Enviando...';
    if (justResent) return 'Enlace reenviado';
    return 'Reenviar enlace';
  }

  Future<void> resend(String email) async {
    if (!canResend || email.isEmpty) return;

    isLoading = true;
    error = null;
    _notify();
    try {
      await _repo.sendPasswordReset(email);
      justResent = true;
      _startCooldown();
    } on AuthException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    secondsLeft = AppConfig.passwordResetResendCooldown;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        secondsLeft = 0;
        justResent = false;
        timer.cancel();
      }
      _notify();
    });
  }

  /// Avisa a la vista solo si la pantalla sigue abierta.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
