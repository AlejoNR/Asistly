import 'app_config.dart';

/// Validadores de formularios. Devuelven `null` si el valor es válido
/// o el mensaje de error a mostrar.
class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  static String? institutionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo institucional';
    if (!_emailRegex.hasMatch(email)) return 'Ingresa un correo válido';

    const domains = AppConfig.institutionalEmailDomains;
    if (domains.isNotEmpty) {
      final domain = email.split('@').last.toLowerCase();
      if (!domains.contains(domain)) {
        return 'Usa tu correo institucional (@${domains.first})';
      }
    }
    return null;
  }

  /// Registro: solo se escribe lo que va antes de "@udla.edu.co".
  static String? institutionalEmailUser(String? value) {
    final user = emailUser(value ?? '');
    if (user.isEmpty) return 'Ingresa tu correo institucional';
    if (!RegExp(r'^[A-Za-z0-9._%+-]+$').hasMatch(user)) {
      return 'Escribe solo lo que va antes de @${AppConfig.institutionalEmailDomains.first}';
    }
    return null;
  }

  /// Lo que va antes del @. Si pega el correo completo, se queda solo con esa parte.
  static String emailUser(String text) {
    final clean = text.trim();
    final at = clean.indexOf('@');
    return at < 0 ? clean : clean.substring(0, at);
  }

  /// Correo completo a partir de lo que escribió: "nombre" -> "nombre@udla.edu.co".
  static String fullInstitutionalEmail(String text) {
    return '${emailUser(text)}@${AppConfig.institutionalEmailDomains.first}'.toLowerCase();
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Crea una contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
      return 'Debe incluir letras y números';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Repite tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Ingresa tu nombre completo';
    if (name.split(RegExp(r'\s+')).length < 2) return 'Ingresa nombre y apellido';
    return null;
  }

  static String? institutionalCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) return 'Ingresa tu código';
    if (!RegExp(r'^[A-Za-z0-9-]{4,20}$').hasMatch(code)) {
      return 'Solo números, letras y guiones';
    }
    return null;
  }
}

/// Oculta parte del correo para mostrarlo en pantalla: usuario@udla.edu.co -> u***@udla.edu.co
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  return '${email[0]}***${email.substring(at)}';
}
