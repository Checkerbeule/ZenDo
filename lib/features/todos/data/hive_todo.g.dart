// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_todo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveTodoAdapter extends TypeAdapter<HiveTodo> {
  @override
  final int typeId = 0;

  @override
  HiveTodo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTodo(
        id: fields[7] as String?,
        expirationDate: fields[3] as DateTime?,
        creationDate: fields[2] as DateTime?,
        listScope: fields[5] as ListScope?,
        tagUuids: (fields[8] as List?)?.cast<String>().toSet(),
        title: fields[0] as String,
      )
      .._title = fields[0] as String
      .._description = fields[1] as String?
      ..completionDate = fields[4] as DateTime?
      ..order = fields[6] as int?;
  }

  @override
  void write(BinaryWriter writer, HiveTodo obj) {
    writer
      ..writeByte(9)
      ..writeByte(7)
      ..write(obj.id)
      ..writeByte(0)
      ..write(obj._title)
      ..writeByte(1)
      ..write(obj._description)
      ..writeByte(2)
      ..write(obj.creationDate)
      ..writeByte(3)
      ..write(obj.expirationDate)
      ..writeByte(4)
      ..write(obj.completionDate)
      ..writeByte(5)
      ..write(obj.listScope)
      ..writeByte(6)
      ..write(obj.order)
      ..writeByte(8)
      ..write(obj.tagUuids.toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
