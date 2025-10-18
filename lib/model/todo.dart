import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  final DateTime creationDate;

  Todo(this.title, this.description) : creationDate = DateTime.now();

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Todo && other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}
