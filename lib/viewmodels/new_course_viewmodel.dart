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

  void setStartTime(TimeOfDay time) {
    startTime = time;
    error = null;
    notify();
  }

  void setEndTime(TimeOfDay time) {
    endTime = time;
    error = null;
    notify();
  }

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
    // Se comparan los minutos desde medianoche para saber cuál hora es mayor.
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes) {
      error = 'La hora de fin debe ser después de la hora de inicio.';
      notify();
      return null;
    }

    isLoading = true;
    error = null;
    notify();

    final days = selectedDays.toList();
    days.sort(); // Lun, Mar, Mié... en orden.

    final course = await _courseRepo.createCourse(
      name: name.trim(),
      group: group.trim(),
      semester: semester.trim(),
      days: days,
      startTime: formatTime(startTime),
      endTime: formatTime(endTime),
      room: room.trim(),
      teacherName: _authRepo.user?.fullName ?? '',
    );

    isLoading = false;
    notify();
    return course;
  }
}
