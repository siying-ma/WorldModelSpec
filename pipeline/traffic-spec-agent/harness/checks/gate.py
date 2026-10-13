"""The gate (design §5): the only acceptance authority for a node, run by the harness itself."""
from __future__ import annotations
import hashlib
import json
import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from ..store import paths
from ..model import nodeid
from ..lean import lean, index_sync
from ..model.blueprint import Node, SCENARIOS, normalize_verdict
from ..model.reading import Reading

VERDICTS = ["SCOPE_VIOLATION", "BUILD_FAIL", "UNSOUND", "CHECK_FAIL", "UNANCHORED_VARIABLE", "DECLARATION_MISMATCH",
            "SCOPE_NARROWED", "UNEXPRESSED", "UNCLAIMED_ATOM", "UNUSED_CLAIM", "BARE_LITERAL", "WITNESS_FAIL", "VACUOUS",
            "GATE_TIMEOUT", "OK"]
#: What a coder's narrowing may be: a reading the words leave open, a declaration that the vocabulary
#: (`no_atom`) or the language (`no_operator`) cannot state the span — returned as `UNEXPRESSED` —, or
#: the coder's account of an `observable_reading` the plan declared on the same span.
NARROWING_KINDS = {"reading", "no_atom", "no_operator", "observable_reading"}
#: Roles whose span decides when a rule applies: a coder may not narrow one (the rule would apply
#: where the law does not), and a plan may not carry one as a residue.
SCOPE_ROLES = {"trigger", "subject", "condition", "exception"}
#: Roles a narrowing may be declared on: the duty and its standards, which the plan carries by an
#: element or an operationalization.
NARROWABLE_ROLES = {"obligation", "standard"}
#: Not a verdict on the node: the toolchain did not run (a missing `lake`, a build that timed out, a
#: harness that stopped with no error). The loop defers the law without counting an attempt and
#: stops after the iteration.
INFRA = "INFRA"
#: A verdict on the node: its harness ran out of time, its formulas being too costly to evaluate on
#: its witnesses. The loop returns the law to the planner with the rule's nesting.
GATE_TIMEOUT = "GATE_TIMEOUT"
#: Keywords and attributes that make a declaration something other than a closed, total value.
#: Scanned in the code only (`lean.code_only`): a law's words in a header comment or in the
#: `standard` string of an operationalization are not Lean.
FORBIDDEN_TOKENS = ["sorry", "admit", "axiom", "unsafe", "partial", "opaque", "implemented_by", "extern", "native_decide", "panic!"]
STANDARD_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
ALLOWED_RULE_IMPORTS = {"TrafficSpec.Core.Language.Rule"}
ALLOWED_WITNESS_IMPORTS_EXTRA = {"TrafficSpec.Core.Evidence.Builders"}
GENERATED = {"library/TrafficSpec/Index.lean", "library/TrafficSpecWitness.lean"}   # written by index_sync, never by a session
#: Names a formula reads that no node claims: the clock, which every window over time reads and
#: no source can fail to observe.
FREE_USES = {"kin_time"}


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
#: Files the harness itself writes while sessions run, and operator logs: a run's ledgers and
#: records (saved after every transition, so a session coding beside another would otherwise see
#: them change), and any log or pid file. The jail denies a session these paths already.
DIGEST_SKIP_RUN_FILES = {"ledger.jsonl", "concept_ledger.jsonl", "accepted_nodes.jsonl", "accepted_concepts.jsonl",
                         "deferred_nodes.jsonl", "mapping.json", "summary.json", "AUTO_NOTES.md", "review_compare.jsonl"}
DIGEST_SKIP_SUFFIXES = (".log", ".pid", ".lock")


@dataclass
class Verdict:
    verdict: str
    details: list[str] = field(default_factory=list)
    report: str = ""
    extras: dict = field(default_factory=dict)    # what an OK carries back: residues the coder added

    def to_dict(self) -> dict:
        return {"verdict": self.verdict, "details": self.details, **({"extras": self.extras} if self.extras else {})}


