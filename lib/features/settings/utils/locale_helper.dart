import 'package:flutter/material.dart';
import 'package:zen_do/features/settings/l10n/settings_localizations.dart';

String getLanguageLabel(BuildContext context, Locale? locale) {
  final loc = SettingsLocalizations.of(context);
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
