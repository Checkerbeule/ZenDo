import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

abstract class AppSettingsService {
  Future<void> saveSortOption(ListScope scope, TodoSortOption sortOption);
  TodoSortOption? getSortOption(ListScope scope);
  Future<void> saveSortOrder(ListScope scope, SortOrder sortOrder);
  SortOrder? getSortOrder(ListScope scope);

  // TODO move critical settings about todo lists to drift DB
  Future<void> saveActiveListScopes(Set<ListScope> activeScopes);
  Set<ListScope>? getActiveListScopes();
  Future<void> addActiveScope(ListScope activeScope);
  Future<void> removeActiveScope(ListScope activeScope);
}

class SharedPrefsAppSettingsService implements AppSettingsService {
  // Singleton instance
  static SharedPrefsAppSettingsService? _instance;
  // internal constructor
  SharedPrefsAppSettingsService._internal(this.prefs);
  // getInstance method to provide access to the singleton
  static Future<SharedPrefsAppSettingsService> getInstance() async {
    return _instance ??= SharedPrefsAppSettingsService._internal(
      await SharedPreferences.getInstance(),
    );
  }

  late final SharedPreferences prefs;

  final _sortOptionLock = Lock();
  final _sortOrderLock = Lock();
  final _listScopesLock = Lock();

  String _getSortOptionPrefKey(ListScope scope) =>
      'todo.list.${scope.name}.sortOption';
  String _getSortOrderPrefKey(ListScope scope) =>
      'todo.list.${scope.name}.sortOrder';

  static const String _activeListScopesPrefKey = 'todo.manager.activeScopes';

  @override
  Future<void> saveSortOption(ListScope scope, TodoSortOption sortOption) async {
    await _sortOptionLock.synchronized(
      () async =>
          await prefs.setInt(_getSortOptionPrefKey(scope), sortOption.index),
    );
  }

  @override
  TodoSortOption? getSortOption(ListScope scope) {
    final index = prefs.getInt(_getSortOptionPrefKey(scope));
    return index == null ? null : TodoSortOption.values[index];
  }

  @override
  Future<void> saveSortOrder(ListScope scope, SortOrder sortOrder) async {
    await _sortOrderLock.synchronized(
      () async =>
          await prefs.setInt(_getSortOrderPrefKey(scope), sortOrder.index),
    );
  }

  @override
  SortOrder? getSortOrder(ListScope scope) {
    final index = prefs.getInt(_getSortOrderPrefKey(scope));
    return index == null ? null : SortOrder.values[index];
  }

  @override
  Future<void> saveActiveListScopes(Set<ListScope> activeScopes) async {
    await _listScopesLock.synchronized(
      () async => await prefs.setStringList(
        _activeListScopesPrefKey,
        activeScopes.map((s) => s.name).toList(),
      ),
    );
  }

  @override
  Set<ListScope>? getActiveListScopes() {
    final List<String>? scopeNames = prefs.getStringList(
      _activeListScopesPrefKey,
    );
    return scopeNames?.map((n) => ListScope.values.byName(n)).toSet();
  }

  @override
  Future<void> addActiveScope(ListScope activeScope) async {
    await _listScopesLock.synchronized(() async {
      final scopeNames = prefs.getStringList(_activeListScopesPrefKey) ?? [];
      if (!scopeNames.contains(activeScope.name)) {
        scopeNames.add(activeScope.name);
        await prefs.setStringList(_activeListScopesPrefKey, scopeNames);
      }
    });
  }

  @override
  Future<void> removeActiveScope(ListScope scope) async {
    await _listScopesLock.synchronized(() async {
      final scopeNames = prefs.getStringList(_activeListScopesPrefKey) ?? [];
      if (scopeNames.remove(scope.name)) {
        await prefs.setStringList(_activeListScopesPrefKey, scopeNames);
      }
    });
  }
}
