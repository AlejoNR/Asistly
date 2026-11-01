/// Un estudiante leído de la lista oficial de matriculados.
/// Solo se guardan estas 3 columnas (CODIGOESTUDIANTE, NOMBRECOMPLETO, MAIL_INST);
/// las demás columnas del archivo se ignoran (Ley 1581 de datos personales).
class OfficialListEntry {
  final String code;
  final String name;
  final String email;

  const OfficialListEntry({required this.code, required this.name, required this.email});

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// Una fila del archivo que no se pudo leer.
class ImportRowError {
  final int row;
  final String message;
  final bool isEmailError; // Para mostrar un ícono de correo en vez del genérico

  const ImportRowError({required this.row, required this.message, this.isEmailError = false});
}

/// Resultado de leer el archivo: filas válidas y filas con error.
class ImportPreview {
  final String fileName;
  final String fileSize;
  final String sheetName;
  final List<OfficialListEntry> validRows;
  final List<ImportRowError> errorRows;

  const ImportPreview({
    required this.fileName,
    required this.fileSize,
    required this.sheetName,
    required this.validRows,
    required this.errorRows,
  });
}
