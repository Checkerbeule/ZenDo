// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get closeApp => 'App schließen';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get dataLoadErrorHeadline => 'Laden der Daten fehlgeschlagen!';

  @override
  String get dataLoadErrorMessage => 'Schließen Sie die App und öffenen Sie sie zu einem späteren Zeitpunkt erneut.\nSollte der Fehler anschließend weiterhin bestehen, löschen Sie den App-Cache (Ihre Daten bleiben erhalten).';

  @override
  String get habits => 'Gewohnheiten';

  @override
  String get notes => 'Notizen';

  @override
  String get openAppSettings => 'Einstellungen öffnen';

  @override
  String get sorting => 'Sortierung';

  @override
  String get todos => 'Aufgaben';

  @override
  String get undo => 'Rückgängig';
}
