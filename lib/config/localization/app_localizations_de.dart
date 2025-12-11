// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get loadingTodosIndicator => 'Lade Aufgaben...';

  @override
  String get dataLoadErrorHeadline => 'Laden der Daten fehlgeschlagen !';

  @override
  String get dataLoadErrorMessage =>
      'Schließen Sie die App und öffenen Sie sie zu einem späteren Zeitpunkt erneut.\nSollte der Fehler anschließend weiterhin bestehen, löschen Sie den App-Cache (Ihre Daten bleiben erhalten).';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get closeApp => 'App schließen';

  @override
  String get editTodo => 'Aufgabe bearbeiten';

  @override
  String get titleLable => 'Titel';

  @override
  String get titleHintText => 'Titel der Aufgabe';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get descriptionHintText => 'Beschreibung (optional)';

  @override
  String get errorTitleEmpty => 'Titel darf nicht leer sein';

  @override
  String get errorTitleUnavailable => 'Titel ist bereits vergeben';

  @override
  String get list => 'Liste';

  @override
  String get errorTodoAllreadyExistsInDestinationList =>
      'Aufgabe bereits vohanden in Zielliste';

  @override
  String get dueOn => 'Fällig am';

  @override
  String get createdOn => 'Erstellt am';

  @override
  String get noOpenTodosLeft => 'Keine offenen Aufgaben vorhanden';

  @override
  String get deleteTodo => 'Aufgabe löschen';

  @override
  String get deleteTodoQuestion =>
      'Diese Aufgabe wirklich unwiederbringlich löschen?';

  @override
  String get completedTodos => 'Erledigte Aufgaben';

  @override
  String get completed => 'erledigt';

  @override
  String get addTodo => 'Aufgabe hinzufügen';

  @override
  String get sorting => 'Sortierung';

  @override
  String get todos => 'Aufgaben';

  @override
  String get habits => 'Gewohnheiten';

  @override
  String get notes => 'Notizen';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get todoTitle => 'Aufgaben-Titel';

  @override
  String get expirationDate => 'Fälligkeitsdatum';

  @override
  String get creationDate => 'Erstalldatum';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get yearly => 'Jährlich';

  @override
  String get backlog => 'Backlog';

  @override
  String get addNewTodo => 'Neue Aufgabe hinzufügen';

  @override
  String moveToXList(String ListScopeLabel) {
    return 'Verschieben in\n$ListScopeLabel Liste';
  }

  @override
  String get shiftNotPossible => 'Verschieben der Aufgabe nicht möglich!';

  @override
  String todoMovedToX(String ListScopeLabel) {
    return 'Aufgabe wurde in $ListScopeLabel Liste verschoben';
  }

  @override
  String get undo => 'Rückgängig';
}
