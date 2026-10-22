/- Decode deduplicated evaluation inputs, restore their unchanged boundaries, then run the monitor.
   The producer verifies that the region inventory and boundaries are identical in every scene.
   Only the library copy used for this evaluation imports this executable; Core is unchanged.
   An optional region-geometry mask permits episode-only checks: a decided violation survives
   restoration of observations; an unknown episode is checked for a geometry-independent
   obligation that is never false and an unavoidable truncated startup window. This mode does
   not compute or certify a full-geometry timeline. -/
import TrafficSpec
import TrafficSpec.Core.Runtime.Decode

open TrafficSpec

def readEvaluationJson {α : Type} (dec : Lean.Json → Decode.D α) (path : String) : IO α := do
  let text ← IO.FS.readFile path
  match Decode.parse dec text with
  | .ok value => pure value
  | .error err => throw (IO.userError s!"{path}: {err}")

def main (args : List String) : IO UInt32 := do
  let certify := args.contains "--certify-without-region-geometry"
  let args := args.filter (· != "--certify-without-region-geometry")
  let (args, selected) := if args.length == 5 then
    (args.take 4, some (args[4]!.splitOn ",")) else (args, none)
  let [manifestPath, readingPath, tracePath, boundaryPath] := args
    | do IO.eprintln "expected manifest reading trace boundaries [rule,rule,...]"; return (2 : UInt32)
  try
    let observedManifest ← readEvaluationJson Decode.manifest manifestPath
    let manifest := if certify then
      { observedManifest with entries := observedManifest.entries.map fun (id, cap) =>
          (id, if id == "st.region_geometry" then .absent else cap) }
      else observedManifest
    if !manifest.complete then throw (IO.userError "incomplete manifest")
    let reading ← readEvaluationJson Decode.reading readingPath
    let trace ← readEvaluationJson Decode.trace tracePath
    let maps ← readEvaluationJson Decode.trace boundaryPath
    let [base] := maps | throw (IO.userError "expected one boundary dictionary scene")
    let restored ← trace.mapM fun scene => do
      if scene.structures.length != base.structures.length then
        throw (IO.userError "region inventory differs from boundary dictionary")
      let structures ← scene.structures.mapM fun region => do
        let some original := base.structures.find? (·.id == region.id)
          | throw (IO.userError "region absent from boundary dictionary")
        if original.kind != region.kind || region.boundary.isSome then
          throw (IO.userError "invalid deduplicated region")
        pure { region with boundary := original.boundary }
      pure { scene with structures := structures }
    let rules := match selected with
      | none => allRules
      | some ids => allRules.filter fun rule => ids.contains rule.id
    if rules.isEmpty then throw (IO.userError "no selected rule is registered")
    let report := Monitor.check rules restored reading manifest allConcepts
    IO.print (Monitor.renderJsonLines report)
    if certify then
      let expanded := rules.map (Concept.expandRule allConcepts)
      let setup := Grounding.Setup.mk' expanded (maskTrace manifest restored) reading manifest.reidGap
      for row in report.rows do
        let some rule := expanded.find? (·.id == row.rule)
          | throw (IO.userError "missing expanded rule")
        let verdict := row.episode
        let method ← if verdict == .violated then pure "violation_with_geometry_withheld"
          else do
            if (formulaAtomIds [rule.obligation]).contains "st.region_geometry" then
              throw (IO.userError "cannot certify a geometry-dependent obligation")
            let obligation := Rule.evalRuleFormula (setup.ctx row.grounding.binding) rule.obligation
            if obligation.any (·.v == .f) then
              throw (IO.userError "a violation remains possible when geometry is restored")
            let initial := row.timeline[0]?.map Prod.snd
            if !(initial.map fun v => v.reasons.any (·.tag == "window_truncated:holdsFor")).getD false then
              throw (IO.userError "no unavoidable startup unknown was established")
            if !(match verdict with | .unknown _ => true | _ => false) then
              throw (IO.userError "expected an unknown episode")
            pure "geometry_independent_obligation_never_false_and_startup_window_unknown"
        IO.println (Lean.Json.mkObj [
          ("kind", Lean.toJson "episode_certificate"), ("rule", Lean.toJson row.rule),
          ("episode", Lean.toJson verdict.tag), ("method", Lean.toJson method),
          ("withheld", Lean.toJson "st.region_geometry"),
          ("scope", Lean.toJson "episode only; not a full-geometry timeline")]).compress
    return (0 : UInt32)
  catch err =>
    IO.eprintln s!"evaluation: {err}"
    return (2 : UInt32)
