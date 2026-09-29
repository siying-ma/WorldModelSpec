"""The gate (design §5): the only acceptance authority for a node, run by the harness itself."""
from __future__ import annotations
import hashlib
import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from . import paths, nodeid, lean, index_sync
from .blueprint import Node, SCENARIOS
from .reading import Reading

VERDICTS = ["SCOPE_VIOLATION", "BUILD_FAIL", "UNSOUND", "CHECK_FAIL", "UNANCHORED_VARIABLE", "DECLARATION_MISMATCH",
            "UNCLAIMED_ATOM", "UNUSED_CLAIM", "BARE_LITERAL", "WITNESS_FAIL", "VACUOUS", "OK"]
FORBIDDEN_TOKENS = ["sorry", "admit", "axiom", "unsafe", "partial", "opaque", "implemented_by", "extern", "native_decide", "panic!"]
STANDARD_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
ALLOWED_RULE_IMPORTS = {"TrafficSpec.Core.Rule"}
ALLOWED_WITNESS_IMPORTS_EXTRA = {"TrafficSpec.Core.Builders"}
GENERATED = {"TrafficSpec/Index.lean", "TrafficSpecWitness.lean"}   # written by index_sync, never by a session


@dataclass
class Verdict:
    verdict: str
    details: list[str] = field(default_factory=list)
    report: str = ""
    extras: dict = field(default_factory=dict)    # what an OK carries back: residues the coder added

    def to_dict(self) -> dict:
        return {"verdict": self.verdict, "details": self.details, **({"extras": self.extras} if self.extras else {})}


def library_digest(root: Path) -> dict[str, str]:
    out = {}
    for p in root.rglob("*.lean"):
        rel = str(p.relative_to(root))
        if ".lake" in p.parts or rel in GENERATED:
            continue
        out[rel] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out


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
import TrafficSpec.Core.Adequacy
import TrafficSpec.Core.Decode
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
    ("residues", Json.arr (r.residues.map Json.str).toArray), ("surrogate", r.surrogate)]
  IO.println s!"DECL\\t{{decl.compress}}"
  IO.println s!"ATOMS\\t{{String.intercalate "," r.atoms}}"
  IO.println s!"COMPOSES\\t{{String.intercalate "," r.composes}}"
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


