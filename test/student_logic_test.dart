import 'package:asistly/models/course.dart';
import 'package:asistly/models/course_student.dart';
import 'package:asistly/models/student_course.dart';
import 'package:asistly/util/session_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const course = Course(
    id: 'c1',
    name: 'Programación Móvil',
    group: 'Grupo 2',
    semester: '2026-2',
    days: [1, 3], // Lunes y miércoles
    startTime: '08:00',
    endTime: '10:00',
    room: 'Aula 101',
    enrollCode: 'PM2-4X7K',
    teacherName: 'Prof. Ramírez',
  );

  group('Leer el QR', () {
    test('Un QR generado por el docente se puede leer', () {
      final text = SessionCodes.qrPayload('c1_2026-11-05', 'secreto', DateTime(2026, 11, 5, 8));
      final qr = SessionCodes.parseQr(text);
      expect(qr, isNotNull);
      expect(qr![0], 'c1_2026-11-05');
      expect(qr[1].length, 8);
    });

    test('Un QR ajeno no se acepta', () {
      expect(SessionCodes.parseQr('https://udla.edu.co'), isNull);
      expect(SessionCodes.parseQr('asistly:solo-sesion'), isNull);
      expect(SessionCodes.parseQr('otra:sesion:codigo'), isNull);
    });
  });

  group('Próxima clase', () {
    test('Hoy, si la clase no ha terminado', () {
      final now = DateTime(2026, 11, 2, 9); // Lunes 9:00, en plena clase
      expect(course.nextClassAfter(now), DateTime(2026, 11, 2, 8));
    });

    test('El siguiente día de clase, si la de hoy ya terminó', () {
      final now = DateTime(2026, 11, 2, 11); // Lunes 11:00
      expect(course.nextClassAfter(now), DateTime(2026, 11, 4, 8)); // Miércoles
    });

    test('Después del último día de la semana sigue la semana siguiente', () {
      final now = DateTime(2026, 11, 5, 8); // Jueves
      expect(course.nextClassAfter(now), DateTime(2026, 11, 9, 8)); // Lunes
    });

    test('Con horario por día usa la hora de ese día', () {
      const perDay = Course(
        id: 'c2',
        name: 'Redes',
        group: 'Grupo 1',
        semester: '2026-2',
        days: [1, 3],
        startTime: '08:00',
        endTime: '10:00',
        startByDay: {1: '08:00', 3: '14:00'},
        endByDay: {1: '10:00', 3: '16:00'},
        room: 'Lab 3',
        enrollCode: 'RED-1AAA',
        teacherName: 'Prof. Ramírez',
      );
      // Lunes 11:00: la del lunes terminó; la del miércoles es a las 14:00.
      expect(perDay.nextClassAfter(DateTime(2026, 11, 2, 11)), DateTime(2026, 11, 4, 14));
      // Miércoles 15:00: sigue en clase (14:00–16:00).
      expect(perDay.nextClassAfter(DateTime(2026, 11, 4, 15)), DateTime(2026, 11, 4, 14));
      expect(perDay.scheduleLabel, 'Lun 08:00 – 10:00, Mié 14:00 – 16:00 · Lab 3');
      expect(course.scheduleLabel, 'Lun y Mié · 08:00 – 10:00 · Aula 101');
    });
  });

  group('Porcentaje del estudiante', () {
    test('Sin clases no está en riesgo', () {
      const item = StudentCourse(course: course, status: EnrollmentStatus.enrolled);
      expect(item.hasClasses, false);
      expect(item.isAtRisk, false);
    });

    test('Menos del 75 % está en riesgo', () {
      const item = StudentCourse(course: course, status: EnrollmentStatus.enrolled, presentCount: 2, absentCount: 1);
      expect(item.percent, 67);
      expect(item.isAtRisk, true);
    });
  });

  group('Señal Bluetooth', () {
    test('el estudiante lee el código que emite el docente', () {
      final code = SessionCodes.code('secreto', 'ble', 123);
      final bytes = SessionCodes.blePayload('c1_2026-11-22', code);
      expect(bytes.length, 8); // Cabe de sobra en un anuncio BLE (31 bytes)
      expect(SessionCodes.parseBlePayload('c1_2026-11-22', bytes), code);
    });

    test('ignora la señal de otra clase', () {
      final bytes = SessionCodes.blePayload('c1_2026-11-22', 'A1B2C3D4');
      expect(SessionCodes.parseBlePayload('c2_2026-11-22', bytes), null);
    });

    test('ignora otros aparatos', () {
      expect(SessionCodes.parseBlePayload('c1_2026-11-22', [1, 2, 3, 4, 5, 6, 7, 8]), null);
      expect(SessionCodes.parseBlePayload('c1_2026-11-22', [0x41, 0x53]), null);
    });
  });
}
