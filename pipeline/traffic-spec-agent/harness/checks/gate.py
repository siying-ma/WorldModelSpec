"""The gate: the only acceptance authority for a node, run by the harness itself."""
from __future__ import annotations
import functools
import hashlib
import json
import os
import re
import time
from contextlib import ExitStack, contextmanager, nullcontext
from typing import Callable
from dataclasses import dataclass, field
from pathlib import Path
from ..store import paths
from ..model import nodeid
from ..lean import lean, index_sync, relations
from ..model.blueprint import Node, SCENARIOS, normalize_verdict, NARROWING_KINDS, CONCEPT_NARROWING_KINDS
from ..model.reading import Reading

VERDICTS = ["SCOPE_VIOLATION", "BUILD_FAIL", "UNSOUND", "CHECK_FAIL", "UNANCHORED_VARIABLE", "DECLARATION_MISMATCH",
            "SCOPE_NARROWED", "UNEXPRESSED", "UNCLAIMED_ATOM", "UNUSED_CLAIM", "BARE_LITERAL", "WITNESS_FAIL", "VACUOUS",
            "PARAM_MISMATCH", "GATE_TIMEOUT", "OK"]
#: Roles whose span decides when a rule applies: a coder may not narrow one (the rule would apply
#: where the law does not), and a plan may not carry one as a residue.
SCOPE_ROLES = {"trigger", "subject", "condition", "exception"}
#: Roles a narrowing may be declared on: the duty and its standards, which the plan carries by an
#: element or an operationalization.
NARROWABLE_ROLES = {"obligation", "standard"}
#: Not a verdict on the node: the toolchain did not run or was stopped (a missing `lake`, a build or a
#: harness stopped before evaluation, a failure located outside the candidate, a resource failure the
#: isolated run did not reproduce). The loop holds the node without counting an attempt and stops
#: after the iteration.
INFRA = "INFRA"
#: A verdict on the candidate's evaluation, not on its mapping: its harness ran out of time while
#: evaluating its witnesses or its adequacy check, the rows printed before the deadline deciding no
#: other verdict, or a resource failure or a panic (`extras["panic"]`) recurred in isolation. It never accepts and never counts an attempt: the loop gates the saved candidate again
#: once at the same deadline (codes the record again if its context changed) and then holds it for the
#: operator, and holds it at once after a panic (a Core defect), with the candidate, the gate harness
#: and its output kept in the task directory.
GATE_TIMEOUT = "GATE_TIMEOUT"
#: Keywords and attributes that make a declaration something other than a closed, total value.
#: Scanned in the code only (`lean.code_only`): a law's words in a header comment or in the
#: `standard` string of an operationalization are not Lean.
FORBIDDEN_TOKENS = ["sorry", "admit", "axiom", "unsafe", "partial", "opaque", "implemented_by", "extern", "native_decide", "panic!",
                    "#eval", "run_cmd", "initialize", "elab"]
STANDARD_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
ALLOWED_RULE_IMPORTS = {"TrafficSpec.Core.Language.Rule"}
ALLOWED_WITNESS_IMPORTS_EXTRA = {"TrafficSpec.Core.Evidence.Builders"}
GENERATED = {"library/TrafficSpec/Index.lean", "library/TrafficSpecWitness.lean"}   # written by index_sync, never by a session
#: Names a formula reads that no node claims: the clock, which every window over time reads and
#: no source can fail to observe.
FREE_USES = {"kin_time"}



def narrowing_key(n: dict) -> tuple[str, str, str]:
    """A narrowing by its span, kind and words, whitespace aside: two declarations of one reading are one."""
    return (" ".join(str(n.get("span", "")).split()), str(n.get("kind", "reading")), " ".join(str(n.get("why", "")).split()))

def reads_of_used(used: set[str], accepted_concepts: dict[str, dict] | None) -> set[str]:
    """Lean names a body reads through the primitives and accepted concepts it uses: a claim among
    them is used, although no leaf of the body names it."""
    from ..lean import surface
    prim = surface.primitive_reads()
    out: set[str] = set()
    for n in used:
        if n.startswith("prim_"):
            out.update(prim.get(n, []))
        elif n.startswith("drv_") and accepted_concepts:
            for cid, rec in accepted_concepts.items():
                if cid.replace(".", "_") == n:
                    out.update(a.replace(".", "_") for a in rec.get("reads", []))
    return out
#: Directories the repository digest does not enter: version control, build outputs, caches, and
#: the per-iteration task directories (a running session writes its own stream there).
DIGEST_SKIP_DIRS = {".git", ".lake", "__pycache__", ".venv", "node_modules", ".mypy_cache", ".pytest_cache"}
#: Offline verification and archived scratch files are outside every coding session's jail.
DIGEST_SKIP_RESULTS_DIRS = {"_verify", "_discarded"}
#: Files the harness itself writes while sessions run, and operator logs: a run's ledgers and
#: records (saved after every transition, so a session coding beside another would otherwise see
#: them change), and any log or pid file. The jail denies a session these paths already.
DIGEST_SKIP_RUN_FILES = {"ledger.jsonl", "concept_ledger.jsonl", "node_ledger.jsonl", "accepted_nodes.jsonl", "accepted_concepts.jsonl",
                         "state.json", "mapping.json", "summary.json", "AUTO_NOTES.md",
                         "rulings.jsonl", "recheck_answers.jsonl", "usage.jsonl", "reading.json", "definition_resolution.json",
                         "aggregate_selection.jsonl", "aggregate_certificates.jsonl", "aggregate_input_manifest.json", "TO_USER.md",
                         "gaps_measured.jsonl", "candidate_journal.json"}
DIGEST_SKIP_SUFFIXES = (".log", ".pid", ".lock")


@dataclass
class Verdict:
    verdict: str
    details: list[str] = field(default_factory=list)
    extras: dict = field(default_factory=dict)    # what an OK carries back: residues the coder added

    def to_dict(self) -> dict:
        return {"verdict": self.verdict, "details": self.details, **({"extras": self.extras} if self.extras else {})}


def repo_digest(root: Path | None = None) -> dict[str, str]:
    """A digest of every file of the pipeline a session could touch, keyed by path relative to
    the pipeline root: the library, the harness, the prompts, the ontology, the corpus, the
    readings, the gap ledger, the run records. Build outputs, caches, version control and the
    per-iteration task directories are left out, and so are the harness's own files in the library
    (the owner's record and the inactive records, with their crash-safe writes' temporary files),
    by name: the owner rewrites them while sessions run, and no session may write them. The scope
    check compares two of these. Inside a candidate scope the root is the candidate's tree."""
    from ..store import owner
    root = (root or (_CANDIDATE.root if _CANDIDATE is not None else paths.REPO)).resolve()
    harness_own = {f"library/{n}" for n in owner.HARNESS_FILES}
    harness_tmp = tuple(f"library/.{n}.tmp-" for n in owner.HARNESS_FILES)
    out: dict[str, str] = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in DIGEST_SKIP_DIRS and not d.startswith("iter-"))
        if Path(dirpath) == root / "results":
            dirnames[:] = [d for d in dirnames if d not in DIGEST_SKIP_RESULTS_DIRS]
        for f in filenames:
            p = Path(dirpath) / f
            rel = p.relative_to(root).as_posix()
            if rel in GENERATED or p.is_symlink() or f.endswith(DIGEST_SKIP_SUFFIXES) or rel in harness_own or rel.startswith(harness_tmp):
                continue
            if rel.startswith("results/") and rel.count("/") == 2 and (f in DIGEST_SKIP_RUN_FILES or (f.startswith(".") and ".tmp-" in f)):
                continue                                   # a harness file, or the temporary file of its crash-safe write
            try:
                out[rel] = hashlib.sha256(p.read_bytes()).hexdigest()
            except OSError:
                continue
    return out


def lib_rel(rel: str) -> str:
    """A path under the library, as the repository digest keys it."""
    return "library/" + rel


def task_registry(work: Path) -> tuple[list[str] | None, list[str] | None]:
    """The ids a gate run from this task directory registers: the accepted ones and the task's
    own (`registry.json`, written by the code phase), or everything on disk when absent."""
    f = work / "registry.json"
    if not f.exists():
        return None, None
    d = json.loads(f.read_text(encoding="utf-8"))
    return d.get("nodes"), d.get("concepts")


def task_keep(work: Path) -> set[str]:
    """Inactive records a gate run from this task directory registers all the same (`registry.json`,
    `keep`): a fenced record checked again, and what it calls."""
    f = work / "registry.json"
    return set(json.loads(f.read_text(encoding="utf-8")).get("keep", [])) if f.exists() else set()


def task_concurrent(work: Path) -> set[str]:
    """Files other tasks running beside this one own, or the loop writes for them, which this task's
    scope check does not count."""
    f = work / "concurrent.json"
    return set(json.loads(f.read_text(encoding="utf-8"))) if f.exists() else set()


@dataclass(frozen=True)
class CandidateScope:
    """The scope of a gate run inside a candidate transaction: `root` is the candidate's tree (its
    library at `root/library`), `write_set` every file the transaction declared it writes, keyed as
    the repository digest keys them."""
    root: Path
    write_set: frozenset


_CANDIDATE: CandidateScope | None = None


@contextmanager
def candidate_scope(scope: CandidateScope):
    """Gate inside a candidate for the duration: the scope check digests the candidate's tree and
    tolerates its declared write set, and nothing else. Set by the harness's own process only (a
    session cannot), while no other gate runs in it."""
    global _CANDIDATE
    saved, _CANDIDATE = _CANDIDATE, scope
    try:
        yield
    finally:
        _CANDIDATE = saved


#: The temporary file a coding session's Edit or Write tool writes beside its target and renames over
#: it: `<target>.tmp.<pid>.<suffix>`, the pid in decimal and the suffix six random bytes in lowercase
#: hex. The name says which file is being written, not who writes it.
ATOMIC_WRITE_SIBLING = re.compile(r"(?P<target>.+)\.tmp\.[1-9][0-9]*\.[0-9a-f]{12}")


def _atomic_write_target(rel: str) -> str | None:
    """The file `rel` is the atomic-write temporary file of, when its name has exactly that form."""
    m = ATOMIC_WRITE_SIBLING.fullmatch(rel)
    return m["target"] if m else None


def scope_stray(baseline: dict[str, str], own: set[str], work: Path) -> list[str]:
    """The files of the pipeline changed since `baseline` that are neither the task's `own` nor
    tolerated by its task directory (`task_concurrent`). Inside a candidate (`candidate_scope`) the
    files are the candidate's tree and the only ones that may change are its declared write set (a
    record's own files among them only when declared); a gate there whose library is not the
    candidate's is out of scope as a whole. A changed file that is the atomic-write temporary file
    (`ATOMIC_WRITE_SIBLING`) of a tolerated file in the same directory is tolerated with it: a session
    beside this task may be writing that file at the moment of the digest. It tolerates no other file,
    and nothing is removed."""
    if _CANDIDATE is None:
        now = repo_digest()
        tolerated = own | task_concurrent(work)
    else:
        if paths.LIBRARY.resolve() != (_CANDIDATE.root / "library").resolve():
            return [f"the gate runs in the candidate scope of {_CANDIDATE.root}, but its library is {paths.LIBRARY}"]
        now = repo_digest(_CANDIDATE.root)
        tolerated = set(_CANDIDATE.write_set)
    changed = {p for p in (set(now) | set(baseline)) - GENERATED if now.get(p) != baseline.get(p)}
    return sorted(p for p in changed - tolerated if _atomic_write_target(p) not in tolerated)


