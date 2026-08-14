#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 scripts/compile_saga.py --output build/Saga_interactive.json

rm -rf deploy
mkdir -p deploy/sagainteractive/custom

python3 scripts/patch_saga.py --output Saga-Interactive-HUD.conf
cp Saga-Interactive-HUD.conf deploy/
cp atlas/mydu_atlas.lua deploy/sagainteractive/custom/

(
  cd deploy
  rm -f ../Saga-Interactive-HUD.zip
  zip -rq ../Saga-Interactive-HUD.zip .
)

if unzip -l Saga-Interactive-HUD.zip | grep -q 'autoconf/'; then
  echo "ERROR: zip must not contain autoconf/ prefix (extract into autoconf/custom/)" >&2
  exit 1
fi
if ! unzip -l Saga-Interactive-HUD.zip | grep -q 'sagainteractive/custom/mydu_atlas.lua'; then
  echo "ERROR: zip missing sagainteractive/custom/mydu_atlas.lua" >&2
  exit 1
fi

python3 scripts/patch_saga.py --inline --output Saga-Interactive-HUD-GFN.conf

echo "Build complete:"
ls -lh Saga-Interactive-HUD.conf Saga-Interactive-HUD-GFN.conf Saga-Interactive-HUD.zip build/Saga_interactive.json
