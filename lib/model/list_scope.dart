import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zen_do/config/localization/app_localizations.dart';

enum ListScope {
  daily(Icons.today, Duration(days: 1), true),
  weekly(Icons.calendar_view_week, Duration(days: 7), true),
  monthly(Icons.calendar_month, Duration(days: 30), true),
  yearly(Icons.calendar_today, Duration(days: 365), true),
  backlog(Icons.list_rounded, Duration.zero, false);

  final IconData icon;
  final Duration duration;
  final bool isAutoTransfer;

  const ListScope(this.icon, this.duration, this.isAutoTransfer);
}

extension ListScopeX on ListScope {
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case ListScope.daily:
        return loc.daily;
      case ListScope.weekly:
        return loc.weekly;
      case ListScope.monthly:
        return loc.monthly;
      case ListScope.yearly:
        return loc.yearly;
      case ListScope.backlog:
        return loc.backlog;
    }
  }
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
