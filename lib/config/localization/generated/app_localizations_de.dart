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
  String get daily_adv => 'Täglich';

  @override
  String get daily_adj => 'tägliche';

  @override
  String get weekly_adv => 'Wöchentlich';

  @override
  String get weekly_adj => 'wöchentliche';

  @override
  String get monthly_adv => 'Monatlich';

  @override
  String get monthly_adj => 'monatliche';

  @override
  String get yearly_adv => 'Jährlich';

  @override
  String get yearly_adj => 'jährliche';

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

  @override
  String get settings => 'Einstellungen';

  @override
  String get commonSettingsSection => 'Allgemein';

  @override
  String get themeSettingsLabel => 'Erscheinungsbild';

  @override
  String get notificationsSettingsLabel => 'Benachrichtigungen';

  @override
  String get languageSettingsLabel => 'Sprache';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get chooseLanguage => 'App-Sprache festlegen';

  @override
  String get organizationSettingsLabel => 'Organisation';

  @override
  String get lists => 'Listen';

  @override
  String get listsSettingsDescription => 'Aufgaben-Listen wählen';

  @override
  String get labelsSettingsLabel => 'Labels';

  @override
  String get feedbackSettingsSection => 'Feddback & Support';

  @override
  String get feedbackInStore => 'Bewerte die App';

  @override
  String get feedbackViaMail => 'Feedback geben';

  @override
  String get supportTheDev => 'Unterstütze den Entwickler';

  @override
  String get legalSettingsSection => 'Rechtliches';

  @override
  String get aboutSettingsLabel => 'Über';

  @override
  String get privacyPolicy => 'Datenschutz';

  @override
  String get termsAndConditions => 'AGB / Lizenz';

  @override
  String get versionSettingsLabel => 'Version';

  @override
  String get minOneListErrorMessage =>
      'Es muss mindest eine Liste ausgewählt sein!';

  @override
  String get loadingSettingsMessage => 'Lade Einstellungen ...';

  @override
  String get choosePreferredListsSettingsLabel =>
      'Lege fest, welche Listen Du verwenden möchtest';
}
