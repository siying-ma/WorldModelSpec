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

from .coverage import Assessment
from .task import IDENT_RE, SpecNode

REQUIRED_KEYS = {"node_id", "theme", "slug", "law_refs", "description", "binders", "scenarios"}

#: The two acceptance witnesses, and what each one rules out. They are not
#: interchangeable and neither is decoration.
#:
#: `forbid` is the only evidence anywhere in this pipeline that a formula says
#: something. A rule equivalent to `□ ⊤` grounds, engages and holds on every
#: capture ever recorded, so no amount of real data separates it from a correct
#: rule until a capture happens to violate it — and most rules are never
#: violated in most captures. `permit` is the only evidence that the antecedent
#: is satisfiable and the obligation reachable at the same time.
#:
#: A third role, `antecedent_off`, was required until it was measured and found
#: to be a theorem rather than a test. It showed that the rule imposes nothing
#: when the situation is absent — which, for a formula shaped `□ (A ⟹ B)`, is
#: what the semantics of implication already guarantee. Across the library it
#: held for 55 of 55 such traces, and it accounted for more than half of all
#: trace-writing work. The fact it was meant to establish is now reported
#: instead by the antecedent-liveness column of a capture run, where it is a
#: measurement rather than a restatement.
SCENARIO_ROLES = {
    "permit":         (True,  "the clause applies and the conduct complies"),
    "forbid":         (False, "the same situation, differing in exactly the fact "
                              "the clause governs"),
}

#: Exactly two: one `permit`, one `forbid`. The cap is the count, because a
#: third witness of either role adds nothing to what the first one established.
MAX_SCENARIOS = 2
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
    assessment: Optional[Assessment] = None,
) -> tuple[list[SpecNode], list[str]]:
    """Return ``(valid_nodes, errors)``. A non-empty error list blocks the phase.

    `assessment` is the coverage table read together with the gap ledger. When
    it is supplied, a node is additionally required to be about a clause the
    state says is plannable — see :func:`_actionability_errors`. It is optional
    so the validator stays usable on a plan alone, which the tests and the
    dry-run path do.
    """
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

        roles = [s.role for s in node.scenarios]
        for s in node.scenarios:
            if s.role not in SCENARIO_ROLES:
                errors.append(f"{where}: scenario `{s.name}` has role "
                              f"{s.role or '(missing)'!r}; it must be one of "
                              f"{sorted(SCENARIO_ROLES)}")
                continue
            wants, means = SCENARIO_ROLES[s.role]
            if s.expected is not wants:
                errors.append(f"{where}: scenario `{s.name}` is `{s.role}` — "
                              f"{means} — so `expected` must be "
                              f"{str(wants).lower()}, not {str(s.expected).lower()}. "
                              f"A role and a verdict that disagree were written "
                              f"from two different readings of the clause.")
        if roles.count("permit") != 1:
            errors.append(f"{where}: needs exactly one `permit` scenario, found "
                          f"{roles.count('permit')} — the compliant conduct the "
                          f"clause governs")
        if roles.count("forbid") != 1:
            errors.append(f"{where}: needs exactly one `forbid` scenario, found "
                          f"{roles.count('forbid')} — none lets a vacuously true "
                          f"rule pass, and a second adds nothing to that "
                          f"guarantee that the first has not already given.")
        if len(node.scenarios) > MAX_SCENARIOS:
            errors.append(f"{where}: {len(node.scenarios)} witnesses, at most "
                          f"{MAX_SCENARIOS} — exactly one `permit` and one "
                          f"`forbid`. A second witness of either role restates "
                          f"what the first already established, at the cost of "
                          f"another trace to build.")
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

        errors.extend(_actionability_errors(node, where, assessment))

        nodes.append(node)

    if max_nodes is not None and len(nodes) > max_nodes:
        errors.append(
            f"plan proposes {len(nodes)} nodes but the per-iteration limit is "
            f"{max_nodes}. Emit the highest-priority {max_nodes} and leave the rest "
            f"for the next iteration."
        )

    return nodes, errors


def _actionability_errors(node: SpecNode, where: str,
                          assessment: Optional[Assessment]) -> list[str]:
    """Refuse a node about a clause the state says is not plannable.

    WHAT THIS PREVENTS, from a run that happened. By its second iteration every
    clause in the corpus had a rule or a recorded verdict and the plan agent
    wrote that there was nothing left to plan. Iterations three, four and five
    then planned five, one and three more nodes — each one reversing an earlier
    `unsupported` verdict, and each reversal a WEAKER reading than the clause
    deserved: a curve-warning sign standing in for road curvature, a brake lamp
    standing in for a vehicle at rest, a town-boundary sign standing in for a
    built-up area. Cost rose by a third of the run's total while the library got
    worse, and nothing in the pipeline could see it happening, because a node
    for an already-decided clause was indistinguishable from a node for a new
    one.

    The rule is therefore: a clause is plannable when its row says `pending`,
    when a gap it was blocked on has retired, or when the operator has written
    `reopen: <law id>` in USER_HINTS.md. Anything else is refused HERE, before a
    coding session is paid for. A planning session that disagrees with a
    terminal verdict has two cheap moves — say so in the plan file, and file a
    dispute on the gap — and no expensive one.

    A clause with no row at all is allowed: that is a corpus the table has not
    caught up with, and refusing it would stall a run on a bookkeeping lapse.
    """
    if assessment is None:
        return []
    actionable = set(assessment.actionable) | set(assessment.missing)
    by_law = {r.law: r for r in assessment.rows}
    out: list[str] = []
    for ref in node.law_refs:
        if ref in actionable or ref not in by_law:
            continue
        row = by_law[ref]
        if row.status == "blocked_on_gap":
            out.append(
                f"{where}: `{ref}` is `blocked_on_gap` on `{row.gap or '?'}`, "
                f"which is still open. Formalizing it now means formalizing a "
                f"weaker reading than the clause deserves. Leave the row alone; "
                f"if you believe the gap is wrong, file a dispute on it.")
        else:
            out.append(
                f"{where}: `{ref}` is `{row.status}`, a terminal status — this "
                f"pipeline has already decided it. Reversing that decision "
                f"needs either a retired gap or an operator `reopen: {ref}` "
                f"line in USER_HINTS.md. Record the disagreement in the plan "
                f"file instead of planning a node.")
    return out


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
