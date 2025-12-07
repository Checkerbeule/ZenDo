import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
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
    //todos.sort((a, b) => a.order!.compareTo(b.order!));
    switch (sortOption) {
      case SortOption.custom:
        /* todos.sort(
          (a, b) => sortOrder == SortOrder.ascending
              ? a.order!.compareTo(b.order!)
              : b.order!.compareTo(a.order!),
        ); */
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        final listManager = todoState.listManager;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverTodoSortFilterAppBar(
                sortOption: sortOption,
                sortOrder: sortOrder,
                onSortChanged: (option, order) {
                  setState(() {
                    sortOption = option;
                    sortOrder = order;
                  });
                },
              ),
              if (widget.list.todos.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    ListTile(
                      title: Text(
                        'Keine offenen Aufgaben vorhanden.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                )
              else
                SliverReorderableList(
                  itemCount: sortedAndFilteredTodos.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex--;
                      }
                      final todo = widget.list.todos.removeAt(oldIndex);
                      widget.list.todos.insert(newIndex, todo);
                    });
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
                                    () => listManager!.moveToOtherList(
                                      todo,
                                      updatedTodo.listScope!,
                                    ),
                                  );
                                }
                                todoState.performAcitionOnList<bool>(
                                  () => listManager!
                                      .getListByScope(updatedTodo.listScope!)!
                                      .replaceTodo(todo, updatedTodo),
                                );
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
                                        'Fällig am ${formatDate(todo.expirationDate!)} !',
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
                                        title: 'Aufgabe löschen ?',
                                        text:
                                            'Diese Aufgabe wirklich unwiederbringlich löschen?',
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
                child: ExpansionTile(
                  initiallyExpanded: expanded,
                  onExpansionChanged: (bool expanding) => expanded = expanding,
                  title: const Text('Erledigte Aufgaben'),
                  subtitle: Text('${widget.list.doneCount} erledigt'),
                  collapsedIconColor: Theme.of(context).primaryColor,
                  children: [
                    for (var todo in widget.list.doneTodos)
                      ListTile(
                        leading: IconButton(
                          onPressed: () => todoState.performAcitionOnList<bool>(
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
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            tooltip: 'Aufgabe hinzufügen',
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
