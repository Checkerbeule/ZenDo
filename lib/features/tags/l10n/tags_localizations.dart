import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'tags_localizations_de.dart';
import 'tags_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of TagsLocalizations
/// returned by `TagsLocalizations.of(context)`.
///
/// Applications need to include `TagsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/tags_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: TagsLocalizations.localizationsDelegates,
///   supportedLocales: TagsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the TagsLocalizations.supportedLocales
/// property.
abstract class TagsLocalizations {
  TagsLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static TagsLocalizations of(BuildContext context) {
    return Localizations.of<TagsLocalizations>(context, TagsLocalizations)!;
  }

  static const LocalizationsDelegate<TagsLocalizations> delegate = _TagsLocalizationsDelegate();

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

  /// No description provided for @addNewTag.
  ///
  /// In en, this message translates to:
  /// **'Add new Tag'**
  String get addNewTag;

  /// No description provided for @addSomeTags.
  ///
  /// In en, this message translates to:
  /// **'Add some!'**
  String get addSomeTags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @colorPickerPrimaryLable.
  ///
  /// In en, this message translates to:
  /// **'Primary colors'**
  String get colorPickerPrimaryLable;

  /// No description provided for @colorPickerWheelLable.
  ///
  /// In en, this message translates to:
  /// **'Color palette'**
  String get colorPickerWheelLable;

  /// No description provided for @connectedTags.
  ///
  /// In en, this message translates to:
  /// **'Connected tags'**
  String get connectedTags;

  /// No description provided for @deleteTagMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the tag \'{tagName}\'?\nObjects with this tag will remain but lose the tag.'**
  String deleteTagMessage(String tagName);

  /// No description provided for @deleteTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get deleteTagTitle;

  /// No description provided for @editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get editTag;

  /// No description provided for @errorLoadingTags.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading tags.'**
  String get errorLoadingTags;

  /// No description provided for @loadingTags.
  ///
  /// In en, this message translates to:
  /// **'Loading tags...'**
  String get loadingTags;

  /// No description provided for @manageTagsScreenHeader.
  ///
  /// In en, this message translates to:
  /// **'Manage your tags to organize content'**
  String get manageTagsScreenHeader;

  /// No description provided for @noTagsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get noTagsAvailable;

  /// No description provided for @noTagsForFiltering.
  ///
  /// In en, this message translates to:
  /// **'No tags available for filtering'**
  String get noTagsForFiltering;

  /// No description provided for @tagColorHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose a color'**
  String get tagColorHeading;

  /// No description provided for @tagColorSubheading.
  ///
  /// In en, this message translates to:
  /// **'Color gradations'**
  String get tagColorSubheading;

  /// No description provided for @tagNameDecoration.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameDecoration;

  /// No description provided for @tagNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameLabel;
}

class _TagsLocalizationsDelegate extends LocalizationsDelegate<TagsLocalizations> {
  const _TagsLocalizationsDelegate();

  @override
  Future<TagsLocalizations> load(Locale locale) {
    return SynchronousFuture<TagsLocalizations>(lookupTagsLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_TagsLocalizationsDelegate old) => false;
}

TagsLocalizations lookupTagsLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return TagsLocalizationsDe();
    case 'en': return TagsLocalizationsEn();
  }

  throw FlutterError(
    'TagsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
