import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/main.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistence/persistence_helper.dart';
import 'package:zen_do/view/page_type.dart';
import 'package:zen_do/view/loading_screen.dart';
import 'package:zen_do/view/todo/todo_list_page.dart';

Logger logger = Logger(level: Level.debug);

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoState(context.read<ZenDoAppState>()),
      builder: (context, child) {
        return _TodoView();
      },
    );
  }
}

class TodoState extends ChangeNotifier {
  final ZenDoAppState appState;
  ListManager? listManager;
  bool isLoadingDataFailed = false;
  String? errorMessage;

  TodoState(this.appState) {
    _initData();
  }

  Future<void> _initData() async {
    Set<ListScope> scopes = {
      //TODO #46 make dynamic based on user preferences
      ListScope.daily,
      ListScope.weekly,
      ListScope.yearly,
      ListScope.backlog,
    };
    try {
      List<TodoList> loadedLists = await PersistenceHelper.loadAll();
      listManager = ListManager(loadedLists, activeScopes: scopes);
      appState.updateMessageCount(
        PageType.todos,
        listManager!.expiredTodosCount,
      );
    } catch (e, s) {
      logger.e('Loading todo lists failed: : $e\n$s');
      isLoadingDataFailed = true;
      errorMessage = e.toString();
      listManager = ListManager([], activeScopes: scopes);
    } finally {
      notifyListeners();
    }
  }

  T performAcitionOnList<T>(Function() action) {
    T result;
    if (listManager != null) {
      result = action();
      appState.updateMessageCount(
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

  //TODO #46 make dynamic based on user preferences
  /* void addList(TodoList list) {
    listManager?.addList(list);
    notifyListeners();
  }

  void removeList(TodoList list) {
    listManager?.removeList(list);
    notifyListeners();
  } */
}

class _TodoView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoState>(
      builder: (context, todoState, child) {
        final listManager = todoState.listManager;
        if (todoState.isLoadingDataFailed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLoadingErrorDialog(context, todoState.errorMessage!);
          });
        }

        return listManager == null
            ? LoadingScreen(message: 'Lade Aufgaben...')
            : DefaultTabController(
                initialIndex: 0,
                length: listManager.listCount,
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
                            text: list.scope.label,
                          ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
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
      return AlertDialog(
        title: const Text('Laden der Daten fehlgeschlagen !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage),
            SizedBox(height: 16),
            Text(
              'Schließen Sie die App und öffenen Sie sie zu einem späteren Zeitpunkt erneut.',
            ),
            Text(
              'Sollte der Fehler anschließend weiterhin bestehen, löschen Sie den App-Cache (Ihre Daten bleiben erhalten).',
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Einstellungen öffnen'),
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
            child: const Text('App schließen'),
            onPressed: () {
              SystemNavigator.pop();
            },
          ),
        ],
      );
    },
  );
}
