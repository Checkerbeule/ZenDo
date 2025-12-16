// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get closeApp => 'Close app';

  @override
  String get custom => 'Custom';

  @override
  String get dataLoadErrorHeadline => 'Loading data failed!';

  @override
  String get dataLoadErrorMessage => 'Close the app and reopen it later. If the error still exists, clear the app cache (your data will be retained).';

  @override
  String get habits => 'Habits';

  @override
  String get notes => 'Notes';

  @override
  String get openAppSettings => 'Open settings';

  @override
  String get sorting => 'Sorting';

  @override
  String get todos => 'Todos';

  @override
  String get undo => 'Undo';
}
