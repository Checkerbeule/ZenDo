import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/persistence/fractionalindex/fractional_index_table.dart';

extension FractionalIndexReordering<T> on List<T> {
  /// Calculates the new fractional index for the element, that has been moved to [newIndex].
  /// Uses the lib [fractional_indexing_dart] to generate the actual fractional index.
  String generateNewFractionalIndex({
    required int oldIndex,
    required int newIndex,
    required String Function(T) getIndex,
  }) {
    return _generateIndex(
      list: this,
      oldIndex: oldIndex,
      newIndex: newIndex,
      getIndex: getIndex,
    );
  }
}

extension FractionalIndexReorderable<T extends Reorderable> on List<T> {
  /// Calculates the new fractional index for the element, that has been moved to [newIndex].
  /// Uses the lib [fractional_indexing_dart] to generate the actual fractional index.
  String generateNewFractionalIndex({
    required int oldIndex,
    required int newIndex,
  }) {
    return _generateIndex(
      list: this,
      oldIndex: oldIndex,
      newIndex: newIndex,
      getIndex: (reorderable) => reorderable.fractionalIndex,
    );
  }
}

String _generateIndex<T>({
  required List<T> list,
  required int oldIndex,
  required int newIndex,
  required String Function(T) getIndex,
}) {
  final int targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
  if (oldIndex == targetIndex) return getIndex(list[oldIndex]);

  String? previousIndex;
  String? nextIndex;

  if (targetIndex == 0) {
    previousIndex = null;
    nextIndex = getIndex(list[0]);
  } else if (targetIndex >= list.length - 1) {
    previousIndex = getIndex(list.last);
    nextIndex = null;
  } else {
    if (oldIndex < targetIndex) {
      previousIndex = getIndex(list[targetIndex]);
      nextIndex = getIndex(list[targetIndex + 1]);
    } else {
      previousIndex = getIndex(list[targetIndex - 1]);
      nextIndex = getIndex(list[targetIndex]);
    }
  }

  return FractionalIndexing.generateKeyBetween(previousIndex, nextIndex);
}
