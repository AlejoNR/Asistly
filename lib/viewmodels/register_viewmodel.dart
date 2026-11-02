import 'package:flutter/material.dart';

import '../services/auth_repository.dart';

/// ViewModel del registro de estudiantes.
class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  RegisterViewModel(this._repo);

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool acceptedTerms = false;
  String? error;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  void setAcceptedTerms(bool value) {
    acceptedTerms = value;
    if (value) error = null;
    notifyListeners();
  }

  /// Devuelve true si la cuenta se creó (si no, el mensaje queda en [error]).
  Future<bool> register({
    required String fullName,
    required String code,
    required String email,
    required String password,
  }) async {
    if (!acceptedTerms) {
      error = 'Debes aceptar los términos y el tratamiento de datos.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repo.registerStudent(
        fullName: fullName,
        code: code,
        email: email,
        password: password,
      );
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
