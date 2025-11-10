import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/main.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/persistence_helper.dart';
import 'package:zen_do/view/app_page.dart';
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
        AppPage.todos,
        listManager!.expiredTodosCount,
      );
    } catch (e, s) {
      logger.e('Loading todo lists failed: : $e\n$s');
      listManager = ListManager([], activeScopes: scopes);
    } finally {
      notifyListeners();
    }
  }

  T performAcitionOnList<T>(Function(TodoList) action, ListScope scope) {
    T result;
    if (listManager != null) {
      final list = listManager!.getListByScope(scope);
      result = action(list);
      appState.updateMessageCount(
        AppPage.todos,
        listManager!.expiredTodosCount,
      );
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
