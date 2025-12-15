import 'package:flutter/material.dart';
import 'package:zen_do/config/localization/generated/app_localizations.dart';

String getLanguageLabel(BuildContext context, Locale? locale) {
  AppLocalizations loc = AppLocalizations.of(context);
  if (locale == null) return '';
  switch (locale.languageCode) {
    case 'en':
      return loc.languageEnglish;
    case 'de':
      return loc.languageGerman;
    default:
      return locale.languageCode;
  }
}
