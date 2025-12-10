import 'package:flutter/material.dart';
import 'package:zen_do/config/localization/app_localizations.dart';

enum PageType {
  todos(),
  habits(),
  notes();

  const PageType();
}

extension PageTypeX on PageType {
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case PageType.todos:
        return loc.todos;
      case PageType.habits:
        return loc.habits;
      case PageType.notes:
        return loc.notes;
    }
  }

  IconData get icon {
    switch (this) {
      case PageType.todos:
        return Icons.view_list_outlined;
      case PageType.habits:
        return Icons.track_changes;
      case PageType.notes:
        return Icons.edit_note;
    }
  }
}
