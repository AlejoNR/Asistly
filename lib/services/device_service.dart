import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Identifica este celular con un código único (UUID).
///
/// La primera vez se genera un UUID al azar y se guarda con
/// `flutter_secure_storage`, que lo cifra dentro del celular. Las siguientes
/// veces se lee el mismo valor. Así no hace falta código nativo (Kotlin/Swift).
///
/// Si el estudiante desinstala la app, el UUID se pierde y el administrador
/// debe desvincular su cuenta desde la consola de Firebase.
class DeviceService {
  static const _key = 'asistly_device_id';
  final _storage = const FlutterSecureStorage();

  // Se guarda en memoria para no leer el almacenamiento cada vez.
  String? _deviceId;

  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    String? saved = await _storage.read(key: _key);
    if (saved == null || saved.isEmpty) {
      saved = const Uuid().v4();
      await _storage.write(key: _key, value: saved);
    }
    _deviceId = saved;
    return saved;
  }
}
