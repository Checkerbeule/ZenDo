import 'package:flutter/material.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/ui/dialog_helper.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/domain/tag_delete_service.dart';
import 'package:zen_do/features/tags/l10n/tags_localizations.dart';
import 'package:zen_do/features/tags/ui/tag_edit_sheet.dart';
import 'package:zen_do/features/tags/ui/tag_widget.dart';

class TagManagementScreen extends StatelessWidget {
  final TagRepository repository;
  final TagDeleteService tagService;

  TagManagementScreen({required this.repository, super.key})
    : tagService = TagDeleteService(tagRepo: repository);

  void _openEditor(BuildContext context, Tag? tag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          TagEditSheet(initialTag: tag, repository: repository),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = TagsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
              loc.manageTagsScreenHeader,
              style: TextStyle(color: Theme.of(context).primaryColorDark),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Tag>>(
              stream: repository.watchTags(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(loc.errorLoadingTags));
                }

                final tags = snapshot.data ?? [];
                if (tags.isEmpty) {
                  return Padding(
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
                            loc.noTagsAvailable,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(loc.addSomeTags, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        title: TagWidget.fromTag(tag: tags[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_forever),
                              onPressed: () async {
                                final delete =
                                    await showDialogWithScaleTransition<bool>(
                                      context: context,
                                      child: DeleteDialog(
                                        title: loc.deleteTagTitle,
                                        text: loc.deleteTagMessage(
                                          tags[index].name,
                                        ),
                                      ),
                                    );
                                if (delete != null && delete) {
                                  tagService.deleteTagAndcleanupReferences(
                                    tags[index],
                                  );
                                }
                              },
                            ),
                            IconButton(
                              onPressed: () =>
                                  _openEditor(context, tags[index]),
                              icon: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        label: Text(loc.addTag),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
