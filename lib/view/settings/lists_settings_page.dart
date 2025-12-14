import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:zen_do/model/appsettings/settings_service.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/view/loading_screen.dart';

class ListsSettingsPage extends StatefulWidget {
  const ListsSettingsPage({super.key});

  @override
  State<ListsSettingsPage> createState() => _ListsSettingsPageState();
}

class _ListsSettingsPageState extends State<ListsSettingsPage> {
  bool isLoading = true;
  late final Map<ListScope, bool> initialLists;
  Map<ListScope, bool> activeLists = {
    for (final scope in ListScope.values) scope: false,
  };
  late final SettingsService settings;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    settings = await SharedPrefsSettingsService.getInstance();
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
        SnackBar(content: Text('Es muss mindest eine Liste ausgewählt sein!')),
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
            icon: Icon(Icons.arrow_back),
            onPressed: () => _close(),
          ),
          title: Text('Listen'),
        ),
        body: isLoading
            ? LoadingScreen(message: 'Lade Einstellungen')
            : SettingsList(
                sections: [
                  SettingsSection(
                    title: Text(
                      'Wähle die Listen, die Du für deine Aufgaben-Organisation benutzen möchtest.',
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
                          title: Text(scope.label(context)),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
