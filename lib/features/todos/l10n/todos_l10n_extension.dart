import 'package:flutter/widgets.dart';
import 'package:zen_do/features/todos/l10n/todos_localizations.dart';

extension TodosL10nX on BuildContext {
  TodosLocalizations get todosL10n => TodosLocalizations.of(this);
}
