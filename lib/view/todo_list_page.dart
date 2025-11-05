import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/view/todo_page.dart';

Logger logger = Logger(level: Level.debug);

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.list});

  final TodoList list;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<TodoState>();
    final listManager = appState.listManager;

    return Scaffold(
      body: ListView(
        shrinkWrap: true,
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
              ListTile(
                leading: IconButton(
                  onPressed: () => {
                    setState(() {
                      widget.list.markAsDone(todo);
                    }),
                  },
                  icon: Icon(Icons.circle_outlined),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    todo.description != null && todo.description!.isNotEmpty
                        ? Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  todo.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  todo.description!,
                                  style: const TextStyle(color: Colors.grey),
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
                            todo.expirationDate!.isBefore(DateTime.now()))) ...[
                      SizedBox(width: 5),
                      Tooltip(
                        message:
                            'Fällig am ${DateFormat('dd.MM.yyyy').format(todo.expirationDate!)} !',
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
                  onPressed: () => {
                    _showDeleteDialog(context, widget.list, todo).then(
                      (deleted) => {
                        if (deleted) {setState(() {})},
                      },
                    ),
                  },
                  icon: Icon(Icons.delete_forever),
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
                    onPressed: () => {
                      setState(() {
                        widget.list.restoreTodo(todo);
                      }),
                    },
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
          _showAddToDoDialog(
            context,
            widget.list,
          ).then((added) => {if (added) setState(() {})});
        },
        tooltip: 'ToDo hinzufügen',
        label: const Text('Neue Aufgabe'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

Future<bool> _showAddToDoDialog(BuildContext context, TodoList list) async {
  String title = '';
  String description = '';
  bool added = false;
  await showDialog<bool>(
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
              backgroundColor: Theme.of(context).colorScheme.surface,
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
              added = list.addTodo(Todo(title, description));
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
  return added;
}

Future<bool> _showDeleteDialog(
  BuildContext context,
  TodoList list,
  Todo todo,
) async {
  bool deleted = false;
  await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Aufgabe löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Diese Aufgabe wirklich unwiederbringlich löschen?"),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Ok'),
            onPressed: () {
              try {
                list.deleteTodo(todo);
                deleted = true;
              } catch (e) {
                logger.e('Failed to delete todo: $e');
              }
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
  return deleted;
}
