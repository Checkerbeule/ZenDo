class Todo {
  String title;
  String? description;
  final DateTime creationDate;

  Todo (this.title, this.description) : creationDate = DateTime.now();

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Todo &&
      other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}