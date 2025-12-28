import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/localization/generated/todo/todo_localizations.dart';
import 'package:zen_do/model/appsettings/settings_service.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';
import 'package:zen_do/model/todo/todo_list.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/dialog_helper.dart';
import 'package:zen_do/view/todo/sliver_todo_sort_filter_app_bar.dart';
import 'package:zen_do/view/todo/todo_edit_page.dart';
import 'package:zen_do/view/todo/todo_page.dart';

import '../../localization/generated/app/app_localizations.dart';

Logger logger = Logger(level: Level.debug);

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.list});

  final TodoList list;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  late final SettingsService settings;
  SortOption sortOption = SortOption.custom;
  SortOrder sortOrder = SortOrder.ascending;
  Offset tapPosition = Offset.zero;

  List<Todo> get sortedAndFilteredTodos {
    final todos = List<Todo>.from(widget.list.todos);
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
    final settingsService = await SharedPrefsSettingsService.getInstance();
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
    final loc = TodoLocalizations.of(context);
    final list = widget.list;
    final listScope = list.scope;
    final Set<SortOption> excludedSortOptions = listScope == ListScope.backlog
        ? {SortOption.expirationDate}
        : {};
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
              ),
              if (list.todos.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    ListTile(
                      title: Text(
                        loc.noOpenTodosLeft,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                )
              else
                SliverReorderableList(
                  itemCount: sortedAndFilteredTodos.length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: 1.0,
                          child: Material(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            elevation: 5,
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    if (sortOption == SortOption.custom) {
                      setState(() {
                        final moved = sortedAndFilteredTodos[oldIndex];
                        final previous = newIndex == 0
                            ? null
                            : sortedAndFilteredTodos[newIndex - 1];
                        list.reorder(moved, previous);
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final todo = sortedAndFilteredTodos[index];
                    return ReorderableDelayedDragStartListener(
                      enabled: sortOption == SortOption.custom,
                      key: ValueKey(todo.id),
                      index: index,
                      child: Dismissible(
                        key: ValueKey(todo.id),
                        background: Container(
                          padding: EdgeInsetsGeometry.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          alignment: Alignment.centerLeft,
                          child: !isLastList
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.moveToXList(
                                        previousListScope.labelAdj(context),
                                      ),
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
                                padding: const EdgeInsetsGeometry.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      loc.moveToXList(
                                        nextListScope.labelAdj(context),
                                      ),
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
                          } else if (direction == DismissDirection.endToStart) {
                            destinationList = listManager.getNextList(
                              listScope,
                            );
                          }
                          isMovable =
                              destinationList?.isTodoTitleVacant(
                                sortedAndFilteredTodos[index].title,
                              ) ??
                              false;
                          if (!isMovable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.shiftNotPossible)),
                            );
                            return false;
                          }
                          return true;
                        },
                        onDismissed: (direction) async {
                          final todoToMove = sortedAndFilteredTodos[index];
                          final retainedExpirationDate =
                              todoToMove.expirationDate;
                          final retainedOrder = todoToMove.order;

                          final messenger = ScaffoldMessenger.of(context);
                          final appLocalizations = AppLocalizations.of(context);

                          String destination = '';
                          bool isMoved = false;
                          if (direction == DismissDirection.startToEnd) {
                            destination =
                                listManager
                                    .getPreviousList(list.scope)
                                    ?.scope
                                    .labelAdj(context) ??
                                loc.next;
                            isMoved = await todoState
                                .performAcitionOnList<bool>(
                                  () => listManager.moveToPreviousList(
                                    todoToMove,
                                  ),
                                );
                          } else if (direction == DismissDirection.endToStart) {
                            destination =
                                listManager
                                    .getNextList(list.scope)
                                    ?.scope
                                    .labelAdj(context) ??
                                loc.previous;
                            isMoved = await todoState
                                .performAcitionOnList<bool>(
                                  () => listManager.moveToNextList(todoToMove),
                                );
                          }

                          if (isMoved) {
                            if (!mounted) return;

                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                persist: false,
                                content: Text(loc.todoMovedToX(destination)),
                                action: SnackBarAction(
                                  label: appLocalizations.undo,
                                  onPressed: () async {
                                    final isUndone = await todoState
                                        .performAcitionOnList<bool>(
                                          () => listManager.moveAndUpdateTodo(
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
                            logger.e('Todo could not be moved to other list!');
                          }
                        },
                        child: Material(
                          child: Listener(
                            onPointerUp: (event) {
                              tapPosition = event.position;
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              onTap: () async {
                                final updatedTodo = await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => TodoEditPage.editTodo(
                                    todo: todo,
                                    todoState: todoState,
                                  ),
                                );

                                if (updatedTodo != null) {
                                  if (updatedTodo.listScope != todo.listScope) {
                                    todoState.performAcitionOnList(
                                      () => listManager.moveAndUpdateTodo(
                                        oldTodo: todo,
                                        todo: updatedTodo,
                                        destination: updatedTodo.listScope!,
                                      ),
                                    );
                                  } else {
                                    todoState.performAcitionOnList<bool>(
                                      () => listManager
                                          .getListByScope(
                                            updatedTodo.listScope!,
                                          )!
                                          .replaceTodo(todo, updatedTodo),
                                    );
                                  }
                                }
                              },
                              leading: IconButton(
                                onPressed: () => {
                                  todoState.performAcitionOnList<void>(
                                    () => list.markAsDone(todo),
                                  ),
                                },
                                icon: const Icon(Icons.circle_outlined),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  todo.description != null &&
                                          todo.description!.isNotEmpty
                                      ? Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                todo.title,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                todo.description!,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).disabledColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        )
                                      : Flexible(
                                          child: Text(
                                            todo.title,
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                  if (listManager.toBeTransferredTomorrow(
                                        todo,
                                      ) ||
                                      (todo.expirationDate != null &&
                                          todo.expirationDate!.isBefore(
                                            DateTime.now(),
                                          ))) ...[
                                    const SizedBox(width: 5),
                                    Tooltip(
                                      message:
                                          '${loc.dueOn} ${formatDate(todo.expirationDate!)} !',
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () async {
                                  final delete =
                                      await showDialogWithScaleTransition<bool>(
                                        context: context,
                                        child: DeleteDialog(
                                          title: '${loc.deleteTodo}?',
                                          text: loc.deleteTodoQuestion,
                                        ),
                                      );
                                  if (delete != null && delete) {
                                    todoState.performAcitionOnList<bool>(
                                      () => list.deleteTodo(todo),
                                    );
                                  }
                                },
                                //_showDeleteDialog(context, widget.list, todo),
                                icon: const Icon(Icons.delete_forever),
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              SliverToBoxAdapter(
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
                          ListTile(
                            leading: IconButton(
                              onPressed: () =>
                                  todoState.performAcitionOnList<bool>(
                                    () => list.restoreTodo(todo),
                                  ),
                              icon: const Icon(Icons.check_circle),
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            tooltip: loc.addTodo,
            mini: true,
            child: const Icon(Icons.add),
            onPressed: () async {
              Todo? newTodo = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => TodoEditPage.newTodo(
                  todoState: todoState,
                  listScope: listScope,
                ),
              );
              if (newTodo != null) {
                todoState.performAcitionOnList<bool>(
                  () => list.addTodo(newTodo),
                );
              }
            },
          ),
        );
      },
    );
  }
}
