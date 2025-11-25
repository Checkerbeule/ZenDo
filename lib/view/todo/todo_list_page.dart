import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/dialog_helper.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        final listManager = todoState.listManager;
        return Scaffold(
          body: ListView(
            //shrinkWrap: true, //TODO needed?
            children: [
              if (widget.list.todos.isEmpty)
                ListTile(
                  title: Text(
                    'Keine offenen Aufgaben vorhanden.',
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                for (var todo in widget.list.todos)
                  InkWell(
                    onTapDown: (tapDetails) {
                      tapPosition = tapDetails.globalPosition;
                    },
                    onTap: () async {
                      final updatedTodo =
                          await showDialogWithScaleTransition<Todo>(
                            context: context,
                            //tapPosition: tapPosition, not used at the moment
                            child: TodoEditPage(todo: todo),
                            barrierDismissable: false,
                          );
                      if (updatedTodo != null) {
                        todoState.performAcitionOnList<bool>(
                          () => widget.list.replaceTodo(todo, updatedTodo),
                        );
                      }
                    },
                    child: ListTile(
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        todo.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        todo.description!,
                                        style: const TextStyle(
                                          color: Colors.grey,
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
                                    widget.list.scope,
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
                                color: Theme.of(context).colorScheme.error,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          final delete = await showDialogWithScaleTransition<bool>(
                            context: context,
                            child: DeleteDialog(
                              title: 'Aufgabe löschen ?',
                              text:
                                  'Diese Aufgabe wirklich unwiederbringlich löschen?',
                            ),
                          );
                          if (delete != null && delete) {
                            todoState.performAcitionOnList<Null>(
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
              ],
              ExpansionTile(
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
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _showAddToDoDialog(context, widget.list);
            },
            tooltip: 'ToDo hinzufügen',
            label: const Text('Neue Aufgabe'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

void _showAddToDoDialog(BuildContext context, TodoList list) async {
  final todoState = context.read<TodoState>();
  String title = '';
  String description = '';
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Neue Aufgabe hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Titel'),
              onChanged: (value) {
                title = value;
              },
            ),
            TextField(
              decoration: const InputDecoration(hintText: 'Beschreibung'),
              onChanged: (value) {
                description = value;
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: const Text('Ok'),
            onPressed: () {
              if (title.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Der Titel darf nicht leer sein.'),
                  ),
                );
                return;
              }
              bool added = todoState.performAcitionOnList<bool>(
                () =>
                    list.addTodo(Todo(title: title, description: description)),
              );
              if (!added) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Eine Aufgabe mit diesem Titel existiert bereits.',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}