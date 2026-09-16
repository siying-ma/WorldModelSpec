"""Plan phase: decide what to formalize next.

The plan agent reads the law corpus, the existing library, and the harness's
feedback from the previous iteration, then emits `objectives.jsonl` — one node
per rule to write. It decides decomposition: whether a clause becomes one rule or
several, and whether a clause is formalizable against CARLA scene graphs at all.

Feedback discipline (from Archon): capture `AUTO_NOTES.md` and `USER_HINTS.md`
*before* the session, inject them into the prompt, and clear them only *after*
the session succeeds — a crashed plan leaves the feedback intact for the retry.
"""

from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Optional

from .. import coverage, gaps, plan_validate, runner
from ..state import clear_auto_notes, clear_temporary_hints
from .base import Phase, PhaseResult


def load_laws(laws_file: Path) -> list[dict]:
    laws: list[dict] = []
    with open(laws_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    laws.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return laws


def format_laws(laws: list[dict]) -> str:
    blocks = []
    for law in laws:
        blocks.append(
            f"### `{law.get('id', '?')}`"
            + (f" — {law['title']}" if law.get("title") else "")
            + "\n\n"
            + law.get("text", "").strip()
            + "\n"
        )
    return "\n".join(blocks) if blocks else "(no laws supplied)\n"


def summarize_library(library_root: Path) -> str:
    """What already exists, so the planner extends rather than duplicates."""
    rules_dir = library_root / "TrafficSpec" / "Rules"
    if not rules_dir.exists():
        return "(the library contains no rules yet)\n"
    lines = []
    for path in sorted(rules_dir.rglob("*.lean")):
        theme = path.parent.name
        refs = ""
        text = path.read_text(encoding="utf-8", errors="replace")
        for line in text.splitlines():
            if "lawRefs" in line:
                refs = line.strip()
                break
        lines.append(f"- `{theme}/{path.stem}` ({path.relative_to(library_root)}) {refs}")
    return "\n".join(lines) + "\n" if lines else "(the library contains no rules yet)\n"


def pick_example_rule(library_root: Path) -> str:
    """An existing rule file to hold up as the worked example.

    Resolved from disk, never hard-coded. Both prompts used to name
    `Rules/Following/R0001_following_distance.lean`, which stopped existing the
    first time a run renumbered its nodes — so the agent was told to read a file
    that was not there. That matters more than it sounds: the example rule is the
    only place either prompt shows the formula notation in context, so operators
    like `⟹` and `⋁` (which appear in no prompt and no schema recipe) were being
    learned from it or not at all.

    Preference order: the shortest rule under `Speed` (the simplest clauses), then
    the shortest rule anywhere. Shortest, because the example is read for shape
    rather than for subject matter.

    Returns `""` when the library carries no rules. That is the state the
    library is FROZEN in — Core, the schema and the prompts are fixed before any
    law is seen, so the first iteration of every run has no example by
    construction. `summarize_example` renders that case as its own block rather
    than interpolating a path that does not exist.
    """
    rules = sorted((library_root / "TrafficSpec" / "Rules").rglob("*.lean"))
    if not rules:
        return ""
    speed = [r for r in rules if r.parent.name == "Speed"]
    pool = speed or rules
    return str(min(pool, key=lambda r: r.stat().st_size))


def summarize_example(library_root: Path) -> str:
    """The worked-example section, or the honest absence of one.

    Both prompts used to interpolate a path into "Read `{path}` to see the shape
    of a finished rule", which reads as an instruction even when the path is a
    placeholder saying no rule exists — and no rule exists on the first
    iteration of every run, because the library is frozen empty. The section is
    generated whole so the absent case can say something true instead.

    The example is held up for SHAPE. Its subject matter is one clause the loop
    happened to formalize first, and a plan agent that reads it for content
    inherits that clause's decompositions.
    """
    path = pick_example_rule(library_root)
    if not path:
        return (
            "## Worked example\n\n"
            "The library carries no rules yet, so there is no finished rule to "
            "read. The generated tables above are the whole of what a rule may "
            "use, and nothing a rule needs is missing from them. What you write "
            "now sets the shape everything later is read against, so keep it "
            "small and make the acceptance tests discriminating.\n"
        )
    return (
        "## Worked example\n\n"
        f"Read `{path}` for the shape of a finished rule: a `PropertySchema` "
        "with binders, a `RuleEntry` carrying `lawRefs`, and scenarios as "
        "concrete traces. Read it for shape, not for subject matter — it "
        "formalizes one clause of one corpus, and its decompositions and "
        "thresholds are that clause's, not a template. Note whether it records "
        "the formalization choices its text did not dictate; every rule must, "
        "so that a reviewer can challenge a reading without rerunning the "
        "pipeline.\n"
    )


def summarize_vocab(library_root: Path) -> str:
    """The available predicates, grouped by the section headings in Vocab.lean."""
    vocab = library_root / "TrafficSpec" / "Core" / "Vocab.lean"
    if not vocab.exists():
        return "(Core/Vocab.lean not found)\n"
    out: list[str] = ["**Predicates** — generated from `Core/Vocab.lean` "
                      "(`def`, grouped by its own section headings). These are the "
                      "only predicates that exist; a rule may not build its own."]
    section = ""
    for line in vocab.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("-- §"):
            section = stripped.lstrip("- ").strip()
            out.append(f"\n**{section}**")
        elif stripped.startswith("def "):
            name = stripped[4:].split(" ")[0].split("(")[0].split(":")[0]
            sig = stripped[4:]
            out.append(f"- `Pred.{name}` — `{sig}`")
    return "\n".join(out) + "\n"


def _lean_ctors(scene_src: str, inductive: str) -> list[str]:
    """Constructor names of a Lean `inductive`, in declaration order.

    The agent-facing entity and relation lists are generated with this rather
    than copied out of `carla/schema.json`, so the prompt cannot name a
    constructor the core does not define.
    """
    m = re.search(
        rf"inductive {inductive}\b(.*?)(?=\ninductive |\ndef |\nnamespace |\Z)",
        scene_src, re.S)
    return re.findall(r"^\s*\|\s*(\w+)", m.group(1), re.M) if m else []


def unbindable_types(library_root: Path) -> list[str]:
    """`EntityType` constructors no binder can ever produce.

    A binder ranges over one of the `*Types` lists in `Core/Scene.lean`; a
    constructor in none of them cannot be bound, so a schema naming it grounds
    zero times. Derived rather than declared, because the declared version named
    one type when two qualify.
    """
    scene = (library_root / "TrafficSpec" / "Core" / "Scene.lean").read_text(
        encoding="utf-8")
    covered: set[str] = set()
    for _, body in re.findall(
            r"def (\w+Types)\s*:\s*List EntityType\s*:=\s*\[(.*?)\]",
            scene, re.S):
        covered |= set(re.findall(r"\.(\w+)", body))
    return sorted(set(_lean_ctors(scene, "EntityType")) - covered)


def capture_census() -> dict:
    """The binder-domain sizes the gate enforces, from the gate itself."""
    import sys as _sys
    _sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
    from check_spec import CAPTURE_ENTITY_CENSUS      # noqa: E402
    return dict(CAPTURE_ENTITY_CENSUS)


def core_model(library_root: Path) -> dict:
    """The data model, read from `Core/Scene.lean` — the only copy there is.

    Everything here used to be duplicated in `carla/schema.json` and compared
    back against Core by four `doctor` checks. The duplication was the reason
    those checks existed: a second copy of an enumeration can name a constructor
    that no longer exists, and the agent has no way to tell. Deleting the copy
    deletes the failure mode and the checks together, which is cheaper than
    policing it.

    Fails loudly rather than falling back. A fallback would render a stale copy
    at exactly the moment the real one became unreadable, which is the case the
    fallback is supposed to protect against.
    """
    scene = library_root / "TrafficSpec" / "Core" / "Scene.lean"
    text = scene.read_text(encoding="utf-8")
    bands = [(lbl, int(m)) for lbl, m in
             re.findall(r"\.(\w+),\s*(\d+)",
                        (re.search(r"def distanceBands.*?\[(.*?)\]", text, re.S)
                         or re.match("", "")).group(1) if
                        re.search(r"def distanceBands.*?\[(.*?)\]", text, re.S) else "")]
    hz = re.search(r"def captureHz : Nat := (\d+)", text)
    prox = re.search(r"def proximityTypes.*?\[(.*?)\]", text, re.S)
    model = {
        "entities": _lean_ctors(text, "EntityType"),
        "relations": _lean_ctors(text, "RelLabel"),
        "bands": bands,
        "capture_hz": int(hz.group(1)) if hz else 0,
        "proximity_types": re.findall(r"\.(\w+)", prox.group(1)) if prox else [],
    }
    missing = [k for k, v in model.items() if not v]
    if missing:
        raise SystemExit(f"plan: {scene} did not yield {', '.join(missing)} — "
                         f"the prompt cannot be built from a stale copy")
    return model


def band_prose(bands: list) -> str:
    """The bands with their ranges, in words, generated from the pairs.

    Written out by hand before, which made the prompt a THIRD copy of
    `distanceBands` after Core and the schema.
    """
    parts, lo = [], 0
    for lbl, hi in bands:
        parts.append(f"`{lbl}` <{hi} m" if lo == 0 else f"`{lbl}` {lo}-{hi} m")
        lo = hi
    return ", ".join(parts)


def summarize_formula(library_root: Path) -> str:
    """The formula language, generated from `Core/Formula.lean`.

    Neither prompt used to name the operators, and neither points at
    `Formula.lean` or `Semantics.lean`. Counting what the rules actually use
    against what the agent was shown: `⟹` appeared 21 times in the library and
    zero times in any prompt or schema recipe; `⋁` 6 times and zero. The agent
    was inferring the language from one example rule — and that example was a
    path that no longer existed. Generating the table from the notation
    declarations keeps it complete and unable to drift.

    The end-of-trace notes are the part that fails *silently*: a wrong operator
    will not compile, but a formula that quietly reads false past the last frame
    is accepted and monitors nothing.
    """
    formula = library_root / "TrafficSpec" / "Core" / "Formula.lean"
    if not formula.exists():
        return "(Core/Formula.lean not found)\n"
    pairs: list[tuple[str, str]] = []
    for line in formula.read_text(encoding="utf-8").splitlines():
        m = re.search(r'scoped (?:prefix|infixl|infixr|notation)[^"]*"([^"]+)"\s*=>\s*SFProp\.(\w+)',
                      line.strip())
        if m:
            pairs.append((m.group(1).strip(), m.group(2)))
    out = ["**Formula language** — generated from `Core/Formula.lean` "
           "(`scoped notation`). These are the only operators that exist:"]
    for sym, ctor in pairs:
        out.append(f"- `{sym}` — `SFProp.{ctor}`")
    out.append("- `.bounded n φ` — φ holds for `n` consecutive frames from here")
    out += [
        "",
        "**End-of-trace behaviour, which decides whether a rule can fire at all:**",
        "- An atom past the last frame reads **false**. So `◯ p` is false at the end, "
        "but `¬ₛ ◯ p` is **true** there — a transition can never be observed from the "
        "final frame.",
        "- `.bounded n φ` whose window runs off the end is **false**. Two "
        "consequences. `□ (¬ₛ .bounded n bad)` is satisfied on any trace shorter "
        "than `n` *whatever the trace contains*, so give every scenario trace at "
        "least `n` frames — the gate rejects shorter ones as `TRACE_TOO_SHORT`. "
        "And the last `n-1` positions cannot START a window, so conduct that is "
        "still in progress when the trace ends is never confirmed: a run of `n-1` "
        "bad frames at the very end reads compliant, and one more recorded frame "
        "would have made it a violation. Put the conduct a negative scenario is "
        "testing well inside the trace, not against its end.",
        "- `□`, `𝒰` and `ℛ` are clamped to the end of the trace, so they degrade "
        "gracefully rather than inverting.",
    ]
    return "\n".join(out) + "\n"


def summarize_builders(library_root: Path) -> str:
    """The trace constructors, generated from `Core/Builders.lean`.

    The last piece of Core a rule uses that the agent was never told. Measured
    across the library: of 12 `Builders` names the rules use, 11 appeared in no
    prompt — the agent had to open the file to learn them.

    That matters most for `mkEgo`, which takes NINE positional `String`
    arguments. A permuted order compiles (they are all strings), passes the gate,
    and silently changes which dynamics the scenario tests — the agent also wrote
    the expected verdict, so nothing disagrees. Showing the signature verbatim is
    cheaper than any check that could catch it afterwards.
    """
    builders = library_root / "TrafficSpec" / "Core" / "Builders.lean"
    if not builders.exists():
        return "(Core/Builders.lean not found)\n"
    text = builders.read_text(encoding="utf-8")
    out = ["**Trace constructors** — generated from `Core/Builders.lean`. "
           "Scenario traces are built only from these:"]
    # The return type must be followed by `:=`, so a parameter whose own type
    # is one of these (`padTo (n : Nat) (τ : Trace)`) does not end the match
    # early and truncate the signature the agent is shown.
    for m in re.finditer(r"^def (mk\w+|frame|padTo)\s*(.*?)\s*"
                         r":\s*(Entity|Relation|Scene|Trace)\s*:=",
                         text, re.M | re.S):
        args = " ".join(m.group(2).split())
        out.append(f"- `{m.group(1)} {args}` → `{m.group(3)}`")
    out.append("")
    out.append("Argument order is load-bearing and unchecked: every dynamics "
               "channel of `mkEgo` is a `String`, so a permuted order compiles "
               "and quietly tests something else. Copy the order above.")
    out.append("")
    out.append("`padTo` exists because how long a trace must be is a property "
               "of the FORMULA, not of the situation a scenario depicts: a "
               "trace shorter than the formula's frame span makes every bounded "
               "operator read a window that runs off the end, which the "
               "semantics report as false. Write the situation at its natural "
               "length and wrap it in `padTo`; do not hand-count frames.")
    return "\n".join(out) + "\n"


def _gate_module():
    """`tools/check_spec.py`, imported for the numbers that size a binder.

    Imported rather than regex-parsed, and read from the gate rather than
    restated in the prompt template: `CAPTURE_ENTITY_CENSUS` is a measurement of
    one capture, so a template that quoted it would go on asserting the old
    figures after a re-measurement — and the templates are frozen before any
    capture exists, which is exactly why no figure obtained by running the
    simulator may be written into one.
    """
    import importlib.util
    path = Path(__file__).resolve().parents[2] / "tools" / "check_spec.py"
    if not path.exists():
        return None
    spec = importlib.util.spec_from_file_location("_gate_for_prompt", path)
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception:                          # the prompt still renders without it
        return None
    return module


def summarize_binders(library_root: Path) -> str:
    """The binder helpers, generated from `Core/Grounding.lean`, with what each costs.

    Seven of them were shown nowhere agent-facing. Each binder MULTIPLIES the
    grounding count, so the choice is a cost decision as well as a modelling one
    — and the two numbers that decide it belong to the gate
    (`CAPTURE_ENTITY_CENSUS`). Rendering them from there keeps the agent's
    arithmetic and the gate's identical by construction.

    There is no budget any more. Refusing a schema for its cost traded a clause
    the library never monitors for a capture run that finishes sooner, and only
    `monitor` pays that cost — the loop's own traces are a handful of frames.
    """
    grounding = library_root / "TrafficSpec" / "Core" / "Grounding.lean"
    if not grounding.exists():
        return "(Core/Grounding.lean not found)\n"
    gate = _gate_module()
    census = getattr(gate, "CAPTURE_ENTITY_CENSUS", {}) or {}
    keys = getattr(gate, "BINDER_CENSUS_KEY", {}) or {}

    out = ["**Binder helpers** — generated from `Core/Grounding.lean` "
           "(`def *Binder`). One per planned binder:"]
    names: list[str] = []
    # `Binder` gained an optional field, so its constructions moved from the
    # anonymous bracket form to named fields, which silently emptied this
    # table until the pattern followed. Both forms are matched, and `doctor`
    # now fails when the table lists fewer binders than the census knows, so
    # a future change to the declaration cannot quietly take the binders away
    # from the agent again.
    _binder_re = (r"^def (\w+Binder) \(label : String\) : Binder :=\s*"
                  r"(?:\u27e8label, ([^\u27e9]+)\u27e9"
                  r"|\{ label, types := ([^,}]+)[,}])")
    for m in re.finditer(_binder_re,
                         grounding.read_text(encoding="utf-8"), re.M):
        name = m.group(1)
        types = (m.group(2) or m.group(3) or "").strip()
        names.append(name)
        count = census.get(keys.get(name, ""))
        cost = f" — about {count} candidates per capture" if count else ""
        out.append(f"- `{name}` ranges over `{types}`{cost}")

    if not (gate and census):
        return "\n".join(out) + "\n"

    out += [
        "",
        "**Every binder multiplies, and none of it is held against you.** "
        "`PropertySchema.bindings` is the cross product of the binders' "
        "candidates, and each grounding is a full evaluation over the whole "
        "trace; two binders of the same type contribute n × (n−1), because "
        "`distinctIds` forbids them sharing an entity. The gate computes that "
        "product from the counts above and REPORTS it. It rejects nothing for "
        "it, and there is no budget to stay under.",
        "",
        "So: **bind whatever the clause needs.** If expressing an obligation "
        "takes a third quantified entity, take it — a clause the library does "
        "not monitor is a permanent loss, and an expensive rule is a capture "
        "run that takes longer. Cost is never a reason to leave a clause "
        "unformalized, and it is never a gap: a gap says something cannot be "
        "expressed, not that expressing it is expensive.",
        "",
        "Fewer binders is still better where the clause allows it, for one "
        "reason only — a binder over an entity the clause is not about "
        "generates pairs whose antecedent is false, which inflates the count "
        "that is supposed to say whether the clause was engaged at all. That is "
        "a modelling argument, not a budget.",
        "",
        "The counts come from `tools/check_spec.py` (`CAPTURE_ENTITY_CENSUS`). "
        "They calibrate one reference capture, not the scene-graph format: a "
        "busier map or a longer capture changes every one of them, so treat "
        "them as an order of magnitude rather than as facts about the data.",
    ]
    return "\n".join(out) + "\n"

    soft = getattr(gate, "GROUNDING_SOFT_CEILING", None)
    out += [
        "",
        "**Every binder multiplies.** `PropertySchema.bindings` is the cross "
        "product of the binders' candidates, and each grounding is a full "
        "evaluation over the whole trace. The gate predicts that product from "
        f"the counts above and rejects a schema over {budget:,} groundings with "
        "`GROUNDING_BUDGET`; two binders of the same type contribute "
        "n × (n−1), because `distinctIds` forbids them sharing an entity.",
        "",
        f"**{budget:,} is a failure detector, not a quota.** Nothing under it "
        f"is thereby endorsed, and a plan that reports its nodes as \"all under "
        f"{budget:,}\" has answered a question nobody asked. The number to aim "
        + (f"at is ~{soft}, which is what a rule costs when it binds only the "
           f"actors its clause is about; the gate warns above that and says "
           f"which binder to argue with. " if soft else "")
        + "Choose the binders the clause requires and no others: where two "
        "readings are both faithful, take the cheaper, and where a binder "
        "exists only to reach a relation, the predicate that would quantify it "
        "internally is a gap worth filing.",
        "",
        "The counts and the budget come from `tools/check_spec.py` "
        "(`CAPTURE_ENTITY_CENSUS`, `GROUNDING_BUDGET`). They calibrate one "
        "reference capture, not the scene-graph format: a busier map or a longer "
        "capture changes every one of them, so treat them as the order of "
        "magnitude the gate will hold you to rather than as facts about the "
        "data.",
    ]

    predict = getattr(gate, "predicted_groundings", None)
    if predict:
        pairs = []
        for i, a in enumerate(names):
            for b in names[i:]:
                estimate, _ = predict(f'{a} "x" {b} "y"', census)
                if estimate > budget:
                    pairs.append((estimate, a, b))
        if pairs:
            shown = sorted(pairs, reverse=True)[:6]
            out += [
                "",
                "Two binders and nothing else already exceed the budget in these "
                "combinations: "
                + ", ".join(f"`{a}` × `{b}` ({n:,})" for n, a, b in shown)
                + (", …" if len(pairs) > len(shown) else "") + ".",
            ]
    return "\n".join(out) + "\n"


def summarize_portability_brief(repo_root: Path) -> str:
    """The transfer classes, for a session that is choosing between predicates.

    The planning session gets the whole ledger because it decides whether a
    clause is formalizable at all. A coding session decides something narrower
    and more frequent — which of two predicates to read when both express the
    clause — and for that the key lists are the whole of what it needs. The
    long-form entries would be noise at that point, and the `video_only`
    section is not addressed to it at all: by the time a node reaches a coding
    session, the question of whether the data exists has been answered.
    """
    path = repo_root / "perception" / "portability.json"
    if not path.exists():
        return ("(no portability ledger at `perception/portability.json` — "
                "nothing is known about which of this data survives the move "
                "to real video, so do not assume any of it does)\n")
    try:
        led = json.loads(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        return f"(portability ledger is not valid JSON: {exc})\n"
    ak, rl = led.get("attribute_keys", {}), led.get("relation_labels", {})
    lines = [
        "This pipeline's eventual target is real video. Where the clause admits "
        "two formalizations and one avoids a simulator-only element, take that "
        "one; where only a simulator-only element will do, use it and say so in "
        "the comment block. This is a PREFERENCE — a rule is never rejected for "
        "reading one, because weakening the CARLA library to flatter a later "
        "transfer would invert the experiment.",
        "",
    ]
    for cls, label in (
            ("sim_only", "**Simulator-only** — no counterpart a camera can "
                         "recover, so a rule reading one cannot run on video"),
            ("both_with_error", "**Recoverable as an ESTIMATE** — portable only "
                                "if your threshold is large relative to the "
                                "error, which is a property of the threshold "
                                "you choose, not of the key"),
            ("portable", "**Portable** — error small relative to any threshold "
                         "a traffic code states")):
        keys = (ak.get(cls) or {}).get("keys") or []
        labels = (rl.get(cls) or {}).get("labels") or []
        if not (keys or labels):
            continue
        lines.append(f"{label}:")
        if keys:
            lines.append("  attributes — " + ", ".join(f"`{k}`" for k in sorted(keys)))
        if labels:
            lines.append("  relations — " + ", ".join(f"`{k}`" for k in sorted(labels)))
        lines.append("")
    return "\n".join(lines)


def summarize_portability(repo_root: Path) -> str:
    """Render the CARLA-to-video portability ledger for the plan agent.

    `carla/schema.json` says what the generator emits; this says which of it a
    camera could recover. They are separate files because their provenance is
    separate, and the distinction reaches the agent as a PREFERENCE rather than
    a restriction: forbidding the simulator-only elements would make the CARLA
    library worse in order to make a later transfer look better, which inverts
    the experiment this pipeline exists to run.

    Absent or unreadable, the block says so. A missing ledger must not read as
    "everything transfers".
    """
    path = repo_root / "perception" / "portability.json"
    if not path.exists():
        return ("(no portability ledger at `perception/portability.json` — "
                "nothing is known about which of this data survives the move "
                "to real video, so do not assume any of it does)\n")
    try:
        led = json.loads(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        return f"(portability ledger is not valid JSON: {exc})\n"

    ak = led.get("attribute_keys", {})
    rl = led.get("relation_labels", {})
    lines = [
        "The pipeline's eventual target is real video. This says which of the "
        "data you are about to read exists there, and it is a PREFERENCE, not "
        "a restriction: where one clause admits two formalizations and one of "
        "them avoids a simulator-only element, take that one — otherwise use "
        "what you need and say in `notes` that the rule will not transfer.",
        "",
    ]
    for cls, label in (
            ("sim_only", "**Simulator-only** — no counterpart a camera can recover"),
            ("both_with_error", "**Recoverable, but as an estimate** — the class "
                                "most often mistaken for portable"),
            ("portable", "**Portable** — recoverable with error small relative "
                         "to any threshold a traffic code states")):
        keys = (ak.get(cls) or {}).get("keys") or []
        labels = (rl.get(cls) or {}).get("labels") or []
        if not (keys or labels):
            continue
        lines.append(f"{label}:")
        if keys:
            lines.append("  attributes — " + ", ".join(f"`{k}`" for k in sorted(keys)))
        if labels:
            lines.append("  relations — " + ", ".join(f"`{k}`" for k in sorted(labels)))
        lines.append("")

    err = (ak.get("both_with_error") or {}).get("error_regimes") or {}
    if err:
        lines += ["Why an estimate is not the same as a value — the regime "
                  "decides whether a THRESHOLD is portable, not the key:"]
        lines += [f"- {k}: {v}" for k, v in sorted(err.items())]
        lines.append("")

    struct = led.get("structural") or {}
    if struct:
        lines += ["Differences attached to no single key, and the ones most "
                  "often missed:"]
        for name, entry in sorted(struct.items()):
            if not isinstance(entry, dict):
                continue
            lines.append(f"- **{name}** ({entry.get('class', '?')}) — "
                         f"{entry.get('statement', '')} "
                         f"{entry.get('consequence', '')}")
        lines.append("")

    # Rendered BY ORIGIN, because the origin decides which of judgement 1's
    # four outcomes a clause falls into, and the two are easy to confuse. An
    # element the simulator has and this pipeline does not take is a capability
    # gap with an owner; only an element the simulator does not have at all
    # makes a clause unsupported. Rendering them in one list, as this block once
    # did, told a planning session that a clause conditioned on conditions the
    # simulator sets had no counterpart.
    vo = led.get("video_only") or {}
    named = {k: v for k, v in vo.items()
             if not k.startswith("$") and isinstance(v, dict)}
    absent = {k: v for k, v in named.items()
              if v.get("origin") == "absent_from_carla"}
    elsewhere = {k: v for k, v in named.items() if k not in absent}
    origins = led.get("origins") or {}
    if absent:
        lines += ["**Absent from the simulator in any form.** A clause needing "
                  "one of these is untestable here for a reason that is not a "
                  "defect of your formalization: record it `unsupported`, with "
                  "a gap at owner `absent` so the verdict is citable.", ""]
        for k, v in sorted(absent.items()):
            lines.append(f"- **{k}** — {v.get('what', '')} "
                         f"[{v.get('evidence', '')}]")
        lines.append("")
    if elsewhere:
        lines += ["**The simulator has it; this pipeline does not take it.** "
                  "NOT unsupported — each is a capability gap, and the `origin` "
                  "says which layer would have to change. File the gap and "
                  "record the clause `blocked_on_gap`; do not approximate the "
                  "element with a different attribute.", ""]
        for k, v in sorted(elsewhere.items()):
            origin = v.get("origin", "?")
            lines.append(f"- **{k}** ({origin}) — {v.get('what', '')} "
                         f"[{v.get('evidence', '')}]")
            if v.get("note"):
                lines.append(f"    note: {v['note']}")
        lines.append("")
        used = {v.get("origin") for v in elsewhere.values()}
        lines += ["Where each origin stops, and what retiring it takes:"]
        lines += [f"- `{o}` — {origins[o]}" for o in sorted(used) if o in origins]
        lines.append("")
    return "\n".join(lines)


def summarize_schema(schema: dict,
                     library_root: Optional[Path] = None) -> str:
    """Render the CARLA contract for the plan agent.

    Every availability tier is shown, because the distinction between them is
    the judgement the plan agent gets wrong most expensively: a law blocked on a
    predicate that does not exist yet is *not* the same as a law blocked on data
    CARLA does not carry, and only the second is `unsupported`.
    """
    ak = schema["attribute_keys"]
    model = core_model(library_root)
    entities, relations = model["entities"], model["relations"]

    lines = [
        "These are the Lean constructor names verbatim — write `.car`, not `.vehicle_car`.",
        "",
        "**Entity types** (`EntityType`, from Core/Scene.lean): "
        + ", ".join(f"`.{t}`" for t in entities),
        "",
        "**Relation labels** (`RelLabel`, from Core/Scene.lean): "
        + ", ".join(f"`.{t}`" for t in relations),
        "",
        "**Proximity bands, closest first** (`distanceBands`, from "
        "Core/Scene.lean) — " + band_prose(model["bands"]) + ". "
        f"`{model['bands'][-2][0]}` is the second *farthest* band; use "
        "`Pred.withinMetres` instead of guessing from the name.",
    ]

    cov = schema.get("relation_coverage", {}).get("proximity_and_angular_pairs", {})
    # `rule`, `excluded_and_why` and `lean_binders` are agent-facing: they say
    # which pairs an edge exists for and which binder to reach for. They used to
    # render nowhere.
    if cov.get("rule"):
        pass  # rendered with the coverage block below
    if cov:
        lines += [
            "",
            "**Which pairs carry a distance** — " + cov.get("ego_is_always_one_end", ""),
            "Covered base classes (`proximityTypes`, from Core/Scene.lean): "
            + ", ".join(f"`{c}`" for c in model["proximity_types"])
            + ". " + cov.get("consequence", ""),
        ]

    # Unconditional: every fact in this block comes from Core/Scene.lean,
    # not from the schema. It used to be guarded on a schema section, so
    # removing that section silently dropped the capture rate from the
    # prompt — the agent was left with no way to reason about how long a
    # trace has to be.
    if True:
        lines += [
            "",
            f"**Time base** — frames carry no timestamp; traces are assumed to be "
            f"sampled at {model['capture_hz']} Hz (`captureHz`, from Core/Scene.lean), "
            f"so a duration becomes a frame count via `TrafficSpec.secondsToFrames`. "
            f"This is a modelling assumption to record, not a missing field.",
            "",
            "How long a trace must then be is a property of the FORMULA, not of "
            "the data — see *The temporal language* above, which is generated "
            "from `Core/Formula.lean` and states it once. Choosing the shortest "
            "persistence window the clause actually justifies is your call: a "
            "longer window needs longer traces and cannot be checked on a "
            "shorter capture.",
        ]

    # Measured facts about the generator that used to sit in `notes` and reach
    # nobody. 55 of 118 long-form schema entries were never rendered, and two of
    # the hardest-won findings — that parked map geometry becomes a `.car` with
    # full proximity edges, and that a light's `controls` edge only reaches
    # junction-internal lanes — were among them. `run_spec doctor` now fails if
    # any entry is undelivered, so this block is not optional decoration.
    # Derived, both of them. The schema used to declare these and both copies
    # were wrong or redundant: `never_bind` listed one type when two are
    # unbindable, and `multiplicity` restated check_spec.CAPTURE_ENTITY_CENSUS,
    # which is the copy the gate actually enforces.
    never = unbindable_types(library_root)
    if never:
        lines += ["", "**Never bind these entity types** — no binder in "
                  "`Core/Grounding.lean` ranges over them, so a schema naming "
                  "one grounds zero times: "
                  + ", ".join(f"`.{t}`" for t in never)]
    census = capture_census()
    if census:
        lines += ["", "**How many entities of a type one situation contributes** "
                  "(this is what a binder multiplies over, from "
                  "`check_spec.CAPTURE_ENTITY_CENSUS`):"]
        lines += [f"- `{k}` — about {v}" for k, v in sorted(census.items())]

    for key, label in (("governance_edges", "Governance edges (`controls`)"),
                       ("isIn_edges", "`isIn` edges")):
        obj = (schema.get("relation_coverage") or {}).get(key) or {}
        body = {k: v for k, v in obj.items() if k != "$comment"}
        if body:
            lines += ["", f"**{label}**: "
                      + " ".join(f"{k}: {v}" for k, v in body.items())]

    lane_edges = (schema.get("relation_coverage") or {}).get("inter_lane_edges") or {}
    presence = (schema.get("relation_coverage") or {}).get("entity_presence") or {}
    for name, obj in (("Inter-lane edges", lane_edges), ("Entity presence", presence)):
        if obj:
            lines += ["", f"**{name}**: " + " ".join(str(v) for v in obj.values())]

    dec = (schema.get("attribute_keys") or {}).get("decimal_note")
    if dec:
        lines += ["", f"**Comparing numeric attributes**: {dec}"]

    if cov:
        excl = cov.get("excluded_and_why") or {}
        lines += ["", "**Which pairs carry a distance or angular edge**: "
                  + str(cov.get("rule", ""))]
        if excl:
            lines += ["Excluded base classes, and why: "
                      + "; ".join(f"`{k}` — {v}" for k, v in excl.items())]
        if cov.get("lean_binders"):
            lines += ["Binder choice: " + cov["lean_binders"]]
        if cov.get("static_background_vehicles"):
            lines += ["Not every covered entity is a real actor: "
                      + cov["static_background_vehicles"]]

    pre = schema.get("capture_preconditions")
    if pre:
        lines += [
            "",
            "**Capture preconditions — figures above that are assumptions, not "
            "facts.** Each is a caller-supplied default of the generator or the "
            "simulator, and none is recorded in a capture, so nothing "
            "downstream can confirm the capture you will be judged on used it. "
            "Frozen Core encodes four of them as constants, which is why a "
            "capture made with other settings does not fail loudly — the trace "
            "still type-checks and still grounds, but its keys no longer MEAN "
            "what Core assumes. Treat a rule whose correctness turns on one of "
            "these as carrying a stated residue:",
            *[f"- `{key}`"
              + (f" (parameter: {', '.join(entry['parameters'])})"
                 if isinstance(entry, dict) and entry.get("parameters") else "")
              + (f" — mirrored in {entry['mirrored_in_core']}"
                 if isinstance(entry, dict) and entry.get("mirrored_in_core")
                 else "")
              + f" — {entry['note'] if isinstance(entry, dict) and 'note' in entry else entry}"
              for key, entry in pre.items()
              if not key.startswith("$") and key != "how_to_fix"
              and not isinstance(entry, dict) or (
                  isinstance(entry, dict) and "note" in entry)],
            *[f"- `{key}` (parameter, no effect on this abstraction) — {text}"
              for key, text in (pre.get("no_effect_on_this_abstraction")
                                or {}).items()
              if not key.startswith("$") and key != "parameters"],
        ]

    lines += [
        "",
        "**Attribute keys** (readable from a rule today, via `Pred.attr*`):",
    ]
    # The KEY LIST comes from carla/adapter.py and Core/Builders.lean — the two
    # things that put an attribute on an entity — not from the schema, which
    # carries only what each key means. Sorted so the block is stable between
    # runs; the schema's `kinds` supplies the description for each.
    import sys as _sys
    _sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "carla"))
    from adapter import lifted_attribute_keys          # noqa: E402
    kinds = ak.get("kinds", {})
    for key in sorted(lifted_attribute_keys(library_root)):
        kind = kinds.get(key, {})
        scope = kind.get("on", "")
        unit = f", {kind['unit']}" if kind.get("unit") else ""
        values = (" one of " + ", ".join(f"`{v}`" for v in kind["values"])
                  if kind.get("values") else "")
        lines.append(f"- `{key}` — {kind.get('kind', 'string')}{unit} on {scope}{values}")
    lines.append(
        "Numeric attributes are decimal strings compared in milli-units "
        "(`Pred.attrMilli*`, 1 m/s = 1000); booleans are `\"true\"`/`\"false\"` "
        "(`Pred.attrTrue`), and an absent boolean reads false."
    )

    partial = schema.get("partially_available", {})
    if partial:
        lines += [
            "",
            "**How to read each part of the generator's output.** Keyed by the "
            "data element, not by any statutory concept, and `covers` names the "
            "entity types and relation labels each one explains — every element "
            "of the data model appears here or is plain enough to need no note. "
            "None of this is `unsupported`. How to combine them into a rule is "
            "your decision, not the schema's:",
        ]
        for key, entry in partial.items():
            if key.startswith("$") or key == "no_note_needed":
                continue
            covers = ", ".join(f"`{c}`" for c in (entry.get("covers") or []))
            lines += [f"- `{key}`" + (f" — covers {covers}" if covers else ""),
                      f"  - available: {entry.get('available', '')}",
                      f"  - mechanism: {entry.get('mechanism', '')}",
                      f"  - data limit: {entry.get('data_limit', '')}",
                      f"  - vocabulary: {entry.get('vocabulary', '')}"]
            # Rendered last and on its own line: this is the field that says which
            # predicate is *wrong* for the concept, and a reading that misses it
            # produces a rule that passes every scenario and fails on real data.
            if entry.get("do_not_use"):
                lines.append(f"  - **DO NOT USE** for `{key}`: {entry['do_not_use']}")

    # The unlifted side of the key partition. Rendered with the actual key
    # names, because this is the section that decides whether a law is
    # `unsupported` or merely blocked, and a group heading alone does not let the
    # agent recognise the key its law needs.
    ane = schema.get("available_not_exposed", {})
    groups = {g: b for g, b in ane.items()
              if not g.startswith("$") and isinstance(b, dict)}
    if groups:
        lines += ["", "**Present in the data, NOT lifted into Lean.** Together "
                      "with the attribute keys above this is the whole of what "
                      "the generator writes — two sides, nothing else exists. A "
                      "law needing one of these is blocked on a vocabulary and "
                      "adapter extension, NOT unsupported: say so in the plan "
                      "and request the key by name:"]
        for group, body in groups.items():
            keys = ", ".join(f"`{k}`" for k in (body.get("keys") or []))
            lines.append(f"- `{group}`" + (f": {keys}" if keys else ""))
            for k, v in body.items():
                if k == "keys" or k.startswith("$") or not isinstance(v, str):
                    continue
                lines.append(f"  - {k}: {v}")

    return "\n".join(lines) + "\n"


class PlanPhase(Phase):
    name = "Plan agent"
    number = 1
    token = "plan"

    def run(self) -> PhaseResult:
        ctx = self.ctx
        if self.should_skip():
            print(f"[info] {self.name} skipped (--from)")
            return PhaseResult(skipped=True)

        self.header()
        ctx.iter_dir.mkdir(parents=True, exist_ok=True)

        auto_notes = ctx.auto_notes_file.read_text(encoding="utf-8") \
            if ctx.auto_notes_file.exists() else ""
        hints = ctx.hints_file.read_text(encoding="utf-8") \
            if ctx.hints_file.exists() else ""

        schema = json.loads(
            (ctx.repo_root / "carla" / "schema.json").read_text(encoding="utf-8")
        )
        laws = load_laws(ctx.laws_file)

        template = (ctx.prompts_dir / "prompt_plan.md").read_text(encoding="utf-8")
        prompt = template.format(
            laws_block=format_laws(laws),
            law_count=len(laws),
            library_summary=summarize_library(ctx.library_root),
            binder_summary=summarize_binders(ctx.library_root),
            vocab_summary=summarize_vocab(ctx.library_root),
            formula_summary=summarize_formula(ctx.library_root),
            schema_summary=summarize_schema(schema, ctx.library_root),
            portability_summary=summarize_portability(ctx.repo_root),
            objectives_file=str(ctx.objectives_file),
            plan_file=str(ctx.plan_file),
            progress_file=str(ctx.progress_file),
            library_root=str(ctx.library_root),
            example_block=summarize_example(ctx.library_root),
            max_nodes=ctx.options.max_nodes_per_iter,
            auto_notes=auto_notes.strip() or "(none — this is the first iteration)",
            user_hints=hints.strip() or "(none)",
            iter_num=ctx.iter_num,
            gaps_file=str(ctx.gaps_file),
            gap_ledger=gaps.render_for_agent(gaps.load(ctx.repo_root)[0]),
            coverage_state=coverage.render_for_agent(coverage.assess(
                ctx.progress_file, ctx.repo_root,
                plan_validate.load_law_ids(ctx.laws_file),
                hints_file=ctx.hints_file)),
        )
        (ctx.iter_dir / "plan_prompt.txt").write_text(prompt, encoding="utf-8")

        if ctx.options.dry_run:
            print("[dry-run] plan prompt written; not launching Claude")
            return PhaseResult(skipped=True)

        start = time.monotonic()
        code, result, timed_out = runner.run_claude(
            prompt,
            cwd=ctx.repo_root,
            stream_path=ctx.iter_dir / "plan_claude_raw.jsonl",
            max_turns=ctx.options.max_turns,
            model=ctx.options.model,
            effort=ctx.options.effort,
            max_budget_usd=ctx.options.max_budget_usd,
            timeout_seconds=(ctx.options.timeout_minutes * 60
                             if ctx.options.timeout_minutes else None),
        )
        secs = int(time.monotonic() - start)
        ctx.write_meta(**{
            "plan.durationSecs": secs,
            "plan.costUsd": runner.extract_cost(result),
            "plan.terminalReason": (result or {}).get("terminal_reason"),
            "plan.timedOut": timed_out,
            "plan.returnCode": code,
        })
        print(f"[info] Plan phase finished in {secs}s")

        # The planner consumed the feedback; clear it so each note lands once.
        if auto_notes.strip():
            clear_auto_notes(ctx.auto_notes_file)
        if hints.strip():
            clear_temporary_hints(ctx.hints_file)

        return PhaseResult()
