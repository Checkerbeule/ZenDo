import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:zen_do/core/app/app_settings_service.dart';
import 'package:zen_do/core/ui/loading_screen.dart';
import 'package:zen_do/features/settings/l10n/settings_l10n_extension.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';

class ListsSettingsScreen extends StatefulWidget {
  const ListsSettingsScreen({super.key});

  @override
  State<ListsSettingsScreen> createState() => _ListsSettingsScreenState();
}

class _ListsSettingsScreenState extends State<ListsSettingsScreen> {
  bool isLoading = true;
  late final Map<ListScope, bool> initialLists;
  Map<ListScope, bool> activeLists = {
    for (final scope in ListScope.values) scope: false,
  };
  late final AppSettingsService settings;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    settings = await SharedPrefsAppSettingsService.getInstance();
    if (!mounted) return;

    setState(() {
      final Set<ListScope>? activeScopes = settings.getActiveListScopes();
      if (activeScopes != null) {
        for (final scope in activeScopes) {
          activeLists[scope] = true;
        }
      }
      initialLists = {...activeLists};
      isLoading = false;
    });
  }

  void _close() {
    int activeScopesCount = 0;
    for (final value in activeLists.values) {
      if (value) activeScopesCount++;
    }
    if (activeScopesCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.settingsL10n.minOneListErrorMessage)),
      );
    } else {
      final hasChanged = !mapEquals(initialLists, activeLists);
      Navigator.pop(context, hasChanged);
    }
  }

  void toggleCheckbox(bool? value, ListScope scope) {
    setState(() {
      if (value != null) {
        activeLists[scope] = value;
        if (value) {
          settings.addActiveScope(scope);
        } else {
          settings.removeActiveScope(scope);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _close(),
          ),
          title: Text(context.settingsL10n.lists),
        ),
        body: isLoading
            ? LoadingScreen(
                message: context.settingsL10n.loadingSettingsMessage,
              )
            : SettingsList(
                contentPadding: const EdgeInsets.only(right: 10),
                sections: [
                  SettingsSection(
                    title: Text(
                      context.settingsL10n.choosePreferredListsSettingsLabel,
                      style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    tiles: [
                      for (final scope in ListScope.values)
                        SettingsTile.switchTile(
                          initialValue: activeLists[scope],
                          onToggle: (value) {
                            setState(() {
                              activeLists[scope] = value;
                              if (value) {
                                settings.addActiveScope(scope);
                              } else {
                                settings.removeActiveScope(scope);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Icon(
                                scope.icon,
                                color: !activeLists[scope]!
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                scope.listName(context),
                                style: TextStyle(
                                  color: !activeLists[scope]!
                                      ? Theme.of(context).disabledColor
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
