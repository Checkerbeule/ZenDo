// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'tags_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class TagsLocalizationsDe extends TagsLocalizations {
  TagsLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get addTag => 'Tag hinzufügen';

  @override
  String deleteTagMessage(String tagName) {
    return 'Tag \'$tagName\' wirklich löschen? Objekte mit diesem Tag bleiben erhalten, verlieren aber den Tag.';
  }

  @override
  String get deleteTagTitle => 'Tag löschen?';

  @override
  String get errorLoadingTags => 'Beim Laden der Tags ist ein Fehler aufgetreten.';

  @override
  String get manageTagsScreenHeader => 'Verwalte deine Tags, um Inhalte zu organisieren';

  @override
  String get noTagsAvailable => 'Noch keine Tags vorhanden.\nFüge einige hinzu!';
}
