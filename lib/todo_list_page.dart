import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/main.dart';
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
    var appState = context.watch<ZenDoAppState>();

    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          if (widget.list.todos.isEmpty)
            ListTile(
              title: Text(
                'Keine Aufgaben vorhanden.\nAlles erledigt!',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            for (var todo in widget.list.todos)
              ListTile(
                leading: IconButton(
                  onPressed: () => {widget.list.markAsDone(todo), appState.notify()},
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
                      widget.list.restoreTodo(todo),
                      appState.notify(),
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
        onPressed: () => {_showAddToDoDialog(context, widget.list)},
        tooltip: 'ToDo hinzufügen',
        label: const Text('Neue Aufgabe'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showAddToDoDialog(BuildContext context, TodoList list) {
  var appState = Provider.of<ZenDoAppState>(context, listen: false);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      String title = '';
      String description = '';
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
              if (title.trim().isNotEmpty) {
                var added = list.addTodo(
                  Todo(title, description),
                );
                if (!added) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Eine Aufgabe mit diesem Titel existiert bereits.',
                      ),
                    ),
                  );
                } else {
                  appState.notify();
                  Navigator.of(context).pop();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Der Titel darf nicht leer sein.'),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
