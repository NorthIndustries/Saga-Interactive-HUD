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
SLOT_TEMPLATE = ROOT / "source" / "slots.json"
OUTPUT_DEFAULT = ROOT / "build" / "Saga_interactive.json"

INCLUDE_RE = re.compile(r"""^\s*include\s*\(\s*['"]src\\(.+?)['"]\s*\)\s*$""")
EMPTY_SLOT_TYPE = {"methods": [], "events": []}
# MyDU decompresses each handler lua block with a hard ~200KB output cap.
MAX_LIBRARY_HANDLER_BYTES = 190_000


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
    slots = dict(template)
    if "11" not in slots or slots["11"].get("name") != "slot21":
        raise SystemExit("Expected slot21 at template key 11")
    return slots


def library_include_paths() -> list[str]:
    body = read_lua("library_includes.lua")
    paths: list[str] = []
    for line in body.splitlines():
        match = INCLUDE_RE.match(line)
        if match:
            paths.append(re.sub(r"[/\\]+", "/", match.group(1)).strip("/"))
    if not paths:
        raise SystemExit("No includes found in library_includes.lua")
    return paths


def minified_handler_size(code: str) -> int:
    from patch_saga import minified_size

    return minified_size(code)


def chunk_library_code(paths: list[str], max_bytes: int) -> list[str]:
    chunks: list[str] = []
    current_paths: list[str] = []

    for path in paths:
        trial_paths = [*current_paths, path]
        trial_code = "\n".join(expand_includes(item) for item in trial_paths)
        if current_paths and minified_handler_size(trial_code) > max_bytes:
            chunks.append("\n".join(expand_includes(item) for item in current_paths))
            current_paths = [path]
            continue
        current_paths = trial_paths

    if current_paths:
        chunks.append("\n".join(expand_includes(item) for item in current_paths))

    for index, chunk in enumerate(chunks):
        size = minified_handler_size(chunk)
        if size > max_bytes:
            raise SystemExit(
                f"Library chunk {index} exceeds handler size budget "
                f"({size} > {max_bytes} bytes)"
            )
    return chunks


def library_handlers() -> list[dict]:
    json_code = read_lua("lib/JSON.lua")
    remap_code = read_lua("data/remap.lua")
    main_chunks = chunk_library_code(
        library_include_paths(),
        MAX_LIBRARY_HANDLER_BYTES,
    )
    handlers = [
        make_handler("-3", "onStart()", 0, json_code),
        make_handler("-3", "onStart()", 1, remap_code),
    ]
    for index, chunk in enumerate(main_chunks):
        handlers.append(make_handler("-3", "onStart()", 2 + index, chunk))
    return handlers


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


def action_dispatch_code(actions: dict, field: str) -> str:
    entries: list[str] = []
    for action in sorted(actions):
        mapping = actions[action]
        if field not in mapping:
            continue
        call = mapping[field].strip()
        entries.append(f"['{action}']=function(){call}end")
    table = "{" + ",".join(entries) + "}"
    return f"local _dispatch={table} if _dispatch[action] then _dispatch[action]() end"


def system_handlers() -> list[dict]:
    actions = json.loads(MANIFEST.read_text(encoding="utf-8"))
    handlers: list[dict] = [
        make_handler("-2", "onFlush()", 0, "onSystemFlush()"),
        make_handler("-2", "onUpdate()", 1, "onSystemUpdate()"),
        make_handler("-2", "onInputText(text)", 2, "onInput(text)", [{"variable": "*"}]),
        make_handler("-2", "onActionStart(action)", 3, action_dispatch_code(actions, "start")),
        make_handler("-2", "onActionStop(action)", 4, action_dispatch_code(actions, "stop")),
        make_handler("-2", "onActionLoop(action)", 5, action_dispatch_code(actions, "loop")),
    ]
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
