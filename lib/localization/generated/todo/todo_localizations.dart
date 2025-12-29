import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'todo_localizations_de.dart';
import 'todo_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of TodoLocalizations
/// returned by `TodoLocalizations.of(context)`.
///
/// Applications need to include `TodoLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'todo/todo_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: TodoLocalizations.localizationsDelegates,
///   supportedLocales: TodoLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the TodoLocalizations.supportedLocales
/// property.
abstract class TodoLocalizations {
  TodoLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static TodoLocalizations of(BuildContext context) {
    return Localizations.of<TodoLocalizations>(context, TodoLocalizations)!;
  }

  static const LocalizationsDelegate<TodoLocalizations> delegate = _TodoLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @addNewTodo.
  ///
  /// In en, this message translates to:
  /// **'Add new todo'**
  String get addNewTodo;

  /// No description provided for @addTodo.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get addTodo;

  /// No description provided for @backlog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get backlog;

  /// No description provided for @changeToFittingList.
  ///
  /// In en, this message translates to:
  /// **'Should the following fitting list be selected?'**
  String get changeToFittingList;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @completedTodos.
  ///
  /// In en, this message translates to:
  /// **'Completed todos'**
  String get completedTodos;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get createdOn;

  /// No description provided for @creationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation date'**
  String get creationDate;

  /// No description provided for @daily_adj.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get daily_adj;

  /// No description provided for @daily_adv.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily_adv;

  /// No description provided for @dateDoesNotFitListError.
  ///
  /// In en, this message translates to:
  /// **'Date does not fit selected list'**
  String get dateDoesNotFitListError;

  /// No description provided for @deleteTodo.
  ///
  /// In en, this message translates to:
  /// **'Delete todo'**
  String get deleteTodo;

  /// No description provided for @deleteTodoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to permanently delete this task?'**
  String get deleteTodoQuestion;

  /// No description provided for @descriptionHintText.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionHintText;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get dueOn;

  /// No description provided for @editTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit todo'**
  String get editTodo;

  /// No description provided for @errorTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title must not be empty'**
  String get errorTitleEmpty;

  /// No description provided for @errorTitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Title is allready taken'**
  String get errorTitleUnavailable;

  /// No description provided for @errorTodoAllreadyExistsInDestinationList.
  ///
  /// In en, this message translates to:
  /// **'Todo allready exists in destination list'**
  String get errorTodoAllreadyExistsInDestinationList;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get expirationDate;

  /// No description provided for @invalidDateFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalidDateFormatError;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @loadingTodosIndicator.
  ///
  /// In en, this message translates to:
  /// **'Loading Todos...'**
  String get loadingTodosIndicator;

  /// No description provided for @monthly_adj.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get monthly_adj;

  /// No description provided for @monthly_adv.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly_adv;

  /// No description provided for @moveToXList.
  ///
  /// In en, this message translates to:
  /// **'Move to\n{ListScopeLabel} list'**
  String moveToXList(String ListScopeLabel);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get next;

  /// No description provided for @noDateelectedError.
  ///
  /// In en, this message translates to:
  /// **'Not date selected'**
  String get noDateelectedError;

  /// No description provided for @noOpenTodosLeft.
  ///
  /// In en, this message translates to:
  /// **'No open todos left'**
  String get noOpenTodosLeft;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'previous'**
  String get previous;

  /// No description provided for @shiftNotPossible.
  ///
  /// In en, this message translates to:
  /// **'Todo can not be moved!'**
  String get shiftNotPossible;

  /// No description provided for @titleHintText.
  ///
  /// In en, this message translates to:
  /// **'The todo\'s title'**
  String get titleHintText;

  /// No description provided for @titleLable.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLable;

  /// No description provided for @todoMovedToX.
  ///
  /// In en, this message translates to:
  /// **'Todo was moved to {ListScopeLabel} list'**
  String todoMovedToX(String ListScopeLabel);

  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'Todo-Title'**
  String get todoTitle;

  /// No description provided for @weekly_adj.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get weekly_adj;

  /// No description provided for @weekly_adv.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly_adv;

  /// No description provided for @yearly_adj.
  ///
  /// In en, this message translates to:
  /// **'yearly'**
  String get yearly_adj;

  /// No description provided for @yearly_adv.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly_adv;
}

class _TodoLocalizationsDelegate extends LocalizationsDelegate<TodoLocalizations> {
  const _TodoLocalizationsDelegate();

  @override
  Future<TodoLocalizations> load(Locale locale) {
    return SynchronousFuture<TodoLocalizations>(lookupTodoLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_TodoLocalizationsDelegate old) => false;
}

TodoLocalizations lookupTodoLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return TodoLocalizationsDe();
    case 'en': return TodoLocalizationsEn();
  }

  throw FlutterError(
    'TodoLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
