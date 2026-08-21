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
import time
from pathlib import Path

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


def summarize_vocab(library_root: Path) -> str:
    """The available predicates, grouped by the section headings in Vocab.lean."""
    vocab = library_root / "TrafficSpec" / "Core" / "Vocab.lean"
    if not vocab.exists():
        return "(Core/Vocab.lean not found)\n"
    out: list[str] = []
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


def summarize_schema(schema: dict) -> str:
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
    lines = [
        "These are the Lean constructor names verbatim — write `.car`, not `.vehicle_car`.",
        "",
        "**Entity types** (`EntityType`): " + ", ".join(f"`.{t}`" for t in ek["tier_a"]),
        "",
        "**Relation labels** (`RelLabel`): " + ", ".join(f"`.{t}`" for t in rl["tier_a"]),
        "",
        "**Proximity bands, closest first** — `safetyHazard` <2 m, `nearCollision` 2–4 m, "
        "`superNear` 4–7 m, `veryNear` 7–10 m, `near` 10–16 m, `visible` 16–25 m. "
        "`near` is the second *farthest* band; use `Pred.withinMetres` instead of "
        "guessing from the name.",
    ]

    cov = schema.get("relation_coverage", {}).get("proximity_and_angular_pairs", {})
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

    pre = schema.get("capture_preconditions")
    if pre:
        lines += [
            "",
            "**Capture preconditions — figures above that are assumptions, not "
            "facts.** Each is a caller-supplied default of the generator or the "
            "simulator, and none is recorded in a capture, so nothing downstream "
            "can confirm the capture you will be judged on used it. Treat a rule "
            "whose correctness turns on one of these as carrying a stated "
            "residue:",
            *[f"- `{key}` — {text}" for key, text in pre.items()
              if not key.startswith("$") and key != "how_to_fix"],
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
            "**Reachable, with a residue to record in the rule's notes.** These are "
            "*not* `unsupported` — formalize them and state the caveat:",
        ]
        for key, entry in sorted(partial.items()):
            if key.startswith("$"):
                continue
            lines.append(f"- `{key}` — available: {entry.get('available', '')} "
                         f"Residue: {entry.get('residue', '')} "
                         f"Vocabulary: {entry.get('vocabulary', '')}")
            # Rendered last and on its own line: this is the field that says which
            # predicate is *wrong* for the concept, and a reading that misses it
            # produces a rule that passes every scenario and fails on real data.
            if entry.get("do_not_use"):
                lines.append(f"  **DO NOT USE** for `{key}`: {entry['do_not_use']}")

    not_exposed = schema.get("available_not_exposed", {})
    if not_exposed:
        lines += [
            "",
            "**Present in the captured data but not yet lifted into Lean.** A law "
            "needing one of these is blocked on a *vocabulary/adapter extension*, "
            "not on CARLA. Say so in your plan and request the predicate — do "
            "**not** record the law as `unsupported`:",
        ]
        for key, why in sorted(not_exposed.items()):
            if key.startswith("$"):
                continue
            lines.append(f"- `{key}` — {why}")

    lines += [
        "",
        "**NOT available in CARLA scene graphs** — this is the only tier that "
        "justifies `unsupported`, and you must say which key it needs:",
    ]
    for key, why in sorted(schema.get("unavailable", {}).items()):
        if key.startswith("$"):
            continue
        lines.append(f"- `{key}` — {why}")

    pitfalls = schema.get("pitfalls", [])
    if pitfalls:
        lines += ["", "**Pitfalls**:"]
        lines += [f"- {p}" for p in pitfalls]

    recipes = schema.get("recipes", {})
    if recipes:
        lines += [
            "",
            "**Recipes** — statutory concept → construction with today's vocabulary. "
            "Use these instead of re-deriving what is possible:",
        ]
        for concept, how in recipes.items():
            if concept.startswith("$"):
                continue
            lines.append(f"- *{concept}* → {how}")

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
            vocab_summary=summarize_vocab(ctx.library_root),
            schema_summary=summarize_schema(schema),
            objectives_file=str(ctx.objectives_file),
            plan_file=str(ctx.plan_file),
            progress_file=str(ctx.progress_file),
            library_root=str(ctx.library_root),
            example_file=str(
                ctx.library_root / "TrafficSpec" / "Rules" / "Following"
                / "R0001_following_distance.lean"
            ),
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
