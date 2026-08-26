"""Deterministic validation of the plan agent's output.

No model involved. If the plan is malformed the code phase does not run at all —
the objections are written to `AUTO_NOTES.md` and the next iteration replans with
them in hand. Catching a bad plan here is far cheaper than discovering it after
four coding sessions.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Optional

from .task import IDENT_RE, SpecNode

REQUIRED_KEYS = {"node_id", "theme", "slug", "law_refs", "description", "binders", "scenarios"}
SLUG_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def load_law_ids(laws_file: Path) -> set[str]:
    ids: set[str] = set()
    if not laws_file.exists():
        return ids
    with open(laws_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ids.add(str(json.loads(line)["id"]))
            except (json.JSONDecodeError, KeyError):
                continue
    return ids


def existing_node_ids(library_root: Path) -> set[str]:
    """Node ids already in the library, derived from the rule files on disk."""
    rules_dir = library_root / "TrafficSpec" / "Rules"
    if not rules_dir.exists():
        return set()
    out = set()
    for path in rules_dir.rglob("*.lean"):
        theme = path.parent.name
        out.add(f"{theme}/{path.stem}")
    return out


def namespace_key(theme: str, slug: str) -> str:
    """The Lean namespace two rules would share, `<Theme>.<prefix>`.

    `SpecNode.namespace` keeps only the slug's leading `_`-delimited segment, so
    two slugs sharing that prefix within a theme land in the SAME namespace and
    their `schema` / `entry` / `scenarios` collide at build time. Nothing else
    catches it: each file passes its own gate, and the clash only appears when
    the integrate phase builds the library, by which point both coding sessions
    have been paid for.
    """
    return f"{theme}.{slug.split('_', 1)[0]}"


def existing_namespaces(library_root: Path) -> set[str]:
    return {namespace_key(n.split("/", 1)[0], n.split("/", 1)[1])
            for n in existing_node_ids(library_root)}


def validate(
    objectives_file: Path,
    laws_file: Path,
    library_root: Path,
    max_nodes: Optional[int] = None,
) -> tuple[list[SpecNode], list[str]]:
    """Return ``(valid_nodes, errors)``. A non-empty error list blocks the phase."""
    errors: list[str] = []

    if not objectives_file.exists():
        return [], [
            f"The plan agent did not create `{objectives_file.name}`. It must write "
            f"one JSON object per line to that exact path."
        ]

    law_ids = load_law_ids(laws_file)
    already = existing_node_ids(library_root)
    already_ns = existing_namespaces(library_root)
    seen: set[str] = set()
    seen_ns: dict[str, str] = {}
    nodes: list[SpecNode] = []

    with open(objectives_file, "r", encoding="utf-8") as f:
        raw_lines = [(n, ln.strip()) for n, ln in enumerate(f, 1)]

    entries = [(n, ln) for n, ln in raw_lines if ln and not ln.startswith("//")]
    if not entries:
        return [], [
            f"`{objectives_file.name}` is empty. If there is genuinely nothing left "
            f"to formalize, set `stage: COMPLETE` in PROGRESS.md instead of emitting "
            f"an empty plan."
        ]

    for lineno, line in entries:
        try:
            d = json.loads(line)
        except json.JSONDecodeError as exc:
            errors.append(f"line {lineno}: not valid JSON ({exc})")
            continue
        if not isinstance(d, dict):
            errors.append(f"line {lineno}: expected a JSON object")
            continue

        missing = REQUIRED_KEYS - set(d)
        if missing:
            errors.append(f"line {lineno}: missing key(s) {sorted(missing)}")
            continue

        try:
            node = SpecNode.from_dict(d)
        except (KeyError, TypeError, ValueError) as exc:
            errors.append(f"line {lineno}: malformed entry ({exc})")
            continue

        where = f"line {lineno} ({node.node_id})"

        if not IDENT_RE.match(node.theme):
            errors.append(f"{where}: theme `{node.theme}` must be a Lean identifier "
                          f"starting with a letter (it becomes a namespace segment)")
        if not SLUG_RE.match(node.slug):
            errors.append(f"{where}: slug `{node.slug}` must match [A-Za-z][A-Za-z0-9_]* "
                          f"(it becomes a file name and a namespace segment)")
        if node.node_id != f"{node.theme}/{node.slug}":
            errors.append(f"{where}: node_id must be exactly `<theme>/<slug>`, "
                          f"i.e. `{node.theme}/{node.slug}`")

        if node.node_id in seen:
            errors.append(f"{where}: duplicate node_id within this plan")
        seen.add(node.node_id)

        ns = namespace_key(node.theme, node.slug)
        if ns in seen_ns:
            errors.append(f"{where}: slug `{node.slug}` shares the namespace "
                          f"`{ns}` with `{seen_ns[ns]}` — the Lean namespace is "
                          f"the theme plus the slug's first `_`-delimited "
                          f"segment, so both rules would declare `schema`, "
                          f"`entry` and `scenarios` in it and the library would "
                          f"not build. Give the slugs distinct prefixes.")
        elif ns in already_ns:
            errors.append(f"{where}: slug `{node.slug}` shares the namespace "
                          f"`{ns}` with a rule already in the library. Give it a "
                          f"distinct first `_`-delimited segment.")
        seen_ns.setdefault(ns, node.node_id)

        if node.node_id in already:
            errors.append(f"{where}: a rule file for this node already exists "
                          f"({node.target_file}). Choose a new slug, or plan work on "
                          f"a different clause.")

        if not node.law_refs:
            errors.append(f"{where}: law_refs must name at least one law id — every "
                          f"rule must be traceable to the text it formalizes")
        for ref in node.law_refs:
            if law_ids and ref not in law_ids:
                errors.append(f"{where}: law_ref `{ref}` is not an id in {laws_file.name}")

        if not node.binders:
            errors.append(f"{where}: binders must not be empty; a rule with no "
                          f"quantified entity cannot ground on a trace")
        for b in node.binders:
            if not IDENT_RE.match(b):
                errors.append(f"{where}: binder label `{b}` must be an identifier")

        positives = [s for s in node.scenarios if s.expected]
        negatives = [s for s in node.scenarios if not s.expected]
        if not positives:
            errors.append(f"{where}: needs at least one positive scenario "
                          f"(expected=true) — conduct the law permits")
        if not negatives:
            errors.append(f"{where}: needs at least one negative scenario "
                          f"(expected=false) — conduct the law forbids. Without one, "
                          f"a vacuously true rule would pass.")
        names = [s.name for s in node.scenarios]
        if len(names) != len(set(names)):
            errors.append(f"{where}: duplicate scenario names")
        for s in node.scenarios:
            if not SLUG_RE.match(s.name):
                errors.append(f"{where}: scenario name `{s.name}` must match "
                              f"[A-Za-z][A-Za-z0-9_]*")

        if node.parent and node.parent not in seen and node.parent not in already:
            errors.append(f"{where}: parent `{node.parent}` is neither in this plan "
                          f"nor in the library")

        nodes.append(node)

    if max_nodes is not None and len(nodes) > max_nodes:
        errors.append(
            f"plan proposes {len(nodes)} nodes but the per-iteration limit is "
            f"{max_nodes}. Emit the highest-priority {max_nodes} and leave the rest "
            f"for the next iteration."
        )

    return nodes, errors


def write_auto_notes(auto_notes_file: Path, sections: list[tuple[str, list[str]]]) -> None:
    """Write the planner's feedback digest.

    Loop-owned: the plan phase reads it, then clears it, so each objection
    reaches the planner exactly once.
    """
    if not any(items for _, items in sections):
        return
    lines = ["# AUTO NOTES", "",
             "Generated by the harness. Address these before proposing new work.", ""]
    for title, items in sections:
        if not items:
            continue
        lines.append(f"## {title}")
        lines.append("")
        for item in items:
            lines.append(f"- {item}")
        lines.append("")
    auto_notes_file.parent.mkdir(parents=True, exist_ok=True)
    auto_notes_file.write_text("\n".join(lines), encoding="utf-8")
    print(f"[info] Wrote planner feedback to {auto_notes_file}")
