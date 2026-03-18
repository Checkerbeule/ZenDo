import 'package:flutter/material.dart';
import 'package:zen_do/core/l10n/app_localizations.dart';

enum PageType {
  todos(),
  habits(),
  notes(),
  pomodoro();

  const PageType();
}

extension PageTypeX on PageType {
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (this) {
      case PageType.todos:
        return loc.todos;
      case PageType.habits:
        return loc.habits;
      case PageType.pomodoro:
        return 'Pomodoro';
      case PageType.notes:
        return loc.notes;
    }
  }

  IconData get icon {
    switch (this) {
      case PageType.todos:
        return Icons.format_list_bulleted_rounded;
      case PageType.habits:
        return Icons.track_changes;
      case PageType.pomodoro:
        return Icons.timer_outlined;
      case PageType.notes:
        return Icons.edit_note;
    }
  }
}
