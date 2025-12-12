import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/view/todo/sliver_todo_sort_filter_app_bar.dart';

abstract class SettingsService {
  Future<void> saveSortOption(ListScope scope, SortOption sortOption);
  Future<void> saveSortOrder(ListScope scope, SortOrder sortOrder);
  Future<SortOption?> getSortOption(ListScope scope);
  Future<SortOrder?> getSortOrder(ListScope scope);

  Future<void> saveActiveListScopes(Set<ListScope> activeScopes);
  Future<Set<ListScope>?> getActiveListScopes();
  Future<void> addActiveScope(ListScope activeScope);
  Future<void> removeActiveScope(ListScope activeScope);
}

class SharedPrefsSettingsService implements SettingsService {
  // Singleton instance
  static SharedPrefsSettingsService? _instance;
  // internal constructor
  SharedPrefsSettingsService._internal(this.prefs);
  // getInstance method to provide access to the singleton
  static Future<SharedPrefsSettingsService> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = SharedPrefsSettingsService._internal(prefs);
    return _instance!;
  }

  late final SharedPreferences prefs;

  final Map<ListScope, SortOption> _sortOptions = {};
  final Map<ListScope, SortOrder> _sortOrders = {};

  Set<ListScope>? _activeListScopes;

  String _getSortOptionPrefKey(ListScope scope) =>
      'todo.list.${scope.name}.sortOption';
  String _getSortOrderPrefKey(ListScope scope) =>
      'todo.list.${scope.name}.sortOrder';

  static const String _activeListScopesPrefKey = 'todo.manager.activeScopes';

  @override
  Future<void> saveSortOption(ListScope scope, SortOption sortOption) async {
    _sortOptions[scope] = sortOption;
    await prefs.setInt(_getSortOptionPrefKey(scope), sortOption.index);
  }

  @override
  Future<void> saveSortOrder(ListScope scope, SortOrder sortOrder) async {
    _sortOrders[scope] = sortOrder;
    await prefs.setInt(_getSortOrderPrefKey(scope), sortOrder.index);
  }

  @override
  Future<SortOption?> getSortOption(ListScope scope) async {
    if (_sortOptions.containsKey(scope)) {
      return _sortOptions[scope];
    }
    final index = prefs.getInt(_getSortOptionPrefKey(scope));
    return index == null ? null : SortOption.values[index];
  }

  @override
  Future<SortOrder?> getSortOrder(ListScope scope) async {
    if (_sortOrders.containsKey(scope)) {
      return _sortOrders[scope];
    }
    final index = prefs.getInt(_getSortOrderPrefKey(scope));
    return index == null ? null : SortOrder.values[index];
  }

  @override
  Future<void> saveActiveListScopes(Set<ListScope> activeScopes) async {
    _activeListScopes = {...activeScopes};
    await prefs.setStringList(
      _activeListScopesPrefKey,
      _toScopeNameList(activeScopes),
    );
  }

  @override
  Future<Set<ListScope>?> getActiveListScopes() async {
    if (_activeListScopes != null) return _activeListScopes;
    final List<String>? scopeNames = prefs.getStringList(
      _activeListScopesPrefKey,
    );
    if (scopeNames != null) {
      _activeListScopes = _toListScopeSet(scopeNames);
    }
    return _activeListScopes;
  }

  @override
  Future<void> addActiveScope(ListScope activeScope) async {
    _activeListScopes ??= {};
    if (!_activeListScopes!.contains(activeScope)) {
      _activeListScopes!.add(activeScope);
      await prefs.setStringList(
        _activeListScopesPrefKey,
        _toScopeNameList(_activeListScopes!),
      );
    }
  }

  @override
  Future<void> removeActiveScope(ListScope scope) async {
    if (_activeListScopes != null) {
      _activeListScopes!.remove(scope);
      await prefs.setStringList(
        _activeListScopesPrefKey,
        _toScopeNameList(_activeListScopes!),
      );
    }
  }

  List<String> _toScopeNameList(Set<ListScope> scopes) {
    final List<String> scopeNames = [];
    for (final s in scopes) {
      scopeNames.add(s.name);
    }
    return scopeNames;
  }

  Set<ListScope> _toListScopeSet(List<String> names) {
    final Set<ListScope> scopeSet = {};
    for (final n in names) {
      scopeSet.add(ListScope.values.byName(n));
    }
    return scopeSet;
  }
}
