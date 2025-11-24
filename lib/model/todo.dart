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

  @HiveField(5)
  ListScope? listScope;

  Todo({required this.title, this.description}) : creationDate = DateTime.now();

  Todo._internal({
    required this.title,
    this.description,
    required this.creationDate,
    this.expirationDate,
    this.completionDate,
    this.listScope,
  });

  Todo copyWith({
    String? title,
    String? description,
    DateTime? creationDate,
    DateTime? expirationDate,
    DateTime? completionDate,
    ListScope? listScope,
  }) {
    return Todo._internal(
      title: title ?? this.title,
      description: description ?? this.description,
      creationDate: creationDate ?? this.creationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      completionDate: completionDate ?? this.completionDate,
      listScope: listScope ?? this.listScope,
    );
  }

  Todo.copy(Todo other)
    : title = other.title,
      description = other.description,
      creationDate = other.creationDate,
      expirationDate = other.expirationDate,
      completionDate = other.completionDate,
      listScope = other.listScope;

  bool get isExpired {
    if (expirationDate == null) {
      return false;
    } else {
      return DateTime.now().isAfter(expirationDate!);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.title == title &&
        other.description == description &&
        other.creationDate == creationDate &&
        other.expirationDate == expirationDate &&
        other.completionDate == completionDate &&
        other.listScope == listScope;
  }

  @override
  int get hashCode => Object.hash(
        title,
        description,
        creationDate,
        expirationDate,
        completionDate,
        listScope,
      );
}
