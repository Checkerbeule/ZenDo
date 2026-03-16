// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'tags_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TagsLocalizationsEn extends TagsLocalizations {
  TagsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addNewTag => 'Add new Tag';

  @override
  String get addTag => 'Add Tag';

  @override
  String get connectedTags => 'Connected tags';

  @override
  String deleteTagMessage(String tagName) {
    return 'Delete the tag \'$tagName\'?\nObjects with this tag will remain but lose the tag.';
  }

  @override
  String get deleteTagTitle => 'Delete tag?';

  @override
  String get editTag => 'Edit Tag';

  @override
  String get errorLoadingTags => 'An error occurred while loading tags.';

  @override
  String get loadingTags => 'Loading tags...';

  @override
  String get manageTagsScreenHeader => 'Manage your tags to organize content';

  @override
  String get noTagsAddSome => 'There are no tags yet.\nAdd some!';

  @override
  String get noTagsAvailable => 'No tags available for filtering';

  @override
  String get tagColorHeading => 'Choose a color';

  @override
  String get tagColorSubheading => 'Color gradations';

  @override
  String get tagNameDecoration => 'Tag name';

  @override
  String get tagNameLabel => 'Tag name';
}
