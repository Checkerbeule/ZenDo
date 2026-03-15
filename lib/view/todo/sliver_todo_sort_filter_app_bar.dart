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

class SliverTodoSortFilterAppBar extends StatefulWidget {
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
  State<SliverTodoSortFilterAppBar> createState() =>
      _SliverTodoSortFilterAppBarState();
}

class _SliverTodoSortFilterAppBarState
    extends State<SliverTodoSortFilterAppBar> {
  late ScrollController _scrollController;
  double _leftFadeStart = 0.0;
  double _rightFadeEnd = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    final double max = pos.maxScrollExtent;
    final double current = pos.pixels;

    if (max <= 0) {
      if (_leftFadeStart != 0.0 || _rightFadeEnd != 1.0) {
        setState(() {
          _leftFadeStart = 0.0;
          _rightFadeEnd = 1.0;
        });
      }
      return;
    }

    double newLeft = current > 0 ? 0.05 : 0.0;

    double newRight = current < max ? 0.95 : 1.0;

    if (newLeft != _leftFadeStart || newRight != _rightFadeEnd) {
      setState(() {
        _leftFadeStart = newLeft;
        _rightFadeEnd = newRight;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = TagsLocalizations.of(context);
    final TagRepository tagRepository = context.read<TagRepository>();
    return SliverAppBar(
      pinned: false,
      floating: false,
      snap: false,
      toolbarHeight: 32,
      actionsPadding: const EdgeInsets.only(right: 22),
      titleSpacing: 0,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      title: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
          return ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, _leftFadeStart, _rightFadeEnd, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Padding(
              padding: EdgeInsetsGeometry.only(left: 5),
              child: StreamBuilder<List<Tag>>(
                stream: tagRepository.watchTags(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final tags = snapshot.data!;
                    if (tags.isEmpty) {
                      return Center(child: Text(loc.noTagsAvailable));
                    }

                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _handleScroll(),
                    );
                    return SizedBox(
                      height: 32,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 5),
                        itemBuilder: (context, index) {
                          return TagWidget.fromTag(
                            tag: tags[index],
                            isCompact: true,
                            isSelected: widget.selectedTagUuids.contains(
                              tags[index].uuid,
                            ),
                            onTap: (uuid) {
                              final newSelection = Set<String>.from(
                                widget.selectedTagUuids,
                              );
                              if (newSelection.contains(uuid)) {
                                newSelection.remove(uuid);
                              } else {
                                newSelection.add(uuid);
                              }
                              widget.onFilterChanged(newSelection);
                            },
                          );
                        },
                      ),
                    );
                  } else {
                    if (snapshot.hasError) {
                      return Text(
                        loc.errorLoadingTags,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return Text(
                      loc.loadingTags,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      actions: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.selectedTagUuids.isNotEmpty ? 32.0 : 0.0,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                    reverseCurve: Curves.easeIn,
                  ),
                  child: child,
                ),
              );
            },
            child: widget.selectedTagUuids.isNotEmpty
                ? InkWell(
                    radius: 20,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    onTap: () {
                      widget.selectedTagUuids.clear();
                      widget.onFilterChanged(widget.selectedTagUuids);
                    },
                    child: Badge(
                      key: ValueKey('clear_button'),
                      alignment: Alignment(1.5, 0),
                      padding: EdgeInsets.all(0),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      label: Text(
                        widget.selectedTagUuids.length.toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          widget.selectedTagUuids.clear();
                          widget.onFilterChanged(widget.selectedTagUuids);
                        },
                        icon: Icon(Icons.close, size: 22),
                        padding: EdgeInsets.all(5),
                      ),
                    ),
                  )
                : SizedBox(key: ValueKey('empty_space')),
          ),
        ),
        MenuAnchor(
          menuChildren: <Widget>[
            for (final sortOption in SortOption.values)
              if (!widget.excludedOptions.contains(sortOption))
                MenuItemButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sortOption.label(context),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (widget.sortOption == sortOption) ...[
                        const SizedBox(width: 5),
                        if (widget.sortOption == SortOption.custom)
                          Icon(
                            Icons.swipe_vertical,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          )
                        else if (widget.sortOrder == SortOrder.ascending)
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
                    final order = widget.sortOption == SortOption.custom
                        ? SortOrder.ascending
                        : widget.sortOption == sortOption &&
                              widget.sortOrder == SortOrder.ascending
                        ? SortOrder.descending
                        : SortOrder.ascending;
                    widget.onSortChanged(sortOption, order);
                  },
                ),
          ],
          builder: (context, controller, child) {
            return InkWell(
              radius: 20,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Badge(
                alignment: Alignment(1, 0),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                label: widget.sortOption == SortOption.custom
                    ? const Icon(
                        Icons.swipe_vertical,
                        size: 12,
                        color: Colors.white,
                      )
                    : Row(
                        children: [
                          Text(
                            '${widget.sortOption.label(context).substring(0, 1)} ',
                          ),
                          widget.sortOrder == SortOrder.ascending
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
                child: IconButton(
                  icon: const Icon(Icons.sort, size: 22),
                  padding: EdgeInsets.all(5),
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                ),
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
