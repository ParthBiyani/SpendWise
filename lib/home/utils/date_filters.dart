bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isSameWeek(DateTime date, DateTime reference) {
  final DateTime refStart = reference.subtract(Duration(days: reference.weekday - 1));
  final DateTime refEnd = refStart.add(const Duration(days: 6));
  return !date.isBefore(startOfDay(refStart)) && !date.isAfter(endOfDay(refEnd));
}

DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime endOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}