_OCC_DEFS = '''-- Variable connectivity: each atom, derived-concept or measure occurrence groups the variables it
-- relates (a comparison does not); `?v` marks a quantifier variable, `$` a composition (its mapped
-- variables are anchored by the composed rule). A comparison with a literal zero ties nothing: a
-- measure compared with zero says that it is measured, not which entity it is measured of.
def argVars (as : List TrafficSpec.Arg) : List String := as.filterMap fun a => match a with | .var v => some v | _ => none
def isZeroLit : TrafficSpec.Term → Bool
  | .lit q _ => TrafficSpec.Q.isZero q
  | _ => false
mutual
partial def occT : TrafficSpec.Term → List (List String)
  | .measure _ as => [argVars as]
  | .quantity _ as ps => argVars as :: ps.flatMap occT
  | .distanceWhile s φ => [s] :: occF φ
  | .sinceRise φ => occF φ
  | .headingSince s g φ => [s] :: (occT g ++ occF φ)
  | .aggregate _ v φ t => ["?" ++ v] :: (occF φ ++ occT t)
  | .add a b | .sub a b | .mul a b | .div a b => occT a ++ occT b
  | .neg a | .abs a => occT a
  | .cond φ a b => occF φ ++ occT a ++ occT b
  | _ => []
partial def occF : TrafficSpec.Formula → List (List String)
  | .atom _ as ps => argVars as :: ps.flatMap occT
  | .same a b => [argVars [a, b]]
  | .cmp l _ r =>                        -- a comparison relates magnitudes, not entities: no tie
    if isZeroLit l || isZeroLit r then (occT l ++ occT r).flatMap (·.map fun v => [v]) else occT l ++ occT r
  | .derived _ as ps => argVars as :: ps.flatMap occT
  | .rule _ m | .ruleApplies _ m => [("$" :: m.map (·.2))]
  | .not φ | .always φ | .eventually φ => occF φ
  | .and φ ψ | .or φ ψ | .implies φ ψ | .until φ ψ | .since φ ψ => occF φ ++ occF ψ
  | .holdsFor _ d s φ | .within _ d s φ => [s] :: (occT d ++ occF φ)
  | .untilWithin _ d s φ ψ => [s] :: (occT d ++ occF φ ++ occF ψ)
  | .atLast _ d s ψ φ => [s] :: (occT d ++ occF ψ ++ occF φ)
  | .count e s _ _ => occF e ++ occF s
  | .rises φ => occF φ
  | .definedWhen p φ => occF p ++ occF φ
  | .existsRegion _ v φ | .forallRegion _ v φ | .existsDevice _ v φ | .forallDevice _ v φ
  | .existsUser v φ | .forallUser v φ => ["?" ++ v] :: occF φ
  | _ => []
end
'''


#: The two phases of a gate harness, one program: run with no argument it prints everything up to
#: and including the witnesses and ends with `DONE_WITNESSES`; run with `adequacy` it prints the
#: adequacy check (`ADEQ_SIZE` per rule it checks: its leaves and the witnesses expecting a decided
#: verdict; `TIME adequacy_start`, ms after `main` began; `ADEQ` rows; `TIME adequacy`) and ends
#: with `DONE`. The gate runs the second phase only when its checks of the first reject nothing.
#: Every `TIME`, `SCEN` and `ADEQ` row is flushed as it is printed, so a run stopped at the
#: deadline keeps the rows before it.
_PHASES = """  if !args.isEmpty && args != ["adequacy"] then throw (IO.userError s!"unknown phase {args}")
  let out ← IO.getStdout
  let tMain ← IO.monoMsNow"""
#: The line that ends each phase's output.
PHASE_END = {"witnesses": "DONE_WITNESSES", "adequacy": "DONE"}
#: The deadline of a gate's evaluation, in seconds: the witness phase's run has it whole, and the
#: adequacy phase's run what the witness phase left of it.
GATE_DEADLINE = 900.0


def _harness_source(node_id: str, reading_json_path: Path, registry: tuple[str, str]) -> str:
    """The node's gate harness; `registry` is its own registry (`index_sync.registry_source`), so the
    evaluation reads no generated file another gate may be rewriting."""
    rns, wns = nodeid.rule_namespace(node_id), nodeid.witness_namespace(node_id)
    imports, defs = registry
    return f'''{imports}import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.TraceLint
import {nodeid.rule_module(node_id)}
import {nodeid.witness_module(node_id)}
{defs}open TrafficSpec Lean
#print axioms {rns}.rule
#print axioms {wns}.scenarios
{_OCC_DEFS}
{relations.lean_defs()}
def main (args : List String) : IO Unit := do
{_PHASES}
  let r := {rns}.rule
  let scs := {wns}.scenarios
  let rules := (allRules.filter (·.id != r.id)) ++ [r]
  let text ← IO.FS.readFile {json.dumps(str(reading_json_path.resolve()))}
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; pure ({{}} : Reading)
  let scs' := scs.map fun sc => {{ sc with reading := ρ }}
  if args == ["adequacy"] then
    IO.println s!"ADEQ_SIZE\\t{{r.id}}\\t{{r.applicability.leafCount + r.obligation.leafCount}}\\t{{(scs'.filter (·.expected.tag != "unknown")).length}}"
    let tAdq ← IO.monoMsNow
    IO.println s!"TIME\\tadequacy_start\\t{{tAdq - tMain}}"
    out.flush
    for u in Adequacy.unexercised rules r scs' allConcepts do IO.println s!"ADEQ\\t{{u}}"; out.flush
    IO.println s!"TIME\\tadequacy\\t{{(← IO.monoMsNow) - tAdq}}"
    out.flush
    IO.println "DONE"
    return
  let decl := Json.mkObj [
    ("id", r.id), ("laws", Json.arr (r.laws.map Json.str).toArray),
    ("binders", Json.arr (r.binders.map fun b => Json.str b.name).toArray),
    ("assumptions", Json.arr (r.assumptions.map Json.str).toArray),
    ("intentions", Json.arr (r.intentions.map Json.str).toArray),
    ("operationalizations", Json.arr (r.operationalizations.map fun o => Json.mkObj [("standard", o.standard), ("concepts", Json.arr (o.concepts.map Json.str).toArray), ("params", Json.arr (o.params.map Json.str).toArray), ("surrogate", o.surrogate)]).toArray),
    ("residues", Json.arr (r.residues.map Json.str).toArray),
    ("narrowings", Json.arr (r.narrowings.map fun n => Json.mkObj [("span", n.span), ("why", n.why), ("kind", n.kind)]).toArray), ("surrogate", r.surrogate)]
  IO.println s!"DECL\\t{{decl.compress}}"
  IO.println s!"RULEJSON\\t{{(Rule.toJson r).compress}}"
  IO.println s!"RULEXJSON\\t{{(Rule.toJson (Concept.expandRule allConcepts r)).compress}}"
  out.flush
  IO.println s!"ATOMS\\t{{String.intercalate "," r.atoms}}"
  IO.println s!"COMPOSES\\t{{String.intercalate "," r.composes}}"
  IO.println s!"AGGREGATES\\t{{String.intercalate "\\t" (Concept.ruleAggregateIds allConcepts r)}}"
  for sc in scs do IO.println s!"MANIFEST\\t{{sc.name}}\\t{{String.intercalate "," sc.manifest.absentIds}}"
  for sc in scs do if !sc.boundary.isEmpty then IO.println s!"BOUNDARY\\t{{sc.name}}"
  let tOcc ← IO.monoMsNow
  for g in (r.binders.flatMap fun b => occF b.cls) ++ occF r.applicability ++ occF r.obligation do
    IO.println s!"OCC\\t{{String.intercalate "," g}}"
  for (q, u) in r.formulas.flatMap Formula.literals do IO.println s!"LITERAL\\t{{q.num}}/{{q.den}}\\t{{repr u}}"
  IO.println s!"TIME\\toccurrences\\t{{(← IO.monoMsNow) - tOcc}}"
  out.flush
  let tChk ← IO.monoMsNow
  let rulesX := rules.map (Concept.expandRule allConcepts)
  for e in Rule.check rulesX (Concept.expandRule allConcepts r) do IO.println s!"CHECK\\t{{e}}"
  for e in Concept.ruleCallDefects allConcepts r do IO.println s!"CHECK\\t{{e}}"
  for e in Rule.checkReading rules r ρ allConcepts do IO.println s!"READING\\t{{e}}"
  for e in DimCheck.rule (DimCheck.envOf ρ allConcepts) r do IO.println s!"DIM\\t{{e.tag}}\\t{{e.render}}"
  IO.println s!"TIME\\tchecks\\t{{(← IO.monoMsNow) - tChk}}"
  out.flush
  let tLint ← IO.monoMsNow
  for sc in scs do
    let τ := TraceLint.completeOccupancy sc.trace
    for e in TraceLint.checkTrace τ do IO.println s!"REF\\t{{sc.name}}\\t{{e}}"
    RelCheck.run sc.name τ
    if let some (a, b) := sc.window then
      if !(sc.trace.any fun s => decide (a ≤ s.t) && decide (s.t ≤ b)) then IO.println s!"NOWINDOW\\t{{sc.name}}"
  IO.println s!"TIME\\tlint\\t{{(← IO.monoMsNow) - tLint}}"
  out.flush
  let tWit ← IO.monoMsNow
  for sc in scs' do
    let tSc ← IO.monoMsNow
    match sc.run rules allConcepts with
    | .ok v => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.expected.tag}}\\t{{v.tag}}\\tok"
    | .error e => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.expected.tag}}\\t?\\t{{e}}"
    out.flush
    IO.println s!"TIME\\tscenario:{{sc.name}}\\t{{(← IO.monoMsNow) - tSc}}"
    out.flush
  IO.println s!"TIME\\twitnesses\\t{{(← IO.monoMsNow) - tWit}}"
  out.flush
  IO.println "DONE_WITNESSES"
'''


#: Signals that end a toolchain run for a reason the run itself may cause (memory, stack, a fault):
#: unresolved until reproduced in isolation.
RESOURCE_SIGNALS = {6: "SIGABRT", 7: "SIGBUS", 9: "SIGKILL", 11: "SIGSEGV"}
#: Signals that stop a run deliberately: never the candidate's.
STOP_SIGNALS = {1: "SIGHUP", 2: "SIGINT", 15: "SIGTERM"}
GENERATED_LIB = {"TrafficSpec/Index.lean", "TrafficSpecWitness.lean"}


def _record(work: Path, phase: str, code: int, out: str, seconds: float | None = None) -> dict:
    """One toolchain run of the gate, appended to the task's `toolchain.jsonl`: the phase, the exit
    code and signal, the origin of a stop (the gate's own deadline, the run's stop event, a stopping
    signal, a resource failure), any panic, the first lines it printed, and its wall time."""
    from ..store import owner
    sig = -code if code < 0 else None
    stop = ("deadline" if lean.timed_out(out) else "run_stop" if owner.STOP.is_set()
            else "stop_signal" if sig in STOP_SIGNALS else "resource" if sig in RESOURCE_SIGNALS or lean.STACK_OVERFLOW.search(out) else None)
    row = {"phase": phase, "exit": code, "signal": sig, "stop": stop, "panic": lean.panicked(out), "head": out.splitlines()[:3],
           "seconds": None if seconds is None else round(seconds, 3)}
    with open(work / "toolchain.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")
    return row


@contextmanager
def _timed(work: Path, phase: str, lock):
    """`lock` (the library lock, `lock`, or the evaluation lock, `evaluation_lock`), with a row of
    that phase appended to the task's `toolchain.jsonl` once it is released: how long it was waited
    for and how long it was held."""
    asked = time.monotonic()
    with lock:
        got = time.monotonic()
        try:
            yield
        finally:
            held = time.monotonic() - got
            with open(work / "toolchain.jsonl", "a", encoding="utf-8") as f:
                f.write(json.dumps({"phase": phase, "wait": round(got - asked, 3), "held": round(held, 3)}) + "\n")


