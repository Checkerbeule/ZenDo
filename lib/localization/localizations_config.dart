import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zen_do/localization/generated/app/app_localizations.dart';
import 'package:zen_do/localization/generated/settings/settings_localizations.dart';
import 'package:zen_do/localization/generated/todo/todo_localizations.dart';

List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  AppLocalizations.delegate,
  TodoLocalizations.delegate,
  SettingsLocalizations.delegate,
];
