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

class BaseDialog extends StatelessWidget {
  const BaseDialog({required this.title, required this.text, super.key});

  final String title;
  final String text;

  List<Widget> getActions(BuildContext context) => [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: getActions(context),
    );
  }
}

class DeleteDialog extends BaseDialog {
  const DeleteDialog({required super.title, required super.text, super.key});

  @override
  List<Widget> getActions(BuildContext context) => [
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
  ];
}

class OkCancelDialog extends BaseDialog {
  const OkCancelDialog({
    required super.title,
    required super.text,
    super.key,
    this.okButtonText,
    this.cancelButtonText,
  });

  final String? okButtonText;
  final String? cancelButtonText;

  @override
  List<Widget> getActions(BuildContext context) => [
    TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
      child: Text(
        cancelButtonText ?? MaterialLocalizations.of(context).cancelButtonLabel,
      ),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    ),
    OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Text(
        okButtonText ?? MaterialLocalizations.of(context).okButtonLabel,
      ),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    ),
  ];
}