def _located(out: str, own: set[str], namespaces: tuple[str, ...], generated: dict[str, Path]) -> tuple[list[str], list[str], list[str]]:
    """The located errors of a failed build or harness: (in the candidate's own files, on a line of a
    generated file that names the candidate — its interface —, elsewhere)."""
    lib = paths.LIBRARY.resolve()
    mine, iface, other = [], [], []
    for f, line, msg in lean.error_sites(out):
        rel = f
        while rel.startswith("./"):
            rel = rel[2:]
        if Path(rel).is_absolute() and Path(rel).is_relative_to(lib):
            rel = Path(rel).relative_to(lib).as_posix()
        where = f"{rel}:{line}: {msg}"
        if rel in own:
            mine.append(where); continue
        src = generated.get(rel) or generated.get(f)
        try:
            text = src.read_text(encoding="utf-8").splitlines()[line - 1] if src else ""
        except (OSError, IndexError):
            text = ""
        (iface if any(ns in text for ns in namespaces) else other).append(where)
    return mine, iface, other


def _toolchain(work: Path, targets: list[str], own: set[str], namespaces: tuple[str, ...], harness: Path,
               register: "Callable[[], None] | None" = None, phase: str = "witnesses",
               timeout: float = GATE_DEADLINE) -> "Verdict | tuple[str, str]":
    """Build the candidate and run one phase of its harness (`PHASE_END`): the witness phase after the
    build, the adequacy phase on the build the witness phase made, with `timeout` the deadline of the
    run. The build holds the library lock, after `register`
    has written the registries it builds; the harness run reads no generated file and holds the
    evaluation lock shared, so it runs beside other gates' evaluations and the reviews. Returns the
    (build, harness) outputs (the build's empty in the adequacy phase), or the verdict a failure is
    attributed to:
    - a located error in the candidate's files, or on a line of a generated file (the registry, the
      harness) that names the candidate's declarations, is the candidate's (`BUILD_FAIL`);
    - a located error elsewhere, a failure with no located error, the toolchain's absence, a deadline
      before evaluation, the run's stop or a stopping signal is `INFRA`, never the candidate's;
    - the harness's deadline during the evaluation of the candidate (in the adequacy phase, at any
      point) returns the output for the gate to classify;
    - a resource failure (a signal the gate did not send, a stack overflow) or a panic is reproduced
      once in isolation, holding the evaluation lock exclusive across the phase's build and run, so
      that no other evaluation's load is charged to the candidate: reproduced, it is the
      candidate's (`GATE_TIMEOUT`, a panic also in `extras`, a possible Core defect); not
      reproduced, the isolated run's outputs stand."""
    lib = paths.LIBRARY
    generated = {**{g: lib / g for g in GENERATED_LIB}, str(harness.resolve()): harness}
    first: dict | None = None
    witnesses = phase == "witnesses"
    for trial in (1, 2):
        with ExitStack() as alone:
            if trial == 2:
                alone.enter_context(_timed(work, "evaluation_lock", lean.evaluation_lock(lib, exclusive=True)))
            bcode, out = 0, ""
            if witnesses:
                with _timed(work, "lock", lean.library_lock(lib)):
                    if register is not None:
                        register()
                    try:
                        t0 = time.monotonic()
                        bcode, out = lean.lake_build(lib, targets)
                    except lean.LeanUnavailable as e:
                        return Verdict(INFRA, [str(e)])
                (work / "build.log").write_text(out, encoding="utf-8")
                b = _record(work, "build", bcode, out, time.monotonic() - t0)
            if bcode != 0:
                if b["stop"] in ("deadline", "run_stop", "stop_signal"):
                    return Verdict(INFRA, [f"the build was stopped ({b['stop']}) before evaluation"] + out.splitlines()[:1])
                if b["stop"] == "resource":
                    if trial == 1:
                        first = b; continue
                    return Verdict(GATE_TIMEOUT, [f"the build failed twice on a resource limit ({RESOURCE_SIGNALS.get(b['signal'], 'stack overflow')})"])
                mine, iface, other = _located(out, own, namespaces, generated)
                if mine or iface:
                    return Verdict("BUILD_FAIL", (mine + [f"the registry does not accept the candidate's declaration: {x}" for x in iface])[:8])
                return Verdict(INFRA, ["the build failed outside the candidate's files"] + (other or out.splitlines()[-3:])[:6])
            with (nullcontext() if trial == 2 else _timed(work, "evaluation_lock", lean.evaluation_lock(lib))):
                try:
                    t0 = time.monotonic()
                    hcode, hout = lean.lean_run(lib, harness, timeout=timeout, args=() if witnesses else (phase,))
                except lean.LeanUnavailable as e:
                    return Verdict(INFRA, [str(e)])
            h = _record(work, "harness" if witnesses else f"harness_{phase}", hcode, hout, time.monotonic() - t0)
        evaluated = bool(re.search(r"^[A-Z_]+\t", hout, re.M))
        if h["stop"] in ("run_stop", "stop_signal") or (h["stop"] == "deadline" and not evaluated and witnesses):
            return Verdict(INFRA, [f"the gate harness was stopped ({h['stop']}) before it evaluated the candidate"])
        if h["stop"] == "resource" or h["panic"]:
            if trial == 1:
                first = h; continue
            why = (f"the evaluation panicked twice (a possible Core defect): {h['panic'][0]}" if h["panic"]
                   else f"the evaluation failed twice on a resource limit ({RESOURCE_SIGNALS.get(h['signal'], 'stack overflow')})")
            _save_output(work, phase, hout)
            return Verdict(GATE_TIMEOUT, [why], extras={"panic": h["panic"]} if h["panic"] else {})
        if hcode != 0 and h["stop"] != "deadline":
            mine, iface, other = _located(hout, own, namespaces, generated)
            if mine or iface:
                return Verdict("BUILD_FAIL", (mine + [f"the gate harness does not accept the candidate's declaration: {x}" for x in iface])[:8])
            if not ended(hout, phase):
                return Verdict(INFRA, ["gate harness did not run"] + (other or hout.splitlines()[:3])[:6])
        if first is not None:
            print(f"[gate] the first run failed ({first['phase']}: {first['stop'] or first['panic']}); the isolated run did not reproduce it")
        return out, hout
    raise AssertionError("unreachable")


def ended(hout: str, phase: str) -> bool:
    """Whether a harness phase printed the line that ends it."""
    return PHASE_END[phase] in hout.splitlines()


def _save_output(work: Path, phase: str, hout: str) -> None:
    """The harness output kept in the task directory: the witness phase's, then the adequacy phase's."""
    with open(work / "gate_harness.out", "w" if phase == "witnesses" else "a", encoding="utf-8") as f:
        f.write(hout if hout.endswith("\n") or not hout else hout + "\n")


def _imports(text: str) -> set[str]:
    return set(re.findall(r"^import (\S+)", text, re.M))


