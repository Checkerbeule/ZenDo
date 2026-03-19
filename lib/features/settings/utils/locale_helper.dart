import 'package:flutter/material.dart';
import 'package:zen_do/features/settings/l10n/settings_l10n_extension.dart';

String getLanguageLabel(BuildContext context, Locale? locale) {
  if (locale == null) return '';
  switch (locale.languageCode) {
    case 'en':
      return context.settingsL10n.languageEnglish;
    case 'de':
      return context.settingsL10n.languageGerman;
    default:
      return locale.languageCode;
  }
}
