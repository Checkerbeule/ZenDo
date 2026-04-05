import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/domain/page_type.dart';
import 'package:zen_do/core/l10n/app_l10n_extension.dart';
import 'package:zen_do/core/persistence/hive/persistence_helper.dart';
import 'package:zen_do/core/ui/loading_screen.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';
import 'package:zen_do/features/todos/domain/list_manager.dart';
import 'package:zen_do/features/todos/l10n/todos_localizations.dart';
import 'package:zen_do/features/todos/ui/todo_list_screen.dart';
import 'package:zen_do/main.dart';

Logger logger = Logger(level: Level.debug);

class TodoState extends ChangeNotifier {
  ZenDoAppState? appState;
  ListManager? listManager;
  bool isLoading = true;
  bool isLoadingDataFailed = false;
  String? errorMessage;
  Map<ListScope, bool> doneTodosExpanded = {};
  Set<String> tagFilters = {};

  TodoState() {
    _initData();
  }

  void setAppState(ZenDoAppState appState) {
    this.appState = appState;
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
    final AppSettingsService settings =
        await SharedPrefsAppSettingsService.getInstance();
    final loadedScopes = settings.getActiveListScopes();
    final Set<ListScope> activeScopes;
    if (loadedScopes != null) {
      activeScopes = loadedScopes;
    } else {
      activeScopes = {
        ListScope.daily,
        ListScope.weekly,
        ListScope.yearly,
        ListScope.backlog,
      };
      settings.saveActiveListScopes(activeScopes);
    }

    try {
      List<TodoList> loadedLists = await PersistenceHelper.loadAll();
      listManager = ListManager(loadedLists, activeScopes: activeScopes);

      var prefs = await SharedPreferences.getInstance();
      var lastTransferDateString = prefs.getString('lastTodoTransferDate');
      var now = DateTime.now().toIso8601String().substring(0, 10);
      if (lastTransferDateString == null || lastTransferDateString != now) {
        logger.d(
          'Transfering todos on app start. Last run: $lastTransferDateString',
        );
        listManager!.transferTodos();
        await prefs.setString('lastTodoTransferDate', now);
      }

      isLoading = false;

      appState?.updateMessageCount(
        PageType.todos,
        listManager!.expiredTodosCount,
      );

      for (var l in listManager!.lists) {
        doneTodosExpanded[l.scope] = false;
      }
    } catch (e, s) {
      logger.e('Loading todo lists failed: : $e\n$s');
      isLoadingDataFailed = true;
      errorMessage = e.toString();
      listManager = ListManager([], activeScopes: activeScopes);
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

  Future<T> performAcitionOnList<T>(FutureOr<T> Function() action) async {
    T result;
    if (listManager != null) {
      result = await action();
      appState!.updateMessageCount(
        PageType.todos,
        listManager!.expiredTodosCount,
      );
      if (T is bool && result == false) {
        return false as T;
      }
      notifyListeners();
    } else if (T is bool) {
      result = false as T;
    } else if (T == Null) {
      result = null as T;
    } else {
      throw Exception(
        '[TodoState] Cannot perform action on list because ListManager is not initialized!',
      );
    }
    return result;
  }
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = TodosLocalizations.of(context);
    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        final listManager = todoState.listManager;
        if (todoState.isLoadingDataFailed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLoadingErrorDialog(context, todoState.errorMessage!);
          });
        }

        return todoState.isLoading
            ? LoadingScreen(message: loc.loadingTodosIndicator)
            : DefaultTabController(
                initialIndex: 0,
                length: listManager!.listCount,
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    toolbarHeight: 0,
                    bottom: TabBar(
                      labelPadding: const EdgeInsets.symmetric(horizontal: 15),
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      dividerColor: Theme.of(context).primaryColor,
                      tabs: [
                        for (var list in listManager.lists)
                          Tab(
                            height: 60,
                            icon: Badge(
                              isLabelVisible:
                                  listManager.toBeTransferredOrExpiredCount(
                                    list,
                                  ) >
                                  0,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.tertiary,
                              label: Text(
                                '${listManager.toBeTransferredOrExpiredCount(list)}',
                              ),
                              child: Icon(list.scope.icon),
                            ),
                            text: list.scope.listName(context),
                          ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: <Widget>[
                      for (var list in listManager.lists)
                        TodoListScreen(list: list),
                    ],
                  ),
                ),
              );
      },
    );
  }
}

void _showLoadingErrorDialog(BuildContext context, String errorMessage) async {
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.appL10n.dataLoadErrorHeadline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            Text(context.appL10n.dataLoadErrorMessage),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(context.appL10n.openAppSettings),
            onPressed: () {
              AppSettings.openAppSettings(
                type: AppSettingsType.settings,
                asAnotherTask: false,
              );
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(context.appL10n.closeApp),
            onPressed: () {
              SystemNavigator.pop();
            },
          ),
        ],
      );
    },
  );
}
