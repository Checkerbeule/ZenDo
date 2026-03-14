import 'package:flutter/material.dart';
import 'package:zen_do/core/persistence/app_database.dart';

class TagWidget extends StatelessWidget {
  final String name;
  final int color;
  final String uuid;
  final bool isCompact;
  final bool isSelected;
  final void Function(String uuid)? onTap;

  const TagWidget({
    required this.name,
    required this.color,
    required this.uuid,
    this.isCompact = false,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  factory TagWidget.fromTag({
    required Tag tag,
    bool isCompact = false,
    bool isSelected = false,
    void Function(String uuid)? onTap,
  }) {
    return TagWidget(
      name: tag.name,
      color: tag.color,
      uuid: tag.uuid,
      isCompact: isCompact,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  factory TagWidget.preview({
    required String name,
    required int colorValue,
    isCompact = true,
  }) {
    return TagWidget(
      name: name,
      color: colorValue,
      uuid: 'TEMP_PREVIEW',
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(color);

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(uuid) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 5 : 10,
          vertical: isCompact ? 2 : 5,
        ),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: isSelected ? 0.4 : 0.08),
          borderRadius: BorderRadius.circular(isCompact ? 5 : 10),
          border: Border.all(
            color: baseColor.withValues(alpha: isSelected ? 1.0 : 0.8),
            width: isSelected ? (isCompact ? 1.5 : 2.5) : (isCompact ? 1 : 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.label : Icons.label_outlined,
              size: isCompact ? 16 : 20,
              color: baseColor.withValues(alpha: isSelected ? 1.0 : 0.9),
            ),
            SizedBox(width: isCompact ? 4 : 8),
            Text(name, style: TextStyle(fontSize: isCompact ? 12 : 14)),
          ],
        ),
      ),
    );
  }
}
