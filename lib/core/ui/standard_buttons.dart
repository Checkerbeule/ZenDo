import 'package:flutter/material.dart';

class CancelButton extends StatelessWidget {
  final void Function() onPressed;

  const CancelButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.error.withValues(alpha: 0.15),
      ),
      child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
    );
  }
}

class SaveButton extends StatelessWidget {
  final void Function() onPressed;

  const SaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.5),
      ),
      child: Text(MaterialLocalizations.of(context).saveButtonLabel),
    );
  }
}

class CancelSaveButtonPair extends StatelessWidget {
  final void Function() onCancelPressed;
  final void Function() onSavePressed;

  const CancelSaveButtonPair({
    super.key,
    required this.onCancelPressed,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CancelButton(onPressed: onCancelPressed),
        const SizedBox(width: 5),
        SaveButton(onPressed: onSavePressed),
      ],
    );
  }
}