def run_gate(node: Node, reading: Reading, baseline: dict[str, str], work: Path, budget_used: int, budget: int,
             accepted_concepts: dict[str, dict] | None = None, acquisition: str | None = None) -> Verdict:
    """The gate for one node. `work` is the node's task directory (harness file, reports);
    `accepted_concepts` the catalogue, whose recorded reads count a claim as used; `acquisition` the
    run's acquisition profile, whose parameter every `heading_since` step bound of the rule must be."""
    work.mkdir(parents=True, exist_ok=True)
    lib = paths.LIBRARY
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    rule_file, wit_file = lib / rule_rel, lib / wit_rel
    details: list[str] = []

    if budget_used >= budget:
        return Verdict("BUDGET_EXHAUSTED", [f"{budget} gate runs used"])
    bad_reading = reading_input_defects(reading)
    if bad_reading:
        return bad_reading

    # 1. scope: nothing in the pipeline changed but the node's two files (and the files the tasks
    # running beside it own or the loop writes for them); the registries carry the accepted nodes and this one
    stray = scope_stray(baseline, {lib_rel(rule_rel), lib_rel(wit_rel)}, work)
    if stray:
        return Verdict("SCOPE_VIOLATION", [f"changed outside the node's files: {stray[:8]}"] + ([f"… and {len(stray) - 8} more"] if len(stray) > 8 else []))
    if not rule_file.exists() or not wit_file.exists():
        return Verdict("SCOPE_VIOLATION", [f"missing {rule_rel if not rule_file.exists() else wit_rel}"])
    rtext, wtext = rule_file.read_text(encoding="utf-8"), wit_file.read_text(encoding="utf-8")
    bad_imports = (_imports(rtext) - ALLOWED_RULE_IMPORTS) | (_imports(wtext) - ALLOWED_WITNESS_IMPORTS_EXTRA - {nodeid.rule_module(node.id)})
    if bad_imports:
        return Verdict("SCOPE_VIOLATION", [f"imports not allowed: {sorted(bad_imports)}"])
    if f"namespace {nodeid.rule_namespace(node.id)}" not in rtext or f"namespace {nodeid.witness_namespace(node.id)}" not in wtext:
        return Verdict("SCOPE_VIOLATION", ["namespace must be derived from the node id"])

    # 2. build, under the library lock, so the registries this gate writes are the ones its build
    # sees; and 3. the harness run, over the harness's own registry, beside other evaluations
    only_nodes, only_concepts = task_registry(work)
    reg = dict(only_nodes=None if only_nodes is None else sorted(set(only_nodes) | {node.id}), only_concepts=only_concepts,
               keep=task_keep(work) | {node.id})
    # a forbidden construct is refused before anything is compiled: the compiler runs what a file elaborates
    bad = forbidden_tokens((("rule", rtext), ("witness", wtext)))
    if bad:
        return Verdict("UNSOUND", details + bad)
    harness = work / "gate_harness.lean"
    reading_json = work / "reading.json"
    reading_json.write_text(reading.lean_json(), encoding="utf-8")
    harness.write_text(_harness_source(node.id, reading_json, index_sync.registry_source(**reg)), encoding="utf-8")
    toolchain = functools.partial(_toolchain, work, ["TrafficSpec.Index", nodeid.rule_module(node.id), nodeid.witness_module(node.id)],
                                  {rule_rel, wit_rel}, (nodeid.rule_namespace(node.id) + ".", nodeid.witness_namespace(node.id) + "."), harness)
    ran = toolchain(register=lambda: index_sync.write_index(**reg))
    if isinstance(ran, Verdict):
        return ran
    out, hout = ran
    if lean.sorry_warnings(out):
        details.append("build reports a declaration that uses sorry")
    _save_output(work, "witnesses", hout)
    decode = [l.split("\t", 1)[1] for l in hout.splitlines() if l.startswith("READING_DECODE\t")]
    if decode:
        return Verdict(INFRA, ["the reading does not decode (an input error, not the candidate's): " + decode[0]])
    for m in re.finditer(r"depends on axioms: \[([^\]]*)\]", hout):
        axioms = {a.strip() for a in m.group(1).split(",") if a.strip()}
        if axioms - STANDARD_AXIOMS:
            details.append(f"non-standard axioms: {sorted(axioms - STANDARD_AXIOMS)}")
    if details:
        return Verdict("UNSOUND", details)
    # the witness phase's rows; after its deadline, only what they already decide (`Cut`)
    cut = Cut(hout)
    if not cut.stopped and not ended(hout, "witnesses"):
        return harness_failure(hout)
    rows = cut.rows
    def col(tag: str) -> list[list[str]]:
        return [r[1:] for r in rows if r[0] == tag]

    # 4. static check
    checks = [r[0] for r in col("CHECK")] + [r[0] for r in col("READING")] + [f"units: {r[1]}" for r in col("DIM")]
    checks += deep_checks(lambda: (divisions_by_measure(json.loads(col("RULEJSON")[0][0])) if col("RULEJSON") else [])
                          + (slot_range_defects(json.loads(col("RULEJSON")[0][0]), reading, accepted_concepts) if col("RULEJSON") else [])
                          + (rule_step_defects(node.id, json.loads(col("RULEXJSON")[0][0]), acquisition, reading)
                             if col("RULEXJSON") else []))
    if checks:
        return Verdict("CHECK_FAIL", checks + cut.note())
    if cut.stopped and not cut.reached("checks"):
        return harness_failure(hout)

    # 4b. anchoring: every quantifier variable reaches a binder through shared arguments
    binders = [b["name"] for b in node.get("binders", [])]
    unanchored = unanchored_variables([row[0].split(",") if row and row[0] else [] for row in col("OCC")], binders)
    if unanchored:
        return Verdict("UNANCHORED_VARIABLE", [f"in the formula, the quantified variable `{v}` shares no atom with a binder, nor with a variable "
                                               "that does: the region, device or user it ranges over is any in the scene, not the subject's — "
                                               "tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a "
                                               "relation to a binder (the record's claims are already checked)" for v in unanchored])

    # 5. declarations
    decl = json.loads(col("DECL")[0][0])
    exp_binders = [b["name"] for b in node.get("binders", [])]
    from ..model.blueprint import concepts_of
    ws = lambda t: " ".join(str(t or "").split())          # prose: whitespace carries no meaning; ids compare exactly
    exp_ops = sorted((ws(o.get("standard", "")), tuple(sorted(concepts_of(o)))) for o in node.get("operationalizations", []))
    got_ops = sorted((ws(o.get("standard", "")), tuple(sorted(o.get("concepts", [])))) for o in decl["operationalizations"])
    mism = []
    if decl["id"] != node.id: mism.append(f"id {decl['id']} ≠ {node.id}")
    if sorted(decl["laws"]) != sorted(node["law_refs"]): mism.append(f"laws {decl['laws']} ≠ {node['law_refs']}")
    if decl["binders"] != exp_binders: mism.append(f"binders {decl['binders']} ≠ {exp_binders}")
    if sorted(decl["assumptions"]) != sorted(a.get("id") for a in node.get("assumptions", [])): mism.append("assumptions differ")
    if sorted(decl["intentions"]) != sorted({a.get("id") for a in node.get("intentions", [])}): mism.append("intentions differ")
    if got_ops != exp_ops: mism.append(f"operationalizations {got_ops} ≠ {exp_ops}")
    node_residues = [ws(r.get("why", "")) for r in node.get("residues", [])]
    decl_residues = [ws(w) for w in decl["residues"]]
    missing_res = [w for w in node_residues if w not in decl_residues]
    if missing_res: mism.append(f"residues of the node missing from the rule: {missing_res[:3]}")
    added_res = [w for w in decl_residues if w not in node_residues]
    if added_res: mism.append(f"residues added to the rule: {added_res[:3]}; a residue is the plan's — a reading you chose on a carried span is a narrowing ⟨span, why⟩")
    spans = node.spans()
    narrowings = [n for n in decl.get("narrowings", []) if isinstance(n, dict)]
    for n in narrowings:
        if n.get("span") not in spans: mism.append(f"narrowing on `{n.get('span')}`, which is no span of the node")
        elif not str(n.get("why", "")).strip(): mism.append(f"narrowing on {n.get('span')} states no why")
        elif spans[n["span"]].get("role") not in NARROWABLE_ROLES | SCOPE_ROLES:
            mism.append(f"narrowing on {n['span']} ({spans[n['span']].get('role')}), a span this node does not carry")
        elif n.get("kind", "reading") not in NARROWING_KINDS:
            mism.append(f"narrowing on {n['span']} has kind {n.get('kind')!r}; one of {sorted(NARROWING_KINDS)}")
    exp_surrogate = any(o.get("surrogate") for o in node.get("operationalizations", []))
    if bool(decl["surrogate"]) != exp_surrogate: mism.append(f"surrogate {decl['surrogate']} ≠ {exp_surrogate}")
    if mism:
        return Verdict("DECLARATION_MISMATCH", mism)
    # the record's own narrowings are the plan's: what is left is what the coder added
    on_record = {narrowing_key(x) for x in node.get("narrowings", []) if isinstance(x, dict)}
    narrowings = [n for n in narrowings if narrowing_key(n) not in on_record]
    # an observable reading the plan declared on a span is the plan's own reading of it, not a narrowing of its scope
    planned_obs = {n.get("span") for n in node.get("narrowings", []) if isinstance(n, dict) and n.get("kind") == "observable_reading"}
    narrowed_scope = [f"narrowing on {n['span']} ({spans[n['span']].get('role')}): {str(n.get('why', ''))[:160]}" for n in narrowings
                      if n.get("span") in spans and spans[n["span"]].get("role") in SCOPE_ROLES
                      and not (n.get("kind") == "observable_reading" and n.get("span") in planned_obs)]
    if narrowed_scope:
        return Verdict("SCOPE_NARROWED", narrowed_scope + ["a span that decides when the rule applies is carried as the node maps it, or the node is wrong: report it in the result note"])
    unexpressed = [n for n in narrowings if n.get("kind") in ("no_atom", "no_operator")]
    if unexpressed:
        return Verdict("UNEXPRESSED", [f"{n['span']} ({n['kind']}): {str(n.get('why', ''))[:200]}" for n in unexpressed]
                       + ["the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it"],
                       extras={"unexpressed": unexpressed})

    # 6. claims and literals
    used = {a for a in col("ATOMS")[0][0].split(",") if a}
    claimed = node.claimed_names()
    canon = owner_name
    unclaimed = sorted({n for n in used if canon(n) not in claimed and n not in FREE_USES})
    if unclaimed:
        return Verdict("UNCLAIMED_ATOM", unclaimed)
    used_via = {canon(n) for n in reads_of_used(used, accepted_concepts)}
    unused = sorted(c for c in claimed if not any(canon(n) == c for n in used) and c not in used_via)
    if unused:
        return Verdict("UNUSED_CLAIM", unused)
    # an aggregate the rule reads, through the concepts it calls too, is one its record claims, by id (`ru.aggregate=<id>`)
    agg_used = {a for row in col("AGGREGATES") for a in row if a}
    agg_claimed = {c.split("=", 1)[1] for c in node.claimed_atoms() if c.startswith("ru.aggregate=")}
    if agg_used - agg_claimed:
        return Verdict("UNCLAIMED_ATOM", [f"ru_aggregate \"{a}\" (the record claims {sorted(agg_claimed) or 'no aggregate'})" for a in sorted(agg_used - agg_claimed)])
    from fractions import Fraction
    from ..model import units
    used_lits = sorted((Fraction(q), u.split(".")[-1].strip()) for q, u in col("LITERAL"))
    declared = []
    for lit in node.literals():
        try:
            core, v = units.to_core(lit.get("value"), lit.get("unit", ""))
            declared.append((v, core))
        except (KeyError, ValueError):
            return Verdict("BARE_LITERAL", [f"declared literal {lit} has an unknown unit"])
    declared = sorted(set(declared))
    used_lits = sorted(set(used_lits))                # a figure counts once, however often a formula writes it
    if used_lits != declared:
        return Verdict("BARE_LITERAL", [f"formula literals {[(str(q), u) for q, u in used_lits]} ≠ the node's declared literals {[(str(q), u) for q, u in declared]}; a figure the law states is declared on its span, any other magnitude belongs in the reading"])
    mism = param_mismatches(json.loads(col("RULEJSON")[0][0]), accepted_concepts, node.literals())
    mism += occasion_window_defects(node, json.loads(col("RULEJSON")[0][0]), accepted_concepts)
    if mism:
        return Verdict("PARAM_MISMATCH", mism)

    # 7. witnesses
    scen = col("SCEN")
    planned = {s["name"]: s for s in node.get("scenarios", [])}
    fails = []
    masked = planned.get("blind", {}).get("masked", [])
    masked = set([masked] if isinstance(masked, str) else masked)
    for name, absent in col("MANIFEST"):
        if name == "blind" and set(a for a in absent.split(",") if a) != masked:
            fails.append(f"blind: the manifest masks {sorted(a for a in absent.split(',') if a)}, the node masks {sorted(masked)}")
    refs = {}
    for name, msg in col("REF"):
        refs.setdefault(name, []).append(msg)
    manifests = {r[0]: [a for a in r[1].split(",") if a] for r in col("MANIFEST") if len(r) > 1}
    for name, expected, got, status in scen:
        if name in refs:                  # a trace no adapter can write: its verdict is not considered
            fails.append(f"{name}: its trace is not one the adapter can produce: {'; '.join(refs[name][:3])}")
        elif status != "ok":
            fails.append(witness_failure(name, status, manifests.get(name) if expected == "unknown" else None))
        elif expected != got:
            fails.append(f"{name}: expected {expected}, got {got}")
        elif name in planned and expected != (SCENARIOS.get(name) or normalize_verdict(planned[name].get("expected", ""))):
            fails.append(f"{name}: the witness declares {expected}, the plan requires {SCENARIOS.get(name) or normalize_verdict(planned[name].get('expected', ''))}")
    for name in list(SCENARIOS) + [p for p in planned if p not in SCENARIOS]:   # every planned scenario is a test
        if name not in {s[0] for s in scen} and not cut.stopped:
            fails.append(f"{name}: no witness of that name")
    fails += boundary_defects({r[0] for r in col("BOUNDARY")}, {n for n, s in planned.items() if s.get("boundary")})
    fails += witness_trace_defects(col)
    if fails:
        return Verdict("WITNESS_FAIL", fails + cut.note())
    if cut.stopped:
        return harness_failure(hout)

    # 8. adequacy: the harness's second phase, run only now, within what the first left of the deadline
    adequacy = adequacy_phase(work, toolchain, hout)
    if isinstance(adequacy, Verdict):
        return adequacy
    adeq = [r[1] for r in (l.split("\t") for l in adequacy.splitlines()) if r[0] == "ADEQ" and len(r) > 1]
    if adeq:
        return Verdict("VACUOUS", adeq)
    return Verdict("OK", [f"{len(scen)} witnesses, {len(used)} names, composes {col('COMPOSES')[0][0] or 'nothing'}"]
                   + ([f"narrowings declared by the coder: {len(narrowings)}"] if narrowings else []),
                   extras={"rule_json": json.loads(col("RULEJSON")[0][0]),
                           **({"narrowings_added": narrowings} if narrowings else {})})


def owner_name(n: str) -> str:
    """The Lean name of the atom a name read in a formula belongs to: an accessor resolves to its
    owning atom (`dev_traffic_signal_shows` to `dev_traffic_signal`), the longest atom id of the
    active Core whose name it extends, so a claim never covers another atom that merely shares its
    prefix; a concept's or a primitive's name is itself."""
    from ..lean import surface
    if n.startswith(("drv_", "prim_")):
        return n
    a = surface.atom_id_of(n, _atom_ids())
    return a.replace(".", "_") if a else n


@functools.lru_cache(maxsize=1)
def _atom_ids() -> frozenset:
    from ..lean import surface
    return frozenset(surface.core_atom_ids())


def reading_input_defects(reading: Reading) -> Verdict | None:
    """A reading that cannot be read whole stops the gate before anything is judged: an input error,
    never the candidate's, and never evaluated as an empty reading."""
    from ..model.reading import reading_defects
    bad = reading_defects(reading.data)
    return Verdict(INFRA, ["the reading cannot be read whole (an input error, not the candidate's): " + "; ".join(bad[:6])]) if bad else None


