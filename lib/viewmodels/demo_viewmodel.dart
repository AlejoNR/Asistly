import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_repository.dart';

/// ViewModel del modo demo: entra como docente o estudiante sin iniciar sesión.
class DemoViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  DemoViewModel(this._repo);

  /// Pone un usuario de ejemplo y devuelve la ruta del Home de ese rol.
  String enterAs(UserRole role) {
    _repo.startDemo(role);
    return _repo.homeRoute;
  }
}
