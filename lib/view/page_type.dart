import 'package:flutter/material.dart';

enum PageType {
  todos(Icons.view_list_outlined),
  habits(Icons.track_changes),
  notes(Icons.edit_note);

  final IconData icon;
  const PageType(this.icon);
}

extension PageTypeX on PageType {
  String label(BuildContext context) {
    return name; //TODO #28 translate page name as label
    /* final loc = AppLocalizations.of(context)!;
    switch (this) {
      case AppPage.todos:
        return loc.todos;
      case AppPage.habits:
        return loc.habits;
      case AppPage.notes:
        return loc.notes;
    } */
  }
}
