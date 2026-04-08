import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/todos/data/todos.dart';

part 'todo_dto.freezed.dart';

@freezed
abstract class TodoDto with _$TodoDto {
  bool get hasTags => tagUuids.isNotEmpty;
  bool get isCompleted => completedAt != null;

  const TodoDto._();

  const factory TodoDto({
    required String uuid,
    required String title,
    String? description,
    required DateTime createdAt,
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
      uuid: todo.uuid,
      title: todo.title,
      description: todo.description,
      createdAt: entity.createdAt,
      expiresAt: todo.expiresAt,
      completedAt: todo.completedAt,
      scope: todo.scope,
      customOrder: todo.customOrder,
      tagUuids: tagUuids,
    );
  }

  bool get isExpired {
    // TODO may not be required anymore if willBeTransferred is enough
    if (expiresAt == null) {
      return false;
    } else {
      return DateTime.now().isAfter(expiresAt!);
    }
  }
}
