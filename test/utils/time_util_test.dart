import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zen_do/utils/time_util.dart';

void main() {
  const className = 'TimeUtil';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('de');
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('en_GB');
  });

  group('$className parseLocalized tests', () {
    test('$className parseLocalized with locale de successfully', () {
      final locale = const Locale('de');
      final dateString = '25.12.2023';

      final parsedDate = parseLocalized(dateString, locale);

      expect(parsedDate, DateTime(2023, 12, 25));
    });

    test('$className parseLocalized with locale en US successfully', () {
      final locale = const Locale('en', 'US');
      final dateString = '12/25/2023';

      final parsedDate = parseLocalized(dateString, locale);

      expect(parsedDate, DateTime(2023, 12, 25));
    });

    test('$className parseLocalized with locale en GB successfully', () {
      final locale = const Locale('en', 'GB');
      final dateString = '25/12/2023';

      final parsedDate = parseLocalized(dateString, locale);

      expect(parsedDate, DateTime(2023, 12, 25));
    });

    test('$className parseLocalized fails on invalid date string', () {
      final locale = const Locale('de');
      final dateString = 'this is not a date';

      expect(
        () => parseLocalized(dateString, locale),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      '$className tryParseLocalized returns null on invalid date string',
      () {
        final locale = const Locale('de');
        final dateString = 'this is not a date';

        final result = tryParseLocalized(dateString, locale);

        expect(result, isNull);
      },
    );
  });

  group('$className normalized DateTime tests', () {
    test(
      '$className normalized DateTime removes hours, minutes, seconds and milliseconds DateTime',
      () {
        final now = DateTime.now();
        final nowNormalized = DateTime(now.year, now.month, now.day);

        final result = DateTime.now().normalized;

        expect(result, nowNormalized);
      },
    );
  });

  group('$className format DateTime tests', () {
    test('$className format DateTime with locale de successfully', () {
      final date = DateTime(2023, 12, 25);
      final locale = const Locale('de');

      final formattedDate = date.formatYmD(locale);

      expect(formattedDate, 'Mo. 25.12.2023');
    });

    test('$className format DateTime with locale en US successfully', () {
      final date = DateTime(2023, 12, 25);
      final locale = const Locale('en', 'US');

      final formattedDate = date.formatYmD(locale);

      expect(formattedDate, 'Mon. 12/25/2023');
    });

    test('$className format DateTime with locale en GB successfully', () {
      final date = DateTime(2023, 12, 25);
      final locale = const Locale('en', 'GB');

      final formattedDate = date.formatYmD(locale);

      expect(formattedDate, 'Mon. 25/12/2023');
    });

    test('$className format DateTime with invalid locale fails', () {
      final date = DateTime(2023, 12, 25);
      final locale = const Locale('xx', 'XX');

      expect(() => date.formatYmD(locale), throwsA(isA<ArgumentError>()));
    });
  });
}
