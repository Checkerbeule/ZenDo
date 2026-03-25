import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';

/// A utility class for calculating fractional indices when reordering elements in a list.
///
/// This class handles both simple lists and filtered views by optionally
/// providing an [unfilteredList] to maintain the correct logical
/// position within the entire dataset.
class FractionalIndexReordering {
  /// Calculates a new fractional index for an element moved from [oldIndex]
  /// to [newIndex] within a given [list].
  ///
  /// Uses the `fractional_indexing_dart` library to generate the actual
  /// string key between the identified neighbors.
  ///
  /// [list]: The current (potentially filtered) list where the reorder occurs.
  /// [unfilteredList]: (Optional) The complete, unfiltered list of all elements.
  ///   Required to ensure the moved element lands logically immediately after
  ///   the chosen predecessor, even if some elements are currently hidden by filters.
  /// [oldIndex]: The original index of the element in [list].
  /// [newIndex]: The destination index provided by the reorder widget
  ///   (e.g., `ReorderableListView`).
  /// [getIndex]: A callback function to extract the fractional index string
  ///   from an element of type [T].
  ///
  /// Returns a [String] representing the new sortable index.
  static String generateFractionalIndex<T>({
    required List<T> list,
    List<T>? unfilteredList,
    required int oldIndex,
    required int newIndex,
    required String Function(T) getIndex,
  }) {
    final int targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;

    if (oldIndex == targetIndex) return getIndex(list[oldIndex]);

    T? previousElem;
    T? nextElem;

    if (targetIndex == 0) {
      previousElem = null;
      nextElem = list[0];
    } else if (targetIndex >= list.length - 1) {
      previousElem = list.last;
      nextElem = null;
    } else {
      if (oldIndex < targetIndex) {
        previousElem = list[targetIndex];
        nextElem = list[targetIndex + 1];
      } else {
        previousElem = list[targetIndex - 1];
        nextElem = list[targetIndex];
      }
    }

    if (unfilteredList != null) {
      nextElem = _findTrueNext(previousElem, unfilteredList);
    }

    final previousIndex = previousElem != null ? getIndex(previousElem) : null;
    final nextIndex = nextElem != null ? getIndex(nextElem) : null;
    return FractionalIndexing.generateKeyBetween(previousIndex, nextIndex);
  }

  /// Internal helper to find the immediate next element in the [unfilteredList].
  ///
  /// This prevents the moved item from skipping over invisible (filtered) elements in the entire dataset.
  ///
  /// [previousElem]: The element identified as the predecessor.
  ///   If `null`, the "next" element is considered the first item of the [unfilteredList].
  /// [unfilteredList]: The complete, unfiltered dataset.
  ///
  /// Throws an [ArgumentError] if [previousElem] is not found in [unfilteredList].
  static T? _findTrueNext<T>(T? previousElem, List<T> unfilteredList) {
    if (previousElem == null) {
      return unfilteredList.firstOrNull;
    }

    final int indexInUnfilteredList = unfilteredList.indexOf(previousElem);

    if (indexInUnfilteredList < 0) {
      throw ArgumentError(
        "Element $previousElem could not be found in unfiltered list but was determined as previous element in given list!",
      );
    }

    if (indexInUnfilteredList + 1 < unfilteredList.length) {
      return unfilteredList.elementAt(indexInUnfilteredList + 1);
    }
    return null;
  }
}
