import 'package:drift/drift.dart';

mixin FractionalIndexTable on Table {
  TextColumn get fractionalIndex => text().withDefault(Constant("a0"))();
}

abstract class WithFractionalIndex {
  String get fractionalIndex;
}
