import 'dart:async';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/course.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Curso creado": copiar y compartir el código de inscripción.
class CourseCreatedViewModel extends BaseViewModel {
  final Course course;
  CourseCreatedViewModel(this.course);

  /// true por 2 segundos después de copiar, para mostrar "Copiado".
  bool justCopied = false;

  /// Una línea por día: "Lun 08:00 – 10:00 · Aula 101".
  List<String> get scheduleLines {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final lines = <String>[];
    for (final day in course.days) {
      lines.add('${names[day - 1]} ${course.timeLabel} · ${course.room}');
    }
    return lines;
  }

  Future<void> copyCode() async {
    // Clipboard es el portapapeles del celular (lo mismo que "Copiar" en otras apps).
    await Clipboard.setData(ClipboardData(text: course.enrollCode));
    justCopied = true;
    notify();
    Timer(const Duration(seconds: 2), () {
      justCopied = false;
      notify();
    });
  }

  /// Abre el menú del celular para compartir (WhatsApp, correo...).
  /// Usa el paquete share_plus.
  Future<void> shareCode() async {
    final text =
        'Únete a ${course.name} (${course.group}) en Asistly '
        'con el código: ${course.enrollCode}';
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
