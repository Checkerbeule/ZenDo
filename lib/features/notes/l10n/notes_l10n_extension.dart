import 'package:flutter/widgets.dart';
import 'package:zen_do/features/notes/l10n/notes_localizations.dart';

extension NotesL10nX on BuildContext {
  NotesLocalizations get notesL10n => NotesLocalizations.of(this);
}
