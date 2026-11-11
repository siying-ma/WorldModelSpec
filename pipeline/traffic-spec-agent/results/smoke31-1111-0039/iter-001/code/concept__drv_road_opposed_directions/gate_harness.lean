import TrafficSpec.Core
import TrafficSpec.Concepts.road.opposed_directions
import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Concepts.road.opposed_directions
import TrafficSpecWitness.Concepts.road.opposed_directions
namespace TrafficSpec
def allRules : List Rule := []
def allConcepts : List Concept := [
  TrafficSpec.Concepts.road.opposed_directions.concept
]
end TrafficSpec
open TrafficSpec Lean
#print axioms TrafficSpec.Concepts.road.opposed_directions.concept
#print axioms TrafficSpecWitness.Concepts.road.opposed_directions.instances
#print axioms TrafficSpecWitness.Concepts.road.opposed_directions.scenarios
-- Variable connectivity: each atom, derived-concept or measure occurrence groups the variables it
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

namespace RelCheck
open TrafficSpec
def run (name : String) (τ : Trace) : IO Unit := do
  for s in τ do
    for m in s.relations do
      let cleared (f : MeasuredRelation → MeasuredRelation) : Scene :=
        { s with relations := s.relations.map fun x => if x.a == m.a && x.b == m.b then f x else x }
      if m.centreDistance.isSome && (rel_centre_distance (cleared fun x => { x with centreDistance := none }) m.a m.b).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_centre_distance: supplied, but Core computes it from the scene; remove it from the trace"
      if m.surfaceGap.isSome && (rel_surface_gap (cleared fun x => { x with surfaceGap := none }) m.a m.b).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_surface_gap: supplied, but Core computes it from the scene; remove it from the trace"
      if m.aAheadOfB.isSome && (rel_ahead_behind_in_lane (cleared fun x => { x with aAheadOfB := none }) m.a m.b).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_ahead_behind_in_lane: supplied, but Core computes it from the scene; remove it from the trace"
      if m.longitudinalOverlap.isSome && (rel_longitudinal_overlap (cleared fun x => { x with longitudinalOverlap := none }) m.a m.b).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_longitudinal_overlap: supplied, but Core computes it from the scene; remove it from the trace"
      if m.oncoming.isSome && (rel_oncoming (cleared fun x => { x with oncoming := none }) m.a m.b Q.zero).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_oncoming: supplied, but Core computes it from the scene; remove it from the trace"
      if m.sameDirection.isSome && (rel_same_direction (cleared fun x => { x with sameDirection := none }) m.a m.b Q.zero).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_same_direction: supplied, but Core computes it from the scene; remove it from the trace"
      if m.bearing.isSome && (rel_bearing (cleared fun x => { x with bearing := none }) m.a m.b).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_bearing: supplied, but Core computes it from the scene; remove it from the trace"
      if m.contact.isSome && (rel_contact (cleared fun x => { x with contact := none }) m.a m.b).isSome then
        IO.println s!"RELCHECK\t{name}\t{s.t}\t{m.a}-{m.b}\trel_contact: supplied, but Core computes it from the scene; remove it from the trace"
end RelCheck