def repo_digest(root: Path | None = None) -> dict[str, str]:
    """A digest of every file of the pipeline a session could touch, keyed by path relative to
    the pipeline root: the library, the harness, the prompts, the ontology, the corpus, the
    readings, the gap ledger, the run records. Build outputs, caches, version control and the
    per-iteration task directories are left out. The scope check compares two of these."""
    root = (root or paths.REPO).resolve()
    out: dict[str, str] = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in DIGEST_SKIP_DIRS and not d.startswith("iter-"))
        for f in filenames:
            p = Path(dirpath) / f
            rel = p.relative_to(root).as_posix()
            if rel in GENERATED or p.is_symlink() or f.endswith(DIGEST_SKIP_SUFFIXES):
                continue
            if rel.startswith("results/") and rel.count("/") == 2 and f in DIGEST_SKIP_RUN_FILES:
                continue
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


def task_concurrent(work: Path) -> set[str]:
    """Files other sessions of the same wave own, which this task's scope check does not count."""
    f = work / "concurrent.json"
    return set(json.loads(f.read_text(encoding="utf-8"))) if f.exists() else set()


_OCC_DEFS = '''-- Variable connectivity: each atom, derived-concept or measure occurrence groups the variables it
-- relates (a comparison does not); `?v` marks a quantifier variable, `$` a composition (its mapped
-- variables are anchored by the composed rule).
def argVars (as : List TrafficSpec.Arg) : List String := as.filterMap fun a => match a with | .var v => some v | _ => none
mutual
partial def occT : TrafficSpec.Term → List (List String)
  | .measure _ as => [argVars as]
  | .quantity _ as ps => argVars as :: ps.flatMap occT
  | .distanceWhile s φ => [s] :: occF φ
  | .sinceRise φ => occF φ
  | .aggregate _ v φ t => ["?" ++ v] :: (occF φ ++ occT t)
  | .add a b | .sub a b | .mul a b | .div a b => occT a ++ occT b
  | .neg a | .abs a => occT a
  | .cond φ a b => occF φ ++ occT a ++ occT b
  | _ => []
partial def occF : TrafficSpec.Formula → List (List String)
  | .atom _ as ps => argVars as :: ps.flatMap occT
  | .same a b => [argVars [a, b]]
  | .cmp l _ r => occT l ++ occT r      -- a comparison relates magnitudes, not entities: no tie
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


def _harness_source(node_id: str, reading_json_path: Path) -> str:
    rns, wns = nodeid.rule_namespace(node_id), nodeid.witness_namespace(node_id)
    return f'''import TrafficSpec
