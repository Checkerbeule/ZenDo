import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/features/settings/l10n/settings_l10n_extension.dart';
import 'package:zen_do/features/settings/ui/language_settings_page.dart';
import 'package:zen_do/features/settings/ui/lists_settings_page.dart';
import 'package:zen_do/features/settings/utils/locale_helper.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/tags/ui/tag_management_screen.dart';

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
    final sectionsTextStyle = TextStyle(
      color: Theme.of(context).primaryColorDark,
    );
    final locale =
        context.read<ProviderL10n>().locale ?? Localizations.localeOf(context);
    final String language = getLanguageLabel(context, locale);

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
          title: Text(context.settingsL10n.settings),
        ),
        body: SettingsList(
          contentPadding: const EdgeInsets.only(bottom: 10),
          sections: [
            SettingsSection(
              title: Text(
                context.settingsL10n.commonSettingsSection,
                style: sectionsTextStyle,
              ),
              tiles: [
                SettingsTile(
                  title: Text(context.settingsL10n.themeSettingsLabel),
                  leading: const Icon(Icons.color_lens),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.notificationsSettingsLabel),
                  leading: const Icon(Icons.notifications),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.backupSettingsLable),
                  leading: const Icon(Icons.backup),
                ),
                SettingsTile.navigation(
                  title: Text(context.settingsL10n.languageSettingsLabel),
                  leading: const Icon(Icons.translate),
                  description: Text(language),
                  onPressed: (context) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsPage(),
                    ),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                context.settingsL10n.organizationSettingsLabel,
                style: sectionsTextStyle,
              ),
              tiles: [
                SettingsTile.navigation(
                  title: Text(context.settingsL10n.lists),
                  description: Text(
                    context.settingsL10n.listsSettingsDescription,
                  ),
                  leading: const Icon(Icons.view_column),
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
                SettingsTile.navigation(
                  title: const Text('Tags'),
                  description: Text(
                    context.settingsL10n.tagsSettingsDescription,
                  ),
                  leading: const Icon(Icons.label),
                  onPressed: (context) async {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (context) => TagManagementScreen(
                          repository: context.read<TagRepository>(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                context.settingsL10n.feedbackSettingsSection,
                style: sectionsTextStyle,
              ),
              tiles: [
                SettingsTile(
                  title: Text(context.settingsL10n.feedbackInStore),
                  leading: const Icon(Icons.star),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.feedbackViaMail),
                  leading: const Icon(Icons.mail),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.supportTheDev),
                  leading: const Icon(Icons.volunteer_activism),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                context.settingsL10n.legalSettingsSection,
                style: sectionsTextStyle,
              ),
              tiles: [
                SettingsTile(
                  title: Text(context.settingsL10n.aboutSettingsLabel),
                  leading: const Icon(Icons.info_outline),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.privacyPolicy),
                  leading: const Icon(Icons.privacy_tip),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.termsAndConditions),
                  leading: const Icon(Icons.description),
                ),
                SettingsTile(
                  title: Text(context.settingsL10n.versionSettingsLabel),
                  description: Text('$appVersion\n$appBuildNumber'),
                  leading: const Icon(Icons.tag),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
