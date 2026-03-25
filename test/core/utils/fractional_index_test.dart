import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/core/utils/fractional_index_reordering.dart';

void main() {
  group('Basic Reordering (No Filters)', () {
    test(
      'FractionalIndexReordering generateFractionalIndex between returns correct index',
      () {
        final List<String> list = ['a0', 'a1', 'a2'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          oldIndex: 0,
          newIndex: 2,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'a1V');
      },
    );

    test(
      'FractionalIndexReordering generateFractionalIndex at end returns correct index',
      () {
        final List<String> list = ['a0', 'a1', 'a2'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          oldIndex: 0,
          newIndex: 3,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'a3');
      },
    );

    test(
      'FractionalIndexReordering generateFractionalIndex at start returns correct index',
      () {
        final List<String> list = ['a0', 'a1', 'a2'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          oldIndex: 1,
          newIndex: 0,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'Zz');
      },
    );
  });

  group('Filtered Reordering (With unfilteredList)', () {
    test(
      'FractionalIndexReordering generateFractionalIndex between with unfilteredList returns correct index',
      () {
        final List<String> list = ['a0', 'a1', 'a3'];
        final List<String> unfilteredList = ['a0', 'a1', 'a2', 'a3'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          unfilteredList: unfilteredList,
          oldIndex: 0,
          newIndex: 2,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'a1V');
      },
    );

    test(
      'FractionalIndexReordering generateFractionalIndex at end with unfilteredList returns correct index',
      () {
        final List<String> list = ['a0', 'a1', 'a2'];
        final List<String> unfilteredList = ['a0', 'a1', 'a2', 'a3'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          unfilteredList: unfilteredList,
          oldIndex: 1,
          newIndex: 3,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'a2V');
      },
    );

    test(
      'FractionalIndexReordering generateFractionalIndex at end with unfilteredList returns correct index',
      () {
        final List<String> list = ['a0', 'a1', 'a3'];
        final List<String> unfilteredList = ['a0', 'a1', 'a2', 'a3'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          unfilteredList: unfilteredList,
          oldIndex: 1,
          newIndex: 3,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'a4');
      },
    );

    test(
      'FractionalIndexReordering generateFractionalIndex at start with unfilteredList returns correct index',
      () {
        final List<String> list = ['a1', 'a2', 'a3'];
        final List<String> unfilteredList = ['a0', 'a1', 'a2', 'a3'];

        final newKey = FractionalIndexReordering.generateFractionalIndex(
          list: list,
          unfilteredList: unfilteredList,
          oldIndex: 1,
          newIndex: 0,
          getIndex: (elem) => elem,
        );

        expect(newKey, 'Zz');
      },
    );

    test(
      'FractionalIndexReordering generateFractionalIndex with unfilteredList throws ArgumentError on non existent element',
      () {
        final List<String> list = ['a0', 'a1', 'a2'];
        final List<String> unfilteredList = ['a0', 'a2', 'a3'];

        expect(
          () => FractionalIndexReordering.generateFractionalIndex(
            list: list,
            unfilteredList: unfilteredList,
            oldIndex: 0,
            newIndex: 2,
            getIndex: (elem) => elem,
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
