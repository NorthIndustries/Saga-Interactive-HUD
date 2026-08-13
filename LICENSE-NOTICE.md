# License and attribution notice

## Original Saga AP HUD

The Lua source in `source/src/` is the **Saga AP HUD 4.0 Alpha** development tree provided by the Saga authors. In-code credit:

> HUD/Autopilot by Sagacious, Mayumi and CodeInfused

North Industries does **not** claim ownership of the HUD logic, autopilot, UI, or interactive menu system. Distribution of the upstream source is subject to the authors' terms; this repository is a MyDU packaging fork with bundled planet data.

## This repository

This repo adds:

- `scripts/compile_saga.py` — compiles modular `include()` source into autoconf JSON
- `scripts/patch_saga.py` — converts to MyDU YAML and patches atlas loading
- `atlas/mydu_atlas.lua` — North Industries MyDU server planet data (from `Game/data/lua/atlas.lua`)
- Build scripts, CI, and install documentation

Original Saga author credit strings in the built conf are preserved.

## Planet data (`mydu_atlas.lua`)

Planet names, positions, and metadata reflect the North Industries MyDU server configuration. Update this file when the server atlas changes.

## JSON library (`source/src/lib/JSON.lua`)

The bundled JSON library is Copyright (c) 2020 rxi — MIT License (see file header).

## Distribution

If you redistribute patched builds, keep this notice and the in-conf Saga author credit intact.