import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import {nodeid.rule_module(node_id)}
import {nodeid.witness_module(node_id)}
open TrafficSpec Lean
#print axioms {rns}.rule
#print axioms {wns}.scenarios
{_OCC_DEFS}
def main : IO Unit := do
  let r := {rns}.rule
  let scs := {wns}.scenarios
  let rules := (allRules.filter (·.id != r.id)) ++ [r]
  let text ← IO.FS.readFile {json.dumps(str(reading_json_path.resolve()))}
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; pure ({{}} : Reading)
  let decl := Json.mkObj [
    ("id", r.id), ("laws", Json.arr (r.laws.map Json.str).toArray),
    ("binders", Json.arr (r.binders.map fun b => Json.str b.name).toArray),
    ("assumptions", Json.arr (r.assumptions.map Json.str).toArray),
    ("operationalizations", Json.arr (r.operationalizations.map fun o => Json.mkObj [("standard", o.standard), ("concepts", Json.arr (o.concepts.map Json.str).toArray), ("params", Json.arr (o.params.map Json.str).toArray), ("surrogate", o.surrogate)]).toArray),
    ("residues", Json.arr (r.residues.map Json.str).toArray),
    ("narrowings", Json.arr (r.narrowings.map fun n => Json.mkObj [("span", n.span), ("why", n.why), ("kind", n.kind)]).toArray), ("surrogate", r.surrogate)]
  IO.println s!"DECL\\t{{decl.compress}}"
  IO.println s!"RULEJSON\\t{{(Rule.toJson r).compress}}"
  (← IO.getStdout).flush
  IO.println s!"ATOMS\\t{{String.intercalate "," r.atoms}}"
  IO.println s!"COMPOSES\\t{{String.intercalate "," r.composes}}"
  for sc in scs do IO.println s!"MANIFEST\\t{{sc.name}}\\t{{String.intercalate "," sc.manifest.absentIds}}"
  for g in (r.binders.flatMap fun b => occF b.cls) ++ occF r.applicability ++ occF r.obligation do
    IO.println s!"OCC\\t{{String.intercalate "," g}}"
  for (q, u) in r.formulas.flatMap Formula.literals do IO.println s!"LITERAL\\t{{q.num}}/{{q.den}}\\t{{repr u}}"
  let rulesX := rules.map (Concept.expandRule allConcepts)
  for e in Rule.check rulesX (Concept.expandRule allConcepts r) do IO.println s!"CHECK\\t{{e}}"
  for e in Rule.checkReading rules r ρ do IO.println s!"READING\\t{{e}}"
  for sc in scs do
    let sc' : Scenario := {{ sc with reading := ρ }}
    match sc'.run rules allConcepts with
    | .ok v => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.expected.tag}}\\t{{v.tag}}\\tok"
    | .error e => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.expected.tag}}\\t?\\t{{e}}"
  let scs' := scs.map fun sc => {{ sc with reading := ρ }}
  for u in Adequacy.unexercised rules r scs' allConcepts do IO.println s!"ADEQ\\t{{u}}"
  IO.println "DONE"
