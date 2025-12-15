import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zen_do/config/localization/generated/app_localizations.dart';
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

  void _close() {
    Navigator.pop(context, hasChanged);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sectionsTextStyle = TextStyle(
      color: Theme.of(context).primaryColorDark,
    );
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
          title: Text(loc.settings),
        ),
        body: SettingsList(
          contentPadding: EdgeInsets.only(bottom: 10),
          sections: [
            SettingsSection(
              title: Text(loc.commonSettingsSection, style: sectionsTextStyle),
              tiles: [
                SettingsTile(
                  title: Text(loc.themeSettingsLabel),
                  leading: Icon(Icons.color_lens),
                ),
                SettingsTile(
                  title: Text(loc.notificationsSettingsLabel),
                  leading: Icon(Icons.notifications),
                ),
              ],
            ),
            SettingsSection(
              title: Text(loc.organizationSettingsLabel, style: sectionsTextStyle),
              tiles: [
                SettingsTile.navigation(
                  title: Text(loc.lists),
                  description: Text(loc.listsSettingsDescription),
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
                SettingsTile(title: Text(loc.labelsSettingsLabel), leading: Icon(Icons.label)),
              ],
            ),
            SettingsSection(
              title: Text(loc.feedbackSettingsSection, style: sectionsTextStyle),
              tiles: [
                SettingsTile(
                  title: Text(loc.feedbackInStore),
                  leading: Icon(Icons.star),
                ),
                SettingsTile(
                  title: Text(loc.feedbackViaMail),
                  leading: Icon(Icons.mail),
                ),
                SettingsTile(
                  title: Text(loc.supportTheDev),
                  leading: Icon(Icons.volunteer_activism),
                ),
              ],
            ),
            SettingsSection(
              title: Text(loc.legalSettingsSection, style: sectionsTextStyle),
              tiles: [
                SettingsTile(
                  title: Text(loc.aboutSettingsLabel),
                  leading: Icon(Icons.info_outline),
                ),
                SettingsTile(
                  title: Text(loc.privacyPolicy),
                  leading: Icon(Icons.privacy_tip),
                ),
                SettingsTile(
                  title: Text(loc.termsAndConditions),
                  leading: Icon(Icons.description),
                ),
                SettingsTile(
                  title: Text(loc.versionSettingsLabel),
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
