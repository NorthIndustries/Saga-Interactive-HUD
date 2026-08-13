# Saga Interactive HUD install (North Industries)

Saga AP HUD **4.0 Alpha** with **bundled server planet data** (`mydu_atlas.lua`). You do **not** need to replace the global `Game/data/lua/atlas.lua` for this HUD.

## Downloads

From [GitHub Releases](https://github.com/NorthIndustries/Saga-Interactive-HUD/releases):

| Artifact | Use when |
|----------|----------|
| **Saga-Interactive-HUD.zip** | Normal install (recommended) |
| **Saga-Interactive-HUD.conf** | Conf only (you still need the atlas file from the zip) |
| **Saga-Interactive-HUD-GFN.conf** | Single-file install; atlas embedded in the conf |

## Modular install (recommended)

1. Download **Saga-Interactive-HUD.zip** from Releases.
2. Extract into your MyDU client folder:

   ```
   MyDU/Game/data/lua/autoconf/custom/
   ```

   You should have:

   - `Saga-Interactive-HUD.conf`
   - `autoconf/custom/sagainteractive/custom/mydu_atlas.lua`

3. In game, apply autoconf **Saga Interactive HUD v4.0 Alpha (North Industries)** on your control unit.
4. Link slots:

   | Slot | Element |
   |------|---------|
   | `core` | Core Unit |
   | `s1`–`s11` | Screen Units (HUD panels) |
   | `s14`, `s21` | Force Field Units (optional) |

   The HUD aliases these internally to `slot1` … `slot21` for Saga code compatibility.

5. Link databanks, radars, warp, shield, etc. per your ship design (same as original Saga AP wiring).

## GFN install (single file)

1. Copy **Saga-Interactive-HUD-GFN.conf** to `MyDU/Game/data/lua/autoconf/custom/`.
2. Apply **Saga Interactive HUD v4.0 Alpha (North Industries) GFN** in game.
3. Link slots as above.

Do **not** keep both modular and GFN confs with similar names in the same folder — apply only one variant.

## Difference from Saga-North-HUD

| | Saga-North-HUD | Saga Interactive HUD |
|--|----------------|----------------------|
| Source | Minified 0.1.2 JSON export | Developer 4.0 Alpha source |
| UI | Classic HUD | Interactive menus + widgets |
| Version | v0.1.2 | v4.0 Alpha |

## Troubleshooting

- **Core not found** — link the core unit to the `core` slot.
- **Planet / route errors** — ensure `mydu_atlas.lua` is at the path above (modular install) or use the GFN conf.
- **Slot linking errors** — use `s1`–`s11`, `s14`, `s21`; do not use reserved names `slot1`, `slot2`, etc. in the autoconf YAML.

## Credits

HUD / autopilot: Sagacious, Mayumi, CodeInfused.  
Atlas bundling and MyDU compile pipeline: North Industries.
