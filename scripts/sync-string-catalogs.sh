#!/usr/bin/env bash
# Refreshes Localizable.xcstrings in FabrixDesign and FabrixFeatures from the source.
# A fresh SwiftPM build writes one .stringsdata file per source file; xcstringstool
# merges them into each module's catalog and drops keys that are no longer used.
set -euo pipefail

package=Packages/FabrixKit
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

xcrun swift build --package-path "$package" --scratch-path "$scratch" --target FabrixFeatures --quiet >/dev/null 2>&1 || xcrun swift build --package-path "$package" --scratch-path "$scratch" --target FabrixFeatures

for module in FabrixDesign FabrixFeatures; do
  args=()
  while IFS= read -r file; do
    args+=(--stringsdata "$file")
  done < <(find "$scratch" -path "*/$module-t.build/Objects-normal/*/*.stringsdata" ! -name 'ExtractedAppShortcuts*')
  xcrun xcstringstool sync "$package/Sources/$module/Resources/Localizable.xcstrings" "${args[@]}"
  echo "synced $module (${#args[@]} source files)"
done
