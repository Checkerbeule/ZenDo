import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/ui/tag_widget.dart';
import 'package:zen_do/localization/generated/app/app_localizations.dart';
import 'package:zen_do/localization/generated/tags/tags_localizations.dart';
import 'package:zen_do/localization/generated/todo/todo_localizations.dart';

enum SortOption { custom, title, expirationDate, creationDate }

enum SortOrder { ascending, descending }

class SliverTodoSortFilterAppBar extends StatelessWidget {
  final SortOption sortOption;
  final SortOrder sortOrder;
  final Set<SortOption> excludedOptions;
  final void Function(SortOption option, SortOrder order) onSortChanged;
  final Set<String> selectedTagUuids;
  final void Function(Set<String> selectedTagUuids) onFilterChanged;

  SliverTodoSortFilterAppBar({
    super.key,
    required this.sortOption,
    required this.sortOrder,
    Set<SortOption>? excludedOptions,
    required this.onSortChanged,
    required this.selectedTagUuids,
    required this.onFilterChanged,
  }) : excludedOptions = excludedOptions ?? {};

  @override
  Widget build(BuildContext context) {
    final loc = TagsLocalizations.of(context);
    final TagRepository tagRepository = context.read<TagRepository>();
    return SliverAppBar(
      pinned: false,
      floating: false,
      snap: false,
      toolbarHeight: 30,
      actionsPadding: const EdgeInsets.only(right: 22),
      titleSpacing: 10,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      title: StreamBuilder<List<Tag>>(
        stream: tagRepository.watchTags(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              loc.loadingTags,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            );
          }
          if (snapshot.hasError) {
            return Text(
              loc.errorLoadingTags,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            );
          }

          final tags = snapshot.data ?? [];
          if (tags.isEmpty) {
            return Center(child: Text(loc.noTagsAvailable));
          }

          return SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              padding: const EdgeInsets.symmetric(vertical: 5),
              separatorBuilder: (context, index) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                return TagWidget.fromTag(
                  tag: tags[index],
                  isCompact: true,
                  isSelected: selectedTagUuids.contains(tags[index].uuid),
                  onTap: (uuid) {
                    final newSelection = Set<String>.from(selectedTagUuids);
                    if (newSelection.contains(uuid)) {
                      newSelection.remove(uuid);
                    } else {
                      newSelection.add(uuid);
                    }
                    onFilterChanged(newSelection);
                  },
                );
              },
            ),
          );
        },
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
                        const SizedBox(width: 5),
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
                            size: 18,
                          )
                        else
                          Icon(
                            Icons.arrow_downward,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
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
            return Badge(
              label: sortOption == SortOption.custom
                  ? const Icon(
                      Icons.swipe_vertical,
                      size: 12,
                      color: Colors.white,
                    )
                  : Row(
                      children: [
                        Text('${sortOption.label(context).substring(0, 1)} '),
                        sortOrder == SortOrder.ascending
                            ? const Icon(
                                Icons.arrow_upward,
                                size: 12,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.arrow_downward,
                                size: 12,
                                color: Colors.white,
                              ),
                      ],
                    ),
              alignment: Alignment(1, 0),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: IconButton(
                icon: const Icon(Icons.sort, size: 18),
                padding: EdgeInsets.all(5),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

extension SortOptionX on SortOption {
  String label(BuildContext context) {
    final loc = TodoLocalizations.of(context);
    switch (this) {
      case SortOption.custom:
        return AppLocalizations.of(context).custom;
      case SortOption.title:
        return loc.todoTitle;
      case SortOption.expirationDate:
        return loc.expirationDate;
      case SortOption.creationDate:
        return loc.creationDate;
    }
  }
}
