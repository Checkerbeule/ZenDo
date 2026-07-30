import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/theme/theme.dart';
import 'package:zen_do/core/ui/dialog_helper.dart';
import 'package:zen_do/features/tags/domain/tag_service.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_service.dart';
import 'package:zen_do/features/todos/l10n/todos_l10n_extension.dart';
import 'package:zen_do/features/todos/ui/todo_edit_sheet.dart';

class TodoCard extends StatefulWidget {
  final TodoDto todo;

  const TodoCard({super.key, required this.todo});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  StreamSubscription<List<Tag>>? _tagSubscription;
  Map<String, Tag> _tagsByUuid = {};

  @override
  void initState() {
    super.initState();
    _tagSubscription = context.read<TagService>().watchAll().listen((allTags) {
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
    final todoService = context
        .read<TodoService>(); // TODO use consumer widget
    final todo = widget.todo;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadiusGeometry.all(AppTheme.smallRadius),
        side: BorderSide(
          color: switch (todo) {
            _ when !todo.isCompleted && todo.isExpired => Theme.of(
              context,
            ).colorScheme.error.withValues(alpha: 0.5),
            _ when !todo.isCompleted && todo.willBeTransferred => Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.5),
            _ => Colors.transparent,
          },
        ),
      ),
      elevation: 0.2,
      child: Badge(
        offset: const Offset(2, 2),
        padding: const EdgeInsets.all(0),
        alignment: Alignment.topLeft,
        backgroundColor: Colors.transparent,
        isLabelVisible:
            !todo.isCompleted && (todo.isExpired || todo.willBeTransferred),
        label: Icon(
          todo.isExpired
              ? Icons.access_time_outlined
              : Icons.arrow_circle_left_outlined,
          size: 15,
          color: todo.isExpired
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.tertiary,
        ),
        child: ListTile(
          visualDensity: const VisualDensity(vertical: -4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          onTap: todo.isCompleted
              ? null
              : () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => TodoEditSheet.editTodo(todo: todo),
                  );
                },
          leading: IconButton(
            icon: Icon(
              todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () async {
              if (todo.isCompleted) {
                await todoService.restore(todo);
              } else {
                await todoService.markAsCompleted(todo.uuid);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                todo.title,
                overflow: TextOverflow.ellipsis,
                style: todo.isCompleted
                    ? TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).disabledColor,
                      )
                    : null,
              ),

              if (todo.description != null && todo.description!.isNotEmpty)
                Text(
                  todo.description!,
                  maxLines: 1,
                  style: TextStyle(
                    decoration: todo.isCompleted
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
            children: todo.tagUuids.map((uuid) {
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
          trailing: todo.isCompleted
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
                      await todoService.delete(todo);
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
