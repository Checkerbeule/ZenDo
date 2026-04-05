import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/ui/base_bottom_sheet.dart';
import 'package:zen_do/core/ui/dialog_helper.dart';
import 'package:zen_do/core/ui/standard_buttons.dart';
import 'package:zen_do/core/utils/time_util.dart';
import 'package:zen_do/features/tags/domain/tag_service.dart';
import 'package:zen_do/features/tags/l10n/tags_l10n_extension.dart';
import 'package:zen_do/features/tags/ui/tag_widget.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/hive_todo.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';
import 'package:zen_do/features/todos/domain/list_manager.dart';
import 'package:zen_do/features/todos/l10n/todos_l10n_extension.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

Logger logger = Logger(level: Level.debug);

class TodoEditSheet extends StatefulWidget {
  const TodoEditSheet.editTodo({
    super.key,
    required this.todoState,
    required this.todo,
  }) : listScope = null;

  const TodoEditSheet.newTodo({
    super.key,
    required this.todoState,
    required this.listScope,
  }) : todo = null;

  final HiveTodo? todo;
  final TodoState todoState;
  final ListScope? listScope;

  @override
  State<TodoEditSheet> createState() => _TodoEditSheetState();
}

class _TodoEditSheetState extends State<TodoEditSheet> {
  late final HiveTodo? todo;
  late final ListManager manager;
  late final bool isNewTodo;

  final formKey = GlobalKey<FormState>();
  final expirationDateKey = GlobalKey<FormFieldState>();
  late ListScope selectedScope;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController expirationDateController;
  late final Set<String> tagUuids;

  bool get isTodoEdited {
    if (isNewTodo) return true;
    final locale = Localizations.localeOf(context);
    return todo!.title != titleController.text.trim() ||
        todo!.description != descriptionController.text.trim() ||
        todo!.listScope != selectedScope ||
        !setEquals(todo!.tagUuids, tagUuids) ||
        (selectedScope != ListScope.backlog &&
            todo!.expirationDate !=
                parseLocalized(expirationDateController.text, locale));
  }

