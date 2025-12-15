import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:zen_do/config/localization/generated/app_localizations.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';
import 'package:zen_do/model/todo/todo_list.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/dialog_helper.dart';
import 'package:zen_do/view/todo/todo_page.dart';

Logger logger = Logger(level: Level.debug);

class TodoEditPage extends StatefulWidget {
  const TodoEditPage({super.key, required this.todo, required this.todoState});

  final Todo todo;
  final TodoState todoState;

  @override
  State<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends State<TodoEditPage> {
  late final Todo todo;
  late final ListManager manager;
  late ListScope selectedScope;
  final List<DropdownMenuItem> listScopeDropDownItems = [];
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  bool get isChanged =>
      todo.title != titleController.text.trim() ||
      todo.description != descriptionController.text.trim() ||
      todo.listScope != selectedScope;

  @override
  void initState() {
    super.initState();

    todo = widget.todo;
    manager = widget.todoState.listManager!;

    selectedScope = todo.listScope!;
    titleController = TextEditingController(text: todo.title);
    descriptionController = TextEditingController(text: todo.description);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    for (final scope in manager.allScopes) {
      listScopeDropDownItems.add(
        DropdownMenuItem(
          value: scope,
          child: Text(
            style: TextStyle(fontWeight: FontWeight.normal),
            scope.label(context),
          ),
        ),
      );
    }
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(loc.editTodo),
          IconButton(
            icon: Icon(Icons.delete_forever),
            color: Theme.of(context).colorScheme.error,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final delete = await showDialogWithScaleTransition<bool>(
                context: context,
                child: DeleteDialog(
                  title: '${loc.deleteTodo}?',
                  text: loc.deleteTodoQuestion,
                ),
              );
              if (delete != null && delete) {
                try {
                  final TodoList list = manager.getListByScope(
                    todo.listScope!,
                  )!;
                  widget.todoState.performAcitionOnList<bool>(
                    () => list.deleteTodo(todo),
                  );
                  navigator.pop();
                } catch (e) {
                  logger.e('Error deleting todo: $todo\n${e.toString()}');
                }
              }
            },
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                autocorrect: true,
                decoration: InputDecoration(
                  labelText: loc.titleLable,
                  hintText: loc.titleHintText,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.errorTitleEmpty;
                  }
                  if (titleController.text != todo.title &&
                      !manager.isTodoTitleVacant(value, todo.listScope!)) {
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
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: loc.descriptionLabel,
                  hintText: loc.descriptionHintText,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(labelText: '${loc.list}: '),
                      items: listScopeDropDownItems,
                      initialValue: selectedScope,
                      onChanged: (value) {
                        selectedScope = value;
                      },
                      validator: (value) {
                        if (selectedScope != todo.listScope &&
                            !manager.isTodoTitleVacant(
                              titleController.text,
                              value as ListScope,
                            )) {
                          return loc.errorTodoAllreadyExistsInDestinationList;
                        }
                        return null;
                      },
                    ),
                  ),
                  //TODO add dropdown for labels with multi select
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${loc.dueOn}: ${formatDate(todo.expirationDate)}'),
                  if (todo.expirationDate != null &&
                      DateTime.now().isAfter(todo.expirationDate!)) ...[
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
              Text('${loc.createdOn}: ${formatDate(todo.creationDate)}'),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          onPressed: () {
            if (isChanged) {
              if (formKey.currentState!.validate()) {
                final updatedTodo = todo.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  listScope: selectedScope,
                );
                Navigator.of(context).pop(updatedTodo);
              }
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
