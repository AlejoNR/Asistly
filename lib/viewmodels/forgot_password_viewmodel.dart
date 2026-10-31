import 'package:flutter/material.dart';

import '../services/auth_repository.dart';

/// ViewModel de "Recuperar contraseña".
class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  ForgotPasswordViewModel(this._repo);

  bool isLoading = false;
  String? error;

  /// Devuelve true si el enlace se envió (si no, el mensaje queda en [error]).
  Future<bool> sendReset(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repo.sendPasswordReset(email);
      return true;
    } on AuthException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
