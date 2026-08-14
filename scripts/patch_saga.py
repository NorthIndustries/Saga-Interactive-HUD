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
# Like MyDU-ArchHUD: semantic slots with class match auto-link on apply.
# Omit select for single elements; select: all for multiples.
SEMANTIC_SLOTS = (
    ("core", "CoreUnit", None),
    ("warpdrive", "WarpDriveUnit", None),
    ("shield", "ShieldGeneratorUnit", None),
    ("antigrav", "AntiGravityGeneratorUnit", None),
    ("gyro", "GyroUnit", None),
    ("transponder", "TransponderUnit", None),
    ("databank", "databank", "all"),
    ("weapon", "WeaponUnit", "all"),
    ("radar", "RadarUnit", "all"),
    ("radarPvp", "RadarPVPUnit", None),
    ("switch", "ManualSwitchUnit", "all"),
    ("forcefield", "ForceFieldUnit", "all"),
    ("screen", "ScreenUnit", "all"),
)
INDENT = "    "
MAX_CONF_BYTES = 262_144
MAX_HANDLER_BYTES = 200_000


def _needs_space_between(last_char: str, first_char: str) -> bool:
    if not last_char or not first_char:
        return False
    if last_char in "(=,[{" or first_char in ",;)]}.":
        return False
    if last_char.isalnum() or last_char in "_)]":
        return first_char.isalnum() or first_char in "_'\"" or first_char == "["
    return False


def _minify_code_segment(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return ""
    text = re.sub(r"\s*([,;()\[\]{}])\s*", r"\1", text)
    text = re.sub(r"(?<![<>=~!])\s*=\s*(?!=)", "=", text)
    for keyword in (
        "local",
        "function",
        "end",
        "then",
        "else",
        "elseif",
        "do",
        "return",
        "in",
        "and",
        "or",
        "not",
    ):
        text = re.sub(rf"(?<![\w]){keyword}(?![\w])", f" {keyword} ", text)
    return re.sub(r"\s+", " ", text).strip()


def _lua_tokens(code: str) -> list[tuple[str, str]]:
    tokens: list[tuple[str, str]] = []
    i = 0
    n = len(code)
    code_start = 0

    def flush_code(end: int) -> None:
        nonlocal code_start
        if end > code_start:
            tokens.append(("code", code[code_start:end]))
        code_start = end

    while i < n:
        if code.startswith("--", i):
            flush_code(i)
            block = re.match(r"--\[(=*)\[", code[i:])
            if block:
                end_marker = f"]{block.group(1)}]"
                j = code.find(end_marker, i + 4 + len(block.group(1)))
                if j == -1:
                    break
                i = j + len(end_marker)
            else:
                j = code.find("\n", i)
                i = n if j == -1 else j + 1
            code_start = i
            continue

        char = code[i]
        if char in "'\"":
            flush_code(i)
            quote = char
            i += 1
            chunk = [quote]
            while i < n:
                c = code[i]
                chunk.append(c)
                if c == "\\" and i + 1 < n:
                    chunk.append(code[i + 1])
                    i += 2
                    continue
                if c == quote:
                    i += 1
                    break
                i += 1
            tokens.append(("literal", "".join(chunk)))
            code_start = i
            continue

        if char == "[":
            long_string = re.match(r"\[(=*)\[", code[i:])
            if long_string:
                flush_code(i)
                eq = long_string.group(1)
                end_marker = f"]{eq}]"
                j = code.find(end_marker, i + 2 + len(eq))
                if j == -1:
                    tokens.append(("literal", code[i:]))
                    return tokens
                tokens.append(("literal", code[i : j + len(end_marker)]))
                i = j + len(end_marker)
                code_start = i
                continue

        i += 1

    flush_code(n)
    return tokens


def minify_lua(code: str) -> str:
    parts: list[str] = []
    last_char = ""

    for kind, text in _lua_tokens(code):
        if kind == "code":
            segment = _minify_code_segment(text)
            if not segment:
                continue
            if parts and _needs_space_between(last_char, segment[0]):
                parts.append(" ")
                last_char = " "
            parts.append(segment)
            last_char = segment[-1]
            continue

        if parts and _needs_space_between(last_char, text[0]):
            parts.append(" ")
            last_char = " "
        parts.append(text)
        last_char = text[-1]

    return "".join(parts)


def yaml_safe_lua(code: str) -> str:
    text = minify_lua(code).replace("\r", " ").replace("\n", " ")
    return re.sub(r"  +", " ", text).strip()


def minified_size(code: str) -> int:
    return len(yaml_safe_lua(code))


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
    minified = yaml_safe_lua(code)
    if not minified:
        lines.append(pad_code)
        return
    lines.append(f"{pad_code}{minified}")


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


def emit_handlers(lines: list[str], handlers: list[dict], indent_level: int) -> None:
    pad = INDENT * indent_level
    pad2 = INDENT * (indent_level + 1)

    for handler in handlers:
        filt = handler["filter"]
        code = handler["code"]
        event_name, yaml_args = handler_yaml_key(filt)

        lines.append(f"{pad}{event_name}:")
        if yaml_args:
            rendered = ", ".join(yaml_arg(value) for value in yaml_args)
            lines.append(f"{pad2}args: [{rendered}]")
        emit_lua_block(lines, indent_level + 1, code)


def to_yaml(data: dict, name: str) -> str:
    lines = [f"name: {name}", "", "slots:"]
    for slot_name, class_name, select_mode in SEMANTIC_SLOTS:
        lines.append(f"{INDENT}{slot_name}:")
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
        emit_handlers(lines, slot_handlers, indent_level=2)

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
    for handler in data.get("handlers", []):
        size = minified_size(handler.get("code", ""))
        if size > MAX_HANDLER_BYTES:
            filt = handler.get("filter", {})
            raise SystemExit(
                f"Handler {filt.get('slotKey')} {filt.get('signature')} key={handler.get('key')} "
                f"exceeds MyDU handler limit ({size} > {MAX_HANDLER_BYTES} bytes)"
            )

    output = to_yaml(data, name)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    size = args.output.stat().st_size
    print(f"Wrote {args.output} ({size} bytes)")
    if not args.inline and size > MAX_CONF_BYTES:
        raise SystemExit(
            f"Output exceeds MyDU size limit ({size} > {MAX_CONF_BYTES} bytes). "
            "Further source reduction or minification is required."
        )


if __name__ == "__main__":
    main()
