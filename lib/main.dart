import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/model/list_manager.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/persistence_helper.dart';
import 'package:zen_do/todo_list_page.dart';
import 'package:zen_do/zen_do_lifecycle_listener.dart';

Logger logger = Logger(level: Level.debug);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initHive();

  unawaited(Workmanager().initialize(callbackDispatcher));
  unawaited(
    Workmanager().registerPeriodicTask(
      "dailyTodoTransfer",
      "transferExpiredTodos",
      frequency: const Duration(hours: 24),
      initialDelay: _durationUntilNextMidnight(),
    ),
  );

  WidgetsBinding.instance.addObserver(ZenDoLifecycleListener());

  runApp(const ZenDoApp());
}

Future<void> initHive() async {
  //TODO move to PersistenceHelper
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(TodoListAdapter());
  Hive.registerAdapter(ListScopeAdapter());
}

Duration _durationUntilNextMidnight() {
  final now = DateTime.now();
  final nextMidnight = DateTime(
    now.year,
    now.month,
    now.day + 1,
    0,
    5,
  ); // 00:05 Uhr
  return nextMidnight.difference(now);
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "transferExpiredTodos":
        await _runWithRetries(task, () async {
          return await ListManager.autoTransferExpiredTodos();
        });
        break;
      default:
        logger.e('Unknown task $task');
        break;
    }

    return Future.value(true);
  });
}

Future<void> _runWithRetries(
  String taskname,
  Future<bool> Function() task, {
  int maxRetries = 5,
  Duration delay = const Duration(minutes: 5),
}) async {
  logger.i('Running task $taskname...');
  for (int i = 0; i < maxRetries; i++) {
    final successfull = await task();
    if (successfull) {
      logger.i('[Workmanager] Task $taskname successfully finished');
      return;
    } else {
      logger.w(
        "[Workmanager] Task $taskname NOT successful – retrying in ${delay.inMinutes} min... (Attempt ${i + 1}/$maxRetries)",
      );
      await Future.delayed(delay);
    }
  }
  logger.e("[Workmanager] Task $taskname failed after $maxRetries attempts.");
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
  }

  Future<void> _initData() async {
    final lists = await PersistenceHelper.loadAll();
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
