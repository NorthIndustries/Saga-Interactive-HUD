#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 scripts/compile_saga.py --output build/Saga_interactive.json

rm -rf deploy
mkdir -p deploy/autoconf/custom/sagainteractive/custom

python3 scripts/patch_saga.py --output Saga-Interactive-HUD.conf
cp Saga-Interactive-HUD.conf deploy/
cp atlas/mydu_atlas.lua deploy/autoconf/custom/sagainteractive/custom/

(
  cd deploy
  zip -r ../Saga-Interactive-HUD.zip .
)

python3 scripts/patch_saga.py --inline --output Saga-Interactive-HUD-GFN.conf

echo "Build complete:"
ls -lh Saga-Interactive-HUD.conf Saga-Interactive-HUD-GFN.conf Saga-Interactive-HUD.zip build/Saga_interactive.json
