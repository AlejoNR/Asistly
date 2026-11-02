import 'package:flutter/material.dart';

/// Base para los ViewModels que cargan datos con `await`.
///
/// Si el usuario sale de la pantalla antes de que llegue la respuesta,
/// el ViewModel ya fue destruido y llamar a notifyListeners() daría error.
/// [notify] revisa eso primero.
class BaseViewModel extends ChangeNotifier {
  bool _disposed = false;

  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
