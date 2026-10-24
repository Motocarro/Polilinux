#!/bin/sh
# OPTIONAL: download the Polimi CA chain from the ICT page into ca/.
# Needs curl and unzip. Not tested against the live site: if it fails, download the zip
# from the Polimi guide by hand and put cachain_geant_harica.pem into ca/.
set -eu
URL="https://www.ict.polimi.it/wp-content/uploads/2026/05/cachain_geant_harica.zip"
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP/ca.zip"
unzip -q -o "$TMP/ca.zip" -d "$TMP/x"
PEM=$(find "$TMP/x" -name 'cachain_geant_harica.pem' | head -n 1)
[ -n "$PEM" ] || { echo "cachain_geant_harica.pem not found inside the zip" >&2; exit 1; }
mkdir -p "$HERE/ca"
cp "$PEM" "$HERE/ca/cachain_geant_harica.pem"
echo "Saved ca/cachain_geant_harica.pem ($(grep -c 'BEGIN CERTIFICATE' "$PEM") certificate(s))."
