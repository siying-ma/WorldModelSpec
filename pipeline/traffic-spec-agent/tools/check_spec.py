#!/usr/bin/env python3
"""The specification gate. The coding agent calls this after every edit.

    python3 tools/check_spec.py --node-id <id> --task-dir <dir> --library-root <dir>

Checks run in order, first failure wins, and each prints exactly one verdict
token on the first line so the prompt can branch on it:

    MISSING_FILE         the rule file was not created where the plan said
    SCOPE_VIOLATION      a file outside the node's target was modified
    STRUCTURE_FAIL       required declarations or namespace missing
    VOCAB_VIOLATION      an ad-hoc predicate, or a Pred.* that does not exist
    CARLA_INCOMPATIBLE   references scene-graph data CARLA cannot produce
    HYGIENE_FAIL         sorry / axiom / native_decide / partial def
    GROUNDING_BUDGET     the binder cross product is too large to evaluate
    COMPILE_FAIL         Lean errors
    TRACE_TOO_SHORT      a scenario trace is shorter than the formula's frame span
    SCENARIO_VACUOUS     a scenario has zero groundings, so it tests nothing
    SCENARIO_FAIL        a scenario's verdict disagrees with the plan
    OK                   accepted, pending integration

Exit status is 0 for every verdict (the verdict text is the payload) and 1 only
for a tool-internal failure such as a missing Lean toolchain.

`OK` from this script is necessary but not sufficient. Both of its inputs are
under the caller's control — `--library-root` says which directory to measure and
`baseline.json` says what to compare it against — so a session can obtain `OK`
without its rule being sound, and two sessions in run `test_eight_rules` did. The
harness therefore re-checks scope after each session against a manifest it
captured and kept itself, and records the verdict `GATE_BYPASS` for an `OK` that
was measured against a different library, a replaced baseline, or with
`--skip-build`. See `scripts/phases/code.py::CodePhase._authorize`.

Every verdict written here carries `library_root`, `baseline_sha` and
`skip_build`, in both `verdict.json` and `progress.jsonl`, so what was measured is
auditable rather than inferred from file mtimes after the fact.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from scripts.lean_check import (  # noqa: E402
    LeanUnavailable,
    eval_harness,
    first_errors,
    lake_build,
    write_node_harness,
)

# ── hygiene patterns ─────────────────────────────────────────────────────
# `sorry` must not match `sorryAx` in a comment or a name like `no_sorry_here`,
# so require word boundaries.
HYGIENE_PATTERNS = [
    (re.compile(r"\bsorry\b"),                 "`sorry` — the specification is incomplete"),
    (re.compile(r"^\s*axiom\b", re.M),         "`axiom` — assumptions must not be introduced"),
    (re.compile(r"\bnative_decide\b"),         "`native_decide` — not kernel-checked"),
    (re.compile(r"^\s*partial\s+def\b", re.M), "`partial def` — evaluation must terminate"),
    (re.compile(r"@\[implemented_by"),         "`@[implemented_by]` — replaces verified code"),
    (re.compile(r"^\s*unsafe\b", re.M),        "`unsafe`"),
]

# A rule file must not build predicates out of raw scene tests: an arbitrary
# `Scene → Bool` closure can read features CARLA never produces, and is opaque
# to review. Predicates belong in Core/Vocab.lean.
ADHOC_PATTERNS = [
    (re.compile(r"\bmkAtom\b"),      "`mkAtom` — build predicates from `Pred.*`, or extend Core/Vocab.lean"),
    (re.compile(r"\bAtomicPred\b"),  "`AtomicPred` literal — use `Pred.*`"),
    (re.compile(r"Scene\s*→\s*Bool"), "a raw `Scene → Bool` test — use `Pred.*`"),
    (re.compile(r"\.atom\b"),        "`.atom` — use `Pred.*`"),
]

REQUIRED_DECLS = ["schema", "entry", "scenarios"]

# Binder helper name -> the census key in carla/schema.json whose count it ranges
# over. `Core/Grounding.lean` is the authority for what each helper admits.
BINDER_CENSUS_KEY = {
    "vehicleBinder": "vehicle",
    "proximityVehicleBinder": "proximityVehicle",
    "proximityRoadUserBinder": "roadUser",
    "roadUserBinder": "roadUser",
    "pedestrianBinder": "pedestrian",
    "laneBinder": "lane",
    "roadBinder": "road",
    "junctionBinder": "junction",
    "trafficLightBinder": "trafficLight",
    "stopSignBinder": "stopSign",
    "controlDeviceBinder": "controlDevice",
    "landmarkBinder": "landmark",
    "speedLimitSignBinder": "speedLimitSign",
    "signBinder": "sign",
    "structureBinder": "structure",
    "truckBinder": "truck",
    "busBinder": "bus",
    "bicycleBinder": "bicycle",
}
BINDER_USE_RE = re.compile(r"\b(\w+Binder)\s+\"")

# Groundings one rule may cost on a reference capture.
#
# `PropertySchema.bindings` is the cross product of every binder's candidates, so
# each binder MULTIPLIES the cost, and every grounding is a full `satisfies` over
# the whole trace — measured at ~20 ms for a 240-frame capture. 500 therefore
# caps one rule at ~10 s per capture, which keeps a 20-rule library inside a
# few minutes.
#
# This exists because the gate cannot otherwise see the cost: a scenario trace
# holds 3-4 lanes, so a rule binding two lanes grounds a handful of times at the
# gate and ~1,200 times on a capture. Two captures were reported unevaluable
# before this check existed.
# Distinct entities of each binder type a typical capture contains — the
# calibration the grounding budget is sized against.
#
# This is a MEASUREMENT OF ONE CAPTURE, not a fact about the scene-graph format,
# which is why it does not live in `carla/schema.json`. It was taken on a
# 240-frame Town03 capture, and Town03 is one CARLA map among many: a busier map
# or a longer capture changes every number here. The schema must stay true for
# any capture; this only has to be a defensible order of magnitude for sizing a
# budget, and it is deliberately rounded UP from the measurement so the check
# does not pass a rule that would then blow up on real traffic.
#
# Raw measurement: vehicle 2 · lane 35 · road 23 · junction 2 · trafficLight 3 ·
# stopSign 0 · landmark 3 · pedestrian 0.
# Re-measure with `traceEntityIds` on a representative capture if the towns or
# traffic densities you record change materially.
CAPTURE_ENTITY_CENSUS = {
    "vehicle": 8, "proximityVehicle": 8, "roadUser": 10, "pedestrian": 6,
    "lane": 35, "road": 23, "junction": 4,
    "trafficLight": 6, "stopSign": 4, "controlDevice": 8, "landmark": 6,
    # Vehicle sub-classes. Bounded above by "vehicle", and deliberately loose:
    # the estimate exists to REFUSE an expensive schema, so over-counting costs
    # a false refusal the author can argue with, while under-counting admits a
    # rule that then cannot be evaluated on a capture at all.
    "truck": 3, "bus": 2, "bicycle": 3,
    "speedLimitSign": 6,
    # Group binders: the sum of their members, since a group binder ranges over
    # all of them. `sign` = trafficLight + stopSign + speedLimitSign + landmark;
    # `structure` = lane + road + junction + the single Off Road node.
    "sign": 22, "structure": 63,
}

# Cost of one grounding: a full `satisfies` over the whole trace. Measured at
# ~20 ms for a 240-frame capture (16,637 groundings in 327 s of `lake env lean`),
# and growing with frames^2 because `Trace` is a `List Scene`.
GROUNDING_BUDGET = 500

# Attribute keys are the one place a syntactically valid spec can still demand
# data CARLA does not carry, so string literals passed to attribute predicates
# are checked against the schema manifest.
ATTR_CALL_RE = re.compile(
    r"\b(?:Pred\.)?(?:attrEq|attrTrue|attrMilliLe|attrMilliGe|attrMilliAbsLe"
    r"|attrMilliAbsGe|lightOn)\s+"
    r"[A-Za-z_][A-Za-z0-9_']*\s+\"([^\"]+)\""
)
PRED_USE_RE = re.compile(r"\bPred\.([A-Za-z][A-Za-z0-9_']*)")
DEF_RE = re.compile(r"^\s*(?:private\s+)?def\s+([A-Za-z][A-Za-z0-9_']*)", re.M)


def predicted_groundings(code: str, census: dict) -> tuple[int, list[str]]:
    """Estimate a schema's grounding count on a reference capture.

    Same-type binders use a falling factorial because `distinctIds` forbids two
    binders sharing an entity: two lane binders give n*(n-1), not n^2.
    Returns ``(estimate, ["laneBinder x lane=35", ...])`` for the message.
    """
    names = BINDER_USE_RE.findall(code)
    total = 1
    seen: dict[str, int] = {}
    detail: list[str] = []
    for name in names:
        key = BINDER_CENSUS_KEY.get(name)
        if key is None:                       # unknown helper: cannot estimate
            return 0, []
        count = int(census.get(key, 0))
        available = max(0, count - seen.get(key, 0))
        seen[key] = seen.get(key, 0) + 1
        detail.append(f"{name} -> {key}={count}" +
                      (f" (distinct: {available})" if available != count else ""))
        total *= max(available, 1) if count else 1
    return total, detail


def strip_lean_comments(text: str) -> str:
    """Blank out Lean comments, preserving line structure and string literals.

    Every pattern-based check below must run on this rather than the raw source:
    a doc comment on a following-distance rule legitimately contains the word
    "unsafe", and legitimately mentions `Pred.foo` in prose. Newlines are kept so
    reported line numbers still line up.

    String literals are preserved verbatim — the CARLA attribute-key check reads
    them — but are tracked so that a `--` inside a string is not mistaken for the
    start of a comment.
    """
    out: list[str] = []
    i, n = 0, len(text)
    block_depth = 0
    in_line_comment = False
    in_string = False

    while i < n:
        ch = text[i]
        two = text[i:i + 2]

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
                out.append("\n")
            else:
                out.append(" ")
            i += 1
        elif block_depth > 0:
            if two == "/-":
                block_depth += 1
                out.append("  ")
                i += 2
            elif two == "-/":
                block_depth -= 1
                out.append("  ")
                i += 2
            else:
                out.append("\n" if ch == "\n" else " ")
                i += 1
        elif in_string:
            if ch == "\\" and i + 1 < n:
                out.append(text[i:i + 2])
                i += 2
            else:
                if ch == '"':
                    in_string = False
                out.append(ch)
                i += 1
        else:
            if two == "/-":
                block_depth = 1
                out.append("  ")
                i += 2
            elif two == "--":
                in_line_comment = True
                out.append("  ")
                i += 2
            elif ch == '"':
                in_string = True
                out.append('"')
                i += 1
            else:
                out.append(ch)
                i += 1

    return "".join(out)


def emit(verdict: str, *lines: str) -> None:
    print(verdict)
    for line in lines:
        print(line)


def record(progress_file: Path, verdict: str, detail: str,
           provenance: Optional[dict] = None) -> int:
    """Append the attempt and return the new attempt count.

    `provenance` names *what was measured* — which library directory, and which
    baseline it was compared against. Without it, a verdict in this log cannot be
    audited after the fact: two runs of this gate can print `OK` for the same
    node while looking at different directories.
    """
    progress_file.parent.mkdir(parents=True, exist_ok=True)
    attempts = 0
    if progress_file.exists():
        with open(progress_file, "r", encoding="utf-8") as f:
            attempts = sum(1 for ln in f if ln.strip())
    rec = {
        "attempt": attempts,
        "verdict": verdict,
        "detail": detail[:4000],
        "timestamp": datetime.now().isoformat(),
    }
    rec.update(provenance or {})
    with open(progress_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    return attempts + 1


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def library_manifest(library_root: Path) -> dict[str, str]:
    """Hash every tracked source file, so scope violations are detectable.

    `.lake/` is build output and is excluded.
    """
    out: dict[str, str] = {}
    for path in sorted(library_root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(library_root)
        if ".lake" in rel.parts:
            continue
        if path.suffix not in {".lean", ".toml"} and path.name not in {
            "lean-toolchain", "lakefile.lean", "lake-manifest.json"
        }:
            continue
        out[str(rel)] = sha(path)
    return out


def scope_diff(baseline: dict[str, str], current: dict[str, str],
               target_rel: str) -> list[str]:
    """Out-of-scope changes between two manifests, ignoring the node's target.

    Shared with the harness's post-session re-check (`scripts/phases/code.py`) so
    the two can never disagree about what counts as a violation.
    """
    touched = []
    for rel, digest in current.items():
        if rel == target_rel:
            continue
        if baseline.get(rel) != digest:
            kind = "modified" if rel in baseline else "added"
            touched.append(f"{kind}: {rel}")
    for rel in baseline:
        if rel not in current and rel != target_rel:
            touched.append(f"deleted: {rel}")
    return sorted(touched)


def load_schema(repo_root: Path) -> dict:
    schema_path = repo_root / "carla" / "schema.json"
    if not schema_path.exists():
        raise FileNotFoundError(f"CARLA schema manifest missing: {schema_path}")
    return json.loads(schema_path.read_text(encoding="utf-8"))


def vocab_names(library_root: Path) -> set[str]:
    vocab = library_root / "TrafficSpec" / "Core" / "Vocab.lean"
    if not vocab.exists():
        return set()
    return set(DEF_RE.findall(vocab.read_text(encoding="utf-8")))


def suggest(name: str, known: set[str], limit: int = 5) -> list[str]:
    """Cheap nearest-name suggestions: shared prefix, then substring."""
    lowered = name.lower()
    scored = sorted(
        known,
        key=lambda k: (
            -len(_common_prefix(k.lower(), lowered)),
            0 if lowered in k.lower() or k.lower() in lowered else 1,
            len(k),
        ),
    )
    return scored[:limit]


def _common_prefix(a: str, b: str) -> str:
    n = 0
    for x, y in zip(a, b):
        if x != y:
            break
        n += 1
    return a[:n]


# ── report parsing ───────────────────────────────────────────────────────

class NodeReport:
    def __init__(self, text: str) -> None:
        self.scenarios: list[dict] = []
        self.frames: dict[str, list[tuple[str, str]]] = {}
        self.groundings: dict[str, list[tuple[str, str]]] = {}
        self.carla_groundings = 0
        self.carla_verdict = "none"
        self.result = "FAIL"
        self.binders = 0
        # Frames the formula must be able to look at before its bounded
        # operators can complete (`Core/Formula.lean::SFProp.frameSpan`).
        self.span = 0
        for line in text.splitlines():
            parts = line.rstrip("\n").split("\t")
            tag = parts[0].strip()
            if tag == "SCEN" and len(parts) >= 6:
                self.scenarios.append({
                    "name": parts[1],
                    "expected": parts[2] == "true",
                    "actual": parts[3] == "true",
                    "groundings": int(parts[4]) if parts[4].isdigit() else 0,
                    "status": parts[5],
                })
            elif tag == "FRAMES" and len(parts) >= 4:
                self.frames.setdefault(parts[1], []).append((parts[2], parts[3]))
            elif tag == "GROUND" and len(parts) >= 4:
                self.groundings.setdefault(parts[1], []).append((parts[2], parts[3]))
            elif tag == "CARLA" and len(parts) >= 3:
                self.carla_groundings = int(parts[1]) if parts[1].isdigit() else 0
                self.carla_verdict = parts[2]
            elif tag == "BINDERS" and len(parts) >= 2:
                self.binders = int(parts[1]) if parts[1].isdigit() else 0
            elif tag == "SPAN" and len(parts) >= 2:
                self.span = int(parts[1]) if parts[1].isdigit() else 0
            elif tag == "RESULT" and len(parts) >= 2:
                self.result = parts[1]

    @property
    def parsed(self) -> bool:
        return bool(self.scenarios) or self.result == "OK"

    def explain(self, name: str) -> str:
        """Per-grounding, per-frame detail for one scenario."""
        lines = []
        for binding, verdict in self.groundings.get(name, []):
            lines.append(f"    grounding {binding}: satisfied={verdict}")
        for binding, bits in self.frames.get(name, []):
            lines.append(f"    frames    {binding}: {bits}   (position 0 leftmost, 1 = holds)")
        return "\n".join(lines) if lines else "    (no groundings — see SCENARIO_VACUOUS)"


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate one formalized rule.")
    ap.add_argument("--node-id", required=True)
    ap.add_argument("--task-dir", required=True)
    ap.add_argument("--library-root", required=True)
    ap.add_argument("--skip-build", action="store_true",
                    help="Skip lake build. For harness debugging only.")
    args = ap.parse_args()

    task_dir = Path(args.task_dir).resolve()
    library_root = Path(args.library_root).resolve()
    spec_file = task_dir / "node_spec.json"
    progress_file = task_dir / "progress.jsonl"
    verdict_file = task_dir / "verdict.json"

    if not spec_file.exists():
        emit("MISSING_FILE", f"Node spec not found: {spec_file}",
             "The harness prepares this file; re-run the task rather than creating it.")
        return 0

    spec = json.loads(spec_file.read_text(encoding="utf-8"))
    target_rel = spec["target_file"]
    target = library_root / target_rel
    module = spec["module"]
    namespace = spec["namespace"]
    declared = spec.get("scenarios", [])

    # Provenance of this gate call. The harness re-checks these after the session
    # and rejects a node whose `OK` was measured against anything other than the
    # library and baseline the harness itself set up — see
    # `scripts/phases/code.py`. Recording them is what makes that possible.
    baseline_path = task_dir / "baseline.json"
    provenance = {
        "library_root": str(library_root),
        "baseline_sha": sha(baseline_path) if baseline_path.exists() else None,
        "skip_build": bool(args.skip_build),
    }

    def finish(verdict: str, detail: str, extra: Optional[dict] = None) -> int:
        attempts = record(progress_file, verdict, detail, provenance)
        payload = {
            "node_id": args.node_id,
            "verdict": verdict,
            "attempts": attempts,
            "detail": detail[:4000],
            "timestamp": datetime.now().isoformat(),
        }
        payload.update(provenance)
        payload.update(extra or {})
        verdict_file.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        return 0

    # ── 1. target exists ────────────────────────────────────────────────
    if not target.exists():
        emit("MISSING_FILE",
             f"Expected rule file does not exist: {target}",
             f"Create it with namespace `{namespace}` and declarations: "
             f"{', '.join(REQUIRED_DECLS)}.")
        return finish("MISSING_FILE", f"missing {target_rel}")

    source = target.read_text(encoding="utf-8")
    # All pattern checks run on the comment-stripped form; prose in doc comments
    # must never trip a hygiene or vocabulary rule.
    code = strip_lean_comments(source)

    # ── 2. scope ────────────────────────────────────────────────────────
    baseline_file = task_dir / "baseline.json"
    if baseline_file.exists():
        baseline = json.loads(baseline_file.read_text(encoding="utf-8"))
        touched = scope_diff(baseline, library_manifest(library_root), target_rel)
        if touched:
            emit("SCOPE_VIOLATION",
                 f"Only `{target_rel}` may be modified by this task. Also changed:",
                 *[f"  {t}" for t in touched],
                 "",
                 "Revert *your own* edits to those files. If the rule genuinely "
                 "needs a new shared predicate in Core/Vocab.lean, stop and report "
                 "it as `missing_vocab` — the plan agent adds it as a separate node.",
                 "",
                 "If a listed file is another node's rule and you did not touch it, "
                 "say so in node_report.json and stop. Do NOT delete it, do not "
                 "rewrite baseline.json, and do not re-run this gate against a copy "
                 "of the library: the harness re-checks scope after your session "
                 "using its own baseline, so working around this verdict cannot "
                 "make the node pass and will be recorded as GATE_BYPASS.")
            return finish("SCOPE_VIOLATION", "; ".join(touched))

    # ── 3. structure ────────────────────────────────────────────────────
    problems: list[str] = []
    if f"namespace {namespace}" not in code:
        problems.append(f"missing `namespace {namespace}`")
    if "import TrafficSpec.Core" not in code:
        problems.append("missing `import TrafficSpec.Core`")
    defined = set(DEF_RE.findall(code))
    for decl in REQUIRED_DECLS:
        if decl not in defined:
            problems.append(f"missing `def {decl}`")
    if problems:
        emit("STRUCTURE_FAIL",
             "The rule file does not match the required shape:",
             *[f"  - {p}" for p in problems],
             "",
             "Every rule file declares exactly: `def schema : PropertySchema`, "
             "`def entry : RuleEntry`, `def scenarios : List Scenario`, inside "
             f"`namespace {namespace}`.")
        return finish("STRUCTURE_FAIL", "; ".join(problems))

    # ── 4. vocabulary ───────────────────────────────────────────────────
    adhoc = [msg for pat, msg in ADHOC_PATTERNS if pat.search(code)]
    if adhoc:
        emit("VOCAB_VIOLATION",
             "A rule file may not define its own scene predicates. Found:",
             *[f"  - {m}" for m in adhoc],
             "",
             "Compose the rule from `TrafficSpec.Pred.*`. If the predicate you "
             "need does not exist, stop and report it as `missing_vocab`.")
        return finish("VOCAB_VIOLATION", "; ".join(adhoc))

    known = vocab_names(library_root)
    used = set(PRED_USE_RE.findall(code))
    unknown = sorted(used - known)
    if unknown and known:
        lines = []
        for name in unknown:
            lines.append(f"  - `Pred.{name}` does not exist. Closest: "
                         + ", ".join(f"`{s}`" for s in suggest(name, known)))
        emit("VOCAB_VIOLATION",
             "Unknown predicates:", *lines,
             "",
             "Read library/TrafficSpec/Core/Vocab.lean for the full vocabulary.")
        return finish("VOCAB_VIOLATION", "unknown: " + ", ".join(unknown))

    # ── 5. CARLA compatibility ──────────────────────────────────────────
    try:
        schema = load_schema(REPO_ROOT)
    except FileNotFoundError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    allowed_attrs = set(schema["attribute_keys"]["tier_a"])

    # Present-but-unlifted keys, declared per group in the schema. The verdict
    # message must separate these from genuinely unknown attributes: an unlifted
    # key means the law is formalizable once the adapter and vocabulary are
    # extended, and telling the agent "does not exist" instead pushes it toward
    # `unsupported` — discarding a formalizable law, which is the expensive
    # direction. The schema used to carry a flat list of absent CONCEPTS for this
    # message; that list could only be written by guessing which laws would want
    # them, so it is gone and the distinction below is derived instead.
    unlifted: dict[str, str] = {}
    for group, body in (schema.get("available_not_exposed") or {}).items():
        if group.startswith("$") or not isinstance(body, dict):
            continue
        for key in (body.get("keys") or []):
            unlifted[key] = group

    bad_attrs = sorted({k for k in ATTR_CALL_RE.findall(code) if k not in allowed_attrs})
    if bad_attrs:
        hints, blocked, absent = [], [], []
        for key in bad_attrs:
            if key in unlifted:
                blocked.append(key)
                hints.append(f"  - attribute `{key}` IS in the scene graph but "
                             f"carla/adapter.py does not lift it "
                             f"(available_not_exposed.{unlifted[key]})")
            else:
                absent.append(key)
                hints.append(f"  - attribute `{key}` is not in the generator's "
                             f"attribute surface at all")
        guidance = []
        if blocked:
            guidance += [
                "",
                f"{', '.join(blocked)}: this is a VOCABULARY GAP, not missing "
                f"data. Do NOT record the law as unsupported. Report a blocker "
                f"asking for the adapter and Core/Vocab.lean to lift the key, "
                f"naming it.",
            ]
        if absent:
            guidance += [
                "",
                f"{', '.join(absent)}: check the schema's `deciding_unsupported` "
                f"steps before concluding it is absent — the concept may be "
                f"computable from keys that ARE lifted. If it truly is not, "
                f"report it as a blocker naming what you looked for. Do not "
                f"approximate it with a different attribute.",
            ]
        emit("CARLA_INCOMPATIBLE",
             "This specification reads scene-graph data it cannot read, so it "
             "could never fire on real traces:",
             *hints,
             "",
             f"Available attribute keys: {', '.join(sorted(allowed_attrs))}.",
             *guidance)
        return finish("CARLA_INCOMPATIBLE", "attrs: " + ", ".join(bad_attrs))

    # No "attribute absent from the sample trace" warning here any more. It read
    # `attribute_keys.tier_b`, a hand-maintained list of what
    # `Carla/Sample.lean` contains — and that file is hand-authored, so the list
    # described our own fixture rather than anything CARLA produces, and had
    # already drifted (it claimed `light_brake`, which Sample.lean never sets).
    # The same question is answered further down, computed rather than declared,
    # by the CARLA grounding count against that trace.
    warnings: list[str] = []

    # ── 6. hygiene ──────────────────────────────────────────────────────
    found = [msg for pat, msg in HYGIENE_PATTERNS if pat.search(code)]
    if found:
        emit("HYGIENE_FAIL",
             "The rule file contains constructs that are not allowed:",
             *[f"  - {m}" for m in found])
        return finish("HYGIENE_FAIL", "; ".join(found))

    # ── 6b. grounding budget ────────────────────────────────────────────
    # Before the build, because this is the cheapest check that can save the
    # most work — and because the failure it prevents is invisible later: the
    # scenario traces are small enough that an over-quantified rule passes the
    # gate in milliseconds and then cannot be evaluated on a capture at all.
    census = CAPTURE_ENTITY_CENSUS
    if census:
        estimate, detail = predicted_groundings(code, census)
        if estimate > GROUNDING_BUDGET:
            emit("GROUNDING_BUDGET",
                 f"This schema would instantiate about {estimate:,} times on a "
                 f"real capture, against a budget of {GROUNDING_BUDGET:,}.",
                 "",
                 "Binder cross product, using the measured entity census in "
                 "carla/schema.json:",
                 *[f"  - {d}" for d in detail],
                 "",
                 "Every binder MULTIPLIES the grounding count, and each grounding "
                 "is a full evaluation over the whole trace (~20 ms for 240 "
                 "frames). A binder over a structural type — `lane`, `road` — "
                 "multiplies by tens, and almost all of the resulting pairs are "
                 "unrelated: lanes on different roads with no edge between them. "
                 "Those make the antecedent false, so they are vacuously "
                 "satisfied and change no verdict — they only cost time.",
                 "",
                 "Express the relation with a predicate that quantifies "
                 "internally instead of binding the entities: `inRightmostLane`, "
                 "`hasLaneToTheRight`, `inLane` with `laneTravelsTo`, "
                 "`opposingLanes`, `governs`. One scan per frame, no extra "
                 "binder. If the relation you need has no such predicate, that is "
                 "a vocabulary gap: stop, and report it as a blocker naming the "
                 "predicate you want — do not bind two structural entities to "
                 "work around it.")
            return finish("GROUNDING_BUDGET",
                          f"~{estimate} groundings > {GROUNDING_BUDGET}")

    # ── 7. compile ──────────────────────────────────────────────────────
    try:
        if not args.skip_build:
            ok, output = lake_build(library_root, module)
            if not ok:
                digest = first_errors(output)
                emit("COMPILE_FAIL",
                     f"`lake build {module}` failed:", "", digest)
                return finish("COMPILE_FAIL", digest)

        # ── 8. scenarios ────────────────────────────────────────────────
        harness = task_dir / "harness.lean"
        write_node_harness(harness, module, namespace)
        ok, output = eval_harness(library_root, harness)
    except LeanUnavailable as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    report = NodeReport(output)
    if not report.parsed:
        digest = first_errors(output)
        emit("COMPILE_FAIL",
             "The scenario harness produced no report. Lean output:", "", digest)
        return finish("COMPILE_FAIL", digest)

    declared_names = {s["name"] for s in declared}
    reported_names = {s["name"] for s in report.scenarios}
    missing = sorted(declared_names - reported_names)
    if missing:
        emit("STRUCTURE_FAIL",
             "The plan declares scenarios that `def scenarios` does not contain:",
             *[f"  - {m}" for m in missing],
             "",
             "Every scenario named in node_spec.json must appear, with the "
             "planned `expected` value.")
        return finish("STRUCTURE_FAIL", "missing scenarios: " + ", ".join(missing))

    short = [s for s in report.scenarios if s["status"] == "SHORT"]
    if short:
        emit("TRACE_TOO_SHORT",
             f"This rule's formula needs {report.span} frames before its bounded "
             f"operators can complete, and these scenario traces are shorter:",
             *[f"  - `{s['name']}`" for s in short],
             "",
             "A trace shorter than that cannot test the rule in either "
             "direction. `Core/Semantics.lean::loopBounded` reads a window that "
             "runs off the end of the trace as false, so a formula shaped "
             "`□ (¬ₛ .bounded n bad)` is satisfied on every short trace no "
             "matter what it contains — a positive scenario then passes for the "
             "wrong reason, and a negative one cannot fail at all.",
             "",
             f"Lengthen every scenario trace to at least {report.span} frames. "
             "Padding with repeats of a representative frame is fine; the point "
             "is that the window has room to complete.")
        return finish("TRACE_TOO_SHORT",
                      f"traces shorter than the {report.span}-frame span: "
                      + ", ".join(s["name"] for s in short))

    vacuous = [s for s in report.scenarios if s["status"] == "VACUOUS"]
    if vacuous:
        lines = []
        for s in vacuous:
            lines.append(f"  - `{s['name']}` grounds to 0 bindings")
        emit("SCENARIO_VACUOUS",
             "These scenarios instantiate the rule zero times, so they are "
             "vacuously satisfied and test nothing:",
             *lines,
             "",
             f"The schema has {report.binders} binder(s). A scenario trace must "
             "contain distinct entities of the right types for every binder — "
             "e.g. two separate vehicles for a two-vehicle rule. Add them with "
             "`mkEgo` / `mkActor` and re-check.")
        return finish("SCENARIO_VACUOUS",
                      "vacuous: " + ", ".join(s["name"] for s in vacuous))

    failed = [s for s in report.scenarios if s["status"] == "FAIL"]
    if failed:
        blocks = []
        for s in failed:
            blocks.append(
                f"  - `{s['name']}`: expected {str(s['expected']).lower()}, "
                f"got {str(s['actual']).lower()} "
                f"({s['groundings']} grounding(s))\n{report.explain(s['name'])}"
            )
        emit("SCENARIO_FAIL",
             "The specification disagrees with its acceptance tests:",
             *blocks,
             "",
             "The frame bitmap shows at which positions the grounded formula "
             "holds. Read it before editing: a rule that is false everywhere is "
             "usually an inverted relation argument order, and one that is true "
             "everywhere usually has an antecedent that never fires.")
        return finish("SCENARIO_FAIL",
                      "failed: " + ", ".join(s["name"] for s in failed))

    # ── 9. accepted ─────────────────────────────────────────────────────
    if report.carla_groundings == 0:
        warnings.append(
            "the rule does not ground on the bundled CARLA sample trace "
            "(0 bindings), so it has no smoke coverage against realistic data — "
            "expected if the rule concerns entity types the sample lacks "
            "(pedestrians, stop signs), suspicious otherwise")

    passed = sum(1 for s in report.scenarios if s["status"] == "PASS")
    emit("OK",
         f"{passed}/{len(report.scenarios)} scenarios pass. "
         f"CARLA sample groundings: {report.carla_groundings}.")
    for w in warnings:
        print(f"WARNING: {w}")
    print("")
    print("Now write node_report.json (see the prompt) and stop.")

    return finish("OK", f"{passed}/{len(report.scenarios)} scenarios", {
        "scenarios_declared": len(report.scenarios),
        "scenarios_passed": passed,
        "carla_groundings": report.carla_groundings,
        "warnings": warnings,
    })


if __name__ == "__main__":
    raise SystemExit(main())
