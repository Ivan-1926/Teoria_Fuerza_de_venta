/// Utilidades para formateo de fechas y montos.
class FormatUtils {
  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static const _monthsShort = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String usd(double value) {
    final neg = value < 0;
    final n = value.abs();
    final fixed = n.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final dec = parts.length > 1 ? parts[1] : '00';
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${neg ? '-' : ''}\$$buf.$dec';
  }

  /// yyyy-MM-dd
  static String dateYmd(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Ej: LUNES 2 JUN
  static String datePortfolioHeader(DateTime d) {
    final wd = _weekdays[d.weekday - 1].toUpperCase();
    final mon = _monthsShort[d.month - 1].toUpperCase();
    return '$wd ${d.day} $mon';
  }

  /// Ej: lunes 2 junio 2026
  static String dateRouteHeader(DateTime d) {
    final wd = _weekdays[d.weekday - 1];
    final mon = _monthsLong[d.month - 1];
    return '$wd ${d.day} $mon ${d.year}';
  }
}
