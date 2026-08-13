#!/usr/bin/env python3
"""Compile Saga 4.0 Alpha Lua source into legacy JSON autoconf structure."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC_ROOT = ROOT / "source" / "src"
MANIFEST = Path(__file__).resolve().parent / "handler_manifest.json"
SLOT_TEMPLATE = (
    ROOT.parent / "Saga-North-HUD" / "source" / "Saga_AP_release.json"
)
OUTPUT_DEFAULT = ROOT / "build" / "Saga_interactive.json"

INCLUDE_RE = re.compile(r"""^\s*include\s*\(\s*['"]src\\(.+?)['"]\s*\)\s*$""")
EMPTY_SLOT_TYPE = {"methods": [], "events": []}


def resolve_lua_path(relative: str) -> Path:
    norm = re.sub(r"[/\\]+", "/", relative).strip("/")
    direct = SRC_ROOT / norm
    if direct.is_file():
        return direct
    target = norm.lower()
    for path in SRC_ROOT.rglob("*.lua"):
        if path.relative_to(SRC_ROOT).as_posix().lower() == target:
            return path
    raise SystemExit(f"Missing source file: {direct}")


def read_lua(relative: str) -> str:
    return resolve_lua_path(relative).read_text(encoding="utf-8")


def expand_includes(relative: str, stack: list[str] | None = None) -> str:
    stack = stack or []
    norm = relative.replace("\\", "/")
    if norm in stack:
        raise SystemExit(f"Include cycle detected: {' -> '.join([*stack, norm])}")

    body = read_lua(norm)
    out_lines: list[str] = []
    for line in body.splitlines():
        match = INCLUDE_RE.match(line)
        if match:
            child = re.sub(r"[/\\]+", "/", match.group(1)).strip("/")
            out_lines.append(expand_includes(child, [*stack, norm]))
        else:
            out_lines.append(line)
    return "\n".join(out_lines)


def handler_filter(slot_key: str, signature: str, args: list[dict] | None = None) -> dict:
    filt: dict = {"slotKey": slot_key, "signature": signature}
    if args:
        filt["args"] = args
    return filt


def make_handler(slot_key: str, signature: str, key: int, code: str, args: list[dict] | None = None) -> dict:
    return {"filter": handler_filter(slot_key, signature, args), "code": code, "key": key}


def load_slots() -> dict:
    template = json.loads(SLOT_TEMPLATE.read_text(encoding="utf-8"))
    slots = dict(template["slots"])
    if "11" not in slots:
        raise SystemExit("Expected slot21 in template slots")
    if not any(v.get("name") == "slot14" for v in slots.values() if isinstance(v, dict)):
        # Insert slot14 after slot11 in numeric order
        slots = dict(sorted(slots.items(), key=lambda kv: int(kv[0]) if kv[0].lstrip("-").isdigit() else -100))
        rebuilt: dict = {}
        for key, value in slots.items():
            rebuilt[key] = value
            if value.get("name") == "slot11":
                next_key = str(max(int(k) for k in rebuilt if k.isdigit()) + 1)
                rebuilt[next_key] = {"name": "slot14", "type": dict(EMPTY_SLOT_TYPE)}
        slots = rebuilt
    return slots


def library_handlers() -> list[dict]:
    json_code = read_lua("lib/JSON.lua")
    remap_code = read_lua("data/remap.lua")
    main_code = expand_includes("library_includes.lua")
    return [
        make_handler("-3", "onStart()", 0, json_code),
        make_handler("-3", "onStart()", 1, remap_code),
        make_handler("-3", "onStart()", 2, main_code),
    ]


def unit_handlers() -> list[dict]:
    globals_code = read_lua("data/globals.lua")
    return [
        make_handler("-1", "onStart()", 0, globals_code),
        make_handler(
            "-1",
            "onStart()",
            1,
            "onUnitStart(system, unit, construct, library, player)",
        ),
        make_handler("-1", "onStop()", 2, "onUnitStop()"),
        make_handler(
            "-1",
            "onTimer(timerId)",
            3,
            "onTimerDebug()",
            [{"value": "DEBUGHUD"}],
        ),
    ]


def system_handlers() -> list[dict]:
    actions = json.loads(MANIFEST.read_text(encoding="utf-8"))
    handlers: list[dict] = [
        make_handler("-2", "onFlush()", 0, "onSystemFlush()"),
        make_handler("-2", "onUpdate()", 1, "onSystemUpdate()"),
        make_handler("-2", "onInputText(text)", 2, "onInput(text)", [{"variable": "*"}]),
    ]
    key = 3
    for action in sorted(actions):
        mapping = actions[action]
        if "start" in mapping:
            handlers.append(
                make_handler(
                    "-2",
                    "onActionStart(action)",
                    key,
                    mapping["start"],
                    [{"value": action}],
                )
            )
            key += 1
        if "stop" in mapping:
            handlers.append(
                make_handler(
                    "-2",
                    "onActionStop(action)",
                    key,
                    mapping["stop"],
                    [{"value": action}],
                )
            )
            key += 1
        if "loop" in mapping:
            handlers.append(
                make_handler(
                    "-2",
                    "onActionLoop(action)",
                    key,
                    mapping["loop"],
                    [{"value": action}],
                )
            )
            key += 1
    return handlers


def compile_autoconf() -> dict:
    handlers = library_handlers() + unit_handlers() + system_handlers()
    return {"slots": load_slots(), "handlers": handlers}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_DEFAULT,
        help="Output JSON path",
    )
    args = parser.parse_args()

    if not SRC_ROOT.is_dir():
        raise SystemExit(f"Missing source tree: {SRC_ROOT}")
    if not MANIFEST.is_file():
        raise SystemExit(f"Missing handler manifest: {MANIFEST}")
    if not SLOT_TEMPLATE.is_file():
        raise SystemExit(f"Missing slot template: {SLOT_TEMPLATE}")

    data = compile_autoconf()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    lib = sum(1 for h in data["handlers"] if h["filter"]["slotKey"] == "-3")
    unit = sum(1 for h in data["handlers"] if h["filter"]["slotKey"] == "-1")
    system = sum(1 for h in data["handlers"] if h["filter"]["slotKey"] == "-2")
    print(
        f"Wrote {args.output} ({args.output.stat().st_size} bytes) "
        f"[library={lib} unit={unit} system={system} handlers={len(data['handlers'])}]"
    )


if __name__ == "__main__":
    main()
