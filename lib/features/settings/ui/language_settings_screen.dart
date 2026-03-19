import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/features/settings/l10n/settings_l10n_extension.dart';
import 'package:zen_do/features/settings/l10n/settings_localizations.dart';
import 'package:zen_do/features/settings/utils/locale_helper.dart';

Logger logger = Logger(level: Level.debug);

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<ProviderL10n>();
    final locale = l10n.locale ?? Localizations.localeOf(context);
    final useSystemLanguage = l10n.locale == null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.settingsL10n.languageSettingsHeadline),
      ),
      body: RadioGroup<Locale>(
        groupValue: locale,
        onChanged: (Locale? value) {
          if (value != null) {
            l10n.locale = value;
          } else {
            logger.w('Localization could not be changed!');
          }
        },
        child: SettingsList(
          contentPadding: const EdgeInsets.only(right: 10),
          sections: [
            SettingsSection(
              title: Text(
                context.settingsL10n.chooseLanguage,
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
              tiles: [
                SettingsTile.switchTile(
                  initialValue: useSystemLanguage,
                  title: Text(context.settingsL10n.useSystemLanguageLabel),
                  onToggle: (useSystemDefault) async {
                    if (useSystemDefault) {
                      l10n.locale = null;
                    } else {
                      l10n.locale = locale;
                    }
                  },
                ),
                for (final Locale locale
                    in SettingsLocalizations.supportedLocales)
                  SettingsTile(
                    enabled: !useSystemLanguage,
                    title: Text(getLanguageLabel(context, locale)),
                    trailing: Radio(value: locale, enabled: !useSystemLanguage),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