def run_gate(node: Node, reading: Reading, baseline: dict[str, str], work: Path, budget_used: int, budget: int) -> Verdict:
    """The gate for one node. `work` is the node's task directory (harness file, reports)."""
    work.mkdir(parents=True, exist_ok=True)
    lib = paths.LIBRARY
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    rule_file, wit_file = lib / rule_rel, lib / wit_rel
    details: list[str] = []

    if budget_used >= budget:
        return Verdict("BUDGET_EXHAUSTED", [f"{budget} gate runs used"])

    # 1. scope (the registries are regenerated first so the build below sees every node on disk)
    index_sync.write_index()
    now = library_digest(lib)
    changed = {p for p in (set(now) | set(baseline)) - GENERATED if now.get(p) != baseline.get(p)}
    stray = sorted(changed - {rule_rel, wit_rel})
    if stray:
        return Verdict("SCOPE_VIOLATION", [f"changed outside the node's files: {stray[:5]}"])
    if not rule_file.exists() or not wit_file.exists():
        return Verdict("SCOPE_VIOLATION", [f"missing {rule_rel if not rule_file.exists() else wit_rel}"])
    rtext, wtext = rule_file.read_text(encoding="utf-8"), wit_file.read_text(encoding="utf-8")
    bad_imports = (_imports(rtext) - ALLOWED_RULE_IMPORTS) | (_imports(wtext) - ALLOWED_WITNESS_IMPORTS_EXTRA - {nodeid.rule_module(node.id)})
    if bad_imports:
        return Verdict("SCOPE_VIOLATION", [f"imports not allowed: {sorted(bad_imports)}"])
    if f"namespace {nodeid.rule_namespace(node.id)}" not in rtext or f"namespace {nodeid.witness_namespace(node.id)}" not in wtext:
        return Verdict("SCOPE_VIOLATION", ["namespace must be derived from the node id"])

    # 2. build
    ok, out = lean.lake_build(lib, ["TrafficSpec.Index", nodeid.rule_module(node.id), nodeid.witness_module(node.id)])
    (work / "build.log").write_text(out, encoding="utf-8")
    if not ok:
        return Verdict("BUILD_FAIL", lean.errors(out)[:8])

    # 3. sound
    for tok in FORBIDDEN_TOKENS:
        for name, text in (("rule", rtext), ("witness", wtext)):
            if re.search(r"(?<![A-Za-z_.])" + re.escape(tok) + r"(?![A-Za-z_])", text):
                details.append(f"{name} file contains `{tok}`")
    if lean.sorry_warnings(out):
        details.append("build reports a declaration that uses sorry")
    harness = work / "gate_harness.lean"
    reading_json = work / "reading.json"
    reading_json.write_text(reading.lean_json(), encoding="utf-8")
    harness.write_text(_harness_source(node.id, reading_json), encoding="utf-8")
    ok, hout = lean.lean_run(lib, harness)
    (work / "gate_harness.out").write_text(hout, encoding="utf-8")
    for m in re.finditer(r"depends on axioms: \[([^\]]*)\]", hout):
        axioms = {a.strip() for a in m.group(1).split(",") if a.strip()}
        if axioms - STANDARD_AXIOMS:
            details.append(f"non-standard axioms: {sorted(axioms - STANDARD_AXIOMS)}")
    if details:
        return Verdict("UNSOUND", details)
    if not ok or "DONE" not in hout:
        return Verdict("BUILD_FAIL", ["gate harness did not run"] + lean.errors(hout)[:8])

    rows = [l.split("\t") for l in hout.splitlines() if "\t" in l]
    def col(tag: str) -> list[list[str]]:
        return [r[1:] for r in rows if r[0] == tag]

    # 4. static check
    checks = [r[0] for r in col("CHECK")] + [r[0] for r in col("READING")]
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
    from .blueprint import concepts_of
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
    added_residues = [w for w in decl["residues"] if w not in node_residues]
    exp_surrogate = any(o.get("surrogate") for o in node.get("operationalizations", []))
    if bool(decl["surrogate"]) != exp_surrogate: mism.append(f"surrogate {decl['surrogate']} ≠ {exp_surrogate}")
    if mism:
        return Verdict("DECLARATION_MISMATCH", mism)

    # 6. claims and literals
    used = {a for a in col("ATOMS")[0][0].split(",") if a}
    claimed = node.claimed_names()
    def canon(n: str) -> str:   # accessor → its atom's Lean name, so `dev_traffic_signal_shows` matches the claim `dev.traffic_signal`
        for c in sorted(claimed, key=len, reverse=True):
            if n == c or n.startswith(c + "_"):
                return c
        return n
    unclaimed = sorted({n for n in used if canon(n) not in claimed})
    if unclaimed:
        return Verdict("UNCLAIMED_ATOM", unclaimed)
    unused = sorted(c for c in claimed if not any(canon(n) == c for n in used))
    if unused:
        return Verdict("UNUSED_CLAIM", unused)
    from fractions import Fraction
    from . import units
    used_lits = sorted((Fraction(q), u.split(".")[-1].strip()) for q, u in col("LITERAL"))
    declared = []
    for lit in node.literals():
        try:
            core, v = units.to_core(lit.get("value"), lit.get("unit", ""))
            declared.append((v, core))
        except (KeyError, ValueError):
            return Verdict("BARE_LITERAL", [f"declared literal {lit} has an unknown unit"])
    declared = sorted(declared)
    if used_lits != declared:
        return Verdict("BARE_LITERAL", [f"formula literals {[(str(q), u) for q, u in used_lits]} ≠ the node's declared literals {[(str(q), u) for q, u in declared]}; a figure the law states is declared on its span, any other magnitude belongs in the reading"])

    # 7. witnesses
    scen = col("SCEN")
    planned = {s["name"]: s for s in node.get("scenarios", [])}
    fails = []
    for name, expected, got, status in scen:
        if status != "ok":
            fails.append(f"{name}: {status}")
        elif expected != got:
            fails.append(f"{name}: expected {expected}, got {got}")
        elif name in planned and SCENARIOS.get(name) and expected != SCENARIOS[name]:
            fails.append(f"{name}: the witness declares {expected}, the plan requires {SCENARIOS[name]}")
    for name in SCENARIOS:
        if name not in {s[0] for s in scen}:
            fails.append(f"{name}: no witness of that name")
    if fails:
        return Verdict("WITNESS_FAIL", fails)

    # 8. adequacy
    adeq = [r[0] for r in col("ADEQ")]
    if adeq:
        return Verdict("VACUOUS", adeq)
    return Verdict("OK", [f"{len(scen)} witnesses, {len(used)} names, composes {col('COMPOSES')[0][0] or 'nothing'}"]
                   + ([f"residues added by the coder: {len(added_residues)}"] if added_residues else []),
                   extras={"residues_added": added_residues} if added_residues else {})


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
                    "WITNESS_FAIL", "SUPERSESSION_NO_DIFF", "DUPLICATE_CONCEPT", "VACUOUS", "OK"]