def main (args : List String) : IO Unit := do
  if !args.isEmpty && args != ["adequacy"] then throw (IO.userError s!"unknown phase {args}")
  let out ← IO.getStdout
  let tMain ← IO.monoMsNow
  let c := TrafficSpec.Concepts.road.opposed_directions.concept
  let cs := (allConcepts.filter (·.id != c.id)) ++ [c]
  let insts := TrafficSpecWitness.Concepts.road.opposed_directions.instances
  let scs := TrafficSpecWitness.Concepts.road.opposed_directions.scenarios
  let text ← IO.FS.readFile "/local-scratch2/sma407/smoke31-run/pipeline/traffic-spec-agent/results/smoke31-1111-0039/iter-001/code/concept__drv_road_opposed_directions/reading.json"
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\t{e}"; pure ({} : Reading)
  let instRules := insts.filterMap (Concept.asRule cs)
  let rules := allRules ++ instRules
  let scs' := scs.map fun sc => { sc with reading := ρ }
  if args == ["adequacy"] then
    for r in instRules do
      IO.println s!"ADEQ_SIZE\t{r.id}\t{r.applicability.leafCount + r.obligation.leafCount}\t{(scs'.filter fun sc => sc.rule == r.id && sc.expected.tag != "unknown").length}"
    let tAdq ← IO.monoMsNow
    IO.println s!"TIME\tadequacy_start\t{tAdq - tMain}"
    out.flush
    for r in instRules do
      for u in Adequacy.unexercised rules r (scs'.filter (·.rule == r.id)) cs do IO.println s!"ADEQ\t{r.id}: {u}"; out.flush
    IO.println s!"TIME\tadequacy\t{(← IO.monoMsNow) - tAdq}"
    out.flush
    IO.println "DONE"
    return
  IO.println s!"DECL\t{(Concept.toJson c).compress}"
  IO.println s!"ATOMS\t{String.intercalate "," c.atoms}"
  IO.println s!"READS\t{String.intercalate "," (Formula.atoms (Concept.expand cs c.bodyFormula)).eraseDups}"
  IO.println s!"AGGREGATES\t{String.intercalate "\t" (Concept.aggregateIds cs c)}"
  IO.println s!"HARDAGG\t{String.intercalate "\t" (Formula.aggregateIds (Concept.expand cs c.bodyFormula)).eraseDups}"
  let bodyJson := match c.body with
    | .formula φ => (Formula.toJson (Concept.expand cs φ)).compress
    | .quantity t => (Term.toJson (Concept.expandTerm cs t)).compress
  IO.println s!"BODY\t{bodyJson}"
  for sc in scs do IO.println s!"WITNESS\t{sc.name}\t{sc.rule}"
  out.flush
  let tChk ← IO.monoMsNow
  for g in occF c.bodyFormula do IO.println s!"OCC\t{String.intercalate "," g}"
  for (q, u) in Formula.literals c.bodyFormula do IO.println s!"LITERAL\t{q.num}/{q.den}\t{repr u}"
  for id in Concept.onCycle cs do IO.println s!"CYCLE\t{id}"
  for e in Concept.check cs c do IO.println s!"CHECK\t{e}"
  for e in Concept.checkReading cs c ρ do IO.println s!"READING\t{e}"
  for e in DimCheck.concept (DimCheck.envOf ρ cs c.params) c do IO.println s!"DIM\t{e.tag}\t{e.render}"
  for i in insts do
    for e in Concept.Instance.defects cs i do IO.println s!"CHECK\t{e}"
    let regionFormals := ((cs.find? (·.id == i.concept)).map (·.regionFormals)).getD []
    match Concept.asRule cs i with
    | none => IO.println s!"INST\t{i.name}\tunfilled"
    | some r =>
      IO.println s!"INST\t{i.name}\tok"
      for e in Rule.check (rules.map (Concept.expandRule cs)) (Concept.expandRule cs r) regionFormals do IO.println s!"CHECK\t{e}"
    if let some ci := cs.find? (·.id == i.concept) then
      for sc in scs.filter (·.rule == i.name) do
        for e in Concept.regionDefects ci sc.name sc.regions do IO.println s!"CHECK\t{e}"
  IO.println s!"TIME\tchecks\t{(← IO.monoMsNow) - tChk}"
  out.flush
  for sc in scs do if !sc.boundary.isEmpty then IO.println s!"BOUNDARY\t{sc.name}"
  let tLint ← IO.monoMsNow
  for sc in scs' do
    let τ := TraceLint.completeOccupancy sc.trace
    for e in TraceLint.checkTrace τ do IO.println s!"REF\t{sc.name}\t{sc.rule}\t{e}"
    RelCheck.run sc.name τ
    if let some (a, b) := sc.window then
      if !(sc.trace.any fun s => decide (a ≤ s.t) && decide (s.t ≤ b)) then IO.println s!"NOWINDOW\t{sc.name}"
  IO.println s!"TIME\tlint\t{(← IO.monoMsNow) - tLint}"
  out.flush
  let tWit ← IO.monoMsNow
  for sc in scs' do
    let tSc ← IO.monoMsNow
    match sc.run rules cs with
    | .ok v => IO.println s!"SCEN\t{sc.name}\t{sc.rule}\t{sc.expected.tag}\t{v.tag}\tok"
    | .error e => IO.println s!"SCEN\t{sc.name}\t{sc.rule}\t{sc.expected.tag}\t?\t{e}"
    out.flush
    IO.println s!"TIME\tscenario:{sc.rule}/{sc.name}\t{(← IO.monoMsNow) - tSc}"
    out.flush
  IO.println s!"TIME\twitnesses\t{(← IO.monoMsNow) - tWit}"
  out.flush
  match c.supersedes with
  | none => pure ()
  | some old =>
    let csOld := allConcepts.filter (·.id != c.id)
    if !(csOld.any (·.id == old)) then IO.println s!"OLD\tmissing {old}"
    for i in insts do
      let iOld : Concept.Instance := { i with concept := old, name := i.name ++ "#old" }
      match Concept.asRule csOld iOld with
      | none => IO.println s!"DIFF\t{i.name}\tunfilled"
      | some rOld =>
        for sc in scs'.filter (fun sc => sc.rule == i.name && sc.name == "counterexample") do
          let scOld : Scenario := { sc with rule := rOld.id }
          let status := match scOld.run (allRules ++ [rOld]) csOld with | .ok _ => "same" | .error _ => "differs"
          IO.println s!"DIFF\t{i.name}\t{status}"
  IO.println "DONE_WITNESSES"