def slot_range_defects(tree, reading: Reading, concepts: dict[str, dict] | None = None) -> list[str]:
    """The values a formula passes to a cosine slot (the tolerance of a relation Core reads as the
    cosine of an angle: the relations that take a parameter, `harness/lean/relations.py`) that lie
    outside [-1, 1]: a literal, a reading parameter, or a concept's formal through the reading
    parameter the call passes for it. A dimensionless value is not therefore a valid one."""
    from fractions import Fraction
    from ..model import units
    slots = {a for a, n, _k, _f in relations.computable() if n}
    by_lean = {cid.replace(".", "_"): rec for cid, rec in (concepts or {}).items()}
    out: list[str] = []

    def value(t, env):
        if isinstance(t, dict) and isinstance(t.get("lit"), dict):
            return Fraction(int(t["lit"]["num"]), int(t["lit"]["den"])), "a literal"
        if isinstance(t, dict) and "param" in t:
            if t["param"] in env:
                return env[t["param"]]
            prm = reading.params.get(t["param"])
            if prm is not None and prm.get("unit") in units.FACTORS:
                return units.to_core(prm["value"], prm["unit"])[1], f"`{t['param']}`"
        return None

    # an explicit stack, so no nesting hides a slot; `calls` are the concepts expanded on the way,
    # each entered once per path (accepted concepts are acyclic; this only keeps the walk finite)
    stack = [(tree, {}, ())]
    while stack:
        x, env, calls = stack.pop()
        if isinstance(x, dict):
            if x.get("atom") in slots:
                for t in x.get("params") or []:
                    v = value(t, env)
                    if v is not None and not (-1 <= v[0] <= 1):
                        out.append(f"`{x['atom']}` reads its tolerance as a cosine, between -1 and 1; {v[1]} gives {float(v[0]):g}")
            name = x.get("derived") or x.get("quantity")
            if isinstance(name, str) and name in by_lean and name not in calls:
                rec = by_lean[name]
                formals = [f.get("name") for f in rec.get("params", [])]
                inner = {f: v for f, t in zip(formals, x.get("params") or []) if (v := value(t, env)) is not None}
                stack.append((rec.get("body_json"), inner, calls + (name,)))
            stack.extend((v, env, calls) for v in x.values())
        elif isinstance(x, list):
            stack.extend((v, env, calls) for v in x)
    return sorted(set(out))


#: How `Scenario.run` states a verdict other than the expected one: the tag and its unknown reasons.
_GOT = re.compile(r"expected (\S+), got (\S+) \[(.*)\]")


def witness_failure(name: str, error: str, masked: list[str] | None = None) -> str:
    """A witness `Scenario.run` rejected, as the repair reads it: the witness's name once, the result
    the rule reached with its unknown reasons (none is listed for a decided verdict), and for a
    witness expecting unknown what its manifest masks (`masked`; None leaves it out)."""
    msg = error[len(name) + 2:] if error.startswith(f"{name}: ") else error
    m = _GOT.fullmatch(msg)
    if m:
        msg = f"expected {m[1]}, got {m[2]}" + (f" for [{m[3]}]" if m[3] else "")
    if masked is not None:
        msg += f"; the manifest masks {', '.join(masked) if masked else 'no atom'}"
    return f"{name}: {msg}"


def boundary_defects(declared: set[str], planned: set[str]) -> list[str]:
    """A history-boundary witness (one that may stay unknown for a window truncated at its trace's start)
    exactly where the plan declares one: the witness cannot widen what the plan let stay unknown."""
    return ([f"{n}: the witness declares a history boundary the plan does not" for n in sorted(declared - planned)]
            + [f"{n}: the plan declares a history boundary the witness does not" for n in sorted(planned - declared)])


def witness_trace_defects(col) -> list[str]:
    """What fails a witness's trace beyond its verdict: a measured relation it supplies that Core
    computes from the scene (`RELCHECK`: a hand-written trace supplies only what Core cannot compute),
    and a window holding no observation to judge (`NOWINDOW`)."""
    return ([f"{r[0]} at t={r[1]} ({r[2]}): {r[3]}" for r in col("RELCHECK")]
            + [f"{r[0]}: its window holds no observation of the trace, so it judges nothing" for r in col("NOWINDOW")])


def divisions_by_measure(tree) -> list[str]:
    """Each division whose divisor reads a measured quantity, in an exported rule or concept body.
    A measurement can be zero (a straight road's curvature, a halted vehicle's speed), and a
    division by zero is unknown, never a verdict: the comparison is written with products."""
    out: list[str] = []

    def measures(x) -> list[str]:
        if isinstance(x, dict):
            return ([x["measure"]] if isinstance(x.get("measure"), str) else []) + [m for v in x.values() for m in measures(v)]
        return [m for v in x for m in measures(v)] if isinstance(x, list) else []

    def walk(x) -> None:
        if isinstance(x, dict):
            d = x.get("div")
            if isinstance(d, list) and len(d) == 2 and measures(d[1]):
                out.append(f"a division by a term that reads {', '.join(f'`{m}`' for m in sorted(set(measures(d[1]))))}: a measured quantity "
                           "can be zero, and a division by zero is unknown, never a verdict — multiply instead (a bound on a ratio "
                           "is a bound on a product: a radius below a bound is a curvature above the bound's reciprocal)")
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(tree)
    return out


def forbidden_tokens(files) -> list[str]:
    """The forbidden keywords each file uses in code (comments and strings blanked)."""
    out = []
    for name, text in files:
        code = lean.code_only(text)
        for tok in FORBIDDEN_TOKENS:
            if re.search(r"(?<![A-Za-z_.])" + re.escape(tok) + r"(?![A-Za-z_])", code):
                out.append(f"{name} file contains `{tok}`")
    return out


class Cut:
    """A witness phase's output, whole or stopped at the deadline (`stopped`). Stopped, its rows decide
    only what more rows could not undo: a static check's row, a witness that did not pass, a trace
    defect; a check whose rows are incomplete (`reached`: the part's `TIME` row is printed) and a
    witness that did not run decide nothing, and a witness that did not run is never counted as
    passed. What they leave undecided is `GATE_TIMEOUT`."""

    def __init__(self, hout: str):
        self.stopped = lean.timed_out(hout)
        self.rows = [l.split("\t") for l in hout.splitlines() if "\t" in l]

    def reached(self, part: str) -> bool:
        return any(r[0] == "TIME" and len(r) > 1 and r[1] == part for r in self.rows)

    def note(self) -> list[str]:
        """What a verdict decided on a stopped phase's rows says about the stop."""
        if not self.stopped:
            return []
        missing = not_run(self.rows)
        return [f"the evaluation was stopped at its deadline; the rows printed before it decide this verdict"
                + (f"; not run, never counted as passed: {', '.join(missing)}" if missing else "")]


def not_run(rows: list[list[str]]) -> list[str]:
    """The witnesses a harness lists (a node's `MANIFEST`, a concept's `WITNESS` rows) with no `SCEN` row."""
    listed = [(r[1], r[2] if r[0] == "WITNESS" else "") for r in rows if r[0] in ("MANIFEST", "WITNESS") and len(r) > 2]
    ran = {(r[1], r[2] if len(r) > 5 else "") for r in rows if r[0] == "SCEN" and len(r) > 4}
    return [f"{n} ({rule})" if rule else n for n, rule in listed if (n, rule) not in ran]


def _harness_seconds(work: Path) -> float:
    """The wall time of the task's latest witness-phase run, as `toolchain.jsonl` records it."""
    f = work / "toolchain.jsonl"
    rows = [json.loads(l) for l in f.read_text(encoding="utf-8").splitlines() if l.strip()] if f.exists() else []
    return next((float(r.get("seconds") or 0.0) for r in reversed(rows) if r.get("phase") == "harness"), 0.0)


def adequacy_phase(work: Path, toolchain: Callable, hout: str) -> "Verdict | str":
    """The harness's adequacy phase, run once the witness phase's rows (`hout`) reject nothing, with
    what the witness phase left of `GATE_DEADLINE`: its output, or the verdict on its run (a
    deadline, when nothing or not enough was left, is `GATE_TIMEOUT`)."""
    spent = _harness_seconds(work)
    left = GATE_DEADLINE - spent
    took = f"the witness phase took {spent:.0f} s of the {GATE_DEADLINE:.0f} s deadline"
    if left <= 0:
        return Verdict(GATE_TIMEOUT, [f"{took}; none was left for the adequacy check"] + evaluation_progress(hout))
    ran = toolchain(phase="adequacy", timeout=left)
    if isinstance(ran, Verdict):
        return ran
    _out, aout = ran
    _save_output(work, "adequacy", aout)
    if ended(aout, "adequacy"):
        return aout
    if lean.timed_out(aout):
        first, *rest = aout.splitlines()
        return Verdict(GATE_TIMEOUT, [first, f"{took}; the adequacy phase had the {left:.0f} s left"]
                       + evaluation_progress("\n".join([hout] + rest)))
    return Verdict(INFRA, ["gate harness did not run (the adequacy phase)"] + aout.splitlines()[:3])


def _ms(v: str) -> int:
    try:
        return int(v)
    except ValueError:
        return 0


def evaluation_progress(hout: str) -> list[str]:
    """What a gate harness stopped at its deadline had printed: the part it was in (each part ends
    with its `TIME` row: the occurrences, for a node, the static checks, the trace lint, the
    witnesses, one row each and `TIME witnesses` after them, a concept's supersession check, then,
    in the adequacy phase, the adequacy check from `TIME adequacy_start` to `TIME adequacy`), the
    witnesses that passed, did not pass and did not run, with their time, and, stopped in the
    adequacy check, when it began and its input (`ADEQ_SIZE`: the leaves it mutates and the decided
    witnesses it re-runs). Only what the harness printed; no cause is inferred."""
    rows = [l.split("\t") for l in hout.splitlines() if "\t" in l]
    times = {r[1]: _ms(r[2]) for r in rows if r[0] == "TIME" and len(r) >= 3}
    scen = [r[1:] for r in rows if r[0] == "SCEN" and len(r) >= 5]
    witness_ms = [(k.split(":", 1)[1], v) for k, v in times.items() if k.startswith("scenario:")]
    ok = lambda sc: sc[-1] == "ok" and sc[-3] == sc[-2]
    passed, failed = [sc for sc in scen if ok(sc)], [sc for sc in scen if not ok(sc)]
    named = lambda sc: f"{sc[1]}/{sc[0]}" if len(sc) == 5 else sc[0]
    node = any(r[0] == "RULEJSON" for r in rows)
    if node and "occurrences" not in times:
        part = "the variable occurrences, before the static checks"
    elif "checks" not in times:
        part = "the static checks"
    elif "lint" not in times:
        part = "the trace lint"
    elif "witnesses" not in times:
        part = f"the witnesses, after {len(witness_ms)} had finished"
    elif not ended(hout, "witnesses"):
        part = "the end of the witness phase" if node else "the supersession check"
    elif "adequacy_start" not in times:
        part = "the adequacy phase, before the adequacy check began"
    elif "adequacy" not in times:
        part = "the adequacy check"
    else:
        part = "the end of the adequacy phase"
    out = [f"the evaluation was stopped in {part}"]
    slow = max(witness_ms, key=lambda kv: kv[1]) if witness_ms else None
    out.append(f"{len(passed)} witness(es) passed and {len(failed)} did not; the {len(witness_ms)} that finished took "
               f"{sum(v for _k, v in witness_ms) / 1000:.1f} s" + (f" in all, the slowest `{slow[0]}` {slow[1] / 1000:.1f} s" if slow else ""))
    if failed:
        out.append("not passed: " + "; ".join(f"{named(sc)}: " + (f"expected {sc[-3]}, got {sc[-2]}" if sc[-1] == "ok" else sc[-1])
                                             for sc in failed[:6]))
    missing = not_run(rows)
    if missing:
        out.append(f"not run: {', '.join(missing)}")
    if "adequacy_start" in times and "adequacy" not in times:
        size = [r[1:] for r in rows if r[0] == "ADEQ_SIZE" and len(r) >= 4]
        out.append(f"the adequacy check began {times['adequacy_start'] / 1000:.1f} s after the adequacy phase's program started "
                   "and did not finish: "
                   + "; ".join(f"`{z[0]}` has {z[1]} leaves, each replaced by true and by false and judged on its {z[2]} decided witness(es)"
                               for z in size))
    return out


def harness_failure(hout: str) -> Verdict:
    """A gate harness that evaluated the candidate and did not end its phase. One that ran out of time
    is the candidate's: its formulas take longer to evaluate on its witnesses than the gate allows,
    and the details give what the harness printed before the deadline (`evaluation_progress`).
    Every other failure `_toolchain` has attributed already; what is left is the toolchain's."""
    if lean.timed_out(hout):
        return Verdict(GATE_TIMEOUT, [hout.splitlines()[0]] + evaluation_progress(hout))
    return Verdict(INFRA, ["gate harness did not run"] + hout.splitlines()[:3])


