import 'package:flutter/widgets.dart';
import 'package:zen_do/features/habits/l10n/habits_localizations.dart';

extension HabitsL10nX on BuildContext {
  HabitsLocalizations get habitsL10n => HabitsLocalizations.of(this);
}
