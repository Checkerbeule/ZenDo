// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'todos_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TodosLocalizationsEn extends TodosLocalizations {
  TodosLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addNewTodo => 'Add new todo';

  @override
  String get backlog => 'Stash';

  @override
  String get changeToFittingList => 'Should the following fitting list be selected?';

  @override
  String get checkTodoFilters => 'Check your filter settings';

  @override
  String get completed => 'completed';

  @override
  String get completedOn => 'Completed on';

  @override
  String get completedTodos => 'Completed todos';

  @override
  String get createdOn => 'Created on';

  @override
  String get creationDate => 'Creation date';

  @override
  String get dailyList => 'Daily List';

  @override
  String get dateDoesNotFitAnyListError => 'Date does not fit any list';

  @override
  String get dateDoesNotFitListError => 'Date does not fit selected list';

  @override
  String get day => 'Day';

  @override
  String get deleteTodo => 'Delete todo';

  @override
  String get deleteTodoQuestion => 'Do you really want to permanently delete this task?';

  @override
  String get descriptionHintText => 'Description (optional)';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dueOn => 'Due on';

  @override
  String get editTodo => 'Edit todo';

  @override
  String get errorTitleEmpty => 'Title must not be empty';

  @override
  String get errorTitleUnavailable => 'Title is allready taken';

  @override
  String get errorTodoAllreadyExistsInDestinationList => 'Todo allready exists in destination list';

  @override
  String get everythingDone => 'Great, there is nothing left to do!';

  @override
  String get expirationDate => 'Due date';

  @override
  String get invalidDateFormatError => 'Invalid date format';

  @override
  String get list => 'List';

  @override
  String get loadingTodosIndicator => 'Loading Todos...';

  @override
  String get month => 'Month';

  @override
  String get monthlyList => 'Monthly List';

  @override
  String get moveTo => 'Move to';

  @override
  String get next => 'next';

  @override
  String get noDateelectedError => 'Not date selected';

  @override
  String get noTodosFound => 'No todos found';

  @override
  String get previous => 'previous';

  @override
  String get shiftNotPossible => 'Todo can not be moved!';

  @override
  String get titleHintText => 'The todo\'s title';

  @override
  String get titleLable => 'Title';

  @override
  String todoMovedToX(String ListScopeLabel) {
    return 'Todo was moved to $ListScopeLabel list';
  }

  @override
  String get todoTitle => 'Todo-Title';

  @override
  String get week => 'Week';

  @override
  String get weeklyList => 'Weekly List';

  @override
  String get year => 'Year';

  @override
  String get yearlyList => 'Yearly List';
}