#: Operators whose reading starts at an observed event: an edge, a past-time "since", the time, the
#: distance or the heading change since a formula rose or held, and edges counted since one. The step
#: bound of `heading_since` is a sampling standard, not a window: it never stands as a look-back length.
ONSET_OPERATORS = {"rises", "since", "since_rise", "count", "distance_while", "heading_since"}
#: Operators whose `length` is a window behind the judged observation. `within` and `until_within`
#: look ahead and are not among them.
LOOKBACK_OPERATORS = {"holds_for", "at_last"}
#: The parameter position of each primitive that is a window behind the judged observation, from the
#: primitive's semantics: the heading change is taken over the window behind. A closest-approach
#: horizon projects motion ahead and is no look-back; the other primitives take no time parameter.
LOOKBACK_PRIMITIVE_PARAMS = {"prim_heading_change": 0}
#: Every primitive that takes no look-back parameter; with the table above it covers every primitive.
NO_LOOKBACK_PRIMITIVES = {"prim_closest_approach_within", "prim_closest_approach_time", "prim_closest_approach_distance",
                          "prim_conditions_hold", "prim_region_lateral_offset", "prim_region_offset_along"}


def heading_steps(x) -> list:
    """The step bound of every `heading_since` in a formula or term as Core exports it, at any depth
    (walked with an explicit stack, so no nesting hides one)."""
    out, stack = [], [x]
    while stack:
        y = stack.pop()
        if isinstance(y, dict):
            if "heading_since" in y:
                out.append(y.get("max_step"))
            stack.extend(reversed(list(y.values())))
        elif isinstance(y, list):
            stack.extend(reversed(y))
    return out


#: The refusal of a formula nested deeper than Python reads it: the static checks have not read it
#: whole, so nothing they would find is ruled out.
TOO_DEEP = ("the formula nests deeper than the gate's static checks can read: it is refused, not taken as passing; "
            "write it with less nesting")


def deep_checks(run) -> list[str]:
    """The defects `run` finds on exported formulas, or the refusal `TOO_DEEP` when parsing or walking
    them exceeds Python's recursion limit."""
    try:
        return run()
    except RecursionError:
        return [TOO_DEEP]


def rule_step_defects(node_id: str, rule_json, profile: str | None, reading) -> list[str]:
    """A step bound of `heading_since` is a sampling standard of the recordings, shared by every rule
    of the run: on the rule with its concept calls expanded (`RULEXJSON`), every one is exactly the
    reading parameter the run's acquisition profile names, and the reading holds that parameter as a
    value the operator reviewed. A literal, any other parameter or an expression is refused, as is a
    rule reading `heading_since` in a run whose profile does not resolve. Empty for a rule that reads
    no `heading_since`."""
    from ..model import acquisition as acq
    steps = heading_steps(rule_json)
    if not steps:
        return []
    try:
        param = acq.step_parameter(profile)
    except acq.ProfileError as e:
        return [f"{node_id}: the rule reads `heading_since`, and {e}; until the operator names a profile with a reviewed "
                "parameter, no rule of this run may read `heading_since`"]
    want = {"param": param}
    out = [f"{node_id}: a `heading_since` step bound is {json.dumps(s, sort_keys=True)}; under the run's acquisition profile "
           f"`{profile}` it is the operator-reviewed parameter `{param}`, written `.param \"{param}\"` in the rule or passed to "
           "the step formal of the concept that reads it: no literal, no other parameter, no expression"
           for s in steps if s != want]
    data = getattr(reading, "data", None) or {}
    return list(dict.fromkeys(out)) + [f"{node_id}: {d}" for d in acq.review_defects(param, data)]


def concept_step_defects(cid: str, body_json, formals: list[str]) -> list[str]:
    """A shared concept serves every caller, so it takes the step bound of each `heading_since` in its
    expanded body from its caller, as one of its own formal parameters; the caller's node gate then
    holds the actual to the run's acquisition-profile parameter. A literal there, written in the body
    or given to a concept it calls, is refused."""
    out = [f"{cid}: a `heading_since` step bound is {json.dumps(s, sort_keys=True)}; a shared concept takes it from its caller "
           f"as one of its formal parameters ({', '.join(f'`{f}`' for f in formals) or 'it declares none'}), and the caller passes "
           "the run's acquisition-profile parameter: no literal, here or given to a concept it calls"
           for s in heading_steps(body_json)
           if not (isinstance(s, dict) and set(s) == {"param"} and s["param"] in formals)]
    return list(dict.fromkeys(out))


def act_support_defects(act: dict | None, body_json) -> list[str]:
    """Whether a concept's body supports the act its record declares, read on the body as Core
    expands it (`Concept.expand`: every called concept inlined with its actuals substituted, so a
    formal forwarded to a callee appears where the callee reads it). A window boundary needs the
    window formal, as it stands, to be the length of a look-back: the window behind of `holds_for`
    over time or of `at_last`, or a primitive's look-back parameter. An event boundary needs an
    operator that starts at an observed event. This is a capability precheck: it does not show that
    the onset the record declares is the one the body anchors to. Empty when the body supports the
    declaration, or when the record declares no act."""
    if not isinstance(act, dict):
        return []
    window = {"param": act.get("window")}
    found = {"window": False, "event": False}

    def visit(x, depth=0) -> None:
        if depth > 200:
            return
        if isinstance(x, dict):
            if any(x.get(op) == "time" for op in LOOKBACK_OPERATORS) and x.get("length") == window:
                found["window"] = True
            pos = LOOKBACK_PRIMITIVE_PARAMS.get(x.get("quantity")) if isinstance(x.get("quantity"), str) else None
            ps = x.get("params") or []
            if pos is not None and len(ps) > pos and ps[pos] == window:
                found["window"] = True
            if any(k in x for k in ONSET_OPERATORS):
                found["event"] = True
            for v in x.values():
                visit(v, depth + 1)
        elif isinstance(x, list):
            for v in x:
                visit(v, depth + 1)
    visit(body_json)
    if act.get("boundary") == "window" and not found["window"]:
        return [f"the record declares a window act over `{act.get('window')}`, but the expanded body never reads that parameter as "
                "the length of a window behind the judged observation (`holds_for` or `at_last` over time, or a primitive's "
                "look-back parameter); a window ahead, a horizon of projected motion or another use is no look-back"]
    if act.get("boundary") == "event" and not found["event"]:
        return ["the record declares an act that starts at its observed onset, but the expanded body reads no operator that "
                f"starts at an event ({', '.join(sorted(ONSET_OPERATORS))}): write the onset, or report `no_operator` on the "
                "words of the contract the language cannot state"]
    return []


def occasion_window_defects(node: Node, rule_json, concepts: dict[str, dict] | None) -> list[str]:
    """Whether a node's window occasion reads the window its acts are recognized over: every call of
    each occasion act in the rule passes, at the position of the formal the act's record declares
    as its window, the occasion's `window` parameter itself. Read on the rule as written, where each
    call's actuals stand at their formals' positions; a parameter of the right unit that is not the
    one passed is no binding. Empty for an event boundary or without an occasion."""
    occ = node.get("occasion")
    if not isinstance(occ, dict) or node.occasion_boundary() != "window":
        return []
    acts = occ.get("act") if isinstance(occ.get("act"), list) else [occ.get("act")]
    want = {"param": occ.get("window")}
    out = []
    for cid in acts:
        rec = (concepts or {}).get(cid)
        decl = rec.get("act") if isinstance(rec, dict) else None
        if not isinstance(decl, dict) or decl.get("boundary") != "window":
            out.append(f"occasion act `{cid}`: its record declares no window act, so the occasion's window cannot be bound to it")
            continue
        formals = [f.get("name") for f in rec.get("params", [])]
        if decl.get("window") not in formals:
            out.append(f"occasion act `{cid}`: its declared window `{decl.get('window')}` is not one of its formals {formals}")
            continue
        pos, lean = formals.index(decl["window"]), cid.replace(".", "_")
        calls = []

        def visit(x) -> None:
            if isinstance(x, dict):
                if lean in (x.get("derived"), x.get("quantity")):
                    calls.append(x.get("params") or [])
                for v in x.values():
                    visit(v)
            elif isinstance(x, list):
                for v in x:
                    visit(v)
        visit(rule_json)
        if not calls:
            out.append(f"occasion act `{cid}` is not called by the rule, so its window cannot be bound to the occasion's `{occ.get('window')}`")
        for ps in calls:
            got = ps[pos] if len(ps) > pos else None
            if got != want:
                out.append(f"occasion act `{cid}` is called with {got!r} for its window `{decl['window']}`, but the occasion reads the "
                           f"act over `{occ.get('window')}`: pass the occasion's window to the act, or declare the window the act is "
                           "recognized over")
    return out


def param_mismatches(formula_json, concepts: dict[str, dict] | None, literals: list[dict]) -> list[str]:
    """What a concept call passes for a parameter the concept declares, apart from its unit (which
    the Core unit check holds): a named parameter, or a figure declared in `literals` in the declared
    unit. Any other literal, zero included, stands in for a magnitude the reading should hold."""
    from fractions import Fraction
    from ..model import units
    core = lambda u: units.FACTORS[u][0] if u in units.FACTORS else None
    declared = set()
    for lit in literals:
        try:
            c, v = units.to_core(lit.get("value"), lit.get("unit", ""))
            declared.add((v, c))
        except (KeyError, ValueError):
            pass
    by_name = {cid.replace(".", "_"): rec for cid, rec in (concepts or {}).items()}
    out: list[str] = []

    def visit(x) -> None:
        if isinstance(x, dict):
            name = x.get("derived") or x.get("quantity")
            rec = by_name.get(name) if isinstance(name, str) else None
            for f, t in zip(rec.get("params", []) if rec else [], x.get("params", [])):
                want, what = core(f.get("unit", "")), f"`{name}` parameter `{f.get('name')}` ({f.get('unit')})"
                if isinstance(t, dict) and "lit" in t:
                    q = Fraction(int(t["lit"]["num"]), int(t["lit"]["den"]))
                    u = units.core_of_tag(t.get("unit")) or t.get("unit")
                    if u != want or (q, u) not in declared:
                        out.append(f"{what} is passed the literal {q} {t.get('unit')}, which no declared figure is: "
                                   f"a magnitude the text leaves open is a parameter of the reading, in {f.get('unit')}")
            for v in x.values():
                visit(v)
        elif isinstance(x, list):
            for v in x:
                visit(v)
    visit(formula_json)
    return out


def unanchored_variables(groups: list[list[str]], binders: list[str]) -> list[str]:
    """Quantifier variables (`?v` groups) not connected to a binder or a composition (`$`) through
    the occurrence groups, by union-find over shared variables."""
    parent: dict[str, str] = {}
    def find(x: str) -> str:
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x
    def union(a: str, b: str) -> None:
        parent[find(a)] = find(b)
    quantified: list[str] = []
    for g in groups:
        vs = [v for v in g if v]
        if len(vs) == 1 and vs[0].startswith("?"):
            quantified.append(vs[0][1:]); continue
        for v in vs[1:]:
            union(vs[0], v)
    anchored = {find(b) for b in binders} | {find("$")}
    seen: list[str] = []
    for v in quantified:
        if v not in seen and find(v) not in anchored:
            seen.append(v)
    return seen


# =============================================================================================
# Concepts: the gate for a concept node — two files, the same
# steps as a rule, plus the cycle, supersession and duplicate checks.
# =============================================================================================
CONCEPT_VERDICTS = ["SCOPE_VIOLATION", "TEST_ADD_ONLY", "BUILD_FAIL", "UNSOUND", "CONCEPT_CYCLE", "CHECK_FAIL",
                    "UNANCHORED_VARIABLE", "DECLARATION_MISMATCH", "UNCLAIMED_ATOM", "UNUSED_CLAIM", "BARE_LITERAL",
                    "WITNESS_FAIL", "SUPERSESSION_NO_DIFF", "DUPLICATE_CONCEPT", "VACUOUS", "UNEXPRESSED", "PARAM_MISMATCH",
                    "GATE_TIMEOUT", "OK"]
