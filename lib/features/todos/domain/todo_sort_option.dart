import 'package:flutter/material.dart';
import 'package:zen_do/core/l10n/app_l10n_extension.dart';
import 'package:zen_do/features/todos/l10n/todos_l10n_extension.dart';

enum TodoSortOption {
  custom,
  title,
  expirationDate,
  creationDate,
  completionDate;

  static Set<TodoSortOption> get uiOptions =>
      TodoSortOption.values.toSet()..remove(TodoSortOption.completionDate);
}

extension SortOptionX on TodoSortOption {
  String label(BuildContext context) {
    switch (this) {
      case TodoSortOption.custom:
        return context.appL10n.custom;
      case TodoSortOption.title:
        return context.todosL10n.todoTitle;
      case TodoSortOption.expirationDate:
        return context.todosL10n.expirationDate;
      case TodoSortOption.creationDate:
        return context.todosL10n.creationDate;
      case TodoSortOption.completionDate:
        throw UnimplementedError(
          'Label for completion date sorting. This should not be used in the UI.',
        );
    }
  }
}
