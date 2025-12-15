import 'package:arb_utils/state_managers/l10n_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zen_do/config/localization/generated/app_localizations.dart';
import 'package:zen_do/utils/locale_helper.dart';

Logger logger = Logger(level: Level.debug);

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  Locale? _localeName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _localeName =
          context.read<ProviderL10n>().locale ??
          Localizations.localeOf(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.lists),
      ),
      body: RadioGroup<Locale>(
        groupValue: _localeName,
        onChanged: (Locale? value) {
          setState(() {
            _localeName = value;
          });
          if (value != null) {
            context.read<ProviderL10n>().locale = value;
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
                for (final Locale locale in AppLocalizations.supportedLocales)
                  SettingsTile(
                    title: Text(getLanguageLabel(context, locale)),
                    trailing: Radio(value: locale),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
