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
}
