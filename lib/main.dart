import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/callback_dispatcher.dart';
import 'package:zen_do/persistance/hive_initializer.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/todo_page.dart';
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
  Map<String, (IconData icon, int messageCount)> pageData = {
    'Listen': (Icons.view_list_outlined, 0),
    'Habits': (Icons.track_changes, 1),
    'Notizen': (Icons.edit_note, 5),
  }; //TODO don't use fake message counts

  void updateMessageCount(String title, int newCount) {
    var page = pageData[title];
    if (page == null) {
      logger.w('Failed to update message count for unknown page: $title');
      return;
    }
    if (page.$2 == newCount) return;
    pageData[title] = (page.$1, newCount);
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
            title: Text('ZenDo ${appState.pageData.keys.elementAt(pageIndex)}'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(icon: Icon(Icons.settings), onPressed: () => {}),
            ], //TODO implement settings,
          ),
          body: IndexedStack(
            index: pageIndex,
            children: [
              TodoPage(pageName: appState.pageData.keys.elementAt(0)),
              Center(
                child: Text(appState.pageData.keys.elementAt(1)),
              ), //TODO implement Habit Page
              Center(
                child: Text(appState.pageData.keys.elementAt(2)),
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
              for (var page in appState.pageData.entries)
                NavigationDestination(
                  icon: page.value.$2 > 0
                      ? Badge(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          label: Text('${page.value.$2}'),
                          child: Icon(page.value.$1),
                        )
                      : Icon(page.value.$1),
                  label: page.key,
                  selectedIcon: page.value.$2 > 0
                      ? Badge(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          label: Text('${page.value.$2}'),
                          child: Icon(
                            page.value.$1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Icon(
                          page.value.$1,
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
