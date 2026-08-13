#!/usr/bin/env python3
"""Patch compiled Saga JSON and emit MyDU YAML autoconf with bundled atlas."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "build" / "Saga_interactive.json"
VERSION_FILE = ROOT / "source" / "src" / "version.lua"
ATLAS = ROOT / "atlas" / "mydu_atlas.lua"
BUNDLED_REQUIRE = "autoconf/custom/sagainteractive/custom/mydu_atlas"
ATLAS_PATTERNS = (
    "atlas = require('atlas')",
    'atlas = require("atlas")',
    'atlas=require("atlas")',
    "atlas=require('atlas')",
)
EMPTY_SLOT_TYPE = {"methods": [], "events": []}
HANDLER_SLOT_KEY_REMAP = {"-3": "-5", "-2": "-4"}
HANDLER_SLOTS = {"-5": "library", "-4": "system", "-1": "unit"}
FORCEFIELD_SLOTS = {"slot14", "slot21"}
SLOT_YAML_NAMES = {f"slot{i}": f"s{i}" for i in range(1, 12)}
SLOT_YAML_NAMES["slot14"] = "s14"
SLOT_YAML_NAMES["slot21"] = "s21"
SLOT_ALIAS_LINE = (
    "slot1=s1 slot2=s2 slot3=s3 slot4=s4 slot5=s5 slot6=s6 slot7=s7 slot8=s8 "
    "slot9=s9 slot10=s10 slot11=s11 slot14=s14 slot21=s21"
)
INDENT = "    "


def normalize_atlas_lua(text: str) -> str:
    text = text.replace("atmosphericRadius", "atmosphereRadius")
    text = re.sub(r"=\s*null\b", "= 0", text)
    return text


def read_atlas_text() -> str:
    return normalize_atlas_lua(ATLAS.read_text(encoding="utf-8"))


def atlas_table_literal() -> str:
    lines = read_atlas_text().splitlines()
    while lines and (not lines[0].strip() or lines[0].lstrip().startswith("--")):
        lines.pop(0)
    body = "\n".join(lines).strip()
    if body.startswith("return"):
        body = body[len("return") :].strip()
    if not body.startswith("{"):
        raise SystemExit(f"Expected atlas module to return a table literal in {ATLAS}")
    return body


def read_version_string() -> str:
    text = VERSION_FILE.read_text(encoding="utf-8")
    major = re.search(r"major\s*=\s*(\d+)", text)
    minor = re.search(r"minor\s*=\s*(\d+)", text)
    branch = re.search(r"branch\s*=\s*branch\.(\w+)", text)
    if not (major and minor and branch):
        raise SystemExit(f"Could not parse version from {VERSION_FILE}")
    branch_name = branch.group(1).capitalize()
    return f"{major.group(1)}.{minor.group(1)} {branch_name}"


def display_name(version: str, inline: bool) -> str:
    name = f"Saga Interactive HUD v{version} (North Industries)"
    return f"{name} GFN" if inline else name


def normalize_slot_keys(data: dict) -> None:
    slots = data.get("slots", {})
    if slots.get("-5", {}).get("name") == "library":
        return

    legacy_library = slots.get("-3")
    legacy_system = slots.get("-2")
    unit = slots.get("-1")
    if legacy_library is None or legacy_system is None or unit is None:
        raise SystemExit("Expected legacy Saga slots -3 (library), -2 (system), -1 (unit)")

    element_slots = {key: value for key, value in slots.items() if not str(key).startswith("-")}
    data["slots"] = {
        **element_slots,
        "-5": legacy_library,
        "-4": legacy_system,
        "-3": {"name": "player", "type": dict(EMPTY_SLOT_TYPE)},
        "-2": {"name": "construct", "type": dict(EMPTY_SLOT_TYPE)},
        "-1": unit,
    }

    for handler in data.get("handlers", []):
        slot_key = handler.get("filter", {}).get("slotKey")
        if slot_key in HANDLER_SLOT_KEY_REMAP:
            handler["filter"]["slotKey"] = HANDLER_SLOT_KEY_REMAP[slot_key]


def element_slot_names(data: dict) -> list[str]:
    items = sorted(
        (int(key), value["name"])
        for key, value in data["slots"].items()
        if key.lstrip("-").isdigit() and int(key) >= 0
    )
    names = [name for _, name in items if name != "core"]
    ordered = ["core", *names]
    if "slot14" not in ordered:
        rebuilt: list[str] = []
        for name in ordered:
            rebuilt.append(name)
            if name == "slot11":
                rebuilt.append("slot14")
        ordered = rebuilt
    return ordered


def yaml_slot_name(original_name: str) -> str:
    return SLOT_YAML_NAMES.get(original_name, original_name)


def slot_class(original_name: str) -> tuple[str, str | None]:
    if original_name == "core":
        return "CoreUnit", None
    if original_name in FORCEFIELD_SLOTS:
        return "ForceFieldUnit", "manual"
    return "ScreenUnit", "manual"


def parse_signature(signature: str) -> tuple[str, list[str]]:
    match = re.match(r"([^(]+)\((.*)\)", signature)
    if not match:
        return signature, []
    params = [part.strip() for part in match.group(2).split(",") if part.strip()]
    return match.group(1), params


def yaml_arg(value: str) -> str:
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value):
        return value
    return f"'{value}'"


def emit_lua_block(lines: list[str], indent_level: int, code: str) -> None:
    pad = INDENT * indent_level
    pad_code = INDENT * (indent_level + 1)
    lines.append(f"{pad}lua: |")
    if not code:
        lines.append(pad_code)
        return
    for line in code.splitlines():
        lines.append(f"{pad_code}{line}")


def handler_yaml_key(filter_obj: dict) -> tuple[str, list[str] | None]:
    signature = filter_obj["signature"]
    args = filter_obj.get("args", [])
    if any(arg.get("variable") == "*" for arg in args):
        return "onInputText(text)", None

    event_name, param_names = parse_signature(signature)
    if not args:
        return event_name, None

    yaml_args: list[str] = []
    for index, arg in enumerate(args):
        if "value" in arg:
            yaml_args.append(arg["value"])
        elif "variable" in arg:
            yaml_args.append(param_names[index] if index < len(param_names) else "arg")
    return event_name, yaml_args


def emit_handlers(
    lines: list[str],
    handlers: list[dict],
    indent_level: int,
    *,
    on_start_prefix: str | None = None,
) -> None:
    pad = INDENT * indent_level
    pad2 = INDENT * (indent_level + 1)
    prefix_used = False

    for handler in handlers:
        filt = handler["filter"]
        code = handler["code"]
        event_name, yaml_args = handler_yaml_key(filt)

        if (
            event_name == "onStart"
            and on_start_prefix
            and not prefix_used
            and not yaml_args
        ):
            code = on_start_prefix + "\n" + code.lstrip("\n")
            prefix_used = True

        lines.append(f"{pad}{event_name}:")
        if yaml_args:
            rendered = ", ".join(yaml_arg(value) for value in yaml_args)
            lines.append(f"{pad2}args: [{rendered}]")
        emit_lua_block(lines, indent_level + 1, code)


def to_yaml(data: dict, name: str) -> str:
    lines = [f"name: {name}", "", "slots:"]
    for original_name in element_slot_names(data):
        yaml_name = yaml_slot_name(original_name)
        class_name, select_mode = slot_class(original_name)
        lines.append(f"{INDENT}{yaml_name}:")
        lines.append(f"{INDENT}{INDENT}class: {class_name}")
        if select_mode:
            lines.append(f"{INDENT}{INDENT}select: {select_mode}")

    lines.append("")
    lines.append("handlers:")
    grouped: dict[str, list[dict]] = {slot: [] for slot in HANDLER_SLOTS.values()}
    for handler in sorted(
        data.get("handlers", []),
        key=lambda item: (item["filter"]["slotKey"], int(item["key"])),
    ):
        slot_key = handler["filter"]["slotKey"]
        slot_name = HANDLER_SLOTS.get(slot_key)
        if slot_name:
            grouped[slot_name].append(handler)

    for slot_name in ("unit", "system", "library"):
        slot_handlers = grouped[slot_name]
        if not slot_handlers:
            continue
        lines.append(f"{INDENT}{slot_name}:")
        prefix = SLOT_ALIAS_LINE if slot_name == "library" else None
        emit_handlers(lines, slot_handlers, indent_level=2, on_start_prefix=prefix)

    return "\n".join(lines) + "\n"


def patch_atlas(data: dict, inline: bool) -> int:
    hits = 0
    bundled = f"require('{BUNDLED_REQUIRE}')"
    replacement_inline = f"atlas = {atlas_table_literal()}"
    replacement_modular = f"atlas = {bundled}"

    for handler in data.get("handlers", []):
        code = handler.get("code", "")
        for pattern in ATLAS_PATTERNS:
            if pattern not in code:
                continue
            hits += 1
            handler["code"] = code.replace(
                pattern,
                replacement_inline if inline else replacement_modular,
                1,
            )
            break

    if hits != 1:
        raise SystemExit(f"Expected exactly 1 atlas require, found {hits}")
    return hits


def patch_source(inline: bool) -> tuple[dict, str]:
    data = json.loads(SOURCE.read_text(encoding="utf-8"))
    version = read_version_string()
    name = display_name(version, inline)
    patch_atlas(data, inline=inline)
    normalize_slot_keys(data)
    return data, name


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inline", action="store_true", help="Inline atlas table into handler code")
    parser.add_argument("--output", required=True, type=Path, help="Output .conf path")
    args = parser.parse_args()

    if not SOURCE.is_file():
        raise SystemExit(f"Missing compiled JSON: {SOURCE} (run compile_saga.py first)")
    if not ATLAS.is_file():
        raise SystemExit(f"Missing atlas file: {ATLAS}")

    data, name = patch_source(inline=args.inline)
    output = to_yaml(data, name)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    print(f"Wrote {args.output} ({args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
