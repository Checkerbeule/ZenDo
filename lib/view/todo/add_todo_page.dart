import 'package:flutter/material.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';

class AddTodoPage extends StatefulWidget {
  const AddTodoPage({
    super.key,
    required this.listManager,
    required this.listScope,
  });

  final ListManager listManager;
  final ListScope listScope;

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Neue Aufgabe hinzufügen',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: titleController,
                  autocorrect: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Titel',
                    hintText: 'Titel der Aufgabe',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Titel darf nicht leer sein';
                    }
                    if (!widget.listManager.isTodoTitleVacant(
                      value,
                      widget.listScope,
                    )) {
                      return 'Titel ist bereits vergeben';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  autocorrect: true,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung',
                    hintText: 'Beschreibung',
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Abbrechen'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Speichern'),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newTodo = Todo(
                            title: titleController.text,
                            description: descriptionController.text,
                          );
                          Navigator.of(context).pop(newTodo);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/* AlertDialog(
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
      ); */