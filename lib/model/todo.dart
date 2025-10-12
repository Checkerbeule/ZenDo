class ToDo {
  String title;
  String? description;
  DateTime creationDate;

  ToDo (this.title, this.description, this.creationDate);

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ToDo &&
      other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}