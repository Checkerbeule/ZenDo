import 'package:flutter/material.dart';

class SliverTodoSortFilterAppBar extends StatelessWidget {
  SliverTodoSortFilterAppBar({
    super.key,
    required this.sortOption,
    required this.sortOrder,
    Set<SortOption>? excludedOptions,
    required this.onSortChanged,
    //required this.onFilterChanged,
  }) : excludedOptions = excludedOptions ?? {};

  final SortOption sortOption;
  final SortOrder sortOrder;
  final Set<SortOption> excludedOptions;
  final void Function(SortOption option, SortOrder order) onSortChanged;
  //final void Function() onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      actionsPadding: const EdgeInsets.only(right: 10),
      pinned: false,
      floating: true,
      snap: true,
      toolbarHeight: 40,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      title: Text(
        'Aufgaben sortieren und filtern',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        MenuAnchor(
          menuChildren: <Widget>[
            for (final sortOption in SortOption.values)
              if (!excludedOptions.contains(sortOption))
                MenuItemButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sortOption.label(context),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (this.sortOption == sortOption) ...[
                        SizedBox(width: 5),
                        if (this.sortOption == SortOption.custom)
                          Icon(
                            Icons.swipe_vertical,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        else if (sortOrder == SortOrder.ascending)
                          Icon(
                            Icons.arrow_upward,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        else
                          Icon(
                            Icons.arrow_downward,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ],
                  ),
                  onPressed: () {
                    final order = this.sortOption == SortOption.custom
                        ? SortOrder.ascending
                        : this.sortOption == sortOption &&
                              sortOrder == SortOrder.ascending
                        ? SortOrder.descending
                        : SortOrder.ascending;
                    onSortChanged(sortOption, order);
                  },
                ),
          ],
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.sort),
            );
          },
        ),
        IconButton(icon: Icon(Icons.filter_alt), onPressed: null),
      ],
    );
  }
}

enum SortOption { custom, title, expirationDate, creationDate }

extension SortOptionX on SortOption {
  String label(BuildContext context) {
    return name;
  }
}

enum SortOrder { ascending, descending }
