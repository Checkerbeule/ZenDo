import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zen_do/core/l10n/app_localizations.dart';
import 'package:zen_do/features/settings/l10n/settings_localizations.dart';
import 'package:zen_do/features/tags/l10n/tags_localizations.dart';
import 'package:zen_do/features/todos/l10n/todos_localizations.dart';

List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  AppLocalizations.delegate,
  TodosLocalizations.delegate,
  SettingsLocalizations.delegate,
  TagsLocalizations.delegate,
];
