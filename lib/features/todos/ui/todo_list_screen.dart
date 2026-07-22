import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/l10n/app_l10n_extension.dart';
import 'package:zen_do/core/ui/loading_screen.dart';
import 'package:zen_do/features/todos/data/hive_todo.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/domain/todo_service.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';
import 'package:zen_do/features/todos/l10n/todos_l10n_extension.dart';
import 'package:zen_do/features/todos/ui/sliver_todo_sort_filter_app_bar.dart';
import 'package:zen_do/features/todos/ui/todo_card.dart';
import 'package:zen_do/features/todos/ui/todo_edit_sheet.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

Logger logger = Logger(level: Level.debug);

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key, required this.listScope});

  final ListScope listScope;

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>
    with AutomaticKeepAliveClientMixin {
  late final AppSettingsService settings;
  TodoSortOption sortOption = TodoSortOption.custom;
  SortOrder sortOrder = SortOrder.ascending;

  List<HiveTodo> getSortedAndFilteredTodos(Set<String> tagFilter) {
    final List<HiveTodo> todos =
        []; // List<HiveTodo>.from(widget.listScope.todos);
    if (tagFilter.isNotEmpty) {
      todos.retainWhere(
        (t) => t.tagUuids.any((tagUuid) => tagFilter.contains(tagUuid)),
      );
    }

    switch (sortOption) {
      case TodoSortOption.custom:
        todos.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
        break;
      case TodoSortOption.title:
        todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case TodoSortOption.expirationDate:
        todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.expirationDate!.compareTo(b.expirationDate!)
              : b.expirationDate!.compareTo(a.expirationDate!),
        );
        break;
      case TodoSortOption.creationDate:
        todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.creationDate.compareTo(b.creationDate)
              : b.creationDate.compareTo(a.creationDate),
        );
        break;
      default:
        todos.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
        break;
    }
    return todos;
  }

  Future<void> _loadSettings() async {
    final settingsService = await SharedPrefsAppSettingsService.getInstance();
    if (!mounted) return;

    settings = settingsService;
    final loadedSortOption = settingsService.getSortOption(widget.listScope);
    final loadedSortOrder = settingsService.getSortOrder(widget.listScope);

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

  // TODO [#124]: implement controller to manage stream states for clean architecture
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final listScope = widget.listScope;
    final tagFilter = context.watch<TodoState>().tagFilter;

    return Consumer<TodoService>(
      builder: (context, todoService, child) {
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
                    excludedOptions: listScope == ListScope.backlog
                        ? {TodoSortOption.expirationDate}
                        : {},
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
                      context.read<TodoState>().updateTagFilter(
                        updatedTagFilter,
                      );
                    },
                  ),

                  StreamBuilder(
                    stream: todoService.watchAllOpenByScope(
                      scope: listScope,
                      tagUuidsFilter: tagFilter,
                      sortOption: sortOption,
                      sortOrder: sortOrder,
                    ),
                    builder: (context, snapshot) {
                      return SliverAnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: snapshot.connectionState.index <= 1
                            ? SliverToBoxAdapter(
                                key: const ValueKey('loading_state'),
                                child: LoadingScreen(
                                  message:
                                      context.todosL10n.loadingTodosIndicator,
                                ),
                              )
                            : !snapshot.hasData
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        context.todosL10n.noTodosFound,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        tagFilter.isNotEmpty
                                            ? context.todosL10n.checkTodoFilters
                                            : context.todosL10n.everythingDone,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SliverReorderableList(
                                key: const ValueKey('todo_list'),
                                itemCount: snapshot.data!.length,
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
                                onReorder: (oldIndex, newIndex) async {
                                  if (sortOption == TodoSortOption.custom) {
                                    await todoService.reorder(
                                      snapshot.data!,
                                      oldIndex,
                                      newIndex,
                                    );
                                  }
                                },
                                itemBuilder: (context, index) {
                                  final todo = snapshot.data![index];

                                  return ReorderableDelayedDragStartListener(
                                    enabled:
                                        sortOption == TodoSortOption.custom,
                                    key: ValueKey(todo.uuid),
                                    index: index,
                                    child: Dismissible(
                                      key: ValueKey(todo.uuid),
                                      background: Container(
                                        padding:
                                            const EdgeInsetsGeometry.symmetric(
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
                                                    '${context.todosL10n.moveTo}\n'
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
                                                    '${context.todosL10n.moveTo}\n'
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
                                      onDismissed: (direction) async {
                                        final retainedExpiry = todo.expiresAt;
                                        final retainedOrder = todo.customOrder;

                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final appL10n = context.appL10n;
                                        final todosL10n = context.todosL10n;

                                        String destinationName = '';
                                        bool isMoved = false;

                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          destinationName =
                                              todoService
                                                  .getPreviousScope(listScope)
                                                  ?.listName(context) ??
                                              todosL10n.next;

                                          isMoved = await todoService
                                              .moveToPreviousList(todo);
                                        } else if (direction ==
                                            DismissDirection.endToStart) {
                                          destinationName =
                                              todoService
                                                  .getNextScope(listScope)
                                                  ?.listName(context) ??
                                              todosL10n.next;

                                          isMoved = await todoService
                                              .moveToNextList(todo);
                                        }

                                        if (isMoved) {
                                          if (!mounted) return;

                                          messenger.clearSnackBars();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              persist: false,
                                              content: Text(
                                                todosL10n.todoMovedToX(
                                                  destinationName,
                                                ),
                                              ),
                                              action: SnackBarAction(
                                                label: appL10n.undo,
                                                onPressed: () async {
                                                  final isUndone =
                                                      await todoService
                                                          .moveToOtherList(
                                                            todo,
                                                            listScope,
                                                          );

                                                  if (isUndone) {
                                                    // Note: This triggers an unnecessary sync since data hasn't changed.
                                                    // We accept this to keep the code simple and ensure data integrity.
                                                    await todoService.update(
                                                      todo.copyWith(
                                                        expiresAt:
                                                            retainedExpiry,
                                                        customOrder:
                                                            retainedOrder,
                                                      ),
                                                    );
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
                                      child: TodoCard(
                                        todo: todo,
                                        key: ValueKey(todo.uuid),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 65),
                      child: Column(
                        children: [
                          const Divider(),
                          StreamBuilder(
                            stream: todoService.watchAllCompletedByScope(
                              scope: listScope,
                            ),
                            builder: (context, snapshot) {
                              return ExpansionTile(
                                title: Text(context.todosL10n.completedTodos),
                                subtitle: snapshot.connectionState.index <= 1
                                    ? Text(
                                        context.todosL10n.loadingTodosIndicator,
                                      )
                                    : Text(
                                        '${snapshot.data?.length ?? 0} ${context.todosL10n.completed}',
                                        //'${list.doneCount} ${context.todosL10n.completed}',
                                      ),
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide.none,
                                ),
                                collapsedIconColor: Theme.of(
                                  context,
                                ).primaryColor,
                                initiallyExpanded:
                                    todoState.doneTodosExpanded[listScope] ??
                                    false,
                                onExpansionChanged: (bool expanding) =>
                                    todoState.toggleExpansion(listScope),
                                children: snapshot.connectionState.index <= 1
                                    ? [
                                        LoadingScreen(
                                          message: context
                                              .todosL10n
                                              .loadingTodosIndicator,
                                        ),
                                      ]
                                    : [
                                        for (var todo in snapshot.data ?? [])
                                          TodoCard(todo: todo),
                                      ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              floatingActionButton: FloatingActionButton(
                tooltip: context.todosL10n.addNewTodo,
                mini: true,
                child: const Icon(Icons.add),
                onPressed: () async {
                  HiveTodo? newTodo = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        TodoEditSheet.newTodo(listScope: listScope),
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
      },
    );
  }
}