ALLOWED_CONCEPT_IMPORTS = {"TrafficSpec.Core.Language.Concept"}


def _concept_harness_source(cid: str, reading_json_path: Path, registry: tuple[str, str]) -> str:
    """The concept's gate harness; `registry` as for a node's."""
    ns, wns = nodeid.concept_namespace(cid), nodeid.concept_witness_namespace(cid)
    imports, defs = registry
    return f'''{imports}import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.TraceLint
import {nodeid.concept_module(cid)}
import {nodeid.concept_witness_module(cid)}
{defs}open TrafficSpec Lean
#print axioms {ns}.concept
#print axioms {wns}.instances
#print axioms {wns}.scenarios
{_OCC_DEFS}
{relations.lean_defs()}
def main (args : List String) : IO Unit := do
{_PHASES}
  let c := {ns}.concept
  let cs := (allConcepts.filter (·.id != c.id)) ++ [c]
  let insts := {wns}.instances
  let scs := {wns}.scenarios
  let text ← IO.FS.readFile {json.dumps(str(reading_json_path.resolve()))}
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; pure ({{}} : Reading)
  let instRules := insts.filterMap (Concept.asRule cs)
  let rules := allRules ++ instRules
  let scs' := scs.map fun sc => {{ sc with reading := ρ }}
  if args == ["adequacy"] then
    for r in instRules do
      IO.println s!"ADEQ_SIZE\\t{{r.id}}\\t{{r.applicability.leafCount + r.obligation.leafCount}}\\t{{(scs'.filter fun sc => sc.rule == r.id && sc.expected.tag != "unknown").length}}"
    let tAdq ← IO.monoMsNow
    IO.println s!"TIME\\tadequacy_start\\t{{tAdq - tMain}}"
    out.flush
    for r in instRules do
      for u in Adequacy.unexercised rules r (scs'.filter (·.rule == r.id)) cs do IO.println s!"ADEQ\\t{{r.id}}: {{u}}"; out.flush
    IO.println s!"TIME\\tadequacy\\t{{(← IO.monoMsNow) - tAdq}}"
    out.flush
    IO.println "DONE"
    return
  IO.println s!"DECL\\t{{(Concept.toJson c).compress}}"
  IO.println s!"ATOMS\\t{{String.intercalate "," c.atoms}}"
  IO.println s!"READS\\t{{String.intercalate "," (Formula.atoms (Concept.expand cs c.bodyFormula)).eraseDups}}"
  IO.println s!"AGGREGATES\\t{{String.intercalate "\\t" (Concept.aggregateIds cs c)}}"
  IO.println s!"HARDAGG\\t{{String.intercalate "\\t" (Formula.aggregateIds (Concept.expand cs c.bodyFormula)).eraseDups}}"
  let bodyJson := match c.body with
    | .formula φ => (Formula.toJson (Concept.expand cs φ)).compress
    | .quantity t => (Term.toJson (Concept.expandTerm cs t)).compress
  IO.println s!"BODY\\t{{bodyJson}}"
  for sc in scs do IO.println s!"WITNESS\\t{{sc.name}}\\t{{sc.rule}}"
  out.flush
  let tChk ← IO.monoMsNow
  for g in occF c.bodyFormula do IO.println s!"OCC\\t{{String.intercalate "," g}}"
  for (q, u) in Formula.literals c.bodyFormula do IO.println s!"LITERAL\\t{{q.num}}/{{q.den}}\\t{{repr u}}"
  for id in Concept.onCycle cs do IO.println s!"CYCLE\\t{{id}}"
  for e in Concept.check cs c do IO.println s!"CHECK\\t{{e}}"
  for e in Concept.checkReading cs c ρ do IO.println s!"READING\\t{{e}}"
  for e in DimCheck.concept (DimCheck.envOf ρ cs c.params) c do IO.println s!"DIM\\t{{e.tag}}\\t{{e.render}}"
  for i in insts do
    for e in Concept.Instance.defects cs i do IO.println s!"CHECK\\t{{e}}"
    let regionFormals := ((cs.find? (·.id == i.concept)).map (·.regionFormals)).getD []
    match Concept.asRule cs i with
    | none => IO.println s!"INST\\t{{i.name}}\\tunfilled"
    | some r =>
      IO.println s!"INST\\t{{i.name}}\\tok"
      for e in Rule.check (rules.map (Concept.expandRule cs)) (Concept.expandRule cs r) regionFormals do IO.println s!"CHECK\\t{{e}}"
    if let some ci := cs.find? (·.id == i.concept) then
      for sc in scs.filter (·.rule == i.name) do
        for e in Concept.regionDefects ci sc.name sc.regions do IO.println s!"CHECK\\t{{e}}"
  IO.println s!"TIME\\tchecks\\t{{(← IO.monoMsNow) - tChk}}"
  out.flush
  for sc in scs do if !sc.boundary.isEmpty then IO.println s!"BOUNDARY\\t{{sc.name}}"
  let tLint ← IO.monoMsNow
  for sc in scs' do
    let τ := TraceLint.completeOccupancy sc.trace
    for e in TraceLint.checkTrace τ do IO.println s!"REF\\t{{sc.name}}\\t{{sc.rule}}\\t{{e}}"
    RelCheck.run sc.name τ
    if let some (a, b) := sc.window then
      if !(sc.trace.any fun s => decide (a ≤ s.t) && decide (s.t ≤ b)) then IO.println s!"NOWINDOW\\t{{sc.name}}"
  IO.println s!"TIME\\tlint\\t{{(← IO.monoMsNow) - tLint}}"
  out.flush
  let tWit ← IO.monoMsNow
  for sc in scs' do
    let tSc ← IO.monoMsNow
    match sc.run rules cs with
    | .ok v => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.rule}}\\t{{sc.expected.tag}}\\t{{v.tag}}\\tok"
    | .error e => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.rule}}\\t{{sc.expected.tag}}\\t?\\t{{e}}"
    out.flush
    IO.println s!"TIME\\tscenario:{{sc.rule}}/{{sc.name}}\\t{{(← IO.monoMsNow) - tSc}}"
    out.flush
  IO.println s!"TIME\\twitnesses\\t{{(← IO.monoMsNow) - tWit}}"
  out.flush
  match c.supersedes with
  | none => pure ()
  | some old =>
    let csOld := allConcepts.filter (·.id != c.id)
    if !(csOld.any (·.id == old)) then IO.println s!"OLD\\tmissing {{old}}"
    for i in insts do
      let iOld : Concept.Instance := {{ i with concept := old, name := i.name ++ "#old" }}
      match Concept.asRule csOld iOld with
      | none => IO.println s!"DIFF\\t{{i.name}}\\tunfilled"
      | some rOld =>
        for sc in scs'.filter (fun sc => sc.rule == i.name && sc.name == "counterexample") do
          let scOld : Scenario := {{ sc with rule := rOld.id }}
          let status := match scOld.run (allRules ++ [rOld]) csOld with | .ok _ => "same" | .error _ => "differs"
          IO.println s!"DIFF\\t{{i.name}}\\t{{status}}"
  IO.println "DONE_WITNESSES"
'''


def hard_coded_aggregates(cid: str, ids: list[str]) -> list[str]:
    """A shared concept reads an aggregate only through a literal formal its caller fills. `ids` are
    the aggregate ids its body names as written, its calls expanded with its own formals left
    unfilled (`HARDAGG`): such an id is written into the body or given to a callee as a literal, and
    whether a road user is a member of it depends on the definition that governs each calling law,
    which no check of the concept alone can verify. An id the caller passes reaches the body as the
    formal, and the caller's own gate holds it against that caller's reading and claims."""
    return [f"{cid}: the body names the definition-scoped aggregate `{a}` itself (here or in a concept it calls with that id); "
            "a shared concept reads an aggregate only through a literal formal its caller fills, so that each calling law's "
            "own gate checks the id against its definitions, its reading and its claims" for a in ids]


def _lean_concept_id(lean_name: str) -> str:
    """`drv_motion_halted` ↦ `drv.motion.halted` (the first two separators)."""
    parts = lean_name.split("_", 2)
    return ".".join(parts) if len(parts) == 3 else lean_name


