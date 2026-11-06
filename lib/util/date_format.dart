/// Fechas en español sin paquetes extra.
class DateFormatEs {
  static const _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _shortDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const _shortMonths = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  /// "Miércoles, 23 de septiembre"
  static String long(DateTime date) {
    return '${_days[date.weekday - 1]}, ${date.day} de ${_months[date.month - 1]}';
  }

  /// "Lun 21 Sep"
  static String short(DateTime date) {
    return '${_shortDays[date.weekday - 1]} ${date.day} ${_shortMonths[date.month - 1]}';
  }

  /// "Lun, 21 Sep"; "Hoy, 23 Sep" o "Ayer, 22 Sep" si corresponde.
  static String relative(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final daysAgo = today.difference(day).inHours ~/ 24;
    var name = _shortDays[date.weekday - 1];
    if (daysAgo == 0) name = 'Hoy';
    if (daysAgo == 1) name = 'Ayer';
    return '$name, ${date.day} ${_shortMonths[date.month - 1]}';
  }

  /// "Lun" (1 = lunes ... 7 = domingo).
  static String shortDay(int weekday) => _shortDays[weekday - 1];

  /// "Septiembre 2026"
  static String monthYear(DateTime date) {
    final month = _months[date.month - 1];
    return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
  }

  /// "08:04 a. m."
  static String time(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minutes = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'a. m.' : 'p. m.';
    return '${hour12.toString().padLeft(2, '0')}:$minutes $period';
  }
}
