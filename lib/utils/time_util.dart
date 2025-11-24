import 'package:intl/intl.dart';

final String dateFormat = 'dd.MM.yyyy';

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

String formatDate(DateTime? date, {String? optionalErrorText}) {
  final errorText = optionalErrorText ?? '(kein Datum vorhanden)';
  if (date == null) {
    return errorText;
  }
  return DateFormat(dateFormat).format(date);
}
