import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/official_list.dart';
import '../util/validators.dart';

/// Error al leer el archivo de la lista oficial (con el mensaje en español).
class OfficialListException implements Exception {
  final String message;
  OfficialListException(this.message);

  @override
  String toString() => message;
}

/// Lee la lista oficial de matriculados desde un archivo .xlsx o .csv.
///
/// Solo toma tres columnas, buscándolas por su nombre en el encabezado:
/// CODIGOESTUDIANTE, NOMBRECOMPLETO y MAIL_INST. Las demás (documento,
/// teléfono, EPS...) se ignoran y nunca salen del celular (Ley 1581).
class OfficialListReader {
  static const maxBytes = 5 * 1024 * 1024; // 5 MB

  static const _codeColumn = 'CODIGOESTUDIANTE';
  static const _nameColumn = 'NOMBRECOMPLETO';
  static const _emailColumn = 'MAIL_INST';

  /// Abre el selector de archivos del celular. Devuelve null si la persona cancela.
  Future<ImportPreview?> pickAndRead() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'csv']);
    if (files.isEmpty) return null; // Canceló

    final file = files.first;
    final size = await file.length() ?? 0;
    if (size > maxBytes) {
      throw OfficialListException('El archivo pesa más de 5 MB.');
    }
    final bytes = await file.readAsBytes();
    return read(file.name, bytes);
  }

  /// Lee los bytes del archivo. Es aparte de [pickAndRead] para poder probarlo sin el celular.
  ImportPreview read(String fileName, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    List<List<String>> rows;
    String sheetName;

    if (lower.endsWith('.csv')) {
      rows = _readCsv(bytes);
      sheetName = 'CSV';
    } else if (lower.endsWith('.xlsx')) {
      final excel = _decodeExcel(bytes);
      // Se usa la primera hoja que tenga el encabezado esperado.
      sheetName = '';
      rows = [];
      for (final name in excel.tables.keys) {
        final sheetRows = _sheetToRows(excel.tables[name]!);
        if (_findHeader(sheetRows) != -1) {
          sheetName = name;
          rows = sheetRows;
          break;
        }
      }
      if (sheetName.isEmpty) throw OfficialListException(_missingColumnsMessage);
    } else {
      throw OfficialListException('Formato no soportado. Usa un archivo .xlsx o .csv.');
    }

    return _buildPreview(fileName, bytes.length, sheetName, rows);
  }

  static const _missingColumnsMessage = 'No se encontraron las columnas CODIGOESTUDIANTE, NOMBRECOMPLETO y MAIL_INST.';

  Excel _decodeExcel(Uint8List bytes) {
    try {
      return Excel.decodeBytes(bytes);
    } catch (e) {
      throw OfficialListException('No se pudo abrir el Excel. Revisa que no esté dañado.');
    }
  }

  /// Convierte una hoja de Excel en filas de texto.
  List<List<String>> _sheetToRows(Sheet sheet) {
    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      final values = <String>[];
      for (final cell in row) {
        values.add(_cellText(cell?.value));
      }
      rows.add(values);
    }
    return rows;
  }

  /// El código se lee siempre como texto. Si Excel lo guardó como número
  /// (2024084 o 2024084.0), se quita el ".0" para no cambiarlo.
  String _cellText(CellValue? value) {
    if (value == null) return '';
    if (value is DoubleCellValue && value.value == value.value.roundToDouble()) {
      return value.value.toInt().toString();
    }
    return value.toString().trim();
  }

  /// CSV sencillo. Acepta coma o punto y coma (Excel en español guarda con ';')
  /// y valores entre comillas.
  List<List<String>> _readCsv(Uint8List bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1); // Marca BOM de Excel
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) return [];
    final separator = lines.first.contains(';') ? ';' : ',';

    final rows = <List<String>>[];
    for (final line in lines) {
      final values = <String>[];
      var current = StringBuffer();
      var inQuotes = false;
      for (var i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          // Dos comillas seguidas dentro de comillas = una comilla literal.
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == separator && !inQuotes) {
          values.add(current.toString().trim());
          current = StringBuffer();
        } else {
          current.write(char);
        }
      }
      values.add(current.toString().trim());
      rows.add(values);
    }
    return rows;
  }

  /// Nombre de columna normalizado: mayúsculas y sin espacios.
  String _normalize(String text) => text.trim().toUpperCase().replaceAll(' ', '');

  /// Índice de la fila del encabezado (puede no ser la primera), o -1.
  int _findHeader(List<List<String>> rows) {
    for (var i = 0; i < rows.length && i < 20; i++) {
      final names = <String>[];
      for (final value in rows[i]) {
        names.add(_normalize(value));
      }
      if (names.contains(_codeColumn) && names.contains(_nameColumn) && names.contains(_emailColumn)) {
        return i;
      }
    }
    return -1;
  }

  ImportPreview _buildPreview(String fileName, int size, String sheetName, List<List<String>> rows) {
    final headerIndex = _findHeader(rows);
    if (headerIndex == -1) throw OfficialListException(_missingColumnsMessage);

    final header = <String>[];
    for (final value in rows[headerIndex]) {
      header.add(_normalize(value));
    }
    final codeAt = header.indexOf(_codeColumn);
    final nameAt = header.indexOf(_nameColumn);
    final emailAt = header.indexOf(_emailColumn);

    String valueAt(List<String> row, int index) => index < row.length ? row[index].trim() : '';

    final valid = <OfficialListEntry>[];
    final errors = <ImportRowError>[];
    final seenCodes = <String>{};

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      final code = valueAt(row, codeAt);
      final name = valueAt(row, nameAt);
      final email = valueAt(row, emailAt).toLowerCase();
      final rowNumber = i + 1; // Como lo ve el docente en Excel (empieza en 1)

      if (code.isEmpty && name.isEmpty && email.isEmpty) continue; // Fila vacía

      if (code.isEmpty) {
        errors.add(ImportRowError(row: rowNumber, message: 'Falta el código estudiantil.'));
      } else if (name.isEmpty) {
        errors.add(ImportRowError(row: rowNumber, message: 'Falta el nombre completo.'));
      } else if (Validators.institutionalEmail(email) != null) {
        errors.add(ImportRowError(row: rowNumber, message: 'Correo inválido ("$email").', isEmailError: true));
      } else if (seenCodes.contains(code)) {
        errors.add(ImportRowError(row: rowNumber, message: 'El código $code está repetido.'));
      } else {
        seenCodes.add(code);
        valid.add(OfficialListEntry(code: code, name: name, email: email));
      }
    }

    if (valid.isEmpty && errors.isEmpty) {
      throw OfficialListException('El archivo no tiene estudiantes debajo del encabezado.');
    }

    return ImportPreview(
      fileName: fileName,
      fileSize: _sizeLabel(size),
      sheetName: sheetName,
      validRows: valid,
      errorRows: errors,
    );
  }

  /// "34.2 KB"
  String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
