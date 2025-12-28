import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:zen_do/localization/generated/todo/todo_localizations.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';
import 'package:zen_do/model/todo/todo_list.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/dialog_helper.dart';
import 'package:zen_do/view/todo/todo_page.dart';

Logger logger = Logger(level: Level.debug);

class TodoEditPage extends StatefulWidget {
  const TodoEditPage.editTodo({
    super.key,
    required this.todoState,
    required this.todo,
  }) : listScope = null;

  const TodoEditPage.newTodo({
    super.key,
    required this.todoState,
    required this.listScope,
  }) : todo = null;

  final Todo? todo;
  final TodoState todoState;
  final ListScope? listScope;

  @override
  State<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends State<TodoEditPage> {
  late final Todo? todo;
  late final ListManager manager;
  late ListScope selectedScope;

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  final DraggableScrollableController sheetController =
      DraggableScrollableController();
  bool isExpanded = false;
  double lowerSnap = 0.41;
  double upperSnap = 0.95;

  bool get isTodoEdited {
    if (todo == null) return true;
    return todo!.title != titleController.text.trim() ||
        todo!.description != descriptionController.text.trim() ||
        todo!.listScope != selectedScope;
  }

  @override
  void initState() {
    super.initState();

    todo = widget.todo;
    manager = widget.todoState.listManager!;

    selectedScope = todo?.listScope ?? widget.listScope!;
    titleController = TextEditingController(text: todo?.title ?? '');
    descriptionController = TextEditingController(
      text: todo?.description ?? '',
    );

    sheetController.addListener(_snapListener);
  }

  void _snapListener() {
    final size = sheetController.size;
    final isUpperSnap = (size - upperSnap).abs() < 0.02;
    final isLowerSnap = (size - lowerSnap).abs() < 0.02;

    if (isLowerSnap || isUpperSnap) {
      isExpanded = isUpperSnap;
    }
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = TodoLocalizations.of(context);
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLow;

    final List<DropdownMenuItem> listScopeDropDownItems = manager.allScopes
        .map(
          (scope) => DropdownMenuItem(
            value: scope,
            child: Text(
              style: TextStyle(fontWeight: FontWeight.normal),
              scope.label(context),
            ),
          ),
        )
        .toList();

    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double keyboardRelative = keyboardHeight / screenHeight;
    final bool isKeyboardOpen = keyboardHeight > 0;

    lowerSnap = (keyboardRelative + 0.25).clamp(0.41, 0.95);
    upperSnap = isKeyboardOpen ? 0.95 : 0.5;
    final List<double> snaps = [lowerSnap, upperSnap];

    if (isKeyboardOpen && isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sheetController.animateTo(
          upperSnap,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      });
    }

    return SafeArea(
      minimum: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: isExpanded ? snaps.last : snaps.first,
          maxChildSize: upperSnap,
          minChildSize: 0.2,
          snap: true,
          snapSizes: snaps,
          expand: false,
          builder: (context, scrollController) {
            return Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Positioned.fill(
                  top: 16,
                  bottom: 48, // space for save/cancel buttons
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        pinned: true,
                        backgroundColor: backgroundColor,
                        surfaceTintColor: backgroundColor,
                        actionsPadding: EdgeInsets.only(left: 5, right: 16),
                        title: Text(loc.editTodo),
                        actions: [
                          if (todo != null)
                            IconButton(
                              icon: const Icon(Icons.delete_forever),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final delete =
                                    await showDialogWithScaleTransition<bool>(
                                      context: context,
                                      child: DeleteDialog(
                                        title: '${loc.deleteTodo}?',
                                        text: loc.deleteTodoQuestion,
                                      ),
                                    );
                                if (delete != null && delete) {
                                  try {
                                    final TodoList list = manager
                                        .getListByScope(todo!.listScope!)!;
                                    widget.todoState.performAcitionOnList<bool>(
                                      () => list.deleteTodo(todo!),
                                    );
                                    navigator.pop();
                                  } catch (e) {
                                    logger.e(
                                      'Error deleting todo: $todo\n${e.toString()}',
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: titleController,
                                  autocorrect: true,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLength: 40,
                                  maxLengthEnforcement: MaxLengthEnforcement
                                      .truncateAfterCompositionEnds,
                                  decoration: InputDecoration(
                                    labelText: loc.titleLable,
                                    hintText: loc.titleHintText,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return loc.errorTitleEmpty;
                                    }
                                    if (!manager.isTodoTitleVacant(
                                      value,
                                      selectedScope,
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
                                  textCapitalization:
                                      TextCapitalization.sentences,
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
                                        decoration: InputDecoration(
                                          labelText: '${loc.list}: ',
                                        ),
                                        items: listScopeDropDownItems,
                                        initialValue: selectedScope,
                                        onChanged: (value) {
                                          selectedScope = value;
                                        },
                                        validator: (value) {
                                          if (!manager.isTodoTitleVacant(
                                            titleController.text,
                                            value as ListScope,
                                          )) {
                                            return loc
                                                .errorTodoAllreadyExistsInDestinationList;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    //TODO add dropdown for labels with multi select
                                  ],
                                ),
                                if (todo != null) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${loc.dueOn}: '),
                                      Text(
                                        formatDate(todo!.expirationDate),
                                        style:
                                            (todo!.expirationDate != null &&
                                                DateTime.now().isAfter(
                                                  todo!.expirationDate!,
                                                ))
                                            ? TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${loc.createdOn}: ${formatDate(todo!.creationDate)}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    color: backgroundColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
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
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          child: Text(
                            MaterialLocalizations.of(context).saveButtonLabel,
                          ),
                          onPressed: () {
                            if (isTodoEdited) {
                              if (formKey.currentState!.validate()) {
                                late final Todo todoToReturn;
                                if (todo == null) {
                                  todoToReturn = Todo(
                                    title: titleController.text,
                                    description: descriptionController.text,
                                  );
                                } else {
                                  todoToReturn = todo!.copyWith(
                                    title: titleController.text,
                                    description: descriptionController.text,
                                    listScope: selectedScope,
                                  );
                                }
                                Navigator.of(context).pop(todoToReturn);
                              }
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
