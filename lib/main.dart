import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/persistance_helper.dart';
import 'package:zen_do/todo_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(TodoListAdapter());
  Hive.registerAdapter(ListScopeAdapter());

  runApp(const ZenDoApp());
}

class ZenDoApp extends StatelessWidget {
  const ZenDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ZenDoAppState(),
      child: MaterialApp(
        title: 'ZenDo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        ),
        home: ZenDoHomePage(),
      ),
    );
  }
}

class ZenDoAppState extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class ZenDoHomePage extends StatefulWidget {
  const ZenDoHomePage({super.key});

  @override
  State<ZenDoHomePage> createState() => _ZenDoHomePageState();
}

class _ZenDoHomePageState extends State<ZenDoHomePage> {
  int pageIndex = 0;
  ListManager? listManager;

  @override
  void initState() {
    super.initState();
    _initData();
    AppLifecycleListener(
      onHide: () => unawaited(PersistanceHelper.close()),
      onInactive: () => unawaited(PersistanceHelper.close()),
      onPause: () => unawaited(PersistanceHelper.close()),
      onDetach: () => unawaited(PersistanceHelper.close()),
    );
  }

  Future<void> _initData() async {
    final lists = await PersistanceHelper.loadAll();
    listManager = ListManager(lists);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: listManager == null
          ? Scaffold(
              appBar: AppBar(
                title: const Text('ZenDo Listen'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              body: Center(child: CircularProgressIndicator()),
            )
          : IndexedStack(
              index: pageIndex,
              children: [
                DefaultTabController(
                  initialIndex: 0,
                  length: listManager!.listCount,
                  child: Scaffold(
                    appBar: AppBar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      title: const Text('ZenDo Listen'),
                      bottom: TabBar(
                        tabs: [
                          for (var list in listManager!.allLists)
                            Tab(
                              icon: Icon(list.scope.icon),
                              text: list.scope.label,
                            ),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        for (var list in listManager!.allLists)
                          TodoListPage(list: list),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Text('Habit Page'),
                ), //TODO implement Habit Page
                const Center(
                  child: Text('Einstellungen'),
                ), //TODO implement Settings Page
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            pageIndex = index;
          });
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            label: 'Listen',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
