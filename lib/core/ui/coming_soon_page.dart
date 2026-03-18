import 'package:flutter/material.dart';
import 'package:zen_do/core/l10n/app_l10n_extension.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 80,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              feature,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Coming soon!", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              "${context.appL10n.comingSoonMessage} 🚀",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
