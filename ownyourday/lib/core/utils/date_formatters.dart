import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final DateFormat dayName = DateFormat('EEEE');
  static final DateFormat monthDayYear = DateFormat('MMMM d, y');
  static final DateFormat monthShortDay = DateFormat('MMM d');
  static final DateFormat monthYear = DateFormat('MMM y');
  static final DateFormat time = DateFormat('h:mm a');
  static final DateFormat weekdayShort = DateFormat('E');

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) {
      return 'Today';
    }
    if (diff == 1) {
      return 'Tomorrow';
    }
    if (diff == -1) {
      return 'Yesterday';
    }
    return monthShortDay.format(date);
  }
}
