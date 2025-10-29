Duration durationUntilNextMidnight({
  timeAfterMidnight = const Duration(minutes: 5), // 00:05 Uhr
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