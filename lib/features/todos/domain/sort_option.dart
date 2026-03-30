import 'package:flutter/material.dart';
import 'package:zen_do/core/l10n/app_l10n_extension.dart';
import 'package:zen_do/features/todos/l10n/todos_l10n_extension.dart';

enum SortOption {
  custom,
  title,
  expirationDate,
  creationDate,
  completionDate;

  static Set<SortOption> get uiOptions =>
      SortOption.values.toSet()..remove(SortOption.completionDate);
}

extension SortOptionX on SortOption {
  String label(BuildContext context) {
    switch (this) {
      case SortOption.custom:
        return context.appL10n.custom;
      case SortOption.title:
        return context.todosL10n.todoTitle;
      case SortOption.expirationDate:
        return context.todosL10n.expirationDate;
      case SortOption.creationDate:
        return context.todosL10n.creationDate;
      case SortOption.completionDate:
        throw UnimplementedError(
          'Label for completion date sorting. This should not be used in the UI.',
        );
    }
  }
}
