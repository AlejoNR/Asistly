import 'package:flutter/material.dart';

import '../models/user_role.dart';

/// ViewModel de "¿Cómo vas a usar Asistly?": guarda el rol elegido.
class RoleViewModel extends ChangeNotifier {
  UserRole selected = UserRole.teacher;

  void select(UserRole role) {
    selected = role;
    notifyListeners();
  }
}
