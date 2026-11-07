#!/usr/bin/env bash
# Runs check-feature-strings.sh against small fixtures: each bad case must fail, the good file must pass.
set -euo pipefail

guard="$(cd "$(dirname "$0")" && pwd)/check-feature-strings.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

expect() {
  local want="$1" name="$2" source="$3"
  rm -rf "$work/src" && mkdir "$work/src"
  printf '%s\n' "$source" > "$work/src/Fixture.swift"
  if "$guard" "$work/src" >/dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then
    echo "FAIL $name: expected $want, got $got" >&2
    exit 1
  fi
  echo "ok $name"
}

expect fail "bare Text" 'Text("Hello")'
expect fail "bare Button" 'Button("Save") {}'
expect fail "bare alert" '.alert("Sign out?", isPresented: $show) {}'
expect fail "bare confirmationDialog" '.confirmationDialog("Delete?", isPresented: $show) {}'
expect fail "literal on the next line" 'Button(
    "Save"
) {}'
expect pass "bundled copy" 'Text("Hello", bundle: .module)
Button(.features("Save")) {}
.alert(.features("Sign out?"), isPresented: $show) {}
Text(
    "Hello", bundle: .module
)
Button(.features(
    "Save"
)) {}
Text(verbatim: name)'
