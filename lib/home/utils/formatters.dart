String formatCurrency(double value, {String prefix = ''}) {
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();
  
  // Split into integer and decimal parts
  final parts = absValue.toStringAsFixed(2).split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];
  
  // Format integer part with Indian numbering system
  String formattedInteger = '';
  final length = integerPart.length;
  
  if (length <= 3) {
    formattedInteger = integerPart;
  } else {
    // Last 3 digits
    formattedInteger = integerPart.substring(length - 3);
    int remaining = length - 3;
    
    // Add groups of 2 digits from right to left
    while (remaining > 0) {
      final start = remaining - 2 > 0 ? remaining - 2 : 0;
      final group = integerPart.substring(start, remaining);
      formattedInteger = '$group,$formattedInteger';
      remaining = start;
    }
  }
  
  return '$sign$prefix₹$formattedInteger.$decimalPart';
}

String formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

String formatTime(DateTime dateTime) {
  final int hourOfPeriod = dateTime.hour % 12;
  final int hour = hourOfPeriod == 0 ? 12 : hourOfPeriod;
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
