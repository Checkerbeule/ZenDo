import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:zen_do/core/app/app_settings_service.dart';
import 'package:zen_do/core/l10n/app_localizations.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/hive_todo.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';
import 'package:zen_do/features/todos/l10n/todos_localizations.dart';
import 'package:zen_do/features/todos/ui/sliver_todo_sort_filter_app_bar.dart';
import 'package:zen_do/features/todos/ui/todo_widget.dart';
import 'package:zen_do/features/todos/ui/todo_edit_sheet.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

Logger logger = Logger(level: Level.debug);

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key, required this.list});

  final TodoList list;

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late final AppSettingsService settings;
  SortOption sortOption = SortOption.custom;
  SortOrder sortOrder = SortOrder.ascending;

  List<HiveTodo> getSortedAndFilteredTodos(Set<String> tagFilter) {
    final todos = List<HiveTodo>.from(widget.list.todos);
    if (tagFilter.isNotEmpty) {
      todos.retainWhere(
        (t) => t.tagUuids.any((tagUuid) => tagFilter.contains(tagUuid)),
      );
    }

    switch (sortOption) {
      case SortOption.custom:
        todos.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
        break;
      case SortOption.title:
        todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SortOption.expirationDate:
        todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.expirationDate!.compareTo(b.expirationDate!)
              : b.expirationDate!.compareTo(a.expirationDate!),
        );
        break;
      case SortOption.creationDate:
        todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.creationDate.compareTo(b.creationDate)
              : b.creationDate.compareTo(a.creationDate),
        );
        break;
    }
    return todos;
  }

  Future<void> _loadSettings() async {
    final settingsService = await SharedPrefsAppSettingsService.getInstance();
    if (!mounted) return;

    settings = settingsService;
    final loadedSortOption = settingsService.getSortOption(widget.list.scope);
    final loadedSortOrder = settingsService.getSortOrder(widget.list.scope);

    if (!mounted) return;
    setState(() {
      sortOption = loadedSortOption ?? sortOption;
      sortOrder = loadedSortOrder ?? sortOrder;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final loc = TodosLocalizations.of(context);
    final list = widget.list;
    final listScope = list.scope;
    final Set<SortOption> excludedSortOptions = listScope == ListScope.backlog
        ? {SortOption.expirationDate}
        : {};
    final tagFilter = context.watch<TodoState>().tagFilter;

    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        final listManager = todoState.listManager!;
        final ListScope? nextListScope = listManager
            .getNextList(listScope)
            ?.scope;
        final ListScope? previousListScope = listManager
            .getPreviousList(listScope)
            ?.scope;
        final isFirstList = nextListScope == null;
        final isLastList = previousListScope == null;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverTodoSortFilterAppBar(
                key: PageStorageKey('sort_filter_bar_${listScope.name}'),
                sortOption: sortOption,
                sortOrder: sortOrder,
                excludedOptions: excludedSortOptions,
                onSortChanged: (option, order) {
                  setState(() {
                    sortOption = option;
                    sortOrder = order;
                  });
                  unawaited(settings.saveSortOption(listScope, sortOption));
                  unawaited(settings.saveSortOrder(listScope, sortOrder));
                },
                selectedTagUuids: tagFilter,
                onFilterChanged: (updatedTagFilter) {
                  context.read<TodoState>().updateTagFilter(updatedTagFilter);
                },
              ),

              SliverAnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: getSortedAndFilteredTodos(tagFilter).isEmpty
                    ? SliverToBoxAdapter(
                        key: const ValueKey('empty_state'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 24.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tagFilter.isNotEmpty
                                    ? Icons.filter_list_alt
                                    : Icons.done_all_rounded,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.noTodosFound,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                tagFilter.isNotEmpty
                                    ? loc.checkTodoFilters
                                    : loc.everythingDone,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverReorderableList(
                        key: const ValueKey('todo_list'),
                        itemCount: getSortedAndFilteredTodos(tagFilter).length,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: 1.01,
                                child: Material(
                                  elevation: 5,
                                  color: Colors.transparent,
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          if (sortOption == SortOption.custom) {
                            setState(() {
                              final moved = getSortedAndFilteredTodos(
                                tagFilter,
                              )[oldIndex];
                              final previous = newIndex == 0
                                  ? null
                                  : getSortedAndFilteredTodos(
                                      tagFilter,
                                    )[newIndex - 1];
                              list.reorder(moved, previous);
                            });
                          }
                        },
                        itemBuilder: (context, index) {
                          final todo = getSortedAndFilteredTodos(
                            tagFilter,
                          )[index];

                          return ReorderableDelayedDragStartListener(
                            enabled: sortOption == SortOption.custom,
                            key: ValueKey(todo.id),
                            index: index,
                            child: Dismissible(
                              key: ValueKey(todo.id),
                              background: Container(
                                padding: const EdgeInsetsGeometry.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                alignment: Alignment.centerLeft,
                                child: !isLastList
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${loc.moveTo}\n'
                                            '${previousListScope.listName(context)}',
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                              secondaryBackground: !isFirstList
                                  ? Container(
                                      padding:
                                          const EdgeInsetsGeometry.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainer,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Icon(
                                            Icons.arrow_back,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${loc.moveTo}\n'
                                            '${nextListScope.listName(context)}',
                                            textAlign: TextAlign.end,
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                              direction: isFirstList && isLastList
                                  ? DismissDirection.none
                                  : isFirstList
                                  ? DismissDirection.startToEnd
                                  : isLastList
                                  ? DismissDirection.endToStart
                                  : DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                late final bool isMovable;
                                late final TodoList? destinationList;
                                if (direction == DismissDirection.startToEnd) {
                                  destinationList = listManager.getPreviousList(
                                    listScope,
                                  );
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  destinationList = listManager.getNextList(
                                    listScope,
                                  );
                                }
                                isMovable =
                                    destinationList?.isTodoTitleVacant(
                                      getSortedAndFilteredTodos(
                                        tagFilter,
                                      )[index].title,
                                    ) ??
                                    false;
                                if (!isMovable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(loc.shiftNotPossible),
                                    ),
                                  );
                                  return false;
                                }
                                return true;
                              },
                              onDismissed: (direction) async {
                                final todoToMove = getSortedAndFilteredTodos(
                                  tagFilter,
                                )[index];
                                final retainedExpirationDate =
                                    todoToMove.expirationDate;
                                final retainedOrder = todoToMove.order;

                                final messenger = ScaffoldMessenger.of(context);
                                final appLocalizations = AppLocalizations.of(
                                  context,
                                );

                                String destination = '';
                                bool isMoved = false;
                                if (direction == DismissDirection.startToEnd) {
                                  destination =
                                      listManager
                                          .getPreviousList(list.scope)
                                          ?.scope
                                          .listName(context) ??
                                      loc.next;
                                  isMoved = await todoState
                                      .performAcitionOnList<bool>(
                                        () => listManager.moveToPreviousList(
                                          todoToMove,
                                        ),
                                      );
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  destination =
                                      listManager
                                          .getNextList(list.scope)
                                          ?.scope
                                          .listName(context) ??
                                      loc.previous;
                                  isMoved = await todoState
                                      .performAcitionOnList<bool>(
                                        () => listManager.moveToNextList(
                                          todoToMove,
                                        ),
                                      );
                                }

                                if (isMoved) {
                                  if (!mounted) return;

                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      persist: false,
                                      content: Text(
                                        loc.todoMovedToX(destination),
                                      ),
                                      action: SnackBarAction(
                                        label: appLocalizations.undo,
                                        onPressed: () async {
                                          final isUndone = await todoState
                                              .performAcitionOnList<bool>(
                                                () => listManager
                                                    .moveAndUpdateTodo(
                                                      todo: todoToMove,
                                                      destination: listScope,
                                                    ),
                                              );
                                          if (isUndone) {
                                            setState(() {
                                              todoToMove.expirationDate =
                                                  retainedExpirationDate;
                                              todoToMove.order = retainedOrder;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  logger.e(
                                    'Todo could not be moved to other list!',
                                  );
                                }
                              },
                              child: TodoWidget(todo: todo, list: list),
                            ),
                          );
                        },
                      ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsetsGeometry.only(bottom: 65),
                  child: Column(
                    children: [
                      const Divider(),
                      ExpansionTile(
                        title: Text(loc.completedTodos),
                        subtitle: Text('${list.doneCount} ${loc.completed}'),
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedIconColor: Theme.of(context).primaryColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        initiallyExpanded:
                            todoState.doneTodosExpanded[listScope] ?? false,
                        onExpansionChanged: (bool expanding) =>
                            todoState.toggleExpansion(listScope),
                        children: [
                          for (var todo in list.doneTodos)
                            TodoWidget(todo: todo, list: list),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            tooltip: loc.addNewTodo,
            mini: true,
            child: const Icon(Icons.add),
            onPressed: () async {
              HiveTodo? newTodo = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => TodoEditSheet.newTodo(
                  todoState: todoState,
                  listScope: listScope,
                ),
              );
              if (newTodo != null) {
                todoState.performAcitionOnList<bool>(
                  () => listManager
                      .getListByScope(newTodo.listScope!)!
                      .addTodo(newTodo),
                );
              }
            },
          ),
        );
      },
    );
  }
}
