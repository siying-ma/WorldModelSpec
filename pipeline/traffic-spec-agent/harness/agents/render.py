"""Prompt interpolation by placeholder replacement (the templates contain JSON braces, so
`str.format` is not used). Every placeholder must be supplied; the doctor holds the templates to
the PLACEHOLDERS tables of the phases.

A template may hold conditional sections, each a block between the markers `<!-- section:<name> -->`
and `<!-- /section:<name> -->`. The markers are written each on a line of its own, but a template
whose lines were joined is read the same way: a marker need not begin a line."""
from __future__ import annotations
import re
from ..store import paths

#: A conditional block with its markers, the line end after each marker and the blank line after it.
SECTION = re.compile(r"<!-- section:([a-z_]+) -->\n?(.*?)<!-- /section:\1 -->\n?\n?", re.S)
MARKER = re.compile(r"<!-- /?section:[a-z_]*")


def _sections(text: str, sections: dict[str, bool]) -> str:
    """`text` with each conditional block kept, without its markers, where `sections` names it true,
    and removed with its markers and the blank line after it otherwise, so a template renders
    without a closed block exactly as it would without the block. A marker without its partner, a
    nested block, or a name in `sections` the template has no block of, is refused."""
    found = list(SECTION.finditer(text))
    if len(MARKER.findall(text)) != 2 * len(found) or any(MARKER.search(m.group(2)) for m in found):
        raise ValueError("a section marker without its partner, or a nested section")
    unknown = sorted(set(sections) - {m.group(1) for m in found})
    if unknown:
        raise KeyError(f"sections not in the template: {unknown}")
    return SECTION.sub(lambda m: m.group(2) if sections.get(m.group(1)) else "", text)


def render(template: str, values: dict[str, str], sections: dict[str, bool] | None = None) -> str:
    """The template with every placeholder replaced; a conditional block is kept, without its markers,
    only where `sections` names it true, and removed otherwise: a rule a template states for one kind
    of evidence is shown only when that evidence is supplied. Closed blocks are removed before the
    placeholders are checked, so a placeholder only a closed block holds need not be supplied."""
    sections = {} if sections is None else sections
    if not isinstance(sections, dict) or not all(isinstance(v, bool) for v in sections.values()):
        raise TypeError(f"{template}: sections must map a section name to true or false, not {sections!r}")
    text = _sections((paths.PROMPTS / template).read_text(encoding="utf-8"), sections)
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