'''


def _imports(text: str) -> set[str]:
    return set(re.findall(r"^import (\S+)", text, re.M))


def run_gate(node: Node, reading: Reading, baseline: dict[str, str], work: Path, budget_used: int, budget: int,
             accepted_concepts: dict[str, dict] | None = None) -> Verdict:
    """The gate for one node. `work` is the node's task directory (harness file, reports);
    `accepted_concepts` the catalogue, whose recorded reads count a claim as used."""
    work.mkdir(parents=True, exist_ok=True)
    lib = paths.LIBRARY
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    rule_file, wit_file = lib / rule_rel, lib / wit_rel
    details: list[str] = []

    if budget_used >= budget:
        return Verdict("BUDGET_EXHAUSTED", [f"{budget} gate runs used"])

    # 1. scope: nothing in the pipeline changed but the node's two files (and the files of the
    # sessions coding beside it); the registries carry the accepted nodes and this one
    now = repo_digest()
    changed = {p for p in (set(now) | set(baseline)) - GENERATED if now.get(p) != baseline.get(p)}
    stray = sorted(changed - {lib_rel(rule_rel), lib_rel(wit_rel)} - task_concurrent(work))
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

    # 2. build, and 3. the harness run: one holder of the library lock at a time, so the
    # registries this gate writes are the ones its build and its run see
    only_nodes, only_concepts = task_registry(work)
    with lean.library_lock(lib):
        index_sync.write_index(only_nodes=None if only_nodes is None else sorted(set(only_nodes) | {node.id}), only_concepts=only_concepts)
        try:
            ok, out = lean.lake_build(lib, ["TrafficSpec.Index", nodeid.rule_module(node.id), nodeid.witness_module(node.id)])
        except lean.LeanUnavailable as e:
            return Verdict(INFRA, [str(e)])
        (work / "build.log").write_text(out, encoding="utf-8")
        if lean.timed_out(out):
            return Verdict(INFRA, [out.splitlines()[0]])
        if not ok:
            return Verdict("BUILD_FAIL", lean.errors(out)[:8])
        details += forbidden_tokens((("rule", rtext), ("witness", wtext)))
        if lean.sorry_warnings(out):
            details.append("build reports a declaration that uses sorry")
        harness = work / "gate_harness.lean"
        reading_json = work / "reading.json"
        reading_json.write_text(reading.lean_json(), encoding="utf-8")
        harness.write_text(_harness_source(node.id, reading_json), encoding="utf-8")
        try:
            ok, hout = lean.lean_run(lib, harness)
        except lean.LeanUnavailable as e:
            return Verdict(INFRA, [str(e)])
    (work / "gate_harness.out").write_text(hout, encoding="utf-8")
    for m in re.finditer(r"depends on axioms: \[([^\]]*)\]", hout):
        axioms = {a.strip() for a in m.group(1).split(",") if a.strip()}
        if axioms - STANDARD_AXIOMS:
            details.append(f"non-standard axioms: {sorted(axioms - STANDARD_AXIOMS)}")
    if details:
        return Verdict("UNSOUND", details)
    if not ok or "DONE" not in hout:
        return harness_failure(hout)

    rows = [l.split("\t") for l in hout.splitlines() if "\t" in l]
    def col(tag: str) -> list[list[str]]:
        return [r[1:] for r in rows if r[0] == tag]

    # 4. static check
    checks = [r[0] for r in col("CHECK")] + [r[0] for r in col("READING")]
    checks += divisions_by_measure(json.loads(col("RULEJSON")[0][0])) if col("RULEJSON") else []
    if checks:
        return Verdict("CHECK_FAIL", checks)

    # 4b. anchoring: every quantifier variable reaches a binder through shared arguments
    binders = [b["name"] for b in node.get("binders", [])]
    unanchored = unanchored_variables([row[0].split(",") if row and row[0] else [] for row in col("OCC")], binders)
    if unanchored:
        return Verdict("UNANCHORED_VARIABLE", [f"`{v}` is related to no binder: the region, device or user it ranges over is any in the scene, not the subject's — tie it through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder" for v in unanchored])

    # 5. declarations
    decl = json.loads(col("DECL")[0][0])
    exp_binders = [b["name"] for b in node.get("binders", [])]
    from ..model.blueprint import concepts_of
    exp_ops = sorted((o.get("standard", ""), tuple(sorted(concepts_of(o)))) for o in node.get("operationalizations", []))
    got_ops = sorted((o.get("standard", ""), tuple(sorted(o.get("concepts", [])))) for o in decl["operationalizations"])
    mism = []
    if decl["id"] != node.id: mism.append(f"id {decl['id']} ≠ {node.id}")
    if sorted(decl["laws"]) != sorted(node["law_refs"]): mism.append(f"laws {decl['laws']} ≠ {node['law_refs']}")
    if decl["binders"] != exp_binders: mism.append(f"binders {decl['binders']} ≠ {exp_binders}")
    if sorted(decl["assumptions"]) != sorted(a.get("id") for a in node.get("assumptions", [])): mism.append("assumptions differ")
    if got_ops != exp_ops: mism.append(f"operationalizations {got_ops} ≠ {exp_ops}")
    node_residues = [r.get("why", "") for r in node.get("residues", [])]
    missing_res = [w for w in node_residues if w not in decl["residues"]]
    if missing_res: mism.append(f"residues of the node missing from the rule: {missing_res[:3]}")
    added_res = [w for w in decl["residues"] if w not in node_residues]
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
    def canon(n: str) -> str:   # accessor → its atom's Lean name, so `dev_traffic_signal_shows` matches the claim `dev.traffic_signal`
        for c in sorted(claimed, key=len, reverse=True):
            if n == c or n.startswith(c + "_"):
                return c
        return n
    unclaimed = sorted({n for n in used if canon(n) not in claimed and n not in FREE_USES})
    if unclaimed:
        return Verdict("UNCLAIMED_ATOM", unclaimed)
    used_via = {canon(n) for n in reads_of_used(used, accepted_concepts)}
    unused = sorted(c for c in claimed if not any(canon(n) == c for n in used) and c not in used_via)
    if unused:
        return Verdict("UNUSED_CLAIM", unused)
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

    # 7. witnesses
    scen = col("SCEN")
    planned = {s["name"]: s for s in node.get("scenarios", [])}
    fails = []
    masked = planned.get("blind", {}).get("masked", [])
    masked = set([masked] if isinstance(masked, str) else masked)
    for name, absent in col("MANIFEST"):
        if name == "blind" and set(a for a in absent.split(",") if a) != masked:
            fails.append(f"blind: the manifest masks {sorted(a for a in absent.split(',') if a)}, the node masks {sorted(masked)}")
    for name, expected, got, status in scen:
        if status != "ok":
            fails.append(f"{name}: {status}")
        elif expected != got:
            fails.append(f"{name}: expected {expected}, got {got}")
        elif name in planned and expected != (SCENARIOS.get(name) or normalize_verdict(planned[name].get("expected", ""))):
            fails.append(f"{name}: the witness declares {expected}, the plan requires {SCENARIOS.get(name) or normalize_verdict(planned[name].get('expected', ''))}")
    for name in list(SCENARIOS) + [p for p in planned if p not in SCENARIOS]:   # every planned scenario is a test
        if name not in {s[0] for s in scen}:
            fails.append(f"{name}: no witness of that name")
    if fails:
        return Verdict("WITNESS_FAIL", fails)

    # 8. adequacy
    adeq = [r[0] for r in col("ADEQ")]
    if adeq:
        return Verdict("VACUOUS", adeq)
    return Verdict("OK", [f"{len(scen)} witnesses, {len(used)} names, composes {col('COMPOSES')[0][0] or 'nothing'}"]
                   + ([f"narrowings declared by the coder: {len(narrowings)}"] if narrowings else []),
                   extras={"rule_json": json.loads(col("RULEJSON")[0][0]),
                           **({"narrowings_added": narrowings} if narrowings else {})})


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


QUANTIFIERS = ("exists_user", "forall_user", "exists_region", "forall_region", "exists_device", "forall_device", "aggregate")
WINDOWS = ("holds_for", "within", "until_within", "at_last")


def nesting(j, quants: int = 0, windows: int = 0) -> tuple[int, int]:
    """The deepest chain of quantifiers in an exported formula, as (quantifiers, window operators
    around them): each quantifier evaluates its body once per entity of the scene, and each window
    operator once per observation of its window."""
    best = (quants, windows)
    if isinstance(j, dict):
        q = quants + any(k in j for k in QUANTIFIERS)
        w = windows + any(k in j for k in WINDOWS)
        for v in j.values():
            best = max(best, nesting(v, q, w))
    elif isinstance(j, list):
        for v in j:
            best = max(best, nesting(v, quants, windows))
    return best


def harness_failure(hout: str) -> Verdict:
    """A gate harness that did not reach `DONE`. A harness that ran out of time is the node's:
    its formulas take longer to evaluate on its witnesses than the gate allows, and the details
    give the deepest nesting of quantifiers the exported rule shows. One that reported no error is
    the toolchain's; one whose error line names what it elaborated is the node's."""
    if lean.timed_out(hout):
        lines = hout.splitlines()
        shape = []
        rj = [l.split("\t", 1)[1] for l in lines if l.startswith("RULEJSON\t")]
        if rj:
            try:
                q, w = nesting(json.loads(rj[0]))
                shape = [f"the deepest chain of the rule nests {q} quantifier(s) over road users, regions or devices "
                         f"under {w} window operator(s); each is evaluated per entity, per observation, per witness "
                         "and per adequacy mutation"]
            except json.JSONDecodeError:
                pass
        return Verdict(GATE_TIMEOUT, [lines[0]] + shape)
    if not lean.errors(hout):
        return Verdict(INFRA, ["gate harness did not run"] + hout.splitlines()[:3])
    return Verdict("BUILD_FAIL", ["gate harness did not run"] + lean.errors(hout)[:8])


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
# Concepts (DERIVED_CONCEPTS_PLAN §5, §6): the gate for a concept node — two files, the same
# steps as a rule, plus the cycle, supersession and duplicate checks.
# =============================================================================================
CONCEPT_VERDICTS = ["SCOPE_VIOLATION", "TEST_ADD_ONLY", "BUILD_FAIL", "UNSOUND", "CONCEPT_CYCLE", "CHECK_FAIL",
                    "UNANCHORED_VARIABLE", "DECLARATION_MISMATCH", "UNCLAIMED_ATOM", "UNUSED_CLAIM", "BARE_LITERAL",
                    "WITNESS_FAIL", "SUPERSESSION_NO_DIFF", "DUPLICATE_CONCEPT", "VACUOUS", "GATE_TIMEOUT", "OK"]
ALLOWED_CONCEPT_IMPORTS = {"TrafficSpec.Core.Language.Concept"}
PUNIT_JSON = {"metre": "metre", "second": "second", "metrePerSecond": "metre_per_second", "metrePerSecondSq": "metre_per_second_sq",
              "degree": "degree", "degreePerSecond": "degree_per_second", "ratio": "ratio", "count": "count"}


def _concept_harness_source(cid: str, reading_json_path: Path) -> str:
    ns, wns = nodeid.concept_namespace(cid), nodeid.concept_witness_namespace(cid)
    return f'''import TrafficSpec
