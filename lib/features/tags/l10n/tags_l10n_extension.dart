import 'package:flutter/widgets.dart';
import 'package:zen_do/features/tags/l10n/tags_localizations.dart';

extension TagsL10nX on BuildContext {
  TagsLocalizations get tagsL10n => TagsLocalizations.of(this);
}
