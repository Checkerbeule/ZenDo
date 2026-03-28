import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/app/page_type.dart';
import 'package:zen_do/core/app/zen_do_lifecycle_listener.dart';
import 'package:zen_do/core/l10n/app_localizations.dart';
import 'package:zen_do/core/l10n/localizations_delegates.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/hive/hive_initializer.dart';
import 'package:zen_do/core/theme/theme.dart';
import 'package:zen_do/core/ui/coming_soon_screen.dart';
import 'package:zen_do/features/settings/ui/settings_screen.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

Logger logger = Logger(level: Level.debug);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveInitializer.initFlutter();

  WidgetsBinding.instance.addObserver(ZenDoLifecycleListener());

  runApp(const ZenDoApp());
}

class ZenDoApp extends StatelessWidget {
  const ZenDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, TagRepository>(
          update: (_, db, __) => TagRepository(db),
        ),
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
            theme: AppTheme.lightTheme,
            locale: l10n.locale,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ZenDoMainPage(),
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
    PageType.pomodoro: 0,
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
                padding: const EdgeInsets.all(5),
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  final hasChanged = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  if (!context.mounted) return;
                  if (hasChanged == true) {
                    context.read<TodoState>().reload();
                  }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: pageIndex,
            children: [
              const TodoScreen(),
              const ComingSoonScreen(feature: 'Habit tracking'),
              const ComingSoonScreen(feature: 'Pomodoro timer'),
              const ComingSoonScreen(feature: 'Notes'),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: pageIndex,
            onDestinationSelected: (int index) {
              setState(() {
                pageIndex = index;
              });
            },
            destinations: <Widget>[
              for (var page in appState.pageMessages.entries)
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: page.value > 0,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    label: Text('${page.value}'),
                    child: Icon(page.key.icon),
                  ),
                  label: page.key.label(context),
                  selectedIcon: Badge(
                    isLabelVisible: page.value > 0,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    label: Text('${page.value}'),
                    child: Icon(
                      page.key.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
