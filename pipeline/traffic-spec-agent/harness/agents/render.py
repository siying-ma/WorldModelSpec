"""Prompt interpolation by placeholder replacement (the templates contain JSON braces, so
`str.format` is not used). Every placeholder must be supplied; the doctor holds the templates to
the PLACEHOLDERS tables of the phases."""
from __future__ import annotations
import re
from pathlib import Path
from ..store import paths


def render(template: str, values: dict[str, str]) -> str:
    text = (paths.PROMPTS / template).read_text(encoding="utf-8")
    missing = set(re.findall(r"\{([a-z_]+)\}", text)) - set(values)
    if missing:
        raise KeyError(f"{template}: placeholders not supplied: {sorted(missing)}")
    for k, v in values.items():
        text = text.replace("{" + k + "}", v)
    return text


def extract_json(text: str) -> dict | None:
    """The last top-level JSON object in a session's result text: one that opens outside any other
    brace or bracket structure. A brace in prose before or after the answer (a set, a Lean structure) is
    passed over, and an object nested inside an answer that does not parse is never taken for the
    answer: an answer that does not parse yields nothing."""
    import json
    dec = json.JSONDecoder()
    found, depth, in_str, esc, i = None, 0, False, False, 0
    while i < len(text):
        ch = text[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
        elif ch == '"' and depth > 0:
            in_str = True
        elif ch == "{":
            if depth == 0:
                try:
                    obj, end = dec.raw_decode(text, i)
                    if isinstance(obj, dict):
                        found = obj
                    i = end
                    continue
                except json.JSONDecodeError:
                    pass
            depth += 1
        elif ch == "[" and depth > 0:
            depth += 1
        elif ch in "}]" and depth > 0:
            depth -= 1
        i += 1
    return found
