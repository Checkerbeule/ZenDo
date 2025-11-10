import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/callback_dispatcher.dart';
import 'package:zen_do/persistance/hive_initializer.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/app_page.dart';
import 'package:zen_do/view/todo/todo_page.dart';
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

class ZenDoAppState extends ChangeNotifier {
  Map<AppPage, int> pageMessages = {
    AppPage.todos: 0,
    AppPage.habits: 0,
    AppPage.notes: 0,
  };

  //TODO use this on every todo update (delete, restore, markAsDone)
  void updateMessageCount(AppPage page, int newCount) {
    if (pageMessages[page] == newCount) return;
    pageMessages[page] = newCount;
    notifyListeners();
  }
}

class ZenDoMainPage extends StatefulWidget {
  const ZenDoMainPage({super.key});

  @override
  State<ZenDoMainPage> createState() => _ZenDoMainPageState();
}

class _ZenDoMainPageState extends State<ZenDoMainPage> {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ZenDoAppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'ZenDo ${appState.pageMessages.keys.elementAt(pageIndex).label(context)}',
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(icon: Icon(Icons.settings), onPressed: () => {}),
            ], //TODO implement settings,
          ),
          body: IndexedStack(
            index: pageIndex,
            children: [
              TodoPage(),
              Center(
                child: Text(AppPage.habits.label(context)),
              ), //TODO implement Habit Page
              Center(
                child: Text(AppPage.notes.label(context)),
              ), //TODO implement notes Page
            ],
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            indicatorColor: Theme.of(context).colorScheme.inversePrimary,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                );
              }
              return TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              );
            }),
            selectedIndex: pageIndex,
            onDestinationSelected: (int index) {
              setState(() {
                pageIndex = index;
              });
            },
            destinations: <Widget>[
              for (var page in appState.pageMessages.entries)
                NavigationDestination(
                  icon: page.value > 0
                      ? Badge(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          label: Text('${page.value}'),
                          child: Icon(page.key.icon),
                        )
                      : Icon(page.key.icon),
                  label: page.key.label(context),
                  selectedIcon: page.value > 0
                      ? Badge(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          label: Text('${page.value}'),
                          child: Icon(
                            page.key.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Icon(
                          page.key.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}
