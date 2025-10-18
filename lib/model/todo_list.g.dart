// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoListAdapter extends TypeAdapter<TodoList> {
  @override
  final int typeId = 1;

  @override
  TodoList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoList(
      fields[0] as ListScope,
    )
      ..todos = (fields[1] as List).cast<Todo>().toSet()
      ..doneTodos = (fields[2] as List).cast<Todo>();
  }

  @override
  void write(BinaryWriter writer, TodoList obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.scope)
      ..writeByte(1)
      ..write(obj.todos.toList())
      ..writeByte(2)
      ..write(obj.doneTodos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
