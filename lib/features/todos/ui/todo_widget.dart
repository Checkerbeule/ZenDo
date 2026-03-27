import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/theme/theme.dart';
import 'package:zen_do/core/ui/dialog_helper.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/data/todo.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';
import 'package:zen_do/features/todos/l10n/todos_l10n_extension.dart';
import 'package:zen_do/features/todos/ui/todo_edit_sheet.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

class TodoWidget extends StatefulWidget {
  final Todo todo;
  final TodoList list;

  const TodoWidget({super.key, required this.todo, required this.list});

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
  StreamSubscription<List<Tag>>? _tagSubscription;
  Map<String, Tag> _tagsByUuid = {};

  @override
  void initState() {
    super.initState();
    _tagSubscription = context.read<TagRepository>().watchTags().listen((
      allTags,
    ) {
      if (mounted) {
        setState(() {
          _tagsByUuid = {for (var tag in allTags) tag.uuid: tag};
        });
      }
    });
  }

  @override
  void dispose() {
    _tagSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoState = context.read<TodoState>();
    final listManager = todoState.listManager!;
    final isExpiredOrToBeTransferred =
        listManager.toBeTransferredTomorrow(widget.todo) ||
        (widget.todo.expirationDate != null &&
            widget.todo.expirationDate!.isBefore(DateTime.now()));
    final isTodoCompleted = widget.todo.completionDate != null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadiusGeometry.all(AppTheme.smallRadius),
        side: BorderSide(
          color: isExpiredOrToBeTransferred && !isTodoCompleted
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      elevation: 0.2,
      child: Badge(
        offset: const Offset(2, 2),
        padding: const EdgeInsets.all(0),
        alignment: Alignment.topLeft,
        backgroundColor: Colors.transparent,
        isLabelVisible: isExpiredOrToBeTransferred && !isTodoCompleted,
        label: Icon(
          Icons.access_time_outlined,
          size: 15,
          color: Theme.of(context).colorScheme.error,
        ),
        child: ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          onTap: isTodoCompleted
              ? null
              : () async {
                  final updatedTodo = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => TodoEditSheet.editTodo(
                      todo: widget.todo,
                      todoState: todoState,
                    ),
                  );

                  if (updatedTodo != null) {
                    if (updatedTodo.listScope != widget.todo.listScope) {
                      todoState.performAcitionOnList(
                        () => listManager.moveAndUpdateTodo(
                          oldTodo: widget.todo,
                          todo: updatedTodo,
                          destination: updatedTodo.listScope!,
                        ),
                      );
                    } else {
                      todoState.performAcitionOnList<bool>(
                        () => listManager
                            .getListByScope(updatedTodo.listScope!)!
                            .replaceTodo(widget.todo, updatedTodo),
                      );
                    }
                  }
                },
          leading: IconButton(
            onPressed: () => isTodoCompleted
                ? todoState.performAcitionOnList<bool>(
                    () => widget.list.restoreTodo(widget.todo),
                  )
                : {
                    todoState.performAcitionOnList<void>(
                      () => widget.list.markAsDone(widget.todo),
                    ),
                  },
            icon: Icon(
              isTodoCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.todo.title,
                overflow: TextOverflow.ellipsis,
                style: isTodoCompleted
                    ? TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).disabledColor,
                      )
                    : null,
              ),

              if (widget.todo.description != null &&
                  widget.todo.description!.isNotEmpty)
                Text(
                  widget.todo.description!,
                  maxLines: 1,
                  style: TextStyle(
                    decoration: isTodoCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: Theme.of(context).disabledColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          subtitle: Wrap(
            alignment: WrapAlignment.start,
            spacing: 2,
            runSpacing: 2,
            children: widget.todo.tagUuids.map((uuid) {
              final tag = _tagsByUuid[uuid];
              if (tag == null) {
                return const SizedBox.shrink();
              }

              return Icon(
                Icons.label,
                size: 14,
                color: Color(_tagsByUuid[uuid]!.color).withValues(alpha: 0.8),
              );
            }).toList(),
          ),
          trailing: isTodoCompleted
              ? null
              : IconButton(
                  onPressed: () async {
                    final delete = await showDialogWithScaleTransition<bool>(
                      context: context,
                      child: DeleteDialog(
                        title: '${context.todosL10n.deleteTodo}?',
                        text: context.todosL10n.deleteTodoQuestion,
                      ),
                    );
                    if (delete != null && delete) {
                      todoState.performAcitionOnList<bool>(
                        () => widget.list.deleteTodo(widget.todo),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  color: Theme.of(context).colorScheme.tertiary,
                ),
        ),
      ),
    );
  }
}
