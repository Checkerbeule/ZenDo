import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/ui/tag_widget.dart';
import 'package:zen_do/localization/generated/tags/tags_localizations.dart';
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
  late final bool isNewTodo;

  final formKey = GlobalKey<FormState>();
  final expirationDateKey = GlobalKey<FormFieldState>();
  final headerKey = GlobalKey();
  final formTopKey = GlobalKey();
  final footerKey = GlobalKey();
  late ListScope selectedScope;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController expirationDateController;
  late final Set<String> tagUuids;

  final DraggableScrollableController sheetController =
      DraggableScrollableController();
  double maxSheetSize = 0.94;
  double lastKeayboardHeight = 0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => updateMaxSheetSize());
  }

  void updateMaxSheetSize() {
    maxSheetSize = calcMaxSheetSize();

    sheetController.animateTo(
      maxSheetSize,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  double calcMaxSheetSize() {
    final formHeight = formKey.currentContext?.size?.height ?? 0;
    final headerHeight = headerKey.currentContext?.size?.height ?? 0;
    final footerHeight = footerKey.currentContext?.size?.height ?? 0;
    final mediaQuery = MediaQuery.of(context);

    final availableHeight =
        mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.viewPadding.bottom;
    final contentHeight = formHeight + headerHeight + footerHeight;

    return (contentHeight / availableHeight).clamp(0.3, 0.94);
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = TodoLocalizations.of(context);
    final tagLoc = TagsLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLow;
    final TagRepository tagRepository = context.read<TagRepository>();

    final List<DropdownMenuItem> listScopeDropDownItems = manager.scopes
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentKeyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

      if (lastKeayboardHeight != currentKeyboardHeight) {
        lastKeayboardHeight = currentKeyboardHeight;
        updateMaxSheetSize();
      }
    });

    return SafeArea(
      child: Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: maxSheetSize,
          maxChildSize: maxSheetSize,
          minChildSize: 0.25,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    final mediaQuery = MediaQuery.of(context);
                    final availableHeight =
                        mediaQuery.size.height -
                        mediaQuery.viewInsets.bottom -
                        mediaQuery.padding.top -
                        mediaQuery.padding.bottom;
                    final double deltaRelative =
                        details.delta.dy / availableHeight;

                    sheetController.jumpTo(
                      (sheetController.size - deltaRelative),
                    );
                  },
                  onVerticalDragEnd: (details) {
                    final velocity = details.velocity.pixelsPerSecond.dy;
                    if (velocity.abs() < 0) return;

                    final height = MediaQuery.sizeOf(context).height;
                    final distance = (velocity / height) * 0.2;
                    final target = (sheetController.size - distance).clamp(
                      0.25,
                      0.94,
                    );
                    final duration = (300 + (velocity.abs() / 10))
                        .clamp(200, 600)
                        .toInt();

                    sheetController.animateTo(
                      target,
                      duration: Duration(milliseconds: duration),
                      curve: Curves.decelerate,
                    );
                  },
                  child: Container(
                    key: headerKey,
                    alignment: Alignment.topCenter,
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Draghandle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isNewTodo ? loc.addNewTodo : loc.editTodo,
                                style: TextTheme.of(context).headlineSmall,
                              ),
                              if (todo != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_forever),
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    final delete =
                                        await showDialogWithScaleTransition<
                                          bool
                                        >(
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
                                        widget.todoState
                                            .performAcitionOnList<bool>(
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
                        ),
                      ],
                    ),
                  ),
                ),
                // Form / body
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          Column(
                            key: formTopKey,
                            children: [
                              TextFormField(
                                controller: titleController,
                                autocorrect: true,
                                autofocus: true,
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
                                  if (isNewTodo &&
                                          !manager.isTodoTitleVacant(
                                            value,
                                            selectedScope,
                                          ) ||
                                      (!isNewTodo &&
                                          todo!.title != value &&
                                          !manager.isTodoTitleVacant(
                                            value,
                                            selectedScope,
                                          ))) {
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
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField(
                                  decoration: InputDecoration(
                                    labelText: '${loc.list}: ',
                                    icon: const Icon(Icons.view_column),
                                  ),
                                  items: listScopeDropDownItems,
                                  initialValue: selectedScope,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedScope = value;
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
                                            todo!.title !=
                                                titleController.text &&
                                            !manager.isTodoTitleVacant(
                                              titleController.text,
                                              value as ListScope,
                                            ))) {
                                      return loc
                                          .errorTodoAllreadyExistsInDestinationList;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: TextFormField(
                                  key: expirationDateKey,
                                  controller: expirationDateController,
                                  enabled: selectedScope != ListScope.backlog,
                                  keyboardType: TextInputType.none,
                                  showCursor: false,
                                  decoration: InputDecoration(
                                    labelText: loc.dueOn,
                                    icon: Icon(
                                      Icons.edit_calendar,
                                      color:
                                          todo?.expirationDate?.isBefore(
                                                DateTime.now(),
                                              ) ??
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
                                    if (activeScopes.last ==
                                            ListScope.backlog &&
                                        activeScopes.length <= 1) {
                                      return; // no date selection possible for backlog
                                    }

                                    final nextList = manager.getNextList(
                                      selectedScope,
                                    );
                                    final firstDate = nextList == null
                                        ? DateTime.now()
                                        : manager
                                              .calcExpirationDate(
                                                nextList.scope,
                                              )!
                                              .add(Duration(days: 1));

                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                          context: context,
                                          initialDate:
                                              selectedDate ?? DateTime.now(),
                                          firstDate: firstDate,
                                          lastDate: manager.calcExpirationDate(
                                            selectedScope,
                                          )!,
                                        );
                                    if (pickedDate != null) {
                                      expirationDateController.value =
                                          TextEditingValue(
                                            text: pickedDate.formatYmD(locale),
                                          );
                                    }
                                  },
                                  validator: (value) {
                                    if (selectedScope == ListScope.backlog) {
                                      return null;
                                    }
                                    if (value == null) {
                                      return loc.noDateelectedError;
                                    }
                                    final selectedDate = tryParseLocalized(
                                      value,
                                      locale,
                                    );
                                    if (selectedDate == null) {
                                      return '${loc.invalidDateFormatError}: $value';
                                    }

                                    final fittingScope = manager
                                        .getScopeForExpirationDate(
                                          selectedDate,
                                        );
                                    if (fittingScope == null) {
                                      return loc.dateDoesNotFitAnyListError;
                                    }
                                    if (fittingScope != selectedScope) {
                                      return '${loc.dateDoesNotFitListError}: ${selectedScope.label(context)}';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tagLoc.connectedTags}:',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          SizedBox(height: 5),
                          StreamBuilder<List<Tag>>(
                            stream: tagRepository.watchTags(),
                            builder: (context, snapshot) {
                              final tagLoc = TagsLocalizations.of(context);
                              if (snapshot.hasData) {
                                final tags = snapshot.data!;
                                if (tags.isEmpty) {
                                  return Center(
                                    child: Text(tagLoc.noTagsAvailable),
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
                                    tagLoc.errorLoadingTags,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontStyle: FontStyle.italic),
                                  );
                                }
                                return Text(
                                  tagLoc.loadingTags,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                );
                              }
                            },
                          ),
                          if (todo != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${loc.createdOn}: '
                              '${todo!.creationDate.formatYmD(locale)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Footer
                Container(
                  key: footerKey,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  color: backgroundColor,
                  child: Row(
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
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        child: Text(
                          MaterialLocalizations.of(context).saveButtonLabel,
                        ),
                        onPressed: () async {
                          if (isTodoEdited) {
                            if (formKey.currentState!.validate()) {
                              late final Todo todoToReturn;
                              final selectedExpirationDate =
                                  selectedScope == ListScope.backlog
                                  ? null
                                  : parseLocalized(
                                      expirationDateController.text,
                                      locale,
                                    );
                              if (isNewTodo) {
                                todoToReturn = Todo(
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
                    ],
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
