import 'package:flutter/material.dart';
import 'package:zen_do/config/localization/generated/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
    return SliverAppBar(
      actionsPadding: const EdgeInsets.only(right: 10),
      pinned: false,
      floating: false,
      snap: false,
      toolbarHeight: 40,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      title: Row(
        children: [
          Text(
            '${loc.sorting}: ${sortOption.label(context)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (sortOption != SortOption.custom) ...[
            SizedBox(width: 5),
            if (sortOrder == SortOrder.ascending) ...[
              Icon(
                Icons.arrow_upward,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ] else ...[
              Icon(
                Icons.arrow_downward,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ],
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
                            size: 20,
                          )
                        else if (sortOrder == SortOrder.ascending)
                          Icon(
                            Icons.arrow_upward,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          )
                        else
                          Icon(
                            Icons.arrow_downward,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
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
        /* if (filter active) ...[
          Badge(
            label: Text('0'),
            offset: Offset(1, 15),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(icon: Icon(Icons.filter_alt), onPressed: null),
          ),
        ] else  */
        ...[IconButton(icon: Icon(Icons.filter_alt), onPressed: null)],
      ],
    );
  }
}

enum SortOption { custom, title, expirationDate, creationDate }

extension SortOptionX on SortOption {
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (this) {
      case SortOption.custom:
        return loc.custom;
      case SortOption.title:
        return loc.todoTitle;
      case SortOption.expirationDate:
        return loc.expirationDate;
      case SortOption.creationDate:
        return loc.creationDate;
    }
  }
}

enum SortOrder { ascending, descending }
