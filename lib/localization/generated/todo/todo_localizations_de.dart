// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'todo_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class TodoLocalizationsDe extends TodoLocalizations {
  TodoLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get addNewTodo => 'Neue Aufgabe hinzufügen';

  @override
  String get addTodo => 'Aufgabe hinzufügen';

  @override
  String get backlog => 'Backlog';

  @override
  String get changeToFittingList => 'Soll die folgende passende Liste auswählen werden?';

  @override
  String get completed => 'erledigt';

  @override
  String get completedTodos => 'Erledigte Aufgaben';

  @override
  String get createdOn => 'Erstellt am';

  @override
  String get creationDate => 'Erstalldatum';

  @override
  String get daily_adj => 'tägliche';

  @override
  String get daily_adv => 'Täglich';

  @override
  String get dateDoesNotFitListError => 'Datum passt nicht zur gewählten Liste';

  @override
  String get deleteTodo => 'Aufgabe löschen';

  @override
  String get deleteTodoQuestion => 'Diese Aufgabe wirklich unwiederbringlich löschen?';

  @override
  String get descriptionHintText => 'Beschreibung (optional)';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get dueOn => 'Fällig am';

  @override
  String get editTodo => 'Aufgabe bearbeiten';

  @override
  String get errorTitleEmpty => 'Titel darf nicht leer sein';

  @override
  String get errorTitleUnavailable => 'Titel ist bereits vergeben';

  @override
  String get errorTodoAllreadyExistsInDestinationList => 'Aufgabe bereits vohanden in Zielliste';

  @override
  String get expirationDate => 'Fälligkeitsdatum';

  @override
  String get invalidDateFormatError => 'Falsches Datumsformat';

  @override
  String get list => 'Liste';

  @override
  String get loadingTodosIndicator => 'Lade Aufgaben...';

  @override
  String get monthly_adj => 'monatliche';

  @override
  String get monthly_adv => 'Monatlich';

  @override
  String moveToXList(String ListScopeLabel) {
    return 'Verschieben in\n$ListScopeLabel Liste';
  }

  @override
  String get next => 'nächste';

  @override
  String get noDateelectedError => 'Kein Datum ausgewählt';

  @override
  String get noOpenTodosLeft => 'Keine offenen Aufgaben vorhanden';

  @override
  String get previous => 'vorherige';

  @override
  String get shiftNotPossible => 'Verschieben der Aufgabe nicht möglich!';

  @override
  String get titleHintText => 'Titel der Aufgabe';

  @override
  String get titleLable => 'Titel';

  @override
  String todoMovedToX(String ListScopeLabel) {
    return 'Aufgabe wurde in $ListScopeLabel Liste verschoben';
  }

  @override
  String get todoTitle => 'Aufgaben-Titel';

  @override
  String get weekly_adj => 'wöchentliche';

  @override
  String get weekly_adv => 'Wöchentlich';

  @override
  String get yearly_adj => 'jährliche';

  @override
  String get yearly_adv => 'Jährlich';
}
