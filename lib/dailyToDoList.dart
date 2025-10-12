import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/main.dart';
import 'package:zen_do/model/todo.dart';

class DailyToDoList extends StatelessWidget {
  const DailyToDoList({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ZenDoAppState>();
    var toDos = appState.toDos;

    return Scaffold(
      body: toDos.isEmpty
          ? Center(child: Text('Keine Aufgaben vorhanden.'))
          : ListView(
              shrinkWrap: true,
              children: [
                for (var todo in toDos)
                  ListTile(
                    leading: IconButton(
                      onPressed: () => appState.removeTodo(todo),
                      icon: Icon(Icons.circle_outlined),
                    ),
                    title: Text(todo.title),
                  ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {_showAddToDoDialog(context)},
        tooltip: 'ToDo hinzufügen',
        label: const Text('Neue Aufgabe'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showAddToDoDialog(BuildContext context) {
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
                Provider.of<ZenDoAppState>(
                  context,
                  listen: false,
                ).addToDo(ToDo(title, description, DateTime.now()));
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
