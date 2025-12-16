import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @loadingTodosIndicator.
  ///
  /// In en, this message translates to:
  /// **'Loading Todos...'**
  String get loadingTodosIndicator;

  /// No description provided for @dataLoadErrorHeadline.
  ///
  /// In en, this message translates to:
  /// **'Loading data failed !'**
  String get dataLoadErrorHeadline;

  /// No description provided for @dataLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Close the app and reopen it later. If the error still exists, clear the app cache (your data will be retained).'**
  String get dataLoadErrorMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeApp;

  /// No description provided for @editTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit todo'**
  String get editTodo;

  /// No description provided for @titleLable.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLable;

  /// No description provided for @titleHintText.
  ///
  /// In en, this message translates to:
  /// **'The todo\'s title'**
  String get titleHintText;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHintText.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionHintText;

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

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @errorTodoAllreadyExistsInDestinationList.
  ///
  /// In en, this message translates to:
  /// **'Todo allready exists in destination list'**
  String get errorTodoAllreadyExistsInDestinationList;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get dueOn;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Createt on'**
  String get createdOn;

  /// No description provided for @noOpenTodosLeft.
  ///
  /// In en, this message translates to:
  /// **'No open todos left'**
  String get noOpenTodosLeft;

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

  /// No description provided for @completedTodos.
  ///
  /// In en, this message translates to:
  /// **'Completed todos'**
  String get completedTodos;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @addTodo.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get addTodo;

  /// No description provided for @sorting.
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get sorting;

  /// No description provided for @todos.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get todos;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'Todo-Title'**
  String get todoTitle;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get expirationDate;

  /// No description provided for @creationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation date'**
  String get creationDate;

  /// No description provided for @daily_adv.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily_adv;

  /// No description provided for @daily_adj.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get daily_adj;

  /// No description provided for @weekly_adv.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly_adv;

  /// No description provided for @weekly_adj.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get weekly_adj;

  /// No description provided for @monthly_adv.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly_adv;

  /// No description provided for @monthly_adj.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get monthly_adj;

  /// No description provided for @yearly_adv.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly_adv;

  /// No description provided for @yearly_adj.
  ///
  /// In en, this message translates to:
  /// **'yearly'**
  String get yearly_adj;

  /// No description provided for @backlog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get backlog;

  /// No description provided for @addNewTodo.
  ///
  /// In en, this message translates to:
  /// **'Add a new todo'**
  String get addNewTodo;

  /// No description provided for @moveToXList.
  ///
  /// In en, this message translates to:
  /// **'Move to\n{ListScopeLabel} list'**
  String moveToXList(String ListScopeLabel);

  /// No description provided for @shiftNotPossible.
  ///
  /// In en, this message translates to:
  /// **'Todo can not be moved!'**
  String get shiftNotPossible;

  /// No description provided for @todoMovedToX.
  ///
  /// In en, this message translates to:
  /// **'Todo was moved to {ListScopeLabel} list'**
  String todoMovedToX(String ListScopeLabel);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @commonSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get commonSettingsSection;

  /// No description provided for @themeSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettingsLabel;

  /// No description provided for @notificationsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettingsLabel;

  /// No description provided for @backupSettingsLable.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSettingsLable;

  /// No description provided for @languageSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsLabel;

  /// No description provided for @languageSettingsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Language settings'**
  String get languageSettingsHeadline;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseLanguage;

  /// No description provided for @useSystemLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get useSystemLanguageLabel;

  /// No description provided for @organizationSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationSettingsLabel;

  /// No description provided for @lists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// No description provided for @listsSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Chose your preffered lists'**
  String get listsSettingsDescription;

  /// No description provided for @labelsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsSettingsLabel;

  /// No description provided for @feedbackSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Feddback & Support'**
  String get feedbackSettingsSection;

  /// No description provided for @feedbackInStore.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get feedbackInStore;

  /// No description provided for @feedbackViaMail.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackViaMail;

  /// No description provided for @supportTheDev.
  ///
  /// In en, this message translates to:
  /// **'Support the developer'**
  String get supportTheDev;

  /// No description provided for @legalSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSettingsSection;

  /// No description provided for @aboutSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSettingsLabel;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @versionSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionSettingsLabel;

  /// No description provided for @minOneListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'There must be at least one list selected'**
  String get minOneListErrorMessage;

  /// No description provided for @loadingSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading settings ...'**
  String get loadingSettingsMessage;

  /// No description provided for @choosePreferredListsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose the lists yout want to use'**
  String get choosePreferredListsSettingsLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
