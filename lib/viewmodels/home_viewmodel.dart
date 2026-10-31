import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_repository.dart';

/// ViewModel del Home provisional: muestra el perfil y permite cerrar sesión.
/// Se reemplazará por los Home de docente y de estudiante.
class HomeViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  HomeViewModel(this._repo);

  AppUser? get user => _repo.user;

  Future<void> signOut() => _repo.signOut();
}
