import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum ListScope {
  daily('Täglich', Icons.today, Duration(days: 1), true),
  weekly('Wöchentlich', Icons.calendar_view_week, Duration(days: 7), true),
  monthly('Monatlich', Icons.calendar_month, Duration(days: 30), true),
  yearly('Jährlich', Icons.calendar_today, Duration(days: 365), true),
  backlog('Backlog', Icons.list_rounded, Duration.zero, false);

  final String label;
  final IconData icon;
  final Duration duration;
  final bool autoTransfer;

  const ListScope(this.label, this.icon, this.duration, this.autoTransfer);
}

class ListScopeAdapter extends TypeAdapter<ListScope> {
  @override
  final int typeId = 2;

  @override
  ListScope read(BinaryReader reader) {
    final index = reader.readInt();
    return ListScope.values[index];
  }

  @override
  void write(BinaryWriter writer, ListScope obj) {
    writer.writeInt(obj.index);
  }
}
