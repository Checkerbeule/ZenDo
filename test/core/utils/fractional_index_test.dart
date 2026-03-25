import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/core/persistence/fractionalindex/fractional_index_table.dart';
import 'package:zen_do/core/utils/fractional_index_reordering.dart';

main() {
  test(
    'FractionalIndexReordering generateFractionalIndex between returns correct index',
    () {
      final List<Reorderable> list = [
        ReorderableTestObject('a0'),
        ReorderableTestObject('a1'),
        ReorderableTestObject('a2'),
      ];

      final newKey = FractionalIndexReordering.generateFractionalIndex(
        list: list,
        oldIndex: 0,
        newIndex: 2,
        getIndex: (testObj) => testObj.fractionalIndex,
      );

      expect(newKey, 'a1V');
    },
  );

  test(
    'FractionalIndexReordering generateFractionalIndex at end returns correct index',
    () {
      final List<Reorderable> list = [
        ReorderableTestObject('a0'),
        ReorderableTestObject('a1'),
        ReorderableTestObject('a2'),
      ];

      final newKey = FractionalIndexReordering.generateFractionalIndex(
        list: list,
        oldIndex: 0,
        newIndex: 3,
        getIndex: (testObj) => testObj.fractionalIndex,
      );

      expect(newKey, 'a3');
    },
  );

  test(
    'FractionalIndexReordering generateFractionalIndex at start returns correct index',
    () {
      final List<Reorderable> list = [
        ReorderableTestObject('a0'),
        ReorderableTestObject('a1'),
        ReorderableTestObject('a2'),
      ];

      final newKey = FractionalIndexReordering.generateFractionalIndex(
        list: list,
        oldIndex: 1,
        newIndex: 0,
        getIndex: (testObj) => testObj.fractionalIndex,
      );

      expect(newKey, 'Zz');
    },
  );
}

class ReorderableTestObject implements Reorderable {
  @override
  String fractionalIndex;

  ReorderableTestObject(this.fractionalIndex);
}
