import 'dart:math';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/ui/base_bottom_sheet.dart';
import 'package:zen_do/core/ui/standard_buttons.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/ui/tag_widget.dart';

import '../l10n/tags_l10n_extension.dart';

class TagEditSheet extends StatefulWidget {
  final Tag? initialTag;
  final TagRepository repository;

  const TagEditSheet({this.initialTag, required this.repository, super.key});

  @override
  State<TagEditSheet> createState() => _TagEditSheetState();
}

class _TagEditSheetState extends State<TagEditSheet> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  final Set<Color> _colorPreset = {
    Colors.blue,
    Colors.blueGrey,
    Colors.indigo,
    Colors.teal,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  };

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialTag?.name ?? '',
    );
    _selectedColor = Color(
      widget.initialTag?.color ??
          _colorPreset
              .elementAt(Random().nextInt(_colorPreset.length))
              .toARGB32(),
    );
  }

  void _save() {
    if (_nameController.text.isEmpty) return;

    if (widget.initialTag == null) {
      widget.repository.createTag(
        name: _nameController.text.trim(),
        color: _selectedColor.toARGB32(),
      );
    } else {
      widget.repository.updateTag(
        widget.initialTag!.copyWith(
          name: _nameController.text.trim(),
          color: _selectedColor.toARGB32(),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      maxHeight: 0.965,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initialTag == null
                ? context.tagsL10n.addNewTag
                : context.tagsL10n.editTag,
            style: TextTheme.of(context).headlineSmall,
          ),
          const SizedBox(height: 2),
          TagWidget.preview(
            name: _nameController.text,
            colorValue: _selectedColor.toARGB32(),
          ),
          const SizedBox(height: 5),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.tagsL10n.tagNameLabel,
            ),
            autofocus: true,
            maxLength: 25,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),

          Container(
            constraints: const BoxConstraints(
              minHeight: 460,
              minWidth: 300,
              maxWidth: 380,
            ),
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (Color color) => setState(() {
                _selectedColor = color;
              }),
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.wheel: true,
              },
              pickerTypeLabels: {
                ColorPickerType.primary:
                    context.tagsL10n.colorPickerPrimaryLable,
                ColorPickerType.wheel: context.tagsL10n.colorPickerWheelLable,
              },
              heading: Text(context.tagsL10n.tagColorHeading),
              subheading: Text(context.tagsL10n.tagColorSubheading),
              wheelSubheading: Text(context.tagsL10n.tagColorSubheading),
              showColorName: true,
            ),
          ),
        ],
      ),
      footer: CancelSaveButtonPair(
        onCancelPressed: () => Navigator.of(context).pop(),
        onSavePressed: _save,
      ),
    );
  }
}
