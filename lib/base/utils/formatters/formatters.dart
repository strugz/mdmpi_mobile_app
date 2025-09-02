import 'package:intl/intl.dart';

class BFormatter {
  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('MM-dd-yyyy').format(date);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
    } else if (phoneNumber.length == 11) {
      return '(${phoneNumber.substring(0, 4)}) ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  static String formatDateTime(String inputDate) {
    try {
      // Parse the original string using the known format
      final originalFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
      final dateTime = originalFormat.parse(inputDate);

      // Format it to the desired output
      final desiredFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");

      return desiredFormat.format(dateTime);
    } catch (e) {
      return ''; // or handle error
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isDaysAgo(DateTime date, int n) {
    final targetDate = DateTime.now().subtract(Duration(days: n));
    return date.year == targetDate.year &&
        date.month == targetDate.month &&
        date.day == targetDate.day;
  }

  static bool isWithinLastNDays(DateTime date, int n) {
    final now = DateTime.now();
    final nDaysAgo = now.subtract(Duration(days: n));
    return date.isAfter(nDaysAgo) && date.isBefore(now.add(Duration(days: 1)));
  }

  // New method for tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }
}
