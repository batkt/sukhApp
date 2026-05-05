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

/// Formats invoice dates from ISO 8601 strings to "YYYY.MM.DD" format
/// Handles malformed dates gracefully
String formatInvoiceDate(String dateString) {
  if (dateString.isEmpty) return '';
  
  try {
    // Parse the ISO 8601 date string
    final dateTime = DateTime.parse(dateString);
    // Format as YYYY.MM.DD
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  } catch (e) {
    // If parsing fails, try to extract just the date part
    try {
      // Try to extract YYYY-MM-DD from the string
      final match = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(dateString);
      if (match != null) {
        return '${match.group(1)}.${match.group(2)}.${match.group(3)}';
      }
    } catch (_) {}
    
    // Return original string if all parsing fails
    return dateString;
  }
}
/// Formats bill periods (like 2026-5) to "YYYY/MM" format
String formatBillPeriod(String period) {
  if (period.isEmpty) return '';
  
  // Handles YYYY-M or YYYY-MM (Wallet API format)
  final walletMatch = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(period);
  if (walletMatch != null) {
    final year = walletMatch.group(1);
    final month = walletMatch.group(2)!.padLeft(2, '0');
    return '$year/$month';
  }

  // Handles YYYY.MM.DD (OWN_ORG format via formatInvoiceDate)
  final ownMatch = RegExp(r'^(\d{4})\.(\d{2})\.(\d{2})$').firstMatch(period);
  if (ownMatch != null) {
    final year = ownMatch.group(1);
    final month = ownMatch.group(2);
    return '$year/$month';
  }

  return period;
}
