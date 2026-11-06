import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import '../services/official_list_reader.dart';
import '../services/session_repository.dart';

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

  /// Convierte cualquier error en un mensaje en español para mostrar en pantalla.
  String errorMessage(Object error) {
    if (error is SessionException) return error.message;
    if (error is CourseException) return error.message;
    if (error is OfficialListException) return error.message;
    if (error is AuthException) return error.message;
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'No tienes permiso para hacer esto. Cierra sesión y vuelve a entrar con tu cuenta.';
      }
      if (error.code == 'unavailable') return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
    }
    debugPrint('Error no esperado: $error'); // Para verlo en la consola al probar
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
