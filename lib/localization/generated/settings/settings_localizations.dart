import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'settings_localizations_de.dart';
import 'settings_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SettingsLocalizations
/// returned by `SettingsLocalizations.of(context)`.
///
/// Applications need to include `SettingsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'settings/settings_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SettingsLocalizations.localizationsDelegates,
///   supportedLocales: SettingsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the SettingsLocalizations.supportedLocales
/// property.
abstract class SettingsLocalizations {
  SettingsLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SettingsLocalizations of(BuildContext context) {
    return Localizations.of<SettingsLocalizations>(context, SettingsLocalizations)!;
  }

  static const LocalizationsDelegate<SettingsLocalizations> delegate = _SettingsLocalizationsDelegate();

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

  /// No description provided for @aboutSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSettingsLabel;

  /// No description provided for @backupSettingsLable.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSettingsLable;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseLanguage;

  /// No description provided for @choosePreferredListsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose the lists yout want to use'**
  String get choosePreferredListsSettingsLabel;

  /// No description provided for @commonSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get commonSettingsSection;

  /// No description provided for @feedbackInStore.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get feedbackInStore;

  /// No description provided for @feedbackSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Feddback & Support'**
  String get feedbackSettingsSection;

  /// No description provided for @feedbackViaMail.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackViaMail;

  /// No description provided for @labelsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsSettingsLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languageSettingsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Language settings'**
  String get languageSettingsHeadline;

  /// No description provided for @languageSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsLabel;

  /// No description provided for @legalSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSettingsSection;

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

  /// No description provided for @loadingSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading settings ...'**
  String get loadingSettingsMessage;

  /// No description provided for @minOneListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'There must be at least one list selected'**
  String get minOneListErrorMessage;

  /// No description provided for @notificationsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettingsLabel;

  /// No description provided for @organizationSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationSettingsLabel;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @supportTheDev.
  ///
  /// In en, this message translates to:
  /// **'Support the developer'**
  String get supportTheDev;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @themeSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettingsLabel;

  /// No description provided for @useSystemLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get useSystemLanguageLabel;

  /// No description provided for @versionSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionSettingsLabel;
}

class _SettingsLocalizationsDelegate extends LocalizationsDelegate<SettingsLocalizations> {
  const _SettingsLocalizationsDelegate();

  @override
  Future<SettingsLocalizations> load(Locale locale) {
    return SynchronousFuture<SettingsLocalizations>(lookupSettingsLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SettingsLocalizationsDelegate old) => false;
}

SettingsLocalizations lookupSettingsLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return SettingsLocalizationsDe();
    case 'en': return SettingsLocalizationsEn();
  }

  throw FlutterError(
    'SettingsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
