import 'package:drift/drift.dart';

enum SortOrder { ascending, descending }

extension SortOrderDriftMapping on SortOrder {
  OrderingMode get toDrift => this == SortOrder.descending
      ? OrderingMode.desc
      : OrderingMode.asc;
}