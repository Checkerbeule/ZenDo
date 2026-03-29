import 'package:zen_do/core/persistence/app_database.dart';

class TodoWithTags {
  final Todo todo;
  final List<Tag> tags;

  TodoWithTags({required this.todo, required this.tags});
}