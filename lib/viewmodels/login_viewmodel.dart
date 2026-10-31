import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_repository.dart';

/// ViewModel del inicio de sesión.
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  LoginViewModel(this._repo);

  bool isLoading = false;
  bool obscurePassword = true;
  String? error;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  /// Devuelve la ruta a la que hay que ir (el Home del rol o 'verify_email'),
  /// o null si falló (el mensaje queda en [error]).
  Future<String?> login(String email, String password, UserRole role) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      return await _repo.login(email, password, role);
    } on AuthException catch (e) {
      error = e.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
