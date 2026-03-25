import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/ui/dialog_helper.dart';
import 'package:zen_do/core/utils/fractional_index_reordering.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/domain/tag_delete_service.dart';
import 'package:zen_do/features/tags/ui/tag_edit_sheet.dart';
import 'package:zen_do/features/tags/ui/tag_widget.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

import '../l10n/tags_l10n_extension.dart';

class TagManagementScreen extends StatefulWidget {
  final TagRepository repository;
  final TagDeleteService tagService;

  TagManagementScreen({required this.repository, super.key})
    : tagService = TagDeleteService(tagRepo: repository);

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final List<String> _deletedTagUuids = [];
  List<Tag> _loadedTags = [];
  StreamSubscription<List<Tag>>? _tagSubscription;

  @override
  void initState() {
    super.initState();
    _tagSubscription = widget.repository.watchTags().listen((newData) {
      if (_isDifferentData(newData)) {
        setState(() {
          _loadedTags = newData;
        });
      }
    });
  }

  @override
  void dispose() {
    _tagSubscription?.cancel();
    super.dispose();
  }

  bool _isDifferentData(List<Tag> newData) {
    if (newData.length != _loadedTags.length) return true;

    for (int i = 0; i < newData.length; i++) {
      if (newData[i].uuid != _loadedTags[i].uuid ||
          newData[i].name != _loadedTags[i].name ||
          newData[i].color != _loadedTags[i].color) {
        return true;
      }
    }

    return false;
  }

  void _close() {
    context.read<TodoState>().removeTagsFromFilter(_deletedTagUuids);
    Navigator.pop(context);
  }

  void _openEditor(BuildContext context, Tag? tag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          TagEditSheet(initialTag: tag, repository: widget.repository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _close(),
          ),
          title: Text('Tags'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsGeometry.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Text(
                context.tagsL10n.manageTagsScreenHeader,
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
            ),
            Expanded(
              child: _loadedTags.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.new_label_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tagsL10n.noTagsAvailable,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              context.tagsL10n.addSomeTags,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _loadedTags.length,
                      onReorder: (oldIndex, newIndex) async {
                        final String newFractionalIndex =
                            FractionalIndexReordering.generateFractionalIndex(
                              list: _loadedTags,
                              oldIndex: oldIndex,
                              newIndex: newIndex,
                              getIndex: (tag) => tag.customOrder,
                            );
                        if (newFractionalIndex ==
                            _loadedTags[oldIndex].customOrder) {
                          return;
                        }

                        final updatedTag = _loadedTags[oldIndex].copyWith(
                          customOrder: newFractionalIndex,
                        );

                        setState(() {
                          _loadedTags.removeAt(oldIndex);
                          final targetIndex = oldIndex < newIndex
                              ? newIndex - 1
                              : newIndex;
                          _loadedTags.insert(targetIndex, updatedTag);
                        });

                        await widget.repository.updateTag(updatedTag);
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) {
                            return Transform.scale(
                              scale: 1.01,
                              child: Material(
                                elevation: 5,
                                color: Colors.transparent,
                                borderRadius: BorderRadiusGeometry.all(
                                  Radius.circular(10),
                                ),
                                child: child,
                              ),
                            );
                          },
                        );
                      },
                      itemBuilder: (context, index) {
                        return Card(
                          key: ValueKey(_loadedTags[index].uuid),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            title: TagWidget.fromTag(tag: _loadedTags[index]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_forever),
                                  onPressed: () async {
                                    final isDeleted =
                                        await showDialogWithScaleTransition<
                                          bool
                                        >(
                                          context: context,
                                          child: DeleteDialog(
                                            title:
                                                context.tagsL10n.deleteTagTitle,
                                            text: context.tagsL10n
                                                .deleteTagMessage(
                                                  _loadedTags[index].name,
                                                ),
                                          ),
                                        );
                                    if (isDeleted == true) {
                                      _deletedTagUuids.add(
                                        _loadedTags[index].uuid,
                                      );
                                      widget.tagService
                                          .deleteTagAndcleanupReferences(
                                            _loadedTags[index],
                                          );
                                    }
                                  },
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _openEditor(context, _loadedTags[index]),
                                  icon: const Icon(Icons.edit),
                                ),
                                const Icon(Icons.drag_indicator),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, null),
          label: Text(context.tagsL10n.addTag),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
