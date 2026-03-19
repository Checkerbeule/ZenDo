import 'package:flutter/widgets.dart';
import 'package:zen_do/core/l10n/app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get appL10n => AppLocalizations.of(this);
}
