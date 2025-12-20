import 'package:flutter/material.dart';
import 'package:zen_do/localization/generated/todo/todo_localizations.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';

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
    final loc = TodoLocalizations.of(context);
    return SafeArea(
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.addNewTodo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: titleController,
                  autocorrect: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: loc.titleLable,
                    hintText: loc.titleHintText,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.errorTitleEmpty;
                    }
                    if (!widget.listManager.isTodoTitleVacant(
                      value,
                      widget.listScope,
                    )) {
                      return loc.errorTitleUnavailable;
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
                    labelText: loc.descriptionLabel,
                    hintText: loc.descriptionHintText,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        MaterialLocalizations.of(context).saveButtonLabel,
                      ),
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
