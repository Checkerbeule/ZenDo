import 'package:flutter/material.dart';

Future<T?> showDialogWithScaleTransition<T>({
  required BuildContext context,
  required Widget child,
  Offset? tapPosition,
  Duration? transitionDuration,
  bool? barrierDismissable,
}) async {
  final duration = transitionDuration ?? Duration(milliseconds: 200);
  final dismssable = barrierDismissable ?? true;
  final offset = tapPosition ?? Offset.zero;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismssable,
    barrierColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.5),
    barrierLabel: '', // needed if barrierDissmissabel is false
    transitionDuration: duration,
    pageBuilder: (context, anim1, anim2) {
      return child;
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        origin: offset, //TODO calculate correct origin position
        child: child,
      );
    },
  );
}

class DeleteDialog extends StatefulWidget {
  const DeleteDialog({required this.title, required this.text, super.key});

  final String title;
  final String text;

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(widget.text)],
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
          child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
