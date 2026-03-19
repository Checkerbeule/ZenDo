#!/bin/bash
SCRIPT_DIR=$(dirname "$(realpath "$0")")
FEATURES_DIR="${SCRIPT_DIR}/../../features"
COMMON_OPTS="--no-nullable-getter"

# generate global app localizations
dart run arb_utils sort --natural-ordering "${SCRIPT_DIR}/app_en.arb"
dart run arb_utils sort --natural-ordering "${SCRIPT_DIR}/app_de.arb"
flutter gen-l10n ${COMMON_OPTS} \
	--arb-dir "${SCRIPT_DIR}" \
	--template-arb-file "app_en.arb" \
	--output-dir "${SCRIPT_DIR}" \
	--output-localization-file "app_localizations.dart" \
	--output-class "AppLocalizations"

# generate feature localizations
for feature_path in "${FEATURES_DIR}"/*; do
	if [ -d "${feature_path}/l10n" ]; then
		FEATURE_NAME=$(basename "$feature_path")
		L10N_DIR="${feature_path}/l10n"

		echo "Processing feature: ${FEATURE_NAME}..."

		# sort .arb files
		for arb_file in "${L10N_DIR}"/*.arb; do
			dart run arb_utils sort --natural-ordering "${arb_file}"
		done

		# generate localization classes
		CLASS_NAME="$(tr '[:lower:]' '[:upper:]' <<<"${FEATURE_NAME:0:1}")${FEATURE_NAME:1}Localizations"
		flutter gen-l10n ${COMMON_OPTS} \
			--arb-dir "${L10N_DIR}" \
			--template-arb-file "${FEATURE_NAME}_en.arb" \
			--output-dir "${L10N_DIR}" \
			--output-localization-file "${FEATURE_NAME}_localizations.dart" \
			--output-class "${CLASS_NAME}"
	fi
done

echo "L10n generation complete!"
