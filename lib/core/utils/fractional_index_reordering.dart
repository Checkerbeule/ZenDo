import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/persistence/fractionalindex/fractional_index_table.dart';

extension FractionalIndexReordering<T extends WithFractionalIndex> on List<T> {
  /// Calculates the new fractional index for the element, that has been moved to [newIndex].
  /// Uses the lib [fractional_indexing_dart] to generate the actual fractional index.
  String generateNewFractionalIndex({
    required int oldIndex,
    required int newIndex,
  }) {
    final int targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (oldIndex == targetIndex) return this[oldIndex].fractionalIndex;

    String? previousIndex;
    String? nextIndex;

    if (targetIndex == 0) {
      previousIndex = null;
      nextIndex = this[0].fractionalIndex;
    } else if (targetIndex >= length - 1) {
      previousIndex = last.fractionalIndex;
      nextIndex = null;
    } else {
      if (oldIndex < targetIndex) {
        previousIndex = this[targetIndex].fractionalIndex;
        nextIndex = this[targetIndex + 1].fractionalIndex;
      } else {
        previousIndex = this[targetIndex - 1].fractionalIndex;
        nextIndex = this[targetIndex].fractionalIndex;
      }
    }

    return FractionalIndexing.generateKeyBetween(previousIndex, nextIndex);
  }
}
