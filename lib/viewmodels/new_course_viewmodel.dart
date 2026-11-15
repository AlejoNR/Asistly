import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/auth_repository.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Nuevo curso": días elegidos, horario y creación del curso.
class NewCourseViewModel extends BaseViewModel {
  final AuthRepository _authRepo;
  final CourseRepository _courseRepo;
  NewCourseViewModel(this._authRepo, this._courseRepo);

  // Lunes y miércoles marcados de entrada, como en el mockup.
  final Set<int> selectedDays = {1, 3};
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

  /// true: una sola hora para todos los días. false: cada día tiene la suya.
  bool sameSchedule = true;
  final Map<int, TimeOfDay> _startByDay = {};
  final Map<int, TimeOfDay> _endByDay = {};

  bool isLoading = false;
  String? error;

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    error = null;
    notify();
  }

  void setSameSchedule(bool value) {
    sameSchedule = value;
    error = null;
    notify();
  }

  /// Hora de ese día; si no se ha cambiado, la general.
  TimeOfDay startFor(int day) => sameSchedule ? startTime : _startByDay[day] ?? startTime;
  TimeOfDay endFor(int day) => sameSchedule ? endTime : _endByDay[day] ?? endTime;

  /// [day] null cambia la hora general (la de todos los días).
  void setStartTime(TimeOfDay time, {int? day}) {
    if (day == null) {
      startTime = time;
    } else {
      _startByDay[day] = time;
    }
    error = null;
    notify();
  }

  void setEndTime(TimeOfDay time, {int? day}) {
    if (day == null) {
      endTime = time;
    } else {
      _endByDay[day] = time;
    }
    error = null;
    notify();
  }

  static const _dayNames = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  /// "08:00"
  static String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Crea el curso. Devuelve el curso creado o null si algo falta (ver [error]).
  Future<Course?> create({
    required String name,
    required String group,
    required String semester,
    required String room,
  }) async {
    if (selectedDays.isEmpty) {
      error = 'Selecciona al menos un día de clase.';
      notify();
      return null;
    }
    final days = selectedDays.toList();
    days.sort(); // Lun, Mar, Mié... en orden.

    for (final day in days) {
      // Se comparan los minutos desde medianoche para saber cuál hora es mayor.
      final start = startFor(day);
      final end = endFor(day);
      if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
        error = sameSchedule
            ? 'La hora de fin debe ser después de la hora de inicio.'
            : 'El ${_dayNames[day - 1]}: la hora de fin debe ser después de la hora de inicio.';
        notify();
        return null;
      }
    }

    isLoading = true;
    error = null;
    notify();

    Course? course;
    try {
      course = await _courseRepo.createCourse(
        name: name.trim(),
        group: group.trim(),
        semester: semester.trim(),
        days: days,
        startByDay: {for (final day in days) day: formatTime(startFor(day))},
        endByDay: {for (final day in days) day: formatTime(endFor(day))},
        room: room.trim(),
        teacherName: _authRepo.user?.fullName ?? '',
      );
    } catch (e) {
      error = errorMessage(e);
    }

    isLoading = false;
    notify();
    return course;
  }
}
