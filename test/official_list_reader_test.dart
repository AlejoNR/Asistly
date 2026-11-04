import 'dart:convert';
import 'dart:typed_data';

import 'package:asistly/services/official_list_reader.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _csv(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  final reader = OfficialListReader();

  test('CSV con punto y coma: solo toma las 3 columnas y valida filas', () {
    const text =
        'PROGRAMA;CODIGOESTUDIANTE;FECHAMATRICULA;MAIL_INST;DOCUMENTO;NOMBRECOMPLETO;TELEFONO\n'
        'Sistemas;2024-0842;2024-01-10;Sofia.Morales@udla.edu.co;123;Sofía Morales;300\n'
        'Sistemas;;2024-01-10;juan@udla.edu.co;456;Juan Pérez;301\n'
        'Sistemas;2024-0999;2024-01-10;juan.perez_udla;789;Juan Pérez;302\n'
        'Sistemas;2024-0842;2024-01-10;otra@udla.edu.co;111;Repetido;303\n'
        ';;;;;;\n';
    final preview = reader.read('lista.csv', _csv(text));

    expect(preview.validRows.length, 1);
    expect(preview.validRows.first.code, '2024-0842');
    expect(preview.validRows.first.name, 'Sofía Morales');
    expect(preview.validRows.first.email, 'sofia.morales@udla.edu.co'); // En minúsculas
    expect(preview.errorRows.length, 3); // Sin código, correo inválido y código repetido
    expect(preview.errorRows[1].isEmailError, true);
  });

  test('CSV con coma y comillas', () {
    const text =
        'CODIGOESTUDIANTE,NOMBRECOMPLETO,MAIL_INST\n'
        '"2024-0001","Pérez, Ana","ana.perez@udla.edu.co"\n';
    final preview = reader.read('lista.csv', _csv(text));
    expect(preview.validRows.single.name, 'Pérez, Ana');
  });

  test('Excel: encuentra el encabezado aunque no esté en la primera fila y lee el código numérico como texto', () {
    final excel = Excel.createExcel();
    final sheet = excel['Matriculados'];
    sheet.appendRow([TextCellValue('Reporte de matriculados 2026-2')]);
    sheet.appendRow([
      TextCellValue('CODIGOESTUDIANTE'),
      TextCellValue('NOMBRECOMPLETO'),
      TextCellValue('MAIL_INST'),
      TextCellValue('EPS'),
    ]);
    sheet.appendRow([
      IntCellValue(2024084),
      TextCellValue('Carlos Mendoza'),
      TextCellValue('carlos.mendoza@udla.edu.co'),
      TextCellValue('Sanitas'),
    ]);
    final bytes = Uint8List.fromList(excel.encode()!);

    final preview = reader.read('lista.xlsx', bytes);
    expect(preview.sheetName, 'Matriculados');
    expect(preview.validRows.single.code, '2024084');
  });

  test('Sin las columnas obligatorias da un error claro', () {
    expect(
      () => reader.read('lista.csv', _csv('NOMBRE,CORREO\nAna,ana@udla.edu.co\n')),
      throwsA(isA<OfficialListException>()),
    );
  });
}
