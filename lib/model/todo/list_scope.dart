import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zen_do/config/localization/generated/app_localizations.dart';

enum ListScope {
  daily(Duration(days: 1), true),
  weekly(Duration(days: 7), true),
  monthly(Duration(days: 30), true),
  yearly(Duration(days: 365), true),
  backlog(Duration.zero, false);

  final Duration duration;
  final bool isAutoTransfer;

  const ListScope(this.duration, this.isAutoTransfer);
}

extension ListScopeX on ListScope {
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (this) {
      case ListScope.daily:
        return loc.daily_adv;
      case ListScope.weekly:
        return loc.weekly_adv;
      case ListScope.monthly:
        return loc.monthly_adv;
      case ListScope.yearly:
        return loc.yearly_adv;
      case ListScope.backlog:
        return loc.backlog;
    }
  }

  String labelAdj(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (this) {
      case ListScope.daily:
        return loc.daily_adj;
      case ListScope.weekly:
        return loc.weekly_adj;
      case ListScope.monthly:
        return loc.monthly_adj;
      case ListScope.yearly:
        return loc.yearly_adj;
      case ListScope.backlog:
        return loc.backlog.toLowerCase();
    }
  }

  IconData get icon {
    switch (this) {
      case ListScope.daily:
        return Icons.today;
      case ListScope.weekly:
        return Icons.calendar_view_week;
      case ListScope.monthly:
        return Icons.calendar_month;
      case ListScope.yearly:
        return Icons.calendar_today;
      case ListScope.backlog:
        return Icons.list_rounded;
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
