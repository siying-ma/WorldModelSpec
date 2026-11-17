import TrafficSpec.Core
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_1c
import TrafficSpec.Concepts.interaction.overtake_pass
import TrafficSpec.Concepts.lane.entering_adjacent_lane
import TrafficSpec.Concepts.lane.heading_right_of_carrier
import TrafficSpec.Concepts.motion.circulating_clockwise_about
import TrafficSpec.Concepts.motion.complete_halt
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Concepts.motion.left_turn_through_region
import TrafficSpec.Concepts.motion.moving_across_carrier
import TrafficSpec.Concepts.motion.moving_against_carrier
import TrafficSpec.Concepts.motion.moving_backward
import TrafficSpec.Concepts.motion.parked
import TrafficSpec.Concepts.motion.right_turn_through_region
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Concepts.motion.u_turn_through_region
import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_1c
import TrafficSpecWitness.NRS_484B.NRS_484B_267_1c
namespace TrafficSpec
def allRules : List Rule := [
  TrafficSpec.Rules.NRS_484B_267_1c.rule
]
def allConcepts : List Concept := [
  TrafficSpec.Concepts.interaction.overtake_pass.concept,
  TrafficSpec.Concepts.lane.entering_adjacent_lane.concept,
  TrafficSpec.Concepts.lane.heading_right_of_carrier.concept,
  TrafficSpec.Concepts.motion.circulating_clockwise_about.concept,
  TrafficSpec.Concepts.motion.complete_halt.concept,
  TrafficSpec.Concepts.motion.left_turn.concept,
  TrafficSpec.Concepts.motion.left_turn_through_region.concept,
  TrafficSpec.Concepts.motion.moving_across_carrier.concept,
  TrafficSpec.Concepts.motion.moving_against_carrier.concept,
  TrafficSpec.Concepts.motion.moving_backward.concept,
  TrafficSpec.Concepts.motion.parked.concept,
  TrafficSpec.Concepts.motion.right_turn_through_region.concept,
  TrafficSpec.Concepts.motion.u_turn.concept,
  TrafficSpec.Concepts.motion.u_turn_through_region.concept
]
end TrafficSpec
open TrafficSpec Lean
#print axioms TrafficSpec.Rules.NRS_484B_267_1c.rule
#print axioms TrafficSpecWitness.NRS_484B_267_1c.scenarios
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

/-- A witness held as the gate holds it: Core's `Scenario.run`, and a `blind` witness Core refuses
    admitted only where its mask is the cause: unknown for masked atoms and windows truncated at the
    trace start, and decided on the same trace with nothing masked. -/
def witnessRun (rules : List TrafficSpec.Rule) (sc : TrafficSpec.Scenario) (cs : List TrafficSpec.Concept) :
    Except String TrafficSpec.Verdict :=
  match sc.run rules cs with
  | .ok v => .ok v
  | .error e =>
    if sc.name != "blind" || !sc.boundary.isEmpty || sc.manifest.absentIds.isEmpty then .error e
    else match ({ sc with boundary := "the masked observations" } : TrafficSpec.Scenario).run rules cs with
      | .error _ => .error e
      | .ok v =>
        let full : TrafficSpec.Scenario := { sc with manifest := TrafficSpec.Build.manifest [] sc.manifest.reidGap }
        let decides := fun (x : TrafficSpec.Verdict) =>
          match ({ full with expected := x } : TrafficSpec.Scenario).run rules cs with
          | .ok _ => true
          | .error _ => false
        if decides .compliant || decides .violated then .ok v
        else .error s!"{e}; with nothing masked the same trace is unknown too, so the mask does not explain the history it lacks"

