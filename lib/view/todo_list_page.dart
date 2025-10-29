import 'package:flutter/material.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';

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
                title: Text(todo.title),
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
        onPressed: () async {
          Future<bool> future = _showAddToDoDialog(context, widget.list);
          future.then((added) => {if (added) setState(() {})});
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
              autofocus: true,
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
