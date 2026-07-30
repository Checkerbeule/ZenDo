import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/ui/loading_screen.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/domain/todo_service.dart';
import 'package:zen_do/features/todos/l10n/todos_localizations.dart';
import 'package:zen_do/features/todos/ui/todo_list_screen.dart';

Logger logger = Logger(level: Level.debug);

class TodoState extends ChangeNotifier {
  bool isLoading = true;
  bool isLoadingDataFailed = false;
  String? errorMessage;
  Map<ListScope, bool> doneTodosExpanded = {};
  Set<String> tagFilters = {};

  TodoState() {
    _initData();
  }

  Future<void> reload() async {
    isLoading = true;
    notifyListeners();
    await _initData();
    notifyListeners();
  }

  void removeTagsFromFilter(List<String> tagUuidsToRemove) {
    tagFilters.removeAll(tagUuidsToRemove);
    notifyListeners();
  }

  Future<void> _initData() async {
    // TODO use provider to retreive settingsService
    final AppSettingsService settings =
        await SharedPrefsAppSettingsService.getInstance();
    final activeScopes = settings.getActiveListScopes();

    try {
      var prefs = await SharedPreferences.getInstance();
      var lastTransferDateString = prefs.getString('lastTodoTransferDate');
      var now = DateTime.now().toIso8601String().substring(0, 10);
      if (lastTransferDateString == null || lastTransferDateString != now) {
        logger.d(
          'Transfering todos on app start. Last run: $lastTransferDateString',
        );
        //listManager!.transferTodos();
        //await prefs.setString('lastTodoTransferDate', now);
      }

      isLoading = false;

      for (var scope in activeScopes) {
        doneTodosExpanded[scope] = false;
      }
    } catch (e, s) {
      logger.e('Loading todo lists failed: : $e\n$s');
      isLoadingDataFailed = true;
      errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void toggleExpansion(ListScope key) {
    doneTodosExpanded[key] = !(doneTodosExpanded[key] ?? true);
  }

  Set<String> get tagFilter {
    return tagFilters;
  }

  void updateTagFilter(Set<String> updatedTagFilter) {
    tagFilters = updatedTagFilter;
    notifyListeners();
  }
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = TodosLocalizations.of(context);
    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        return Consumer<AppSettingsService>(
          builder: (context, settingsService, child) {
            return todoState.isLoading
                ? LoadingScreen(message: loc.loadingTodosIndicator)
                : DefaultTabController(
                    initialIndex: 0,
                    length: settingsService
                        .getActiveListScopes()
                        .length,
                    child: Consumer<TodoService>(
                      builder: (context, todoService, child) {
                        return Scaffold(
                          appBar: PreferredSize(
                            preferredSize: const Size.fromHeight(
                              65.0,
                            ),
                            child: AppBar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              bottom: TabBar(
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                isScrollable: true,
                                tabAlignment: TabAlignment.center,
                                dividerColor: Theme.of(context).primaryColor,
                                tabs: [
                                  for (var scope
                                      in settingsService.getActiveListScopes())
                                    StreamBuilder<int>(
                                      stream: todoService.watchWillBeTransferedOrExpiredCount(
                                        scope,
                                      ),
                                      builder: (context, snapshot) {
                                        return Tab(
                                          height: 60,
                                          icon: Badge(
                                            isLabelVisible:
                                                snapshot.hasData &&
                                                snapshot.data! > 0,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                            label: Text('${snapshot.data}'),
                                            child: Icon(scope.icon),
                                          ),
                                          text: scope.listName(context),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          body: TabBarView(
                            children: <Widget>[
                              for (var scope
                                  in settingsService.getActiveListScopes())
                                TodoListScreen(
                                  key: ValueKey(scope),
                                  listScope: scope,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
          },
        );
      },
    );
  }
}
