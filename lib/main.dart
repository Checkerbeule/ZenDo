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
      //TODO use MultiProvider
      create: (context) => TodoState(),
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

class ZenDoAppState extends ChangeNotifier {} //not used at the moment

class ZenDoMainPage extends StatefulWidget {
  const ZenDoMainPage({super.key});

  @override
  State<ZenDoMainPage> createState() => _ZenDoMainPageState();
}

class _ZenDoMainPageState extends State<ZenDoMainPage> {
  int pageIndex = 0;
  final Map<String, IconData> _pageIcons = {
    'Listen': Icons.view_list_outlined,
    'Habits': Icons.track_changes,
    'Notizen': Icons.edit_note,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZenDo ${_pageIcons.keys.elementAt(pageIndex)}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () => {}),
        ], //TODO implement settings,
      ),
      body: IndexedStack(
        index: pageIndex,
        children: [
          const TodoPage(),
          const Center(child: Text('Habit Page')), //TODO implement Habit Page
          const Center(child: Text('Notizen Page')), //TODO implement notes Page
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
          for (var entry in _pageIcons.entries)
            NavigationDestination(
              icon: Icon(entry.value),
              label: entry.key,
              selectedIcon: Icon(
                entry.value,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
