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

from .. import runner
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
        "- `.bounded n φ` whose window runs off the end is **false**. So "
        "`□ (¬ₛ .bounded n bad)` is satisfied on any trace shorter than `n`, "
        "*whatever the trace contains*, and the last `n-1` frames of every trace are "
        "a blind zone. Give every scenario trace at least `n` frames; the gate "
        "rejects shorter ones as `TRACE_TOO_SHORT`.",
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
    out = ["**Trace constructors** — generated from `Core/Builders.lean` "
           "(`def mk*`). Scenario traces are built only from these:"]
    for m in re.finditer(r"^def (mk\w+|frame)\s*(.*?)\s*:\s*(Entity|Relation|Scene)\b",
                         text, re.M | re.S):
        args = " ".join(m.group(2).split())
        out.append(f"- `{m.group(1)} {args}` → `{m.group(3)}`")
    out.append("")
    out.append("Argument order is load-bearing and unchecked: every dynamics "
               "channel of `mkEgo` is a `String`, so a permuted order compiles "
               "and quietly tests something else. Copy the order above.")
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
    (`CAPTURE_ENTITY_CENSUS`, `GROUNDING_BUDGET`). Rendering them from there
    keeps the agent's arithmetic and the gate's identical by construction, and
    the over-budget combinations below are computed with the gate's own
    `predicted_groundings`, so they cannot drift from what it will actually
    reject.
    """
    grounding = library_root / "TrafficSpec" / "Core" / "Grounding.lean"
    if not grounding.exists():
        return "(Core/Grounding.lean not found)\n"
    gate = _gate_module()
    census = getattr(gate, "CAPTURE_ENTITY_CENSUS", {}) or {}
    keys = getattr(gate, "BINDER_CENSUS_KEY", {}) or {}
    budget = getattr(gate, "GROUNDING_BUDGET", None)

    out = ["**Binder helpers** — generated from `Core/Grounding.lean` "
           "(`def *Binder`). One per planned binder:"]
    names: list[str] = []
    for m in re.finditer(r"^def (\w+Binder) \(label : String\) : Binder := \u27e8label, ([^\u27e9]+)\u27e9",
                         grounding.read_text(encoding="utf-8"), re.M):
        name, types = m.group(1), m.group(2).strip()
        names.append(name)
        count = census.get(keys.get(name, ""))
        cost = f" — about {count} candidates per capture" if count else ""
        out.append(f"- `{name}` ranges over `{types}`{cost}")

    if not (gate and census and budget):
        return "\n".join(out) + "\n"

    out += [
        "",
        "**Every binder multiplies.** `PropertySchema.bindings` is the cross "
        "product of the binders' candidates, and each grounding is a full "
        "evaluation over the whole trace. The gate predicts that product from "
        f"the counts above and rejects a schema over {budget:,} groundings with "
        "`GROUNDING_BUDGET`; two binders of the same type contribute "
        "n × (n−1), because `distinctIds` forbids them sharing an entity.",
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


def summarize_schema(schema: dict,
                     library_root: Optional[Path] = None) -> str:
    """Render the CARLA contract for the plan agent.

    Every availability tier is shown, because the distinction between them is
    the judgement the plan agent gets wrong most expensively: a law blocked on a
    predicate that does not exist yet is *not* the same as a law blocked on data
    CARLA does not carry, and only the second is `unsupported`.
    """
    ek = schema["entity_types"]
    rl = schema["relation_labels"]
    ak = schema["attribute_keys"]
    tb = schema.get("time_base", {})
    # Generated from Core/Scene.lean, not read from the schema. A hand-maintained
    # copy of an enumeration can list a constructor that no longer exists, and the
    # agent has no way to tell. `run_spec doctor` checks the two still agree, so a
    # drift is a failed check rather than a rule that will not compile.
    entity_src = "carla/schema.json → entity_types.tier_a"
    relation_src = "carla/schema.json → relation_labels.tier_a"
    entities, relations = list(ek["tier_a"]), list(rl["tier_a"])
    if library_root is not None:
        scene = library_root / "TrafficSpec" / "Core" / "Scene.lean"
        if scene.exists():
            text = scene.read_text(encoding="utf-8")
            gen_e = _lean_ctors(text, "EntityType")
            gen_r = _lean_ctors(text, "RelLabel")
            if gen_e:
                entities, entity_src = gen_e, "Core/Scene.lean → inductive EntityType"
            if gen_r:
                relations, relation_src = gen_r, "Core/Scene.lean → inductive RelLabel"

    lines = [
        "These are the Lean constructor names verbatim — write `.car`, not `.vehicle_car`.",
        "",
        f"**Entity types** (`EntityType`, from {entity_src}): "
        + ", ".join(f"`.{t}`" for t in entities),
        "",
        f"**Relation labels** (`RelLabel`, from {relation_src}): "
        + ", ".join(f"`.{t}`" for t in relations),
        "",
        "**Proximity bands, closest first** — `safetyHazard` <2 m, `nearCollision` 2–4 m, "
        "`superNear` 4–7 m, `veryNear` 7–10 m, `near` 10–16 m, `visible` 16–25 m. "
        "`near` is the second *farthest* band; use `Pred.withinMetres` instead of "
        "guessing from the name.",
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
            "Covered base classes: "
            + ", ".join(f"`{c}`" for c in cov.get("covered_base_classes", []))
            + ". " + cov.get("consequence", ""),
        ]

    if tb:
        lines += [
            "",
            f"**Time base** — frames carry no timestamp; the reference capture runs at "
            f"{tb.get('capture_hz')} Hz ({tb.get('frame_interval_seconds')} s per frame), "
            f"so a duration becomes a frame count via `TrafficSpec.secondsToFrames`. "
            f"This is a modelling assumption to record, not a missing field.",
            "",
            "**A duration also sets a minimum trace length.** "
            "`Core/Semantics.lean` reads a `.bounded n` window that runs off the "
            "end of the trace as false, so `□ (¬ₛ .bounded n bad)` — the usual "
            "safety shape — reports *compliant* on any trace shorter than `n`, "
            "whatever it contains. Every scenario trace you plan must therefore "
            "be at least as long as the longest duration the rule uses, and the "
            "gate rejects shorter ones as `TRACE_TOO_SHORT`. Prefer the shortest "
            "persistence window the clause actually justifies: a 4-second window "
            "needs 80-frame traces and cannot be checked on a shorter capture.",
        ]

    # Measured facts about the generator that used to sit in `notes` and reach
    # nobody. 55 of 118 long-form schema entries were never rendered, and two of
    # the hardest-won findings — that parked map geometry becomes a `.car` with
    # full proximity edges, and that a light's `controls` edge only reaches
    # junction-internal lanes — were among them. `run_spec doctor` now fails if
    # any entry is undelivered, so this block is not optional decoration.
    never = (schema.get("entity_types") or {}).get("never_bind") or []
    if never:
        lines += ["", "**Never bind these entity types**: "
                  + ", ".join(f"`.{t}`" for t in never)]
    mult = (schema.get("entity_types") or {}).get("multiplicity") or {}
    if mult:
        lines += ["", "**How many entities of a type one situation contributes** "
                  "(this is what a binder multiplies over):"]
        lines += [f"- `.{k}` — {v}" for k, v in mult.items()]

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
    kinds = ak.get("kinds", {})
    for key in ak["tier_a"]:
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

    # How absence is DERIVED. The schema is frozen before the pipeline sees any
    # law, so it cannot pre-enumerate which absences a corpus will ask about.
    # Rendered before the two key lists because it is what tells the agent how to
    # use them: a list of absences could be read off, a derivation must be
    # applied.
    steps = schema.get("deciding_unsupported", {})
    if steps:
        lines += ["", "**Deciding whether a law is unsupported** — work down "
                      "these in order. There is no list of absent things: the "
                      "two key lists below enumerate everything that exists, so "
                      "absence is what you derive when both come up empty:"]
        for key, text in steps.items():
            if key.startswith("$"):
                continue
            lines.append(f"- **{key}** — {text}")

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

        template = (ctx.prompts_dir / "prompt_plan.txt").read_text(encoding="utf-8")
        prompt = template.format(
            laws_block=format_laws(laws),
            law_count=len(laws),
            library_summary=summarize_library(ctx.library_root),
            binder_summary=summarize_binders(ctx.library_root),
            vocab_summary=summarize_vocab(ctx.library_root),
            formula_summary=summarize_formula(ctx.library_root),
            schema_summary=summarize_schema(schema, ctx.library_root),
            objectives_file=str(ctx.objectives_file),
            plan_file=str(ctx.plan_file),
            progress_file=str(ctx.progress_file),
            library_root=str(ctx.library_root),
            example_block=summarize_example(ctx.library_root),
            max_nodes=ctx.options.max_nodes_per_iter,
            auto_notes=auto_notes.strip() or "(none — this is the first iteration)",
            user_hints=hints.strip() or "(none)",
            iter_num=ctx.iter_num,
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
