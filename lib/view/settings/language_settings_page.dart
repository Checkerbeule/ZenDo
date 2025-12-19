import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/localization/generated/settings/settings_localizations.dart';
import 'package:zen_do/utils/locale_helper.dart';

Logger logger = Logger(level: Level.debug);

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = SettingsLocalizations.of(context);
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
        title: Text(loc.languageSettingsHeadline),
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
          contentPadding: EdgeInsets.only(right: 10),
          sections: [
            SettingsSection(
              title: Text(
                loc.chooseLanguage,
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
              tiles: [
                SettingsTile.switchTile(
                  initialValue: useSystemLanguage,
                  title: Text(loc.useSystemLanguageLabel),
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
