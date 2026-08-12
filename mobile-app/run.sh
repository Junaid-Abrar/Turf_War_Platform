#!/usr/bin/env bash
#
# Runs the app with the --dart-define flags built from a local .env file.
#
# Flutter cannot read a .env at runtime, so every configuration value has to be
# passed on the command line. Typing five --dart-define flags by hand is how the
# hardcoded ngrok URL ended up committed in the first place; this wrapper reads
# .env instead.
#
#   cp .env.example .env      # then edit
#   ./run.sh                  # flutter run on the default device
#   ./run.sh -d chrome        # any extra args pass through to flutter
#
# To build instead of run:
#   ./run.sh build apk --release
set -euo pipefail

cd "$(dirname "$0")"

ENV_FILE="${ENV_FILE:-.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "No $ENV_FILE found. Copy the template first:" >&2
  echo "  cp .env.example $ENV_FILE" >&2
  exit 1
fi

DEFINES=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip blanks and comments.
  [[ -z "${line// }" || "$line" == \#* ]] && continue
  # Strip an optional `export ` prefix and surrounding quotes on the value.
  line="${line#export }"
  key="${line%%=*}"
  value="${line#*=}"
  value="${value%\"}"; value="${value#\"}"
  value="${value%\'}"; value="${value#\'}"
  DEFINES+=(--dart-define="${key}=${value}")
done < "$ENV_FILE"

# Default to `run` when the first argument is a flag or absent.
if [[ $# -eq 0 || "$1" == -* ]]; then
  set -- run "$@"
fi

echo "flutter $1 with $((${#DEFINES[@]})) defines from $ENV_FILE"
exec flutter "$@" "${DEFINES[@]}"
