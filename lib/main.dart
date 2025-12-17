import 'dart:async';

import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zen_do/callback_dispatcher.dart';
import 'package:zen_do/localization/generated/app/app_localizations.dart';
import 'package:zen_do/localization/localizations_config.dart';
import 'package:zen_do/persistence/hive_initializer.dart';
import 'package:zen_do/utils/time_util.dart';
import 'package:zen_do/view/habits/habit_page.dart';
import 'package:zen_do/view/page_type.dart';
import 'package:zen_do/view/settings/settings_page.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProviderL10n>(create: (_) => ProviderL10n()),
        ChangeNotifierProvider<ZenDoAppState>(create: (_) => ZenDoAppState()),
        ChangeNotifierProxyProvider<ZenDoAppState, TodoState>(
          create: (_) => TodoState(),
          update: (_, appState, todoState) => todoState!..setAppState(appState),
        ),
      ],
      child: Consumer<ProviderL10n>(
        builder: (context, l10n, child) {
          return MaterialApp(
            title: 'ZenDo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
            ),
            locale: l10n.locale,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ZenDoMainPage(),
          );
        },
      ),
    );
  }
}

class ZenDoAppState extends ChangeNotifier {
  Map<PageType, int> pageMessages = {
    PageType.todos: 0,
    PageType.habits: 0,
    PageType.notes: 0,
  };

  void updateMessageCount(PageType page, int newCount) {
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
              'ZenDo ꞏ ${appState.pageMessages.keys.elementAt(pageIndex).label(context)}',
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () async {
                  final hasChanged = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                  if (!context.mounted) return;
                  if (hasChanged ?? false) {
                    context.read<TodoState>().reload();
                  }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: pageIndex,
            children: [
              TodoPage(),
              HabitPage(), //TODO implement Habit Page
              Center(
                child: Text(PageType.notes.label(context)),
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
