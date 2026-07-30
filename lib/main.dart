import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/domain/page_type.dart';
import 'package:zen_do/core/domain/zen_do_lifecycle_listener.dart';
import 'package:zen_do/core/l10n/app_localizations.dart';
import 'package:zen_do/core/l10n/localizations_delegates.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/persistence/hive/hive_initializer.dart';
import 'package:zen_do/core/persistence/hive_to_drift_migration_service.dart';
import 'package:zen_do/core/theme/theme.dart';
import 'package:zen_do/core/ui/coming_soon_screen.dart';
import 'package:zen_do/features/settings/ui/settings_screen.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/domain/tag_service.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/domain/todo_service.dart';
import 'package:zen_do/features/todos/ui/todo_screen.dart';

Logger logger = Logger(level: Level.debug);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveInitializer.initFlutter();

  WidgetsBinding.instance.addObserver(ZenDoLifecycleListener());

  final database = AppDatabase();

  try {
    database.executor.ensureOpen(database);
    final migrationService = HiveToDriftMigrationService(database);
    await migrationService.migrate();
  } catch (e) {
    logger.e("Migration from Hive to Drift failed: $e");
  }

  final AppSettingsService settingsService =
      await SharedPrefsAppSettingsService.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => database,
          dispose: (_, db) => db.close(),
        ),
        Provider<AppSettingsService>.value(value: settingsService),
      ],
      child: const ZenDoApp(),
    ),
  );
}

class ZenDoApp extends StatelessWidget {
  const ZenDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider<AppDatabase>(
        //   create: (_) => AppDatabase(),
        //   dispose: (_, db) => db.close(),
        // ),
        ProxyProvider<AppDatabase, EntityRepository>(
          update: (_, db, _) => EntityRepository(db),
        ),
        ProxyProvider<AppDatabase, TagRepository>(
          update: (_, db, _) => TagRepository(db),
        ),
        ProxyProvider2<TagRepository, EntityRepository, TagService>(
          update: (_, tagRepo, entityRepo, _) =>
              TagService(tagRepo: tagRepo, entityRepo: entityRepo),
        ),
        ProxyProvider4<
          AppDatabase,
          EntityRepository,
          TagRepository,
          AppSettingsService,
          TodoService
        >(
          update: (_, db, entityRepo, tagRepo, settingsService, _) =>
              TodoService(
                todoRepo: TodoRepository(db),
                entityRepo: entityRepo,
                todoTagsRepo: TodoTagsRepository(db),
                tagRepo: tagRepo,
                settingsService: settingsService,
              ),
        ),

        ChangeNotifierProvider<ProviderL10n>(create: (_) => ProviderL10n()),
        ChangeNotifierProvider<TodoState>(create: (_) => TodoState()),
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

class ZenDoMainPage extends StatefulWidget {
  const ZenDoMainPage({super.key});

  @override
  State<ZenDoMainPage> createState() => _ZenDoMainPageState();
}

class _ZenDoMainPageState extends State<ZenDoMainPage> {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'ZenDo ꞏ ${PageType.values.elementAt(pageIndex).label(context)}',
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
              const ComingSoonScreen(feature: 'Notes'),
              const ComingSoonScreen(feature: 'Habit tracking'),
              const ComingSoonScreen(feature: 'Pomodoro timer'),
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
              // TODO [#73] implement proper state and page management
              StreamBuilder<int>(
                stream: todoService.watchExpiredCount(),
                builder: (context, snapshot) {
                  final hasExpiredTodos =
                      snapshot.hasData && snapshot.data! > 0;
                  return Badge(
                    offset: Offset(-25, 5),
                    isLabelVisible: hasExpiredTodos,
                    label: Text(snapshot.data?.toString() ?? ""),
                    child: NavigationDestination(
                      icon: Icon(PageType.todos.icon),
                      label: PageType.todos.label(context),
                      selectedIcon: Icon(
                        PageType.todos.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              Badge(
                offset: Offset(-25, 5),
                isLabelVisible: false,
                label: Text(PageType.notes.label(context)),
                child: NavigationDestination(
                  icon: Icon(PageType.notes.icon),
                  label: PageType.notes.label(context),
                  selectedIcon: Icon(
                    PageType.notes.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Badge(
                offset: Offset(-25, 5),
                isLabelVisible: false,
                label: Text(PageType.habits.label(context)),
                child: NavigationDestination(
                  icon: Icon(PageType.habits.icon),
                  label: PageType.habits.label(context),
                  selectedIcon: Icon(
                    PageType.habits.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Badge(
                offset: Offset(-25, 5),
                isLabelVisible: false,
                label: Text(PageType.pomodoro.label(context)),
                child: NavigationDestination(
                  icon: Icon(PageType.pomodoro.icon),
                  label: PageType.pomodoro.label(context),
                  selectedIcon: Icon(
                    PageType.pomodoro.icon,
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
