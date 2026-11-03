#!/usr/bin/env bash
# Static checks that need no root and no VM: shell syntax (+ shellcheck when
# installed), the Hyprland config verified by Hyprland itself, JSON configs,
# desktop entries and the Python test harness.
set -uo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
desktop="$root/packages/aris-desktop/rootfs"
failures=0

pass() { printf '  \e[32mok\e[0m    %s\n' "$*"; }
fail() {
  printf '  \e[31mFAIL\e[0m  %s\n' "$*"
  failures=$((failures + 1))
}
skip() { printf '  \e[33mskip\e[0m  %s\n' "$*"; }

echo "Shell scripts"
mapfile -t scripts < <(grep -rlE '^#!.*\b(ba)?sh\b' "$root/scripts" "$root/packages" "$root/iso/airootfs" "$root/iso/profiledef.sh" 2>/dev/null)
for f in "${scripts[@]}"; do
  shell=bash
  head -n1 "$f" | grep -qE '^#!/bin/sh' && shell=sh
  if out="$($shell -n "$f" 2>&1)"; then pass "${f#"$root"/}"; else fail "${f#"$root"/}: $out"; fi
done
if command -v shellcheck >/dev/null; then
  if shellcheck -x -S warning "${scripts[@]}"; then pass "shellcheck"; else fail "shellcheck"; fi
else
  skip "shellcheck not installed"
fi

echo "Hyprland config (Hyprland --verify-config)"
if command -v Hyprland >/dev/null; then
  for mode in installed live; do
    home="$(mktemp -d)"
    cp -a "$desktop/etc/skel/." "$home/"
    live=""
    [[ $mode == live ]] && live=1
    out="$(cd "$home" && env -i HOME="$home" PATH=/usr/bin ARIS_PATH="$desktop/usr/share/aris" ARIS_LIVE="$live" \
      XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}" Hyprland --verify-config -c "$home/.config/hypr/hyprland.lua" 2>&1)"
    rm -rf "$home"
    if grep -qx 'config ok' <<<"$out"; then
      pass "hyprland.lua ($mode)"
    else
      fail "hyprland.lua ($mode): $(sed -n '/Config parsing result/,$p' <<<"$out")"
    fi
  done
else
  skip "Hyprland not installed on this host"
fi

echo "JSON configs"
while IFS= read -r f; do
  # JSONC: drop whole-line // comments before parsing.
  if grep -v '^\s*//' "$f" | jq empty 2>/dev/null; then pass "${f#"$root"/}"; else fail "${f#"$root"/}"; fi
done < <(find "$root/packages" -name '*.json' -o -name '*.jsonc')

echo "Desktop entries"
if command -v desktop-file-validate >/dev/null; then
  while IFS= read -r f; do
    if out="$(desktop-file-validate "$f" 2>&1)"; then pass "${f#"$root"/}"; else fail "${f#"$root"/}: $out"; fi
  done < <(find "$root/packages" -name '*.desktop')
else
  skip "desktop-file-validate not installed"
fi

echo "Python"
if python3 -m py_compile "$root/scripts/vm-test.py" 2>/dev/null; then pass "scripts/vm-test.py"; else fail "scripts/vm-test.py"; fi
rm -rf "$root/scripts/__pycache__"

echo
if ((failures)); then
  echo "$failures check(s) failed."
  exit 1
fi
echo "All checks passed."
