import 'package:flutter/material.dart';
import 'package:zen_do/config/localization/app_localizations.dart';

enum PageType {
  todos(Icons.view_list_outlined),
  habits(Icons.track_changes),
  notes(Icons.edit_note);

  final IconData icon;
  const PageType(this.icon);
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
}
