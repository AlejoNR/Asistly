import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Códigos rotativos de la sesión (especificación, sección 4).
///
/// Cada 15 segundos cambia la "ventana" de tiempo y con ella el código.
/// El código se calcula con HMAC-SHA256 (paquete `crypto`) a partir del
/// secreto de la sesión: sin el secreto no se puede adivinar el siguiente.
/// El QR y el Bluetooth usan propósitos distintos ('qr' y 'ble'), así que
/// sus códigos nunca son iguales.
class SessionCodes {
  static const windowSeconds = 15;

  /// Número de ventana de 15 s desde 1970. Cambia cada 15 segundos.
  static int windowAt(DateTime time) {
    return time.millisecondsSinceEpoch ~/ 1000 ~/ windowSeconds;
  }

  /// Segundos que faltan para que cambie el código (de 15 a 1).
  static int secondsToNextWindow(DateTime time) {
    final seconds = time.millisecondsSinceEpoch ~/ 1000;
    return windowSeconds - (seconds % windowSeconds);
  }

  /// Código de 8 caracteres para una ventana y un propósito ('qr' o 'ble').
  static String code(String secret, String purpose, int window) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode('$purpose:$window'));
    return digest.toString().substring(0, 8).toUpperCase();
  }

  /// Texto que va dentro del QR: id de la sesión + código vigente.
  static String qrPayload(String sessionId, String secret, DateTime now) {
    final window = windowAt(now);
    return 'asistly:$sessionId:${code(secret, 'qr', window)}';
  }

  // ---------- Señal Bluetooth (anuncio BLE del celular del docente) ----------
  //
  // El anuncio lleva "datos del fabricante" (manufacturer data): un número de
  // fabricante y unos bytes. 0xFFFF es el número reservado para pruebas y
  // proyectos sin fabricante registrado. Los 8 bytes son:
  //   'A' 'S'           -> marca de Asistly, para ignorar otros aparatos
  //   2 bytes           -> etiqueta de la sesión (sale del id de la sesión)
  //   4 bytes           -> código Bluetooth vigente (el mismo de privado/tokens)
  // Son pocos bytes a propósito: un anuncio BLE solo admite 31.

  static const bleManufacturerId = 0xFFFF;
  static const _bleMark = [0x41, 0x53]; // 'A', 'S'

  /// Etiqueta de 2 bytes de la sesión: así el estudiante ignora la señal de otra clase.
  static List<int> bleSessionTag(String sessionId) {
    final digest = sha256.convert(utf8.encode(sessionId)).bytes;
    return [digest[0], digest[1]];
  }

  /// Bytes que emite el docente para la sesión y el código Bluetooth dados.
  static List<int> blePayload(String sessionId, String bleCode) {
    final bytes = <int>[..._bleMark, ...bleSessionTag(sessionId)];
    // El código son 8 caracteres hexadecimales = 4 bytes.
    for (var i = 0; i < 8; i += 2) {
      bytes.add(int.parse(bleCode.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  /// Si los bytes son la señal de esta sesión, devuelve el código ("A1B2C3D4").
  /// Si son de otra sesión o de otro aparato, devuelve null.
  static String? parseBlePayload(String sessionId, List<int> bytes) {
    if (bytes.length != 8) return null;
    final tag = bleSessionTag(sessionId);
    if (bytes[0] != _bleMark[0] || bytes[1] != _bleMark[1]) return null;
    if (bytes[2] != tag[0] || bytes[3] != tag[1]) return null;
    var code = '';
    for (var i = 4; i < 8; i++) {
      code += bytes[i].toRadixString(16).padLeft(2, '0');
    }
    return code.toUpperCase();
  }

  /// Parte un QR leído en [sesión, código]. Devuelve null si no es un QR de Asistly.
  static List<String>? parseQr(String text) {
    final parts = text.split(':');
    if (parts.length != 3 || parts[0] != 'asistly') return null;
    if (parts[1].isEmpty || parts[2].isEmpty) return null;
    return [parts[1], parts[2]];
  }
}
