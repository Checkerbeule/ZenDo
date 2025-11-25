import 'package:flutter/material.dart';

Future<T?> showDialogWithScaleTransition<T>(
  BuildContext context,
  Offset tapPosition,
  Widget child,
  {Duration? transitionDuration}
) async {
  final duration = transitionDuration ?? Duration(milliseconds: 200);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    pageBuilder: (context, anim1, anim2) {
      return child;
    },
    barrierColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.5),
    transitionDuration: duration,
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        //origin: tapPosition, //TODO calculate correct origin position
        child: child,
      );
    },
  );
}
