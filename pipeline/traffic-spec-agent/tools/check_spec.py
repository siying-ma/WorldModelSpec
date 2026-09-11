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

# The rule file. `scenarios` is deliberately NOT here: the witnesses live in
# their own file under `TrafficSpecWitness/`, because a witness is evidence
# about a rule rather than part of it, and nothing that runs the library in an
# application reads one.
REQUIRED_DECLS = ["schema", "entry"]
WITNESS_DECLS = ["scenarios"]

# Binder helper name -> the census key in carla/schema.json whose count it ranges
# over. `Core/Grounding.lean` is the authority for what each helper admits.
BINDER_CENSUS_KEY = {
    "vehicleBinder": "vehicle",
    "proximityVehicleBinder": "proximityVehicle",
    "proximityRoadUserBinder": "roadUser",
    "roadUserBinder": "roadUser",
    # The `proximate*` binders drop, per trace, every candidate that never
    # shares a distance edge with the ego, so their true count is a subset of
    # the unrestricted binder's. They are sized here from the SAME census key
    # on purpose: the estimate exists to REFUSE an expensive schema, and a
    # restriction whose effect depends on the capture cannot be relied on to
    # bring one under budget. Over-counting costs a false refusal the author
    # can argue with; under-counting admits a schema that then cannot be
    # evaluated at all.
    "proximateRoadUserBinder": "roadUser",
    "proximateVehicleBinder": "proximityVehicle",
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
# the whole trace, and the cost grows with frames^2. 500 therefore
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
# capture that is no longer in the tree, on one CARLA map among many: a busier
# map or a longer capture changes every number here, and the original is not
# reproducible. They are kept as a deliberately conservative order of
# magnitude; re-derive them before tightening the budget rather than trusting
# the digits. The schema must stay true for
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

# Cost of one grounding: a full `satisfies` over the whole trace, growing with
# frames^2 because `Trace` is a `List Scene`. The ceiling is an order of
# magnitude, not a tuned figure.
GROUNDING_BUDGET = 500

# Where a schema stops being cheap and starts needing a reason.
#
# The hard budget is a FAILURE DETECTOR: at 500 the rule is about to become
# unevaluable, and nothing under it is thereby endorsed. Read as a quota it
# invites the opposite of what it is for — one run planned a rule at 480 of 500
# and recorded "all under 500" as if that were the goal, when the 480 came from
# binding a landmark that a predicate could have quantified internally.
#
# This second number is what a rule that binds only the actors its clause is
# about actually costs. Two actors is 64 on the census below; the measured
# runtime model (`lean_seconds ~ 7.86e-5 * frames * groundings`) puts a whole
# library of two dozen rules on a 3,000-frame capture inside ten minutes only if
# the AVERAGE rule is near 100. So: over this, the gate does not refuse, it asks
# for the reason in writing.
GROUNDING_SOFT_CEILING = 100

# Census keys that count ACTORS — the entities a clause is actually about. A
# binder over one of these is the clause's own cost and cannot be argued away;
# everything else (a sign, a landmark, a lane, a road, a junction) is usually a
# relation reached by binding, which a predicate could quantify internally.
# Used only to decide which binder the soft-ceiling warning points at.
ACTOR_CENSUS_KEYS = frozenset({
    "vehicle", "proximityVehicle", "roadUser", "pedestrian",
    "truck", "bus", "bicycle",
})

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
        # The witness file belongs to this node too — two files, one node.
        touched = [x for x in touched if x != spec.get("witness_file")]
        if touched:
            emit("SCOPE_VIOLATION",
                 f"Only `{target_rel}` and its witness file may be modified by "
             f"this task. Also changed:",
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

    witness_rel = spec.get("witness_file")
    witness_ns = spec.get("witness_namespace")
    witness = (library_root / witness_rel) if witness_rel else None
    if witness is not None:
        if not witness.exists():
            problems.append(f"missing witness file `{witness_rel}`")
        else:
            wtext = strip_lean_comments(witness.read_text(encoding="utf-8"))
            if f"namespace {witness_ns}" not in wtext:
                problems.append(f"witness file: missing `namespace {witness_ns}`")
            for decl in WITNESS_DECLS:
                if decl not in set(DEF_RE.findall(wtext)):
                    problems.append(f"witness file: missing `def {decl}`")
    if problems:
        emit("STRUCTURE_FAIL",
             "The rule file does not match the required shape:",
             *[f"  - {p}" for p in problems],
             "",
             f"The rule file declares `def schema : PropertySchema` and "
             f"`def entry : RuleEntry` inside `namespace {namespace}`. The "
             f"witness file declares `def scenarios : List Scenario` inside "
             f"`namespace {witness_ns}`.")
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

    # Derived from carla/adapter.py's mapping tables and Core/Builders.lean,
    # the two things that actually put an attribute on an entity. The schema
    # used to declare the same 53 keys as a list; a second copy that is correct
    # today still has to be kept correct tomorrow.
    sys.path.insert(0, str(REPO_ROOT / "carla"))
    from adapter import lifted_attribute_keys          # noqa: E402
    allowed_attrs = lifted_attribute_keys(library_root)

    # Present-but-unlifted keys, declared per group in the schema. The verdict
    # message must separate these from genuinely unknown attributes: an unlifted
    # key means the law is formalizable once the adapter and vocabulary are
    # extended, and telling the agent "does not exist" instead pushes it toward
    # `unsupported` — discarding a formalizable law, which is the expensive
    # direction. The schema used to carry a flat list of absent CONCEPTS for this
    # message; that list could only be written by guessing which laws would want
    # them, so it is gone and the distinction below is derived instead.
    # Everything carla_sgg emits, minus what the adapter lifts. Derived for the
    # same reason: the schema used to list these keys per group, so a generator
    # change had to be mirrored by hand into a file that could not detect the
    # omission. The GROUPS stay in the schema, because the reason a key is not
    # lifted is prose that nothing can derive.
    # NOTE the two sides are named in different vocabularies: `allowed_attrs`
    # holds LEAN names, `surface()` holds GENERATOR names, and subtracting one
    # from the other silently reports every renamed key as unlifted.
    # `CONSUMED_ATTRS` is the adapter's own generator-side set, so it is the one
    # that subtracts correctly.
    from adapter import CONSUMED_ATTRS, generator_key_to_lean   # noqa: E402
    # The generator is a SIBLING repository and is not guaranteed to be checked
    # out beside this one — the gate runs on every edit of every coding session
    # and must not need it. So the unlifted side falls back to the schema's
    # reason-group patterns, which are in-repo, and only sharpens itself to the
    # exact key set when the generator happens to be readable. `run_spec doctor`
    # is where the two are held to each other; it may require the generator, the
    # gate may not.
    unlifted: dict[str, str] = {}
    try:
        sys.path.insert(0, str(REPO_ROOT / "scripts"))
        from diagnostics.sgg_surface import surface    # noqa: E402
        unlifted = {k: "available_not_exposed"
                    for k in set(surface()) - set(CONSUMED_ATTRS)}
    except Exception:                                  # noqa: BLE001
        for group, body in (schema.get("available_not_exposed") or {}).items():
            if group.startswith("$") or not isinstance(body, dict):
                continue
            for pattern in (body.get("matches") or []):
                unlifted[pattern] = group
    # A generator key that IS consumed reaches Lean under another name. Saying
    # "does not exist" to a rule that reached for the generator's spelling is
    # the answer that pushes a formalizable law toward `unsupported`.
    renamed = generator_key_to_lean(library_root)

    bad_attrs = sorted({k for k in ATTR_CALL_RE.findall(code) if k not in allowed_attrs})
    if bad_attrs:
        hints, blocked, absent = [], [], []
        def _unlifted_group(key: str) -> str | None:
            """The reason group for a key, whether `unlifted` holds exact keys
            (generator readable) or regex patterns (the fallback)."""
            if key in unlifted:
                return unlifted[key]
            for pattern, group in unlifted.items():
                if pattern.startswith("^") and re.search(pattern, key):
                    return group
            return None

        for key in bad_attrs:
            group = _unlifted_group(key)
            if key in renamed:
                hints.append(f"  - attribute `{key}` is the GENERATOR's name; in "
                             f"Lean it is "
                             f"{', '.join('`' + n + '`' for n in renamed[key])}")
            elif group is not None:
                blocked.append(key)
                hints.append(f"  - attribute `{key}` IS in the scene graph but "
                             f"carla/adapter.py does not lift it "
                             f"(available_not_exposed.{group})")
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
                f"{', '.join(absent)}: work down the *Deciding whether a law is "
                f"unsupported* steps in your prompt before concluding it is absent — the concept may be "
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
    # `attribute_keys.tier_b`, a hand-maintained list of what the bundled
    # fixture contained, so it described our own fixture rather than anything
    # CARLA produces, and had already drifted (it claimed `light_brake`, which
    # the fixture never set). The fixture itself is gone: it was built from
    # `Core/Builders.lean`, so a rule grounding on it showed only that its
    # binders bind against data written to make them bind. Whether a spec fires
    # correctly is asked of a recorded capture and its human labels, by
    # `scripts/diagnostics/capture_eval.py`, and not by this gate.
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
                 "is a full evaluation over the whole trace (cost grows with "
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
        if estimate > GROUNDING_SOFT_CEILING:
            # Name the binder worth ARGUING about, not merely the biggest
            # factor. A binder over an actor is what the clause is about and
            # cannot be removed; one over a sign, landmark or road-structure
            # type is usually standing in for a predicate that would quantify
            # it internally, which is the change that actually retires the
            # cost. Rank the structural ones first, then by size.
            def _rank(d: str) -> tuple:
                key = d.split("->", 1)[-1].split("=", 1)[0].strip()
                count = int(d.rsplit("=", 1)[-1].split()[0].rstrip(")"))
                return (key not in ACTOR_CENSUS_KEYS, count)
            worst = max(detail, key=_rank) if detail else ""
            warnings.append(
                f"this schema would instantiate about {estimate:,} times on a "
                f"real capture. That is under the {GROUNDING_BUDGET:,} the gate "
                f"refuses, but well over the ~{GROUNDING_SOFT_CEILING} a rule "
                f"costs when it binds only the actors its clause is about"
                + (f" — the largest contributor is {worst}" if worst else "")
                + ". Being under the budget is not a reason to stop: say in "
                f"your report why no cheaper binding expresses this clause. If "
                f"the expensive binder exists only to reach a relation, the "
                f"predicate that would quantify it internally is a "
                f"`missing_vocab` worth naming.")

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
        write_node_harness(harness, module, namespace,
                           spec["witness_module"], spec["witness_namespace"])
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
             "Both witnesses named in node_spec.json must appear in the "
             "witness file, with the planned `expected` value.")
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
             f"Wrap every short trace in `padTo {report.span}` "
             "(`Core/Builders.lean`), which repeats its last frame up to that "
             "length. How long a trace must be is a property of the formula, "
             "not of the situation the scenario depicts, so this is arithmetic "
             "rather than a change to what the scenario tests — do not alter "
             "the situation to reach the length.")
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
    # No "does it ground on a bundled fixture" warning any more. The fixture
    # carried one entity of every type, so every well-formed rule's binders
    # could always bind and the count never reached zero — measured across the
    # library, 0 of 19 rules. The question it was meant to ask is asked properly
    # by SCENARIO_VACUOUS, against the rule's own scenarios.

    passed = sum(1 for s in report.scenarios if s["status"] == "PASS")
    emit("OK",
         f"{passed}/{len(report.scenarios)} scenarios pass.")
    for w in warnings:
        print(f"WARNING: {w}")
    print("")
    print("Now write node_report.json (see the prompt) and stop.")

    return finish("OK", f"{passed}/{len(report.scenarios)} scenarios", {
        "scenarios_declared": len(report.scenarios),
        "scenarios_passed": passed,
        "warnings": warnings,
    })


if __name__ == "__main__":
    raise SystemExit(main())
