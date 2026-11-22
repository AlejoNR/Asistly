class AppConfig {
  static const universityName = 'Universidad de la Amazonia';

  /// Dominios de correo permitidos para registrarse e iniciar sesión.
  /// Vacío = se acepta cualquier dominio (útil mientras se prueba).
  /// Ejemplo: `['udla.edu.co']`.
  static const List<String> institutionalEmailDomains = ['udla.edu.co'];

  /// Segundos de espera antes de poder reenviar un correo.
  static const verificationResendCooldown = 45;
  static const passwordResetResendCooldown = 60;

  /// Señal Bluetooth del docente: intensidad mínima (RSSI, en dBm) para aceptarla.
  /// Más cerca de 0 = hay que estar más cerca del celular del docente.
  /// -80 es un valor de partida; hay que calibrarlo en el aula real.
  static const bleMinRssi = -80;

  /// Segundos que el estudiante busca la señal antes de mostrar el error.
  static const bleSearchSeconds = 20;
}
