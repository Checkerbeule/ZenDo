import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_do/config/localization/app_localizations.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/dialog_helper.dart';
import 'package:zen_do/view/todo/add_todo_page.dart';
import 'package:zen_do/view/todo/sliver_todo_sort_filter_app_bar.dart';
import 'package:zen_do/view/todo/todo_edit_page.dart';
import 'package:zen_do/view/todo/todo_page.dart';

Logger logger = Logger(level: Level.debug);

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.list});

  final TodoList list;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool expanded = false;
  Offset tapPosition = Offset.zero;
  SortOption sortOption = SortOption.custom;
  SortOrder sortOrder = SortOrder.ascending;

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

  String getSortOptionPrefKey(ListScope scope) {
    return 'todo.${scope.name}.list.sortOption';
  }

  String getSortOrderPrefKey(ListScope scope) {
    return 'todo.${scope.name}.list.sortOrder';
  }

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      getSortOptionPrefKey(widget.list.scope),
      sortOption.index,
    );
    await prefs.setInt(getSortOrderPrefKey(widget.list.scope), sortOrder.index);
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      sortOption =
          SortOption.values[prefs.getInt(
                getSortOptionPrefKey(widget.list.scope),
              ) ??
              SortOption.custom.index];
      sortOrder =
          SortOrder.values[prefs.getInt(
                getSortOrderPrefKey(widget.list.scope),
              ) ??
              SortOrder.ascending.index];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final Set<SortOption> excludedSortOptions =
        widget.list.scope == ListScope.backlog
        ? {SortOption.expirationDate}
        : {};
    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        final loc = AppLocalizations.of(context)!;
        final listManager = todoState.listManager;
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
                  unawaited(_saveSortPreferences());
                },
              ),
              if (widget.list.todos.isEmpty)
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
                  itemCount: sortedAndFilteredTodos.length,
                  onReorder: (oldIndex, newIndex) {
                    if (sortOption == SortOption.custom) {
                      setState(() {
                        final moved = sortedAndFilteredTodos[oldIndex];
                        final previous = newIndex == 0
                            ? null
                            : sortedAndFilteredTodos[newIndex - 1];
                        widget.list.reorder(moved, previous);
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final todo = sortedAndFilteredTodos[index];
                    return ReorderableDelayedDragStartListener(
                      enabled: sortOption == SortOption.custom,
                      key: ValueKey(todo.hashCode),
                      index: index,
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
                              final updatedTodo =
                                  await showDialogWithScaleTransition<Todo>(
                                    context: context,
                                    //tapPosition: tapPosition, not used at the moment
                                    child: TodoEditPage(
                                      todo: todo,
                                      todoState: todoState,
                                    ),
                                    barrierDismissable: false,
                                  );
                              if (updatedTodo != null) {
                                if (updatedTodo.listScope != todo.listScope) {
                                  todoState.performAcitionOnList(
                                    () => listManager!.moveAndUpdateTodo(
                                      oldTodo: todo,
                                      todo: updatedTodo,
                                      destination: updatedTodo.listScope!,
                                    ),
                                  );
                                } else {
                                  todoState.performAcitionOnList<bool>(
                                    () => listManager!
                                        .getListByScope(updatedTodo.listScope!)!
                                        .replaceTodo(todo, updatedTodo),
                                  );
                                }
                              }
                            },
                            leading: IconButton(
                              onPressed: () => {
                                todoState.performAcitionOnList<Null>(
                                  () => widget.list.markAsDone(todo),
                                ),
                              },
                              icon: Icon(Icons.circle_outlined),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                if (listManager != null &&
                                    (listManager.toBeTransferredTomorrow(
                                          todo,
                                        ) ||
                                        (todo.expirationDate != null &&
                                            todo.expirationDate!.isBefore(
                                              DateTime.now(),
                                            )))) ...[
                                  SizedBox(width: 5),
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
                                        title: '${loc.deleteTodo} ?',
                                        text: loc.deleteTodoQuestion,
                                      ),
                                    );
                                if (delete != null && delete) {
                                  todoState.performAcitionOnList<bool>(
                                    () => widget.list.deleteTodo(todo),
                                  );
                                }
                              },
                              //_showDeleteDialog(context, widget.list, todo),
                              icon: Icon(Icons.delete_forever),
                              color: Theme.of(context).colorScheme.tertiary,
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
                    Divider(),
                    ExpansionTile(
                      title: Text(loc.completedTodos),
                      subtitle: Text('${widget.list.doneCount} ${loc.completed}'),
                      shape: RoundedRectangleBorder(side: BorderSide.none),
                      collapsedIconColor: Theme.of(context).primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      initiallyExpanded: expanded,
                      onExpansionChanged: (bool expanding) =>
                          expanded = expanding,
                      children: [
                        for (var todo in widget.list.doneTodos)
                          ListTile(
                            leading: IconButton(
                              onPressed: () =>
                                  todoState.performAcitionOnList<bool>(
                                    () => widget.list.restoreTodo(todo),
                                  ),
                              icon: Icon(Icons.check_circle),
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
                builder: (BuildContext context) {
                  return AddTodoPage(
                    listManager: todoState.listManager!,
                    listScope: widget.list.scope,
                  );
                },
              );
              if (newTodo != null) {
                todoState.performAcitionOnList<bool>(
                  () => widget.list.addTodo(newTodo),
                );
              }
            },
          ),
        );
      },
    );
  }
}
