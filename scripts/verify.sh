#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WORK="${ROOT}/scripts/work"
MODULAR="${WORK}/Saga-Interactive-HUD.conf"
GFN="${WORK}/Saga-Interactive-HUD-GFN.conf"
BUNDLED="require('autoconf/custom/sagainteractive/custom/mydu_atlas')"
DISPLAY='name: Saga Interactive HUD v4.0 Alpha (North Industries)'

rm -rf "$WORK"
mkdir -p "$WORK" build

echo "Checking source tree and atlas..."
test -d source/src
test -f source/slots.json
test -f source/src/version.lua
test -f source/src/library_includes.lua
test -f atlas/mydu_atlas.lua
grep -q 'return {' atlas/mydu_atlas.lua

echo "Compiling source to JSON..."
python3 scripts/compile_saga.py --output build/Saga_interactive.json
test -s build/Saga_interactive.json

echo "Checking modular patch..."
python3 scripts/patch_saga.py --output "$MODULAR"
head -n 1 "$MODULAR" | grep -qF "$DISPLAY"
grep -qF "$BUNDLED" "$MODULAR"
grep -q 'class: CoreUnit' "$MODULAR"
grep -q 'warpdrive:' "$MODULAR"
grep -q 'class: WarpDriveUnit' "$MODULAR"
grep -q 'databank:' "$MODULAR"
grep -q 'select: all' "$MODULAR"
if grep -qE "require\(['\"]atlas['\"]\)" "$MODULAR"; then
  echo "ERROR: modular conf still requires global atlas" >&2
  exit 1
fi
if grep -q 'slot1:' "$MODULAR"; then
  echo "ERROR: reserved slot1: must not appear in slots" >&2
  exit 1
fi
if grep -q 'select: manual' "$MODULAR"; then
  echo "ERROR: manual slots prevent auto-linking; use semantic slots like ArchHUD" >&2
  exit 1
fi
if grep -q '^{' "$MODULAR"; then
  echo "ERROR: output must be YAML, not JSON" >&2
  exit 1
fi

python3 <<'PY'
import re
from pathlib import Path
text = Path("scripts/work/Saga-Interactive-HUD.conf").read_text()
for token in ["    core:", "    warpdrive:", "    databank:", "    screen:", "    library:"]:
    assert token in text, token
lib = re.search(r"    library:(.*?)(?=\n\S|\Z)", text, re.S)
assert lib and len(re.findall(r"^\s+onStart:\s*$", lib.group(1), re.M)) >= 4, "expected at least 4 library onStart handlers"
if re.search(r"lua: \|\n            .*\n            [^ ]", text):
    raise AssertionError("lua block contains unindented continuation lines (invalid YAML)")
print("YAML structure OK")
PY

echo "Checking inline patch..."
python3 scripts/patch_saga.py --inline --output "$GFN"
grep -qE 'atlas=\{' "$GFN"
if grep -q 'sagainteractive/custom/mydu_atlas' "$GFN"; then
  echo "ERROR: GFN conf still references bundled atlas require" >&2
  exit 1
fi
if grep -qE "require\(['\"]atlas['\"]\)" "$GFN"; then
  echo "ERROR: GFN conf still requires global atlas" >&2
  exit 1
fi

echo "Checking build scripts..."
test -x scripts/build.sh
test -f scripts/compile_saga.py
test -f scripts/patch_saga.py
test -f scripts/handler_manifest.json

echo "Checking output size..."
test "$(stat -c%s "$MODULAR")" -le 262144

echo "All static checks passed."
