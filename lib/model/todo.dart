import 'package:hive/hive.dart';
import 'package:zen_do/model/list_scope.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  final DateTime creationDate;

  @HiveField(3)
  DateTime? expirationDate;

  @HiveField(4)
  DateTime? completionDate;

  Todo(this.title, [this.description]) : creationDate = DateTime.now();

  bool toBeTransferred(Duration durationOfNextListScope) {
    if (expirationDate == null) {
      return false;
    }
    final transferDate = expirationDate!.subtract(durationOfNextListScope);
    return DateTime.now().isAfter(transferDate);
  }

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Todo && other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}