def run_concept_gate(rec, reading: Reading, baseline: dict[str, str], work: Path, budget_used: int, budget: int,
                     mode: str = "train", accepted: dict[str, dict] | None = None) -> Verdict:
    """The gate for one concept record. `accepted` is the catalogue (for duplicates); `mode` `test` refuses a supersession."""
    from ..model.blueprint import CONCEPT_SCENARIOS
    from ..lean import surface, render_formula
    from ..model import units
    accepted = accepted or {}
    work.mkdir(parents=True, exist_ok=True)
    lib = paths.LIBRARY
    cid = rec.id
    c_rel, w_rel = nodeid.concept_path(cid), nodeid.concept_witness_path(cid)
    c_file, w_file = lib / c_rel, lib / w_rel
    details: list[str] = []
    if budget_used >= budget:
        return Verdict("BUDGET_EXHAUSTED", [f"{budget} gate runs used"])
    bad_reading = reading_input_defects(reading)
    if bad_reading:
        return bad_reading

    # 1. scope
    stray = scope_stray(baseline, {lib_rel(c_rel), lib_rel(w_rel)}, work)
    if stray:
        return Verdict("SCOPE_VIOLATION", [f"changed outside the concept's files: {stray[:8]}"] + ([f"… and {len(stray) - 8} more"] if len(stray) > 8 else []))
    if not c_file.exists() or not w_file.exists():
        return Verdict("SCOPE_VIOLATION", [f"missing {c_rel if not c_file.exists() else w_rel}"])
    ctext, wtext = c_file.read_text(encoding="utf-8"), w_file.read_text(encoding="utf-8")
    bad_imports = (_imports(ctext) - ALLOWED_CONCEPT_IMPORTS) | (_imports(wtext) - ALLOWED_WITNESS_IMPORTS_EXTRA - {nodeid.concept_module(cid)})
    if bad_imports:
        return Verdict("SCOPE_VIOLATION", [f"imports not allowed: {sorted(bad_imports)}"])
    if f"namespace {nodeid.concept_namespace(cid)}" not in ctext or f"namespace {nodeid.concept_witness_namespace(cid)}" not in wtext:
        return Verdict("SCOPE_VIOLATION", ["namespace must be derived from the concept id"])
    if rec.get("supersedes") and mode == "test":
        return Verdict("TEST_ADD_ONLY", [f"a test run adds concepts and supersedes none; `{rec.get('supersedes')}` keeps its body, the defect is recorded"])

    # 2. build, and 3. the harness run, as for a node
    only_nodes, only_concepts = task_registry(work)
    reg = dict(only_nodes=only_nodes, only_concepts=None if only_concepts is None else sorted(set(only_concepts) | {cid}),
               keep=task_keep(work) | {cid})
    # a forbidden construct is refused before anything is compiled: the compiler runs what a file elaborates
    bad = forbidden_tokens((("concept", ctext), ("witness", wtext)))
    if bad:
        return Verdict("UNSOUND", details + bad)
    harness = work / "gate_harness.lean"
    reading_json = work / "reading.json"
    reading_json.write_text(reading.lean_json(), encoding="utf-8")
    harness.write_text(_concept_harness_source(cid, reading_json, index_sync.registry_source(**reg)), encoding="utf-8")
    toolchain = functools.partial(_toolchain, work, ["TrafficSpec.Index", nodeid.concept_module(cid), nodeid.concept_witness_module(cid)],
                                  {c_rel, w_rel}, (nodeid.concept_namespace(cid) + ".", nodeid.concept_witness_namespace(cid) + "."), harness)
    ran = toolchain(register=lambda: index_sync.write_index(**reg))
    if isinstance(ran, Verdict):
        return ran
    out, hout = ran
    if lean.sorry_warnings(out):
        details.append("build reports a declaration that uses sorry")
    _save_output(work, "witnesses", hout)
    decode = [l.split("\t", 1)[1] for l in hout.splitlines() if l.startswith("READING_DECODE\t")]
    if decode:
        return Verdict(INFRA, ["the reading does not decode (an input error, not the candidate's): " + decode[0]])
    for m in re.finditer(r"depends on axioms: \[([^\]]*)\]", hout):
        axioms = {a.strip() for a in m.group(1).split(",") if a.strip()}
        if axioms - STANDARD_AXIOMS:
            details.append(f"non-standard axioms: {sorted(axioms - STANDARD_AXIOMS)}")
    if details:
        return Verdict("UNSOUND", details)
    # the witness phase's rows; after its deadline, only what they already decide (`Cut`)
    cut = Cut(hout)
    if not cut.stopped and not ended(hout, "witnesses"):
        return harness_failure(hout)
    rows = cut.rows
    def col(tag: str) -> list[list[str]]:
        return [r[1:] for r in rows if r[0] == tag]

    # 4. cycle, static check
    cyc = [r[0] for r in col("CYCLE")]
    if cyc:
        return Verdict("CONCEPT_CYCLE", cyc + cut.note())
    checks = [r[0] for r in col("CHECK")] + [r[0] for r in col("READING")] + [f"units: {r[1]}" for r in col("DIM")]
    checks += hard_coded_aggregates(cid, [a for row in col("HARDAGG") for a in row if a])
    checks += deep_checks(lambda: (divisions_by_measure(json.loads(col("BODY")[0][0]))
                                   + concept_step_defects(cid, json.loads(col("BODY")[0][0]), [p.get("name") for p in rec.params()]))
                          if col("BODY") else [])
    if checks:
        return Verdict("CHECK_FAIL", checks + cut.note())
    if cut.stopped and not cut.reached("checks"):
        return harness_failure(hout)

    # 4b. anchoring within the body: quantified variables reach a track or region formal (the caller supplies both)
    roots = [a["name"] for a in rec.args() if a.get("sort") in ("track", "region")]
    if roots:
        unanchored = unanchored_variables([row[0].split(",") if row and row[0] else [] for row in col("OCC")], roots)
        if unanchored:
            return Verdict("UNANCHORED_VARIABLE", [f"in the body, the quantified variable `{v}` shares no atom with a track or region "
                                                   "formal of the concept, nor with a variable that does" for v in unanchored])

    # 5. declarations
    decl = json.loads(col("DECL")[0][0])
    mism = []
    ws = lambda s: " ".join(str(s or "").split())
    if decl["id"] != cid: mism.append(f"id {decl['id']} ≠ {cid}")
    if ws(decl["contract"]) != ws(rec.get("contract")): mism.append("contract differs from the record")
    if (decl.get("definition") or None) != (rec.get("definition") or None): mism.append("definition differs from the record")
    if decl["kind"] != rec.get("kind"): mism.append(f"kind {decl['kind']} ≠ {rec.get('kind')}")
    exp_args = [(a["name"], a["sort"], list(a.get("values", [])) if a.get("sort") == "literal" else []) for a in rec.args()]
    got_args = [(a["name"], a["sort"]["sort"], list(a["sort"].get("values", []))) for a in decl["args"]]
    if got_args != exp_args: mism.append(f"args {got_args} ≠ {exp_args}")
    exp_params = [(p["name"], units.json_tag(units.FACTORS[p["unit"]][0])) for p in rec.params()]
    got_params = [(p["name"], p["unit"]) for p in decl["params"]]
    if got_params != exp_params: mism.append(f"params {got_params} ≠ {exp_params}")
    rec_res = [ws(r.get("why", "")) for r in rec.get("residues", [])]
    decl_res = [ws(w) for w in decl["residues"]]
    missing_res = [w for w in rec_res if w not in decl_res]
    if missing_res: mism.append(f"residues of the record missing from the concept: {missing_res[:3]}")
    added_res = [w for w in decl_res if w not in rec_res]
    if added_res: mism.append(f"residues added to the concept: {added_res[:3]}; a residue is the record's — a reading you chose that the contract leaves open is a narrowing ⟨words of the contract, why⟩")
    contract_ws = ws(rec.get("contract"))
    narrowings = [n for n in decl.get("narrowings", []) if isinstance(n, dict)]
    for n in narrowings:
        if not ws(n.get("span")) or ws(n.get("span")) not in contract_ws: mism.append(f"narrowing on `{str(n.get('span', ''))[:60]}`, which is not a run of the contract's words")
        elif not str(n.get("why", "")).strip(): mism.append(f"narrowing on `{str(n.get('span'))[:60]}` states no why")
        elif n.get("kind", "reading") not in CONCEPT_NARROWING_KINDS:
            mism.append(f"narrowing on `{str(n.get('span'))[:60]}` has kind {n.get('kind')!r}; one of {sorted(CONCEPT_NARROWING_KINDS)}")
    if (decl.get("supersedes") or None) != (rec.get("supersedes") or None): mism.append("supersedes differs from the record")
    on_record = {narrowing_key(x) for x in rec.get("narrowings", []) if isinstance(x, dict)}
    narrowings = [n for n in narrowings if narrowing_key(n) not in on_record]
    if mism:
        return Verdict("DECLARATION_MISMATCH", mism)
    unexpressed = [n for n in narrowings if n.get("kind") in ("no_atom", "no_operator")]
    if unexpressed:
        return Verdict("UNEXPRESSED", [f"`{str(n.get('span'))[:80]}` ({n['kind']}): {str(n.get('why', ''))[:200]}" for n in unexpressed]
                       + ["the vocabulary or the language cannot state these words: the repair session retypes a formal the body "
                          "cannot honour, or withdraws the concept naming what is missing"],
                       extras={"unexpressed": unexpressed})

    # 6. claims and literals
    used = {a for a in col("ATOMS")[0][0].split(",") if a}
    claimed = rec.claimed_names() | {r.replace(".", "_") for r in rec.refs()}
    canon = owner_name
    unclaimed = sorted({n for n in used if canon(n) not in claimed and n not in FREE_USES})
    if unclaimed:
        return Verdict("UNCLAIMED_ATOM", unclaimed)
    used_via = {canon(n) for n in reads_of_used(used, accepted)}
    unused = sorted(cl for cl in claimed if not any(canon(n) == cl for n in used) and cl not in used_via)
    if unused:
        return Verdict("UNUSED_CLAIM", unused)
    # an aggregate the body reads, through the concepts it calls too, is one its record claims, by id
    agg_used = {a for row in col("AGGREGATES") for a in row if a}
    agg_claimed = {c.split("=", 1)[1] for c in rec.claimed_atoms() if c.startswith("ru.aggregate=")}
    if agg_used - agg_claimed:
        return Verdict("UNCLAIMED_ATOM", [f"ru_aggregate \"{a}\" (the record claims {sorted(agg_claimed) or 'no aggregate'})" for a in sorted(agg_used - agg_claimed)])
    from fractions import Fraction
    used_lits = sorted((Fraction(q), u.split(".")[-1].strip()) for q, u in col("LITERAL"))
    declared = []
    for lit in rec.literals():
        try:
            core, v = units.to_core(lit.get("value"), lit.get("unit", ""))
            declared.append((v, core))
        except (KeyError, ValueError):
            return Verdict("BARE_LITERAL", [f"declared literal {lit} has an unknown unit"])
    declared = sorted(set(declared))
    used_lits = sorted(set(used_lits))                # a figure counts once, however often the body (or its rendering as a formula) writes it
    if used_lits != declared:
        return Verdict("BARE_LITERAL", [f"body literals {[(str(q), u) for q, u in used_lits]} ≠ the record's declared literals {[(str(q), u) for q, u in declared]}; a magnitude is a formal parameter unless the record declares it"])
    mism = param_mismatches(json.loads(col("BODY")[0][0]), accepted, rec.get("literals", []))
    if mism:
        return Verdict("PARAM_MISMATCH", mism)
    mism = act_support_defects(rec.get("act"), json.loads(col("BODY")[0][0]))
    if mism:
        return Verdict("DECLARATION_MISMATCH", mism)

    # 7. witnesses
    fails = [f"instance {name}: a formal is unfilled" for name, status in col("INST") if status != "ok"]
    scen = col("SCEN")
    wanted = dict(CONCEPT_SCENARIOS)
    if rec.get("supersedes") and rec.get("counterexample"):
        wanted["counterexample"] = normalize_verdict((rec.get("counterexample") or {}).get("expected", "violated"))
    refs = {}
    for name, rule, msg in col("REF"):
        refs.setdefault((name, rule), []).append(msg)
    for name, _rule, expected, got, status in scen:
        if (name, _rule) in refs:         # a trace no adapter can write: its verdict is not considered
            fails.append(f"{name} ({_rule}): its trace is not one the adapter can produce: {'; '.join(refs[(name, _rule)][:3])}")
        elif status != "ok":
            fails.append(witness_failure(name, status))
        elif expected != got:
            fails.append(f"{name}: expected {expected}, got {got}")
        elif name in wanted and expected != wanted[name]:
            fails.append(f"{name}: the witness declares {expected}, the record requires {wanted[name]}")
    for name in wanted:
        if name not in {s[0] for s in scen} and not cut.stopped:
            fails.append(f"{name}: no witness of that name")
    fails += boundary_defects({r[0] for r in col("BOUNDARY")}, set())
    fails += witness_trace_defects(col)
    if fails:
        return Verdict("WITNESS_FAIL", fails + cut.note())
    if cut.stopped:
        return harness_failure(hout)

    # 7b. a supersession differs from the old body on its counterexample; a fenced version is
    # superseded on its fence, whose evidence stands for a counterexample
    if rec.get("supersedes") and not (accepted.get(rec.get("supersedes")) or {}).get("fenced"):
        diffs = col("DIFF")
        if col("OLD") or not diffs or any(d[1] != "differs" for d in diffs):
            return Verdict("SUPERSESSION_NO_DIFF", [f"the old body gives the same verdict on the counterexample ({diffs})" if diffs else "no counterexample ran against the old body"])

    # 8. duplicates of the catalogue, by alpha-equivalence of the expanded body
    body_json = json.loads(col("BODY")[0][0])
    canonical = render_formula.canonical(body_json, [a["name"] for a in rec.args()], [p["name"] for p in rec.params()])
    for oid, orec in accepted.items():
        if oid != rec.get("supersedes") and not orec.get("fenced") and orec.get("canonical_body") == canonical:
            return Verdict("DUPLICATE_CONCEPT", [f"the body is alpha-equivalent to accepted `{oid}`: call it instead"])

    # 9. adequacy: the harness's second phase, run only now, within what the first left of the deadline
    adequacy = adequacy_phase(work, toolchain, hout)
    if isinstance(adequacy, Verdict):
        return adequacy
    adeq = [r[1] for r in (l.split("\t") for l in adequacy.splitlines()) if r[0] == "ADEQ" and len(r) > 1]
    if adeq:
        return Verdict("VACUOUS", adeq)
    atom_ids = set(surface.core_atom_ids())
    prim_reads = surface.primitive_reads()
    read_names = [n for n in col("READS")[0][0].split(",") if n]
    read_names += [a for n in read_names if n.startswith("prim_") for a in prim_reads.get(n, [])]
    reads = sorted({a for n in read_names for a in [surface.atom_id_of(n, atom_ids)] if a})
    refs = sorted({_lean_concept_id(n) for n in used if n.startswith("drv_") and nodeid.is_concept_id(_lean_concept_id(n))})
    return Verdict("OK", [f"{len(scen)} witnesses, {len(used)} names, reads {len(reads)} atom(s)"]
                   + ([f"narrowings declared by the coder: {len(narrowings)}"] if narrowings else []),
                   extras={"reads": reads, "refs": refs, "canonical_body": canonical, "body_json": body_json,
                           **({"narrowings_added": narrowings} if narrowings else {})})
