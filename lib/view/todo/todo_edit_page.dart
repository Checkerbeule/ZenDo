import 'package:flutter/material.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/utils/time_util.dart';

class TodoEditPage extends StatefulWidget {
  const TodoEditPage({super.key, required this.todo});

  final Todo todo;

  @override
  State<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends State<TodoEditPage> {
  final formKey = GlobalKey<FormState>();
  late final titleController = TextEditingController(text: widget.todo.title);
  late final descriptionController = TextEditingController(
    text: widget.todo.description,
  );

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem> listScopeDropDownItems = [];
    ListScope? selectedScope;
    for (final scope in ListScope.values) {
      final item = DropdownMenuItem(value: scope, child: Text(scope.label));
      listScopeDropDownItems.add(item);
      if(scope == widget.todo.listScope) {
        selectedScope = scope;
      }
    }

    return AlertDialog(
      title: const Text('Aufgabe bearbeiten'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Titel',
                  hintText: 'Titel der Aufgabe',
                ),
                autocorrect: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Titel darf nicht leer sein';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Beschreibung',
                  hintText: 'Beschreibung',
                ),
                autocorrect: true,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(labelText: 'Liste: '),
                      items: listScopeDropDownItems,
                      initialValue: selectedScope,
                      onChanged: null, //readonly/disabled
                    ),
                  ),
                  //TODO add dropdown for labels with multi select
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Fällig am: ${formatDate(widget.todo.expirationDate)}'),
                  if (widget.todo.expirationDate != null &&
                      DateTime.now().isAfter(widget.todo.expirationDate!)) ...[
                    SizedBox(width: 5),
                    Icon(
                      Icons.access_time_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 18,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
              Text('Erstellt am: ${formatDate(widget.todo.creationDate)}'),
            ],
          ),
        ),
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
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Speichern'),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final updatedTodo = widget.todo.copyWith(
                title: titleController.text,
                description: descriptionController.text,
              );
              Navigator.of(context).pop(updatedTodo);
            }
          },
        ),
      ],
    );
  }
}