  @override
  void initState() {
    super.initState();

    todo = widget.todo;
    manager = widget.todoState.listManager!;
    isNewTodo = todo == null;

    selectedScope = todo?.listScope ?? widget.listScope!;
    titleController = TextEditingController(text: todo?.title ?? '');
    descriptionController = TextEditingController(
      text: todo?.description ?? '',
    );
    tagUuids = Set.from(todo?.tagUuids ?? {});
    expirationDateController = TextEditingController(text: ' - ');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        final locale = Localizations.localeOf(context);
        expirationDateController.text =
            todo?.expirationDate?.formatYmD(locale) ??
            manager.calcExpirationDate(selectedScope)?.formatYmD(locale) ??
            ' - ';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //final loc = TodosLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final TagService tagService = context.read<TagService>();
    final isTodoCompleted = todo?.completionDate != null;

    final List<DropdownMenuItem<ListScope>> listScopeDropDownItems = manager
        .scopes
        .map(
          (scope) => DropdownMenuItem(
            value: scope,
            child: Text(
              style: TextStyle(fontWeight: FontWeight.normal),
              scope.listName(context),
            ),
          ),
        )
        .toList();

    return BaseBottomSheet(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNewTodo
                ? context.todosL10n.addNewTodo
                : context.todosL10n.editTodo,
            style: TextTheme.of(context).headlineSmall,
          ),
          if (todo != null)
            Row(
              children: [
                if (!isTodoCompleted)
                  IconButton(
                    icon: Icon(Icons.check_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      try {
                        final TodoList list = manager.getListByScope(
                          todo!.listScope!,
                        )!;
                        widget.todoState.performAcitionOnList<void>(
                          () => list.markAsDone(todo!),
                        );
                      } catch (e) {
                        logger.e(
                          'Error ${isTodoCompleted ? 'restoring' : 'completing'} todo: $todo\n${e.toString()}',
                        );
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final delete = await showDialogWithScaleTransition<bool>(
                      context: context,
                      child: DeleteDialog(
                        title: '${context.todosL10n.deleteTodo}?',
                        text: context.todosL10n.deleteTodoQuestion,
                      ),
                    );
                    if (delete != null && delete) {
                      try {
                        final TodoList list = manager.getListByScope(
                          todo!.listScope!,
                        )!;
                        widget.todoState.performAcitionOnList<bool>(
                          () => list.deleteTodo(todo!),
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
        ],
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            Column(
              children: [
                TextFormField(
                  controller: titleController,
                  autocorrect: true,
                  autofocus: isNewTodo,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 40,
                  maxLengthEnforcement:
                      MaxLengthEnforcement.truncateAfterCompositionEnds,
                  decoration: InputDecoration(
                    labelText: context.todosL10n.titleLable,
                    hintText: context.todosL10n.titleHintText,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.todosL10n.errorTitleEmpty;
                    }
                    if (isNewTodo &&
                            !manager.isTodoTitleVacant(value, selectedScope) ||
                        (!isNewTodo &&
                            todo!.title != value &&
                            !manager.isTodoTitleVacant(value, selectedScope))) {
                      return context.todosL10n.errorTitleUnavailable;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  autocorrect: true,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.todosL10n.descriptionLabel,
                    hintText: context.todosL10n.descriptionHintText,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ListScope>(
                    decoration: InputDecoration(
                      labelText: '${context.todosL10n.list}: ',
                      icon: const Icon(Icons.view_column),
                    ),
                    items: listScopeDropDownItems,
                    initialValue: selectedScope,
                    onChanged: isTodoCompleted
                        ? null
                        : (value) {
                            setState(() {
                              selectedScope = value!;
                              expirationDateController.text =
                                  manager
                                      .calcExpirationDate(selectedScope)
                                      ?.formatYmD(locale) ??
                                  ' - ';
                            });
                          },
                    validator: (value) {
                      if (isNewTodo &&
                              !manager.isTodoTitleVacant(
                                titleController.text,
                                value as ListScope,
                              ) ||
                          (!isNewTodo &&
                              todo!.title != titleController.text &&
                              !manager.isTodoTitleVacant(
                                titleController.text,
                                value as ListScope,
                              ))) {
                        return context
                            .todosL10n
                            .errorTodoAllreadyExistsInDestinationList;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextFormField(
                    key: expirationDateKey,
                    controller: expirationDateController,
                    enabled:
                        selectedScope != ListScope.backlog && !isTodoCompleted,
                    keyboardType: TextInputType.none,
                    showCursor: false,
                    decoration: InputDecoration(
                      labelText: context.todosL10n.dueOn,
                      icon: Icon(
                        Icons.edit_calendar,
                        color:
                            todo?.expirationDate?.isBefore(DateTime.now()) ??
                                false
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                    onTap: () async {
                      final selectedDate = tryParseLocalized(
                        expirationDateController.text,
                        locale,
                      );

                      final activeScopes = manager.scopes;
                      if (activeScopes.last == ListScope.backlog &&
                          activeScopes.length <= 1) {
                        return; // no date selection possible for backlog
                      }

                      final nextList = manager.getNextList(selectedScope);
                      final firstDate = nextList == null
                          ? DateTime.now()
                          : manager
                                .calcExpirationDate(nextList.scope)!
                                .add(Duration(days: 1));

                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: firstDate,
                        lastDate: manager.calcExpirationDate(selectedScope)!,
                      );
                      if (pickedDate != null) {
                        expirationDateController.value = TextEditingValue(
                          text: pickedDate.formatYmD(locale),
                        );
                      }
                    },
                    validator: (value) {
                      if (selectedScope == ListScope.backlog) {
                        return null;
                      }
                      if (value == null) {
                        return context.todosL10n.noDateelectedError;
                      }
                      final selectedDate = tryParseLocalized(value, locale);
                      if (selectedDate == null) {
                        return '${context.todosL10n.invalidDateFormatError}: $value';
                      }

                      final fittingScope = manager.getScopeForExpirationDate(
                        selectedDate,
                      );
                      if (fittingScope == null) {
                        return context.todosL10n.dateDoesNotFitAnyListError;
                      }
                      if (fittingScope != selectedScope) {
                        return '${context.todosL10n.dateDoesNotFitListError}: ${selectedScope.label(context)}';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${context.tagsL10n.connectedTags}:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 5),
            StreamBuilder<List<Tag>>(
              stream: tagService.watchAll(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final tags = snapshot.data!;
                  if (tags.isEmpty) {
                    return Center(
                      child: Text(context.tagsL10n.noTagsAvailable),
                    );
                  }
                  return Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: tags.map((tag) {
                      return TagWidget.fromTag(
                        tag: tag,
                        isCompact: true,
                        isSelected: tagUuids.contains(tag.uuid),
                        onTap: (uuid) {
                          setState(() {
                            if (tagUuids.contains(uuid)) {
                              tagUuids.remove(uuid);
                            } else {
                              tagUuids.add(uuid);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                } else {
                  if (snapshot.hasError) {
                    return Text(
                      context.tagsL10n.errorLoadingTags,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return Text(
                    context.tagsL10n.loadingTags,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
              },
            ),
            if (todo != null) ...[
              const SizedBox(height: 16),
              Text(
                '${context.todosL10n.createdOn}: '
                '${todo!.creationDate.formatYmD(locale)}',
              ),
              if (isTodoCompleted) ...[
                const SizedBox(height: 5),
                Text(
                  '${context.todosL10n.completedOn}: '
                  '${todo!.completionDate!.formatYmD(locale)}',
                ),
              ],
            ],
          ],
        ),
      ),
      footer: CancelSaveButtonPair(
        onCancelPressed: () => Navigator.of(context).pop(),
        onSavePressed: () async {
          if (isTodoEdited) {
            if (formKey.currentState!.validate()) {
              late final HiveTodo todoToReturn;
              final selectedExpirationDate = selectedScope == ListScope.backlog
                  ? null
                  : parseLocalized(expirationDateController.text, locale);
              if (isNewTodo) {
                todoToReturn = HiveTodo(
                  title: titleController.text,
                  description: descriptionController.text,
                  expirationDate: selectedExpirationDate,
                  listScope: selectedScope,
                  tagUuids: Set.from(tagUuids),
                );
              } else {
                todoToReturn = todo!.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  listScope: selectedScope,
                  expirationDate: selectedExpirationDate,
                  tagUuids: Set.from(tagUuids),
                );
              }
              Navigator.of(context).pop(todoToReturn);
            }
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
