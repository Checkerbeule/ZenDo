enum TodoScope {

  daily(Duration(days: 1), autoTransfer: true),
  weekly(Duration(days: 7), autoTransfer: true),
  monthly(Duration(days: 30), autoTransfer: true),
  yearly(Duration(days: 365), autoTransfer: true),
  backlog(Duration.zero, autoTransfer: false);

  final Duration duration;
  final bool autoTransfer;
  const TodoScope(this.duration, {this.autoTransfer = true});
}