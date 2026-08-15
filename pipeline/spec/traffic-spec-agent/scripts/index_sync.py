"""Regenerate `TrafficSpec/Index.lean` from the rule files on disk.

The registry is derived, never hand-maintained: the source of truth is the set
of files under `Rules/`. Any rule file that declares the expected namespace and
`entry`/`scenarios` gets registered; anything else is reported so the integrate
phase can reject it rather than silently leaving a rule out of the library.
"""

from __future__ import annotations

import re
from pathlib import Path

NAMESPACE_RE = re.compile(r"^\s*namespace\s+(TrafficSpec\.Rules\.[A-Za-z0-9_.]+)", re.M)
DEF_RE = re.compile(r"^\s*def\s+([A-Za-z][A-Za-z0-9_']*)", re.M)

IMPORT_BEGIN = "-- BEGIN GENERATED IMPORTS"
IMPORT_END = "-- END GENERATED IMPORTS"
RULES_BEGIN = "  -- BEGIN GENERATED RULES"
RULES_END = "  -- END GENERATED RULES"
SCEN_BEGIN = "  -- BEGIN GENERATED SCENARIOS"
SCEN_END = "  -- END GENERATED SCENARIOS"


class RuleFile:
    def __init__(self, path: Path, library_root: Path) -> None:
        self.path = path
        self.rel = path.relative_to(library_root)
        text = path.read_text(encoding="utf-8")
        m = NAMESPACE_RE.search(text)
        self.namespace = m.group(1) if m else None
        self.defs = set(DEF_RE.findall(text))

    @property
    def module(self) -> str:
        return str(self.rel.with_suffix("")).replace("/", ".")

    @property
    def short_namespace(self) -> str | None:
        """Namespace with the leading `TrafficSpec.` stripped, for use inside it."""
        if not self.namespace:
            return None
        return self.namespace[len("TrafficSpec."):]

    @property
    def problems(self) -> list[str]:
        out = []
        if not self.namespace:
            out.append(f"{self.rel}: no `namespace TrafficSpec.Rules.…` declaration")
        for decl in ("schema", "entry", "scenarios"):
            if decl not in self.defs:
                out.append(f"{self.rel}: missing `def {decl}`")
        return out


def discover(library_root: Path) -> list[RuleFile]:
    rules_dir = library_root / "TrafficSpec" / "Rules"
    if not rules_dir.exists():
        return []
    return [RuleFile(p, library_root) for p in sorted(rules_dir.rglob("*.lean"))]


def _replace_block(text: str, begin: str, end: str, body: list[str]) -> str:
    start = text.find(begin)
    stop = text.find(end)
    if start == -1 or stop == -1 or stop < start:
        raise ValueError(f"Index.lean is missing its {begin!r}/{end!r} markers")
    return text[:start + len(begin)] + "\n" + "\n".join(body) + "\n" + text[stop:]


def sync(library_root: Path, dry_run: bool = False) -> tuple[bool, list[str]]:
    """Rewrite Index.lean. Returns ``(changed, problems)``.

    Problems are per-file structural defects. When any exist, nothing is written:
    a partially-registered library is worse than an unchanged one.
    """
    index_path = library_root / "TrafficSpec" / "Index.lean"
    if not index_path.exists():
        return False, [f"{index_path} does not exist"]

    files = discover(library_root)
    problems = [p for f in files for p in f.problems]
    if problems:
        return False, problems

    imports = [f"import {f.module}" for f in files]
    rules = ", ".join(f"{f.short_namespace}.entry" for f in files)
    scens = ", ".join(
        f"({f.short_namespace}.entry, {f.short_namespace}.scenarios)" for f in files
    )

    original = index_path.read_text(encoding="utf-8")
    text = _replace_block(original, IMPORT_BEGIN, IMPORT_END, imports)
    text = _replace_block(text, RULES_BEGIN, RULES_END, [f"  [ {rules} ]" if rules else "  []"])
    text = _replace_block(text, SCEN_BEGIN, SCEN_END, [f"  [ {scens} ]" if scens else "  []"])

    changed = text != original
    if changed and not dry_run:
        index_path.write_text(text, encoding="utf-8")
        print(f"[info] Registered {len(files)} rule(s) in {index_path.name}")
    return changed, []


def registered_count(library_root: Path) -> int:
    return len(discover(library_root))
