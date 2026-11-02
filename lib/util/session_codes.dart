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
}
