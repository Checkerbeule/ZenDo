import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns the duration until the next midnight from now on.
/// An optional offset [timeAfterMidnight] can be provided to specify a time after midnight.
/// Default offset is 5 minutes (00:05 AM).
Duration durationUntilNextMidnight({
  Duration timeAfterMidnight = const Duration(minutes: 5), // 00:05 Uhr
}) {
  final now = DateTime.now();
  final nextMidnight = DateTime(
    now.year,
    now.month,
    now.day + 1,
    0,
    0,
  ).add(timeAfterMidnight);
  return nextMidnight.difference(now);
}

/// Parses a date string [dateString] according to the provided [locale].
/// Supports multiple date formats for robustness.
/// Throws a [FormatException] if parsing fails for all supported formats.
DateTime parseLocalized(String dateString, Locale locale) {
  final formatUs = DateFormat('MM/dd/yyyy');
  final formatUk = DateFormat('dd/MM/yyyy');
  final formatDe = DateFormat('dd.MM.yyyy');

  DateTime result;
  try {
    result = DateFormat.yMd(locale.toLanguageTag()).parse(dateString);
  } catch (_) {
    try {
      result = formatUs.parse(dateString);
    } catch (_) {
      try {
        result = formatUk.parse(dateString);
      } catch (_) {
        try {
          result = formatDe.parse(dateString);
        } catch (_) {
          rethrow;
        }
      }
    }
  }
  return result;
}

DateTime? tryParseLocalized(String dateString, Locale locale) {
  try {
    return parseLocalized(dateString, locale);
  } catch (_) {
    return null;
  }
}

extension DateTimeX on DateTime {
  String formatYmD(Locale locale) {
    return DateFormat.yMd(locale.toLanguageTag()).format(this);
  }
}