def main (args : List String) : IO Unit := do
  if !args.isEmpty && args != ["adequacy"] then throw (IO.userError s!"unknown phase {args}")
  let out ← IO.getStdout
  let tMain ← IO.monoMsNow
  let r := TrafficSpec.Rules.NRS_484B_267_1c.rule
  let scs := TrafficSpecWitness.NRS_484B_267_1c.scenarios
  let rules := (allRules.filter (·.id != r.id)) ++ [r]
  let text ← IO.FS.readFile "/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-002/code/NRS_484B_267_1c/reading.json"
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\t{e}"; pure ({} : Reading)
  let scs' := scs.map fun sc => { sc with reading := ρ }
  if args == ["adequacy"] then
    IO.println s!"ADEQ_SIZE\t{r.id}\t{r.applicability.leafCount + r.obligation.leafCount}\t{(scs'.filter (·.expected.tag != "unknown")).length}"
    let tAdq ← IO.monoMsNow
    IO.println s!"TIME\tadequacy_start\t{tAdq - tMain}"
    out.flush
    for u in Adequacy.unexercised rules r scs' allConcepts do IO.println s!"ADEQ\t{u}"; out.flush
    IO.println s!"TIME\tadequacy\t{(← IO.monoMsNow) - tAdq}"
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
  IO.println s!"DECL\t{decl.compress}"
  IO.println s!"RULEJSON\t{(Rule.toJson r).compress}"
  IO.println s!"RULEXJSON\t{(Rule.toJson (Concept.expandRule allConcepts r)).compress}"
  out.flush
  IO.println s!"ATOMS\t{String.intercalate "," r.atoms}"
  IO.println s!"COMPOSES\t{String.intercalate "," r.composes}"
  IO.println s!"AGGREGATES\t{String.intercalate "\t" (Concept.ruleAggregateIds allConcepts r)}"
  for sc in scs do IO.println s!"MANIFEST\t{sc.name}\t{String.intercalate "," sc.manifest.absentIds}"
  for sc in scs do if !sc.boundary.isEmpty then IO.println s!"BOUNDARY\t{sc.name}"
  let tOcc ← IO.monoMsNow
  for g in (r.binders.flatMap fun b => occF b.cls) ++ occF r.applicability ++ occF r.obligation do
    IO.println s!"OCC\t{String.intercalate "," g}"
  for (q, u) in r.formulas.flatMap Formula.literals do IO.println s!"LITERAL\t{q.num}/{q.den}\t{repr u}"
  IO.println s!"TIME\toccurrences\t{(← IO.monoMsNow) - tOcc}"
  out.flush
  let tChk ← IO.monoMsNow
  let rulesX := rules.map (Concept.expandRule allConcepts)
  for e in Rule.check rulesX (Concept.expandRule allConcepts r) do IO.println s!"CHECK\t{e}"
  for e in Concept.ruleCallDefects allConcepts r do IO.println s!"CHECK\t{e}"
  for e in Rule.checkReading rules r ρ allConcepts do IO.println s!"READING\t{e}"
  for e in DimCheck.rule (DimCheck.envOf ρ allConcepts) r do IO.println s!"DIM\t{e.tag}\t{e.render}"
  IO.println s!"TIME\tchecks\t{(← IO.monoMsNow) - tChk}"
  out.flush
  let tLint ← IO.monoMsNow
  for sc in scs do
    let τ := TraceLint.completeOccupancy sc.trace
    for e in TraceLint.checkTrace τ do IO.println s!"REF\t{sc.name}\t{e}"
    RelCheck.run sc.name τ
    if let some (a, b) := sc.window then
      if !(sc.trace.any fun s => decide (a ≤ s.t) && decide (s.t ≤ b)) then IO.println s!"NOWINDOW\t{sc.name}"
  IO.println s!"TIME\tlint\t{(← IO.monoMsNow) - tLint}"
  out.flush
  let tWit ← IO.monoMsNow
  for sc in scs' do
    let tSc ← IO.monoMsNow
    match witnessRun rules sc allConcepts with
    | .ok v => IO.println s!"SCEN\t{sc.name}\t{sc.expected.tag}\t{v.tag}\tok"
    | .error e => IO.println s!"SCEN\t{sc.name}\t{sc.expected.tag}\t?\t{e}"
    out.flush
    IO.println s!"TIME\tscenario:{sc.name}\t{(← IO.monoMsNow) - tSc}"
    out.flush
  IO.println s!"TIME\twitnesses\t{(← IO.monoMsNow) - tWit}"
  out.flush
  IO.println "DONE_WITNESSES"
