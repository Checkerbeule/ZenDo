import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zen_do/features/todos/l10n/todos_localizations.dart';

enum ListScope implements Comparable<ListScope> {
  day(Duration(days: 1), true),
  week(Duration(days: 7), true),
  month(Duration(days: 30), true),
  year(Duration(days: 365), true),
  backlog(Duration.zero, false);

  final Duration duration;
  final bool isAutoTransfer;

  const ListScope(this.duration, this.isAutoTransfer);

  @override
  int compareTo(ListScope other) {
    if (this == ListScope.backlog) {
      return other == ListScope.backlog ? 0 : 1;
    }
    if (other == ListScope.backlog) return -1;

    return duration.compareTo(other.duration);
  }

  // Hilfsmethode für die Migration
  static ListScope fromLegacyName(String name) {
    return switch (name.toLowerCase()) {
      'daily' => ListScope.day,
      'weekly' => ListScope.week,
      'monthly' => ListScope.month,
      'yearly' => ListScope.year,
      _ => ListScope.backlog,
    };
  }

  String get legacyName {
    return switch (this) {
      ListScope.day => 'daily',
      ListScope.week => 'weekly',
      ListScope.month => 'monthly',
      ListScope.year => 'yearly',
      ListScope.backlog => 'backlog',
    };
  }
}

extension ListScopeX on ListScope {
  String label(BuildContext context) {
    final loc = TodosLocalizations.of(context);
    switch (this) {
      case ListScope.day:
        return loc.day;
      case ListScope.week:
        return loc.week;
      case ListScope.month:
        return loc.month;
      case ListScope.year:
        return loc.year;
      case ListScope.backlog:
        return loc.backlog;
    }
  }

  String listName(BuildContext context) {
    final loc = TodosLocalizations.of(context);
    switch (this) {
      case ListScope.day:
        return loc.dailyList;
      case ListScope.week:
        return loc.weeklyList;
      case ListScope.month:
        return loc.monthlyList;
      case ListScope.year:
        return loc.yearlyList;
      case ListScope.backlog:
        return loc.backlog;
    }
  }

  IconData get icon {
    switch (this) {
      case ListScope.day:
        return Icons.today;
      case ListScope.week:
        return Icons.calendar_view_week;
      case ListScope.month:
        return Icons.calendar_month;
      case ListScope.year:
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
