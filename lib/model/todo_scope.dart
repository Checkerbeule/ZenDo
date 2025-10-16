import 'package:flutter/material.dart';

enum TodoScope {
  daily('Täglich', Icons.today, Duration(days: 1), true),
  weekly('Wöchentlich', Icons.calendar_view_week, Duration(days: 7), true),
  monthly('Monatlich', Icons.calendar_month, Duration(days: 30), true),
  yearly('Jährlich', Icons.calendar_today, Duration(days: 365), true),
  backlog('Backlog', Icons.list_rounded, Duration.zero, false);

  final String name;
  final IconData icon;
  final Duration duration;
  final bool autoTransfer;
  const TodoScope(this.name, this.icon, this.duration, this.autoTransfer);
}
