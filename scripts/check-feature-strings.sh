#!/usr/bin/env bash
# Fails when FabrixFeatures passes a bare string literal where it is looked up as
# localized copy. Package code resolves such literals against the app's main bundle,
# so they miss the Features string catalog. Use Text("…", bundle: .module),
# String(localized: "…", bundle: .module) or .features("…") instead.
set -euo pipefail

root="${1:-Packages/FabrixKit/Sources/FabrixFeatures}"

patterns=(
  # Design components
  '\b(SectionCard|EmptyRow|LabeledField|FieldTitle|SectionHeader|MetricCard|Pill)\("'
  '\bKindTag\(title: "'
  '\b(actionTitle|detail): "'
  # SwiftUI views and modifiers that take a title
  '\b(Button|Label|Toggle|Picker|Section|TextField|SecureField|DisclosureGroup|ContentUnavailableView|Menu|Tab|CommandMenu|LabeledContent|confirmationDialog|alert)\("'
  '\.(navigationTitle|navigationSubtitle|help|accessibilityLabel|accessibilityHint|accessibilityValue)\("'
  '\bprompt: "'
  # Lookups without a bundle
  '\bText\("([^"\\]|\\.)*"\)'
  '\bString\(localized: "([^"\\]|\\.)*"\)'
  '\bLocalizedStringResource\("([^"\\]|\\.)*"\)'
)

status=0
for pattern in "${patterns[@]}"; do
  if matches=$(grep -rnE --include='*.swift' "$pattern" "$root" | grep -v '#Preview'); then
    echo "$matches"
    status=1
  fi
done

# A call split over lines: one line ends in "(" and the next starts with a literal.
if matches=$(find "$root" -name '*.swift' -exec awk '
  FNR == 1 { prev = "" }
  { line = $0; sub(/^[ \t]+/, "", line) }
  prev ~ /\($/ && prev !~ /#Preview|\.features\($/ && line ~ /^"/ && line !~ /bundle: *\.module/ {
    printf "%s:%d: %s\n", FILENAME, FNR - 1, prev
  }
  { prev = $0; sub(/[ \t]+$/, "", prev) }
' {} +) && [ -n "$matches" ]; then
  echo "$matches"
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo "error: localized copy in FabrixFeatures must name its bundle (bundle: .module or .features(\"…\"))." >&2
fi
exit "$status"
