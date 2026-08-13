# Saga Interactive HUD

MyDU build of **Saga AP HUD 4.0 Alpha** — the developer source release with interactive menu/HUD widgets — with **bundled server planet data** (`mydu_atlas.lua`). Players do not need to replace the global `Game/data/lua/atlas.lua`.

Original HUD credit: **Sagacious, Mayumi, CodeInfused** (see in-conf strings).

For the legacy minified **0.1.2** release, see [Saga-North-HUD](../Saga-North-HUD).

## Downloads

From [GitHub Releases](https://github.com/NorthIndustries/Saga-Interactive-HUD/releases):

| Artifact | Use when |
|----------|----------|
| **Saga-Interactive-HUD.zip** | Normal install (recommended) |
| **Saga-Interactive-HUD.conf** | Modular conf only (you still need `mydu_atlas.lua` from the zip) |
| **Saga-Interactive-HUD-GFN.conf** | Atlas embedded in the conf; no separate atlas file |

See [INSTALL.md](INSTALL.md) for player setup.

## What changed

This repo **compiles readable Lua source** (`source/src/`) into MyDU YAML autoconf. Atlas loading is patched to:

```lua
atlas = require('autoconf/custom/sagainteractive/custom/mydu_atlas')
```

The GFN variant inlines the atlas table directly into the conf (~610 KB total).

Planet data comes from North Industries MyDU `atlas.lua`. See [LICENSE-NOTICE.md](LICENSE-NOTICE.md).

## Building

Requirements: `python3`, `zip`.

```bash
chmod +x scripts/*.sh
./scripts/verify.sh
./scripts/build.sh
```

Pipeline:

1. `compile_saga.py` — resolves `include()` tree → `build/Saga_interactive.json`
2. `patch_saga.py` — JSON → YAML + atlas bundling

Outputs: `Saga-Interactive-HUD.conf`, `Saga-Interactive-HUD.zip`, `Saga-Interactive-HUD-GFN.conf`.

## Updating planet data

1. Copy the current MyDU client `Game/data/lua/atlas.lua` into `atlas/mydu_atlas.lua` (keep the header comment).
2. Run `./scripts/build.sh`.
3. Tag and push to `master` — CI publishes a GitHub Release.

## Updating HUD source

Replace `source/src/` with a new developer source drop, then rebuild. Slot wiring and handler manifest live in `scripts/handler_manifest.json` and the compile step.

## Help

North Industries: [mydu.north-industries.com](https://mydu.north-industries.com)
