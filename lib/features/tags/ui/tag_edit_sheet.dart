import 'dart:math';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:zen_do/core/persistence/app_database.dart';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
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
          const SizedBox(height: 2),
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
              minHeight: 450,
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

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(MaterialLocalizations.of(context).saveButtonLabel),
                onPressed: () {
                  _save();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
