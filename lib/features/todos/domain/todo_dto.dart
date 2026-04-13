import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/todos/data/todos.dart';

part 'todo_dto.freezed.dart';

@freezed
abstract class TodoDto with _$TodoDto {
  const TodoDto._();

  const factory TodoDto({
    required String $uuid,
    required DateTime $createdAt,
    required String title,
    String? description,
    DateTime? expiresAt,
    DateTime? completedAt,
    required ListScope scope,
    required String customOrder,
    @Default({}) Set<String> tagUuids,
    @Default(false) bool willBeTransferred,
  }) = _TodoDto;

  factory TodoDto.fromDb({
    required Todo todo,
    required Entity entity,
    Set<String> tagUuids = const {},
  }) {
    return TodoDto(
      $uuid: todo.uuid,
      $createdAt: entity.createdAt,
      title: todo.title,
      description: todo.description,
      expiresAt: todo.expiresAt,
      completedAt: todo.completedAt,
      scope: todo.scope,
      customOrder: todo.customOrder,
      tagUuids: tagUuids,
    );
  }

  String get uuid => $uuid;
  DateTime get createdAt => $createdAt;

  bool get hasTags => tagUuids.isNotEmpty;
  bool get isCompleted => completedAt != null;

  bool get isExpired {
    // TODO may not be required anymore if willBeTransferred is enough
    if (expiresAt == null) {
      return false;
    } else {
      return DateTime.now().isAfter(expiresAt!);
    }
  }
}
