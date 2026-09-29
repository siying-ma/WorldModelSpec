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
    """The last JSON object in a session's result text."""
    import json
    for m in reversed(list(re.finditer(r"\{.*\}", text, re.S))):
        try:
            return json.loads(m.group(0))
        except json.JSONDecodeError:
            # try progressively shorter tails
            s = m.group(0)
            for i in range(len(s), 0, -1):
                if s[i - 1] == "}":
                    try:
                        return json.loads(s[:i])
                    except json.JSONDecodeError:
                        continue
    return None
