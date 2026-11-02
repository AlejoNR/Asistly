import 'package:flutter/material.dart';

import '../services/auth_repository.dart';

/// ViewModel del splash: revisa si hay una sesión guardada.
class SplashViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  SplashViewModel(this._repo);

  /// Tiempo mínimo que se ve el splash, para que la animación alcance a verse.
  static const minDuration = Duration(milliseconds: 2200);

  /// Devuelve la ruta a la que hay que ir: 'role', 'verify_email' o el Home del rol.
  Future<String> start() async {
    // La espera y la revisión de la sesión corren al mismo tiempo.
    final minWait = Future.delayed(minDuration);
    final route = await _repo.restoreSession();
    await minWait;
    return route;
  }
}