import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import {nodeid.concept_module(cid)}
import {nodeid.concept_witness_module(cid)}
open TrafficSpec Lean
#print axioms {ns}.concept
#print axioms {wns}.instances
#print axioms {wns}.scenarios
{_OCC_DEFS}
def main : IO Unit := do
  let c := {ns}.concept
  let cs := (allConcepts.filter (·.id != c.id)) ++ [c]
  let insts := {wns}.instances
  let scs := {wns}.scenarios
  let text ← IO.FS.readFile {json.dumps(str(reading_json_path.resolve()))}
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; pure ({{}} : Reading)
  IO.println s!"DECL\\t{{(Concept.toJson c).compress}}"
  IO.println s!"ATOMS\\t{{String.intercalate "," c.atoms}}"
  IO.println s!"READS\\t{{String.intercalate "," (Formula.atoms (Concept.expand cs c.bodyFormula)).eraseDups}}"
  let bodyJson := match c.body with
    | .formula φ => (Formula.toJson (Concept.expand cs φ)).compress
    | .quantity t => (Term.toJson (Concept.expandTerm cs t)).compress
  IO.println s!"BODY\\t{{bodyJson}}"
  for g in occF c.bodyFormula do IO.println s!"OCC\\t{{String.intercalate "," g}}"
  for (q, u) in Formula.literals c.bodyFormula do IO.println s!"LITERAL\\t{{q.num}}/{{q.den}}\\t{{repr u}}"
  for id in Concept.onCycle cs do IO.println s!"CYCLE\\t{{id}}"
  for e in Concept.check cs c do IO.println s!"CHECK\\t{{e}}"
  let instRules := insts.filterMap (Concept.asRule cs)
  let rules := allRules ++ instRules
  for i in insts do
    match Concept.asRule cs i with
    | none => IO.println s!"INST\\t{{i.name}}\\tunfilled"
    | some r =>
      IO.println s!"INST\\t{{i.name}}\\tok"
      for e in Rule.check (rules.map (Concept.expandRule cs)) (Concept.expandRule cs r) do IO.println s!"CHECK\\t{{e}}"
  let scs' := scs.map fun sc => {{ sc with reading := ρ }}
  for sc in scs' do
    match sc.run rules cs with
    | .ok v => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.rule}}\\t{{sc.expected.tag}}\\t{{v.tag}}\\tok"
    | .error e => IO.println s!"SCEN\\t{{sc.name}}\\t{{sc.rule}}\\t{{sc.expected.tag}}\\t?\\t{{e}}"
  for r in instRules do
    for u in Adequacy.unexercised rules r (scs'.filter (·.rule == r.id)) cs do IO.println s!"ADEQ\\t{{r.id}}: {{u}}"
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
  IO.println "DONE"
'''


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

    # 1. scope
    now = repo_digest()
    changed = {p for p in (set(now) | set(baseline)) - GENERATED if now.get(p) != baseline.get(p)}
    stray = sorted(changed - {lib_rel(c_rel), lib_rel(w_rel)} - task_concurrent(work))
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

    # 2. build, and 3. the harness run, under the library lock
    only_nodes, only_concepts = task_registry(work)
    with lean.library_lock(lib):
        index_sync.write_index(only_nodes=only_nodes, only_concepts=None if only_concepts is None else sorted(set(only_concepts) | {cid}))
        try:
            ok, out = lean.lake_build(lib, ["TrafficSpec.Index", nodeid.concept_module(cid), nodeid.concept_witness_module(cid)])
        except lean.LeanUnavailable as e:
            return Verdict(INFRA, [str(e)])
        (work / "build.log").write_text(out, encoding="utf-8")
        if lean.timed_out(out):
            return Verdict(INFRA, [out.splitlines()[0]])
        if not ok:
            return Verdict("BUILD_FAIL", lean.errors(out)[:8])
        details += forbidden_tokens((("concept", ctext), ("witness", wtext)))
        if lean.sorry_warnings(out):
            details.append("build reports a declaration that uses sorry")
        harness = work / "gate_harness.lean"
        reading_json = work / "reading.json"
        reading_json.write_text(reading.lean_json(), encoding="utf-8")
        harness.write_text(_concept_harness_source(cid, reading_json), encoding="utf-8")
        try:
            ok, hout = lean.lean_run(lib, harness)
        except lean.LeanUnavailable as e:
            return Verdict(INFRA, [str(e)])
    (work / "gate_harness.out").write_text(hout, encoding="utf-8")
    for m in re.finditer(r"depends on axioms: \[([^\]]*)\]", hout):
        axioms = {a.strip() for a in m.group(1).split(",") if a.strip()}
        if axioms - STANDARD_AXIOMS:
            details.append(f"non-standard axioms: {sorted(axioms - STANDARD_AXIOMS)}")
    if details:
        return Verdict("UNSOUND", details)
    if not ok or "DONE" not in hout:
        return harness_failure(hout)
    rows = [l.split("\t") for l in hout.splitlines() if "\t" in l]
    def col(tag: str) -> list[list[str]]:
        return [r[1:] for r in rows if r[0] == tag]

    # 4. cycle, static check
    cyc = [r[0] for r in col("CYCLE")]
    if cyc:
        return Verdict("CONCEPT_CYCLE", cyc)
    checks = [r[0] for r in col("CHECK")] + [r[0] for r in col("READING")]
    checks += divisions_by_measure(json.loads(col("BODY")[0][0])) if col("BODY") else []
    if checks:
        return Verdict("CHECK_FAIL", checks)

    # 4b. anchoring within the body: quantified variables reach a track formal
    tracks = [a["name"] for a in rec.args() if a.get("sort") == "track"]
    if tracks:
        unanchored = unanchored_variables([row[0].split(",") if row and row[0] else [] for row in col("OCC")], tracks)
        if unanchored:
            return Verdict("UNANCHORED_VARIABLE", [f"`{v}` is related to no track formal of the concept" for v in unanchored])

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
    exp_params = [(p["name"], PUNIT_JSON[units.FACTORS[p["unit"]][0]]) for p in rec.params()]
    got_params = [(p["name"], p["unit"]) for p in decl["params"]]
    if got_params != exp_params: mism.append(f"params {got_params} ≠ {exp_params}")
    rec_res = [r.get("why", "") for r in rec.get("residues", [])]
    missing_res = [w for w in rec_res if w not in decl["residues"]]
    if missing_res: mism.append(f"residues of the record missing from the concept: {missing_res[:3]}")
    added_res = [w for w in decl["residues"] if w not in rec_res]
    if added_res: mism.append(f"residues added to the concept: {added_res[:3]}; a residue is the record's — a reading you chose that the contract leaves open is a narrowing ⟨words of the contract, why⟩")
    contract_ws = ws(rec.get("contract"))
    narrowings = [n for n in decl.get("narrowings", []) if isinstance(n, dict)]
    for n in narrowings:
        if not ws(n.get("span")) or ws(n.get("span")) not in contract_ws: mism.append(f"narrowing on `{str(n.get('span', ''))[:60]}`, which is not a run of the contract's words")
        elif not str(n.get("why", "")).strip(): mism.append(f"narrowing on `{str(n.get('span'))[:60]}` states no why")
    if (decl.get("supersedes") or None) != (rec.get("supersedes") or None): mism.append("supersedes differs from the record")
    if mism:
        return Verdict("DECLARATION_MISMATCH", mism)

    # 6. claims and literals
    used = {a for a in col("ATOMS")[0][0].split(",") if a}
    claimed = rec.claimed_names() | {r.replace(".", "_") for r in rec.refs()}
    def canon(n: str) -> str:
        for cl in sorted(claimed, key=len, reverse=True):
            if n == cl or n.startswith(cl + "_"):
                return cl
        return n
    unclaimed = sorted({n for n in used if canon(n) not in claimed and n not in FREE_USES})
    if unclaimed:
        return Verdict("UNCLAIMED_ATOM", unclaimed)
    used_via = {canon(n) for n in reads_of_used(used, accepted)}
    unused = sorted(cl for cl in claimed if not any(canon(n) == cl for n in used) and cl not in used_via)
    if unused:
        return Verdict("UNUSED_CLAIM", unused)
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

    # 7. witnesses
    fails = [f"instance {name}: a formal is unfilled" for name, status in col("INST") if status != "ok"]
    scen = col("SCEN")
    wanted = dict(CONCEPT_SCENARIOS)
    if rec.get("supersedes"):
        wanted["counterexample"] = normalize_verdict((rec.get("counterexample") or {}).get("expected", "violated"))
    for name, _rule, expected, got, status in scen:
        if status != "ok":
            fails.append(f"{name}: {status}")
        elif expected != got:
            fails.append(f"{name}: expected {expected}, got {got}")
        elif name in wanted and expected != wanted[name]:
            fails.append(f"{name}: the witness declares {expected}, the record requires {wanted[name]}")
    for name in wanted:
        if name not in {s[0] for s in scen}:
            fails.append(f"{name}: no witness of that name")
    if fails:
        return Verdict("WITNESS_FAIL", fails)

    # 7b. a supersession differs from the old body on its counterexample
    if rec.get("supersedes"):
        diffs = col("DIFF")
        if col("OLD") or not diffs or any(d[1] != "differs" for d in diffs):
            return Verdict("SUPERSESSION_NO_DIFF", [f"the old body gives the same verdict on the counterexample ({diffs})" if diffs else "no counterexample ran against the old body"])

    # 8. duplicates of the catalogue, by alpha-equivalence of the expanded body
    body_json = json.loads(col("BODY")[0][0])
    canonical = render_formula.canonical(body_json, [a["name"] for a in rec.args()], [p["name"] for p in rec.params()])
    for oid, orec in accepted.items():
        if oid != rec.get("supersedes") and orec.get("canonical_body") == canonical:
            return Verdict("DUPLICATE_CONCEPT", [f"the body is alpha-equivalent to accepted `{oid}`: call it instead"])

    # 9. adequacy
    adeq = [r[0] for r in col("ADEQ")]
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
