import 'package:intl/intl.dart';

/// Standard number formatter for currency and decimal values.
/// Example: formatNumber(12503.456, 2) -> "12,503.46"
String formatNumber(double number, [int decimalDigits = 2]) {
  try {
    final format = NumberFormat.decimalPattern('en_US');
    format.minimumFractionDigits = decimalDigits;
    format.maximumFractionDigits = decimalDigits;
    return format.format(number);
  } catch (e) {
    // Fallback if intl fails or has issues
    final parts = number.toStringAsFixed(decimalDigits).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
    
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(regex, (match) => '${match[1]},');
    
    return '$formattedInteger$decimalPart';
  }
}
