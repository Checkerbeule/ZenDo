import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/config/localization/app_localizations.dart';
import 'package:zen_do/main.dart';
import 'package:zen_do/model/appsettings/settings_service.dart';
import 'package:zen_do/model/todo/list_manager.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo_list.dart';
import 'package:zen_do/persistence/persistence_helper.dart';
import 'package:zen_do/view/page_type.dart';
import 'package:zen_do/view/loading_screen.dart';
import 'package:zen_do/view/todo/todo_list_page.dart';

Logger logger = Logger(level: Level.debug);

class TodoState extends ChangeNotifier {
  ZenDoAppState? appState;
  ListManager? listManager;
  bool isLoading = true;
  bool isLoadingDataFailed = false;
  String? errorMessage;
  Map<ListScope, bool> doneTodosExpanded = {};

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

  Future<void> _initData() async {
    final SettingsService settings =
        await SharedPrefsSettingsService.getInstance();
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
      isLoading = false;

      appState?.updateMessageCount(
        PageType.todos,
        listManager!.expiredTodosCount,
      );

      for (var l in listManager!.allLists) {
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

  T performAcitionOnList<T>(Function() action) {
    T result;
    if (listManager != null) {
      result = action();
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

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
                      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      dividerColor: Theme.of(context).primaryColor,
                      tabs: [
                        for (var list in listManager.allLists)
                          Tab(
                            icon:
                                listManager.toBeTransferredOrExpiredCount(
                                      list,
                                    ) >
                                    0
                                ? Badge(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    label: Text(
                                      '${listManager.toBeTransferredOrExpiredCount(list)}',
                                    ),
                                    child: Icon(list.scope.icon),
                                  )
                                : Icon(list.scope.icon),
                            text: list.scope.label(context),
                          ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: <Widget>[
                      for (var list in listManager.allLists)
                        TodoListPage(list: list),
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
      final loc = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(loc.dataLoadErrorHeadline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage),
            SizedBox(height: 16),
            Text(loc.dataLoadErrorMessage),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(loc.openSettings),
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
            child: Text(loc.closeApp),
            onPressed: () {
              SystemNavigator.pop();
            },
          ),
        ],
      );
    },
  );
}
