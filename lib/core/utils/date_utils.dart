// This file provides utility functions for date formatting and manipulation.
// It ensures consistent date display across the app and handles different locales.
// This demonstrates proper date handling and internationalization support.

import 'package:intl/intl.dart';

/// Utility class for date formatting and manipulation.
/// Provides consistent date display across different locales and formats.
class DateUtils {
  // Private constructor to prevent instantiation (utility class)
  DateUtils._();

  /// Formats a date in a user-friendly, locale-specific format.
  /// Uses the device's locale to determine date formatting preferences.
  ///
  /// Example:
  /// - US: "January 15, 2024"
  /// - EU: "15 January 2024"
  /// - UK: "15th January 2024"
  static String formatDate(DateTime date) {
    final formatter = DateFormat.yMMMd();
    return formatter.format(date);
  }

  /// Formats a date with time in a user-friendly format.
  /// Useful for displaying timestamps and event times.
  ///
  /// Example: "January 15, 2024 at 2:30 PM"
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat.yMMMd().add_jm();
    return formatter.format(date);
  }

  /// Formats a date in a short, compact format.
  /// Useful for displaying dates in lists or compact spaces.
  ///
  /// Example: "Jan 15, 2024"
  static String formatShortDate(DateTime date) {
    final formatter = DateFormat.MMMd();
    return formatter.format(date);
  }

  /// Formats a date showing only the month and year.
  /// Useful for monthly summaries and reports.
  ///
  /// Example: "January 2024"
  static String formatMonthYear(DateTime date) {
    final formatter = DateFormat.yMMM();
    return formatter.format(date);
  }

  /// Formats a date showing only the day of the week.
  /// Useful for displaying recurring events or weekly views.
  ///
  /// Example: "Monday"
  static String formatDayOfWeek(DateTime date) {
    final formatter = DateFormat.EEEE();
    return formatter.format(date);
  }

  /// Formats a date showing only the day of the week in short form.
  /// Useful for compact displays like calendars.
  ///
  /// Example: "Mon"
  static String formatShortDayOfWeek(DateTime date) {
    final formatter = DateFormat.E();
    return formatter.format(date);
  }

  /// Formats a time in 12-hour format with AM/PM.
  /// Useful for displaying specific times.
  ///
  /// Example: "2:30 PM"
  static String formatTime(DateTime time) {
    final formatter = DateFormat.jm();
    return formatter.format(time);
  }

  /// Formats a time in 24-hour format.
  /// Useful for international or technical displays.
  ///
  /// Example: "14:30"
  static String formatTime24Hour(DateTime time) {
    final formatter = DateFormat.Hm();
    return formatter.format(time);
  }

  /// Formats a relative time (e.g., "2 hours ago", "yesterday").
  /// Useful for showing how long ago something happened.
  ///
  /// Examples:
  /// - "2 hours ago"
  /// - "yesterday"
  /// - "3 days ago"
  /// - "last week"
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  /// Gets the start of the day (midnight) for a given date.
  /// Useful for date range calculations and comparisons.
  ///
  /// Example: 2024-01-15 14:30:45 → 2024-01-15 00:00:00
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the end of the day (23:59:59) for a given date.
  /// Useful for date range calculations and comparisons.
  ///
  /// Example: 2024-01-15 14:30:45 → 2024-01-15 23:59:59
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Gets the start of the week (Monday) for a given date.
  /// Useful for weekly summaries and reports.
  ///
  /// Example: 2024-01-15 (Wednesday) → 2024-01-13 (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  /// Gets the end of the week (Sunday) for a given date.
  /// Useful for weekly summaries and reports.
  ///
  /// Example: 2024-01-15 (Wednesday) → 2024-01-19 (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return date.add(Duration(days: daysUntilSunday));
  }

  /// Gets the start of the month for a given date.
  /// Useful for monthly summaries and reports.
  ///
  /// Example: 2024-01-15 → 2024-01-01
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Gets the end of the month for a given date.
  /// Useful for monthly summaries and reports.
  ///
  /// Example: 2024-01-15 → 2024-01-31
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Gets the start of the year for a given date.
  /// Useful for yearly summaries and reports.
  ///
  /// Example: 2024-01-15 → 2024-01-01
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Gets the end of the year for a given date.
  /// Useful for yearly summaries and reports.
  ///
  /// Example: 2024-01-15 → 2024-12-31
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  /// Checks if two dates are the same day.
  /// Ignores time differences and only compares the date part.
  ///
  /// Returns true if both dates fall on the same calendar day.
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if a date is today.
  /// Compares the given date with the current date.
  ///
  /// Returns true if the date is today.
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Checks if a date is yesterday.
  /// Compares the given date with yesterday's date.
  ///
  /// Returns true if the date is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Checks if a date is tomorrow.
  /// Compares the given date with tomorrow's date.
  ///
  /// Returns true if the date is tomorrow.
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Gets the number of days between two dates.
  /// Returns a positive number if date2 is after date1.
  ///
  /// Example: daysBetween(2024-01-01, 2024-01-15) → 14
  static int daysBetween(DateTime date1, DateTime date2) {
    final start = startOfDay(date1);
    final end = startOfDay(date2);
    return end.difference(start).inDays;
  }

  /// Gets the number of weeks between two dates.
  /// Returns a positive number if date2 is after date1.
  ///
  /// Example: weeksBetween(2024-01-01, 2024-01-15) → 2
  static int weeksBetween(DateTime date1, DateTime date2) {
    final start = startOfWeek(date1);
    final end = startOfWeek(date2);
    return end.difference(start).inDays ~/ 7;
  }

  /// Gets the number of months between two dates.
  /// Returns a positive number if date2 is after date1.
  ///
  /// Example: monthsBetween(2024-01-01, 2024-03-15) → 2
  static int monthsBetween(DateTime date1, DateTime date2) {
    return (date2.year - date1.year) * 12 + (date2.month - date1.month);
  }

  /// Adds a specified number of days to a date.
  /// Useful for calculating future or past dates.
  ///
  /// Example: addDays(2024-01-15, 7) → 2024-01-22
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtracts a specified number of days from a date.
  /// Useful for calculating past dates.
  ///
  /// Example: subtractDays(2024-01-15, 7) → 2024-01-08
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Gets the age in years from a birth date.
  /// Calculates the difference between birth date and current date.
  ///
  /// Example: getAge(1990-01-15) → 34 (in 2024)
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Checks if a year is a leap year.
  /// A leap year has 366 days instead of 365.
  ///
  /// Returns true if the year is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Gets the number of days in a specific month.
  /// Takes leap years into account for February.
  ///
  /// Example: getDaysInMonth(2024, 2) → 29 (leap year)
  /// Example: getDaysInMonth(2023, 2) → 28 (not a leap year)
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Formats a duration in a human-readable format.
  /// Useful for displaying time spans and intervals.
  ///
  /// Examples:
  /// - Duration(hours: 2, minutes: 30) → "2 hours 30 minutes"
  /// - Duration(days: 1, hours: 12) → "1 day 12 hours"
  static String formatDuration(Duration duration) {
    final parts = <String>[];

    if (duration.inDays > 0) {
      parts.add('${duration.inDays} day${duration.inDays == 1 ? '' : 's'}');
    }

    final hours = duration.inHours % 24;
    if (hours > 0) {
      parts.add('$hours hour${hours == 1 ? '' : 's'}');
    }

    final minutes = duration.inMinutes % 60;
    if (minutes > 0) {
      parts.add('$minutes minute${minutes == 1 ? '' : 's'}');
    }

    if (parts.isEmpty) {
      return '0 minutes';
    }

    return parts.join(' ');
  }
}
