import 'package:flutter/material.dart';

class SliverTodoSortFilterAppBar extends StatelessWidget {
  const SliverTodoSortFilterAppBar({
    super.key,
    required this.sortOption,
    required this.sortOrder,
    required this.onSortChanged,
    //required this.onFilterChanged,
  });

  final SortOption sortOption;
  final SortOrder sortOrder;
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
              MenuItemButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sortOption.label(context)),
                    if (this.sortOption == sortOption) ...[
                      SizedBox(width: 5),
                      if (this.sortOption == SortOption.custom)
                        const Icon(Icons.swipe_vertical)
                      else if (sortOrder == SortOrder.ascending)
                        const Icon(Icons.arrow_upward)
                      else
                        const Icon(Icons.arrow_downward),
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
        IconButton(icon: Icon(Icons.filter_alt), onPressed: () {}),
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
