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
WIT_BEGIN = "  -- BEGIN GENERATED WITNESSES"
WIT_END = "  -- END GENERATED WITNESSES"
WIT_IMPORT_BEGIN = "-- BEGIN GENERATED IMPORTS"
WIT_IMPORT_END = "-- END GENERATED IMPORTS"


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
        for decl in ("schema", "entry"):
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


def witness_path(library_root: Path, rule: "RuleFile") -> Path:
    """Where the witnesses for a rule file live.

    Mirrors the rule's own path under a different library root, so the pairing
    is a fact about the file system rather than a registry someone has to keep
    in step.
    """
    rel = rule.path.relative_to(library_root / "TrafficSpec" / "Rules")
    return library_root / "TrafficSpecWitness" / rel


def _sync_witnesses(library_root: Path, files: list, dry_run: bool
                    ) -> tuple[bool, list[str]]:
    root = library_root / "TrafficSpecWitness.lean"
    if not root.exists():
        return False, [f"{root} does not exist"]
    problems: list[str] = []
    imports: list[str] = []
    pairs: list[str] = []
    for f in files:
        wit = witness_path(library_root, f)
        if not wit.exists():
            problems.append(
                f"{f.rel}: no witness file at "
                f"{wit.relative_to(library_root)} — every rule needs the two "
                f"traces that show it can be violated and can be complied with")
            continue
        text = wit.read_text(encoding="utf-8", errors="replace")
        ns = next((ln.split()[1] for ln in text.splitlines()
                   if ln.startswith("namespace TrafficSpecWitness")), None)
        if ns is None:
            problems.append(f"{wit.name}: no `namespace TrafficSpecWitness.…`")
            continue
        if "def scenarios" not in text:
            problems.append(f"{wit.name}: missing `def scenarios`")
            continue
        rel = wit.relative_to(library_root).with_suffix("")
        imports.append("import " + ".".join(rel.parts))
        pairs.append(f"({f.short_namespace}.entry, {ns}.scenarios)")
    # And the other direction. A witness with no rule is the residue of a node
    # that was rejected and rolled back incompletely: it keeps building, keeps
    # looking like evidence, and sits in the scope baseline of every node that
    # runs after it. Reported here because the integrate phase treats these as
    # failures, so the loop stops on it instead of accumulating them.
    expected = {witness_path(library_root, f).resolve() for f in files}
    wit_dir = library_root / "TrafficSpecWitness"
    if wit_dir.exists():
        for stray in sorted(wit_dir.rglob("*.lean")):
            if stray.resolve() not in expected:
                problems.append(
                    f"{stray.relative_to(library_root)}: witness file with no "
                    f"rule — a rejected node left it behind")
    if problems:
        return False, problems
    original = root.read_text(encoding="utf-8")
    text = _replace_block(original, WIT_IMPORT_BEGIN, WIT_IMPORT_END, imports)
    text = _replace_block(text, WIT_BEGIN, WIT_END,
                          [f"  [ {', '.join(pairs)} ]" if pairs else "  []"])
    changed = text != original
    if changed and not dry_run:
        root.write_text(text, encoding="utf-8")
        print(f"[info] Registered {len(pairs)} witness module(s) in {root.name}")
    return changed, []


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

    original = index_path.read_text(encoding="utf-8")
    text = _replace_block(original, IMPORT_BEGIN, IMPORT_END, imports)
    text = _replace_block(text, RULES_BEGIN, RULES_END, [f"  [ {rules} ]" if rules else "  []"])

    changed = text != original
    if changed and not dry_run:
        index_path.write_text(text, encoding="utf-8")
        print(f"[info] Registered {len(files)} rule(s) in {index_path.name}")

    # The witness root is generated from the same file list, so a rule and its
    # witness cannot drift apart: a rule with no witness file is a structural
    # problem reported here, not a silently missing acceptance test.
    changed_w, problems_w = _sync_witnesses(library_root, files, dry_run)
    changed = changed or changed_w
    # Returned, not discarded. The rule-file problems above are returned early,
    # so this tail used to end `return changed, []` — correct while there was
    # nothing left to report, and silently swallowing every witness problem the
    # moment there was.
    return changed, problems + problems_w


def registered_count(library_root: Path) -> int:
    return len(discover(library_root))
