dir_path=$(dirname $(realpath $0))

dart run arb_utils sort --natural-ordering ${dir_path}/arb/app/app_en.arb
dart run arb_utils sort --natural-ordering ${dir_path}/arb/app/app_de.arb
flutter gen-l10n --no-nullable-getter --arb-dir ${dir_path}/arb/app --template-arb-file app_en.arb --output-dir ${dir_path}/generated/app --output-localization-file app_localizations.dart --output-class AppLocalizations

dart run arb_utils sort --natural-ordering ${dir_path}/arb/todo/todo_en.arb
dart run arb_utils sort --natural-ordering ${dir_path}/arb/todo/todo_de.arb
flutter gen-l10n --no-nullable-getter --arb-dir ${dir_path}/arb/todo --template-arb-file todo_en.arb --output-dir ${dir_path}/generated/todo --output-localization-file todo_localizations.dart --output-class TodoLocalizations

dart run arb_utils sort --natural-ordering ${dir_path}/arb/settings/settings_en.arb
dart run arb_utils sort --natural-ordering ${dir_path}/arb/settings/settings_de.arb
flutter gen-l10n --no-nullable-getter --arb-dir ${dir_path}/arb/settings --template-arb-file settings_en.arb --output-dir ${dir_path}/generated/settings --output-localization-file settings_localizations.dart --output-class SettingsLocalizations


