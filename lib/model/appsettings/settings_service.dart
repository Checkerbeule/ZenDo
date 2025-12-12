import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/view/todo/sliver_todo_sort_filter_app_bar.dart';

abstract class SettingsService {
  Future<void> saveSortOption(ListScope scope, SortOption sortOption);
  Future<void> saveSortOrder(ListScope scope, SortOrder sortOrder);
  Future<SortOption?> getSortOption(ListScope scope);
  Future<SortOrder?> getSortOrder(ListScope scope);
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

  Map<ListScope, SortOption> sortOptions = {};
  Map<ListScope, SortOrder> sortOrders = {};

  String _getSortOptionPrefKey(ListScope scope) {
    return 'todo.${scope.name}.list.sortOption';
  }

  String _getSortOrderPrefKey(ListScope scope) {
    return 'todo.${scope.name}.list.sortOrder';
  }

  @override
  Future<void> saveSortOption(ListScope scope, SortOption sortOption) async {
    sortOptions[scope] = sortOption;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getSortOptionPrefKey(scope), sortOption.index);
  }

  @override
  Future<void> saveSortOrder(ListScope scope, SortOrder sortOrder) async {
    sortOrders[scope] = sortOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getSortOrderPrefKey(scope), sortOrder.index);
  }

  @override
  Future<SortOption?> getSortOption(ListScope scope) async {
    if (sortOptions.containsKey(scope)) {
      return sortOptions[scope];
    }
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_getSortOptionPrefKey(scope));
    if (index != null) {
      return SortOption.values[index];
    }
    return null;
  }

  @override
  Future<SortOrder?> getSortOrder(ListScope scope) async {
    if (sortOrders.containsKey(scope)) {
      return sortOrders[scope];
    }
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_getSortOrderPrefKey(scope));
    if (index != null) {
      return SortOrder.values[index];
    }
    return null;
  }
}
