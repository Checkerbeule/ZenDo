import 'package:flutter/material.dart';

class TagWidget extends StatelessWidget {
  final String name;
  final int colorValue;
  final bool isCompact;

  const TagWidget({
    required this.name,
    required this.colorValue,
    this.isCompact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(colorValue);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(isCompact ? 5 : 10),
        border: Border.all(
          color: baseColor.withValues(alpha: 1.0),
          width: isCompact ? 1 : 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outlined,
            size: isCompact ? 16 : 20,
            color: baseColor,
          ),
          SizedBox(width: isCompact ? 4 : 8),
          Text(name, style: TextStyle(fontSize: isCompact ? 12 : 14)),
        ],
      ),
    );
  }
}
