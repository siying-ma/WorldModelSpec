import TrafficSpec.Core.Evidence.Builders
namespace TrafficSpec.Tests.HistoryBoundary
open TrafficSpec Units

-- A history-boundary witness stays unknown for a window truncated at the start of its trace, at
-- least once, and otherwise only for masked atoms; every other witness keeps needing a decided or
-- masked reason.
def V : Arg := .var "v"
def fast : Formula := .cmp (.measure "kin_speed" [V]) .gt (.lit (metresPerSecond 1) .metrePerSecond)
/-- The search runs back over observations east of x = 5 m and closes at the first one at or west of it. -/
def eastOf5 : Formula := .cmp (.measure "kin_position" [V, .lit "x"]) .gt (.lit (metres 5) .metre)
/-- "v has been slow at some observation since it was last at or west of x = 5 m". -/
def slowOnce : Rule :=
  { id := "t/slow_once", laws := [], binders := [{ name := "v", cls := .atom "ru_motor_vehicle" [V] [] }]
    applicability := .tt, obligation := .since eastOf5 (.not fast) }
def mover (k : TrackId) (x : Nat) : RoadUser :=
  Build.user k [.motorVehicle] (metres x, metres (4 * k)) Build.east (metresPerSecond 10) (metres 2, metres 1, metres 1)
/-- Always fast from x = 0: the search closes at the first observation, so the rule is violated. -/
def τClosed : Trace := (List.range 4).map fun i => { t := Int.ofNat (1000 * i), subject := some 1, users := [mover 1 (10 * i)] }
/-- Always fast from x = 10: the search reaches the trace start, so the rule is unknown. -/
def τOpen : Trace := (List.range 4).map fun i => { t := Int.ofNat (1000 * i), subject := some 1, users := [mover 1 (10 + 10 * i)] }

def wit (name : String) (τ : Trace) (expected : Verdict) (boundary : String := "") (absent : List String := []) : Scenario :=
  { name := name, rule := slowOnce.id, trace := τ, reading := {}, manifest := Build.manifest absent,
    grounding := [("v", 1)], expected := expected, boundary := boundary }
def tagOf (e : Except String Verdict) : String := match e with | .ok v => v.tag | .error m => "error: " ++ m

#guard tagOf ((wit "b" τOpen (.unknown []) "the approach before the recording").run [slowOnce]) = "unknown"
#guard tagOf ((wit "b" τOpen (.unknown [])).run [slowOnce]) =
  "error: b: unknown for [window_truncated:since], not for an atom the manifest masks"
#guard tagOf ((wit "b" τClosed (.unknown []) "h").run [slowOnce]) = "error: b: expected unknown, got violated []"
#guard tagOf ((wit "b" τClosed .violated "h").run [slowOnce]) =
  "error: b: a history boundary is declared on a witness that expects violated, not unknown"
#guard tagOf ((wit "b" τClosed .violated).run [slowOnce]) = "violated"
-- masked atoms stay admitted beside the truncation
#guard tagOf ((wit "b" τOpen (.unknown []) "h" ["kin.speed"]).run [slowOnce]) = "unknown"
-- unknown only for a masked atom: the boundary names no truncation that happened
def speedOnly : Rule := { slowOnce with id := "t/fast_now", obligation := .not fast }
#guard tagOf (({ wit "b" τClosed (.unknown []) "h" ["kin.speed"] with rule := speedOnly.id }).run [speedOnly]) =
  "error: b: a history-boundary witness, but no window is truncated at the trace start"
-- a missing parameter, or a window truncated at the trace end, is never a boundary
def needsParam : Rule := { slowOnce with id := "t/param", obligation := .since eastOf5 (.cmp (.measure "kin_speed" [V]) .le (.param "p.slow")) }
#guard tagOf (({ wit "b" τOpen (.unknown []) "h" with rule := needsParam.id }).run [needsParam]) =
  "error: b: unknown for [parameter_missing:p.slow], not for an atom the manifest masks or a window truncated at the trace start"
def ahead : Rule := { slowOnce with id := "t/ahead", obligation := .eventually (.not fast) }
#guard tagOf (({ wit "b" τClosed (.unknown []) "h" with rule := ahead.id }).run [ahead]) =
  "error: b: unknown for [window_truncated:eventually], not for an atom the manifest masks or a window truncated at the trace start"
-- an undefined precondition is never a boundary
def undefinedPre : Rule := { slowOnce with id := "t/undef", obligation := .definedWhen .ff (.not fast) }
#guard tagOf (({ wit "b" τOpen (.unknown []) "h" with rule := undefinedPre.id }).run [undefinedPre]) =
  "error: b: unknown for [undefined:defined_when], not for an atom the manifest masks or a window truncated at the trace start"
-- every operator that looks back carries a tag the boundary admits
def oneScene : Trace := [{ t := 0, subject := some 1, users := [mover 1 0] }]
def back : List Formula :=
  [ .since .tt .ff, .rises .tt, .holdsFor .time (.lit (seconds 1) .second) "v" .tt
  , .atLast .time (.lit (seconds 1) .second) "v" .tt .tt, .count .tt .tt .ge 1
  , .cmp (.sinceRise .tt) .ge (.lit (seconds 1) .second), .cmp (.distanceWhile "v" .tt) .ge (.lit (metres 1) .metre) ]
#guard back.all fun φ =>
  let r : Rule := { slowOnce with id := "t/back", obligation := φ }
  let τ := oneScene.map fun s => { s with users := s.users.map fun x => { x with kin := { x.kin with pathLength := some Q.zero } } }
  match Grounding.Setup.admit [r] τ {} Q.zero with
  | .error _ => false
  | .ok S => ((Grounding.evaluate S r ⟨[("v", 1)], []⟩).verdicts.toList.flatMap (·.2.reasons)).all fun w =>
      match w with | .windowTruncated op => Scenario.pastOps.contains op | _ => false

end TrafficSpec.Tests.HistoryBoundary
