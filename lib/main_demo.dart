import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'main.dart';

/// MODO DEMO (solo para desarrollo): igual que la app normal, pero arranca en
/// una pantalla que permite entrar como docente o estudiante SIN iniciar sesión.
///
/// Se corre con:  flutter run -t lib/main_demo.dart
/// o en VS Code eligiendo "Asistly (demo sin login)" en Ejecutar y depurar.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppState(initialRoute: 'demo'));
}
