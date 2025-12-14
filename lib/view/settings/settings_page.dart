import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zen_do/view/settings/lists_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // TODO implement hasChanged properly for multiple settings changes
  bool hasChanged = false;
  String? appVersion = '';
  String? appBuildNumber = '';

  void _close() {
    Navigator.pop(context, hasChanged);
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      setState(() {
        appVersion = info.version;
        appBuildNumber = info.appName;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionsTextStyle = TextStyle(
      color: Theme.of(context).primaryColorDark,
    );
    return PopScope<bool>(
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
          title: Text('Settings'),
        ),
        body: SettingsList(
          contentPadding: EdgeInsets.only(bottom: 10),
          sections: [
            SettingsSection(
              title: Text('Allgemein', style: sectionsTextStyle),
              tiles: [
                SettingsTile(
                  title: Text('Theme'),
                  leading: Icon(Icons.color_lens),
                ),
                SettingsTile(
                  title: Text('Benachrichtigungen'),
                  leading: Icon(Icons.notifications),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Organisation', style: sectionsTextStyle),
              tiles: [
                SettingsTile.navigation(
                  title: Text('Listen'),
                  description: Text('Aufgaben-Listen wählen'),
                  leading: Icon(Icons.view_column),
                  onPressed: (context) async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (context) => const ListsSettingsPage(),
                      ),
                    );
                    hasChanged = changed ?? false;
                  },
                ),
                SettingsTile(title: Text('Labels'), leading: Icon(Icons.label)),
              ],
            ),
            SettingsSection(
              title: Text('Support', style: sectionsTextStyle),
              tiles: [
                SettingsTile(
                  title: Text('Bewerten im Store'),
                  leading: Icon(Icons.star),
                ),
                SettingsTile(
                  title: Text('Feddback geben'),
                  leading: Icon(Icons.mail),
                ),
                SettingsTile(
                  title: Text('Support the dev'),
                  leading: Icon(Icons.volunteer_activism),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Rechtliches', style: sectionsTextStyle),
              tiles: [
                SettingsTile(
                  title: Text('Über'),
                  leading: Icon(Icons.info_outline),
                ),
                SettingsTile(
                  title: Text('Datenschutz'),
                  leading: Icon(Icons.privacy_tip),
                ),
                SettingsTile(
                  title: Text('AGB / LIzenz'),
                  leading: Icon(Icons.description),
                ),
                SettingsTile(
                  title: Text('Version'),
                  description: Text('$appVersion\n$appBuildNumber'),
                  leading: Icon(Icons.tag),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
