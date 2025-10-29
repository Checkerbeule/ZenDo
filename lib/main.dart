import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/callback_dispatcher.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/hive_initializer.dart';
import 'package:zen_do/persistance/persistence_helper.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/todo_list_page.dart';
import 'package:zen_do/zen_do_lifecycle_listener.dart';

Logger logger = Logger(level: Level.debug);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(HiveInitializer.initFlutter());

  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    "dailyTodoTransfer",
    "transferExpiredTodos",
    frequency: const Duration(hours: 24),
    initialDelay: durationUntilNextMidnight(),
  );

  WidgetsBinding.instance.addObserver(ZenDoLifecycleListener());

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
        home: ZenDoMainPage(),
      ),
    );
  }
}

class ZenDoAppState extends ChangeNotifier {} // not used at the moment

class ZenDoMainPage extends StatefulWidget {
  const ZenDoMainPage({super.key});

  @override
  State<ZenDoMainPage> createState() => _ZenDoMainPageState();
}

class _ZenDoMainPageState extends State<ZenDoMainPage> {
  int pageIndex = 0;
  ListManager? listManager;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    List<TodoList> lists;
    try {
      lists = await PersistenceHelper.loadAll();
    } catch (e, s) {
      logger.e('Loading todo lists failed: : $e\n$s');
      lists = [];
    }
    listManager = ListManager(
      lists,
      activeScopes: {
        ListScope.daily,
        ListScope.weekly,
        ListScope.yearly,
        ListScope.backlog,
      },
    );
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
