// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loadingTodosIndicator => 'Loading Todos...';

  @override
  String get dataLoadErrorHeadline => 'Loading data failed !';

  @override
  String get dataLoadErrorMessage =>
      'Close the app and reopen it later. If the error still exists, clear the app cache (your data will be retained).';

  @override
  String get openSettings => 'Open settings';

  @override
  String get closeApp => 'Close App';

  @override
  String get editTodo => 'Edit todo';

  @override
  String get titleLable => 'Title';

  @override
  String get titleHintText => 'The todo\'s title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHintText => 'Description (optional)';

  @override
  String get errorTitleEmpty => 'Title must not be empty';

  @override
  String get errorTitleUnavailable => 'Title is allready taken';

  @override
  String get list => 'List';

  @override
  String get errorTodoAllreadyExistsInDestinationList =>
      'Todo allready exists in destination list';

  @override
  String get dueOn => 'Due on';

  @override
  String get createdOn => 'Createt on';

  @override
  String get noOpenTodosLeft => 'No open todos left';

  @override
  String get deleteTodo => 'Delete todo';

  @override
  String get deleteTodoQuestion =>
      'Do you really want to permanently delete this task?';

  @override
  String get completedTodos => 'Completed todos';

  @override
  String get completed => 'completed';

  @override
  String get addTodo => 'Add todo';

  @override
  String get sorting => 'Sorting';

  @override
  String get todos => 'Todos';

  @override
  String get habits => 'Habits';

  @override
  String get notes => 'Notes';

  @override
  String get custom => 'Custom';

  @override
  String get todoTitle => 'Todo-Title';

  @override
  String get expirationDate => 'Due date';

  @override
  String get creationDate => 'Creation date';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get backlog => 'Backlog';

  @override
  String get addNewTodo => 'Add a new todo';

  @override
  String moveToXList(String ListScopeLabel) {
    return 'Move to\n$ListScopeLabel list';
  }

  @override
  String get shiftNotPossible => 'Todo can not be moved!';

  @override
  String todoMovedToX(String ListScopeLabel) {
    return 'Todo was moved to $ListScopeLabel list';
  }

  @override
  String get undo => 'Undo';
}