ALLOWED_CONCEPT_IMPORTS = {"TrafficSpec.Core.Concept"}
PUNIT_JSON = {"metre": "metre", "second": "second", "metrePerSecond": "metre_per_second", "metrePerSecondSq": "metre_per_second_sq",
              "degree": "degree", "degreePerSecond": "degree_per_second", "ratio": "ratio", "count": "count"}


def _concept_harness_source(cid: str, reading_json_path: Path) -> str:
    ns, wns = nodeid.concept_namespace(cid), nodeid.concept_witness_namespace(cid)
    return f'''import TrafficSpec
import TrafficSpec.Core.Adequacy
import TrafficSpec.Core.Decode
import TrafficSpec.Core.Export
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
    from .blueprint import CONCEPT_SCENARIOS
    from . import surface, render_formula, units
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
    index_sync.write_index()
    now = library_digest(lib)
    changed = {p for p in (set(now) | set(baseline)) - GENERATED if now.get(p) != baseline.get(p)}
    stray = sorted(changed - {c_rel, w_rel})
    if stray:
        return Verdict("SCOPE_VIOLATION", [f"changed outside the concept's files: {stray[:5]}"])
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

    # 2. build
    ok, out = lean.lake_build(lib, ["TrafficSpec.Index", nodeid.concept_module(cid), nodeid.concept_witness_module(cid)])
    (work / "build.log").write_text(out, encoding="utf-8")
    if not ok:
        return Verdict("BUILD_FAIL", lean.errors(out)[:8])

    # 3. sound
    for tok in FORBIDDEN_TOKENS:
        for name, text in (("concept", ctext), ("witness", wtext)):
            if re.search(r"(?<![A-Za-z_.])" + re.escape(tok) + r"(?![A-Za-z_])", text):
                details.append(f"{name} file contains `{tok}`")
    if lean.sorry_warnings(out):
        details.append("build reports a declaration that uses sorry")
    harness = work / "gate_harness.lean"
    reading_json = work / "reading.json"
    reading_json.write_text(reading.lean_json(), encoding="utf-8")
    harness.write_text(_concept_harness_source(cid, reading_json), encoding="utf-8")
    ok, hout = lean.lean_run(lib, harness)
    (work / "gate_harness.out").write_text(hout, encoding="utf-8")
    for m in re.finditer(r"depends on axioms: \[([^\]]*)\]", hout):
        axioms = {a.strip() for a in m.group(1).split(",") if a.strip()}
        if axioms - STANDARD_AXIOMS:
            details.append(f"non-standard axioms: {sorted(axioms - STANDARD_AXIOMS)}")
    if details:
        return Verdict("UNSOUND", details)
    if not ok or "DONE" not in hout:
        return Verdict("BUILD_FAIL", ["gate harness did not run"] + lean.errors(hout)[:8])
    rows = [l.split("\t") for l in hout.splitlines() if "\t" in l]
    def col(tag: str) -> list[list[str]]:
        return [r[1:] for r in rows if r[0] == tag]

    # 4. cycle, static check
    cyc = [r[0] for r in col("CYCLE")]
    if cyc:
        return Verdict("CONCEPT_CYCLE", cyc)
    checks = [r[0] for r in col("CHECK")] + [r[0] for r in col("READING")]
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
    added_residues = [w for w in decl["residues"] if w not in rec_res]
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
    unclaimed = sorted({n for n in used if canon(n) not in claimed})
    if unclaimed:
        return Verdict("UNCLAIMED_ATOM", unclaimed)
    unused = sorted(cl for cl in claimed if not any(canon(n) == cl for n in used))
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
    if used_lits != sorted(declared):
        return Verdict("BARE_LITERAL", [f"body literals {[(str(q), u) for q, u in used_lits]} ≠ the record's declared literals {[(str(q), u) for q, u in sorted(declared)]}; a magnitude is a formal parameter unless the record declares it"])

    # 7. witnesses
    fails = [f"instance {name}: a formal is unfilled" for name, status in col("INST") if status != "ok"]
    scen = col("SCEN")
    wanted = dict(CONCEPT_SCENARIOS)
    if rec.get("supersedes"):
        from .blueprint import normalize_verdict
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
                   + ([f"residues added by the coder: {len(added_residues)}"] if added_residues else []),
                   extras={"reads": reads, "refs": refs, "canonical_body": canonical, "body_json": body_json,
                           **({"residues_added": added_residues} if added_residues else {})})
