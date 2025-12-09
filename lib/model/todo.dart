import 'package:hive/hive.dart';
import 'package:zen_do/model/list_scope.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  late String _title;
  String get title => _title;
  set title(String title) {
    if (title.isEmpty) {
      throw ArgumentError('title must not be empty!');
    }
    _title = title.trim();
  }

  @HiveField(1)
  String? _description;
  String? get description => _description;
  set description(String? description) {
    _description = description?.trim();
  }

  @HiveField(2)
  final DateTime creationDate;

  @HiveField(3)
  DateTime? expirationDate;

  @HiveField(4)
  DateTime? completionDate;

  @HiveField(5)
  ListScope? listScope;

  @HiveField(6)
  int? order;

  Todo({required String title, String? description})
    : creationDate = DateTime.now() {
    this.title = title;
    this.description = description;
  }

  Todo._internal({
    required String title,
    String? description,
    required this.creationDate,
    this.expirationDate,
    this.completionDate,
    this.listScope,
    this.order,
  }) {
    this.title = title;
    this.description = description;
  }

  Todo copyWith({
    String? title,
    String? description,
    DateTime? creationDate,
    DateTime? expirationDate,
    DateTime? completionDate,
    ListScope? listScope,
    int? order,
  }) {
    return Todo._internal(
      title: title ?? this.title,
      description: description ?? this.description,
      creationDate: creationDate ?? this.creationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      completionDate: completionDate ?? this.completionDate,
      listScope: listScope ?? this.listScope,
      order: order ?? this.order,
    );
  }

  Todo.copy(Todo other)
    : creationDate = other.creationDate,
      expirationDate = other.expirationDate,
      completionDate = other.completionDate,
      listScope = other.listScope,
      order = other.order {
    title = other.title;
    description = other.description;
  }

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
