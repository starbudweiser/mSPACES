#!/bin/bash
# Publie une version : compile, notarise, pousse main et crée la release GitHub.
# Usage : ./release.sh <version> [notes]
set -euo pipefail
cd "$(dirname "$0")"
V="${1:?version}"; NOTES="${2:-mSPACES $V}"
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "modifications non commitées" >&2; exit 1; }
./build.sh "$V"
rm -rf build/notarized
DIST="$PWD/build/notarized" /Volumes/SKYRIM/TOOLS/MAC/_tools/notarize_app.sh "$HOME/Applications/Applications Personnelles/mSPACES.app"
git push origin main
gh release create "$V" build/notarized/mSPACES.zip --repo starbudweiser/mSPACES --target main --title "mSPACES $V" --notes "$NOTES"
