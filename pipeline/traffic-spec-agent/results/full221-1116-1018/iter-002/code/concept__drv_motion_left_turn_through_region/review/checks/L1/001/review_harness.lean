import TrafficSpec.Core
import TrafficSpec.Concepts.lane.heading_right_of_carrier
import TrafficSpec.Concepts.motion.left_turn_through_region
import TrafficSpec.Concepts.motion.moving_across_carrier
import TrafficSpec.Concepts.motion.moving_against_carrier
import TrafficSpec.Concepts.motion.moving_backward
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Concepts.motion.u_turn_through_region
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Concepts.motion.left_turn_through_region
namespace TrafficSpec
def allRules : List Rule := []
def allConcepts : List Concept := [
  TrafficSpec.Concepts.lane.heading_right_of_carrier.concept,
  TrafficSpec.Concepts.motion.left_turn_through_region.concept,
  TrafficSpec.Concepts.motion.moving_across_carrier.concept,
  TrafficSpec.Concepts.motion.moving_against_carrier.concept,
  TrafficSpec.Concepts.motion.moving_backward.concept,
  TrafficSpec.Concepts.motion.u_turn.concept,
  TrafficSpec.Concepts.motion.u_turn_through_region.concept
]
end TrafficSpec
open TrafficSpec Lean
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

def main : IO Unit := do
  let c := TrafficSpec.Concepts.motion.left_turn_through_region.concept
  let cs := (allConcepts.filter (·.id != c.id)) ++ [c]
  let ρ : Reading ← match Decode.parse Decode.reading (← IO.FS.readFile "/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-002/code/concept__drv_motion_left_turn_through_region/review/checks/L1/001/reading.json") with | .ok v => pure v | .error e => throw (IO.userError s!"reading: {e}")
  let items : List (Nat × String × List (String × Nat) × List (String × Nat) × List (String × String) × List (String × Nat) × List (String × TrafficSpec.Term) × Option (TrafficSpec.Term × TrafficSpec.Term) × Int) := [(1, "/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-002/code/concept__drv_motion_left_turn_through_region/review/checks/L1/001/disagreement_1.json", [("a", 1)], [("r", 10)], [], [], [("step", (.lit (Q.mk' (1) 1) .second : TrafficSpec.Term)), ("turn_min", (.lit (Q.mk' (45) 1) .degree : TrafficSpec.Term)), ("u_turn_min", (.lit (Q.mk' (135) 1) .degree : TrafficSpec.Term))], none, (2000 : Int))]
  for (k, path, grounding, regs, lits, nats, ps, bd, atT) in items do
    let inst : Concept.Instance := { name := s!"review_{k}", concept := c.id, literals := lits, nats := nats, params := ps, bounds := bd }
    match Concept.asRule cs inst with
    | none => IO.println s!"DIS\t{k}\tunfilled\t"
    | some r =>
      let r' := Concept.expandRule cs r
      let text ← IO.FS.readFile path
      match Decode.parse Decode.trace text with
      | .error e => IO.println s!"DIS\t{k}\tdecode\t{e}"
      | .ok τ0 =>
        let τ := TraceLint.completeOccupancy τ0
        let m := Manifest.full "review"
        let admitted := Grounding.Setup.admit [r'] (maskTrace m τ) ρ m.reidGap
        let refused := (match admitted with | .error ds => ds | .ok _ => []) ++
          regs.filterMap fun (n, reg) => if τ.any (fun s => (s.structure? reg).isSome) then none
            else some s!"region formal `{n}` is region {reg}, which is no structure of the trace"
        IO.println s!"LINT\t{k}\t{(Json.arr ((TraceLint.checkTrace τ ++ refused).map Json.str).toArray).compress}"
        RelCheck.run (toString k) τ
        for s in τ do
          IO.println s!"OCCD\t{k}\t{s.t}\t{String.intercalate "," (s.occupies.map fun p => s!"{p.1}-{p.2}")}"
        match admitted, refused with
        | .error _, _ | _, _ :: _ => IO.println s!"DIS\t{k}\tlint\t"
        | .ok S, [] =>
          let g : Grounding.Grounding := { assign := grounding.map (fun (n, t) => (n, Grounding.canon S.cm t)), regions := regs }
          let tl := Grounding.evaluate S r' g
          let mut found : Option (Nat × Verdict) := none
          for j in [0:tl.verdicts.size] do
            if tl.verdicts[j]!.1 == atT then found := some (j, tl.verdicts[j]!.2)
          match found with
          | none => IO.println s!"DIS\t{k}\tat_missing\t"
          | some (j, v) =>
            IO.println s!"DIS\t{k}\t{v.tag}\t{String.intercalate "," (v.reasons.map UnknownReason.tag)}"
            match r'.obligation with
            | .and (.cmp _ _ value) _ =>
              match (Semantics.evalTAll (S.ctx g.binding) value)[j]? with
              | some (.ok q) => IO.println s!"VAL\t{k}\t{q.num}/{q.den}"
              | some (.error e) => IO.println s!"VAL\t{k}\tunknown:{e.tag}"
              | none => IO.println s!"VAL\t{k}\tmissing"
            | _ => pure ()
