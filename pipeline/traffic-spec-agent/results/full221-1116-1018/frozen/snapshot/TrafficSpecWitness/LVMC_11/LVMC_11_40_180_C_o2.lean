/-
  Witnesses for LVMC_11_40_180_C_o2.

  Geometry (the witness's own figures; none appears in the rule): a sidewalk (region 1) is the
  strip y ∈ [0, 4] m, a roadway (region 2) the strip y ∈ [-8, 0] m, both from x = -100 to 200 m;
  everyone heads east. The rider (track 1, half-length 0.9 m) rides at y = 1 m on the sidewalk or
  y = -1 m on the roadway; the other road user (track 2, half-length 0.3 m) walks at y = 3 m on
  the sidewalk at 1 m/s. With these extents the walker is ahead of the rider where its x exceeds
  the rider's by more than 1.2 m, behind where it is less by more than 1.2 m, alongside otherwise.

  Instants are 1 s apart from t = 20 s. The pass scenes (`forbid`, `permit`, `blind`, `branch_1`,
  `branch_3`, `branch_4`, `branch_5`): the rider waits at rest at x = 0 for k = 0…3 while the walker
  walks off from alongside (x = k), so the walker is alongside at k = 0, 1 and comes to be ahead at
  k = 2 (the run's start, inside the recording), ahead at k = 3 (the onset); the rider then rides at
  3 m/s (x = 3, 6, 9, 12 at k = 4…7): alongside at k = 4, 5, behind at k = 6 (the recognition).
  The traces are padded 12 s before (the first scene repeated) so the 10 s window is covered,
  and each witness speaks about the instants from 20 s on.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_180_C_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_180_C_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def sidewalk : Structure := Build.rect 1 .sidewalk (m (-100)) (m 0) (m 200) (m 4)
def roadway : Structure := Build.rect 2 .roadway (m (-100)) (m (-8)) (m 200) (m 0)

def riderHalf : Q × Q × Q := (cm 90, cm 30, cm 60)
def walkerHalf : Q × Q × Q := (cm 30, cm 30, cm 90)

def onSidewalkY : Q := m 1
def onRoadwayY : Q := m (-1)

/-- Horn and bell/whistle per instant. -/
abbrev Sig := Nat → Option Bool × Option Bool

def silent : Sig := fun _ => (some false, some false)
def unheard : Sig := fun _ => (none, none)

def rider (cls : RoadUserClass) (x y v : Q) (s : Option Bool × Option Bool) : RoadUser :=
  Build.withSignals (Build.user 1 [cls] (x, y) Build.east v riderHalf)
    fun g => { g with horn := s.1, siren := s.2 }

def walker (cls : RoadUserClass) (x v : Q) : RoadUser :=
  Build.user 2 [cls] (x, m 3) Build.east v walkerHalf

def t0 : Timestamp := 20000

/-- A trace of `n` scenes: the rider at (rx k, ry k) at speed rv k, the walker at px k. -/
def mkTrace (n : Nat) (riderCls walkerCls : RoadUserClass) (rx ry rv px : Nat → Q) (sig : Sig)
    (padBefore : Bool := true) : Trace :=
  let τ := Build.trace n t0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider riderCls (rx k) (ry k) (rv k) (sig k), walker walkerCls (px k) (mps 1) ]
      [ sidewalk, roadway ]
      [ ]
  Build.pad τ (if padBefore then Units.seconds 12 else Q.zero) (Units.seconds 2) (Units.seconds 1)

/-- The rider waits at rest at x = 0 for k ≤ 3, then rides at 3 m/s. -/
def waitThenRideX (k : Nat) : Q := if k ≤ 3 then m 0 else m (3 * ((k : Int) - 3))
def waitThenRideV (k : Nat) : Q := if k ≤ 3 then m 0 else mps 3
def walkX (k : Nat) : Q := m (k : Int)

def passTrace (riderCls walkerCls : RoadUserClass) (ry : Nat → Q) (sig : Sig) : Trace :=
  mkTrace 8 riderCls walkerCls waitThenRideX ry waitThenRideV walkX sig

/-- The instants a padded witness speaks about. -/
def speaksAbout : Option (Timestamp × Timestamp) := some (t0, t0 + 9000)

/-- `forbid` (violated): A bicycle rides on the sidewalk behind a pedestrian walking the same way, draws alongside and passes, and no horn, bell or whistle sounds while the pedestrian is ahead of it; the pedestrian came to be ahead within the recording. -/
def forbidTrace : Trace := passTrace .bicycle .pedestrian (fun _ => onSidewalkY) silent

/-- `permit` (compliant): The same pass, with the bicycle's bell sounding while the pedestrian is still ahead of it. -/
def permitTrace : Trace :=
  passTrace .bicycle .pedestrian (fun _ => onSidewalkY)
    fun k => if k = 2 ∨ k = 3 then (some false, some true) else (some false, some false)

/-- `idle` (not_applicable): A bicycle rides on the sidewalk behind a pedestrian at the same pace and never passes. -/
def idleTrace : Trace :=
  mkTrace 8 .bicycle .pedestrian (fun k => m (k : Int)) (fun _ => onSidewalkY) (fun _ => mps 1)
    (fun k => m ((k : Int) + 4)) silent

/-- `blind` (unknown): The same pass with no signal in the trace, from a source without audio that declares horn and bell absent. -/
def blindTrace : Trace := passTrace .bicycle .pedestrian (fun _ => onSidewalkY) unheard

/-- `branch_1` (violated): An electric scooter begins the pass on the roadway edge and moves onto the sidewalk while alongside the pedestrian, completing the pass there without any signal.
    Built with an electric bicycle: the run's reading includes no class under the electric-scooter
    aggregate (ru.electric_scooter is unresolved there), so a scooter's class is unknown and no
    decided verdict can be reached with one. -/
def branch_1Trace : Trace :=
  passTrace .electricBicycle .pedestrian (fun k => if k ≤ 3 then onRoadwayY else onSidewalkY) silent

/-- `branch_2` (not_applicable): An electric scooter rides on the sidewalk, leaves it for the roadway before drawing alongside, and passes a pedestrian on the sidewalk from the roadway without signal: it is on the sidewalk only before the act began.
    The scooter rides at 2 m/s on the sidewalk (x = 0, 2), drops to the roadway at k = 2 and rides
    at 4 m/s (x = 4, 8, 12, 16, 20); the walker at x = 10 + k is ahead at k ≤ 4 (onset k = 4, on
    the roadway), alongside at k = 5, behind at k = 6. -/
def branch_2Trace : Trace :=
  mkTrace 7 .electricScooter .pedestrian
    (fun k => m ([0, 2, 4, 8, 12, 16, 20].getD k 20))
    (fun k => if k ≤ 1 then onSidewalkY else onRoadwayY)
    (fun k => if k ≤ 1 then mps 2 else mps 4)
    (fun k => m ((k : Int) + 10)) silent

/-- `branch_3` (not_applicable): a bicycle waits at rest on the sidewalk while the pedestrian walks
    ahead, then rides on the roadway and passes without signal: it is on the sidewalk during the
    pass only at the onset, and at rest there. -/
def branch_3Trace : Trace :=
  passTrace .bicycle .pedestrian (fun k => if k ≤ 3 then onSidewalkY else onRoadwayY) silent

/-- `branch_4` (not_applicable): the same pass on the sidewalk without signal, of another bicycle
    ridden at walking pace — no pedestrian is passed. -/
def branch_4Trace : Trace := passTrace .bicycle .bicycle (fun _ => onSidewalkY) silent

/-- `branch_5` (compliant): the same pass, with the bicycle's horn sounding at the onset. -/
def branch_5Trace : Trace :=
  passTrace .bicycle .pedestrian (fun _ => onSidewalkY)
    fun k => if k = 3 then (some true, some false) else (some false, some false)

/-- `history_boundary` (unknown): The recording begins with the pedestrian already ahead of the bicycle on the sidewalk; the bicycle passes without a signal in the recording, and the search reaches the start of the recording without reaching the observation at which the pedestrian came to be ahead.
    The bicycle rides at 3 m/s from x = 0, the pedestrian walks from x = 5: ahead at k = 0, 1,
    alongside at k = 2, 3, behind at k = 4 (recognition). No padding before. -/
def history_boundaryTrace : Trace :=
  mkTrace 5 .bicycle .pedestrian (fun k => m (3 * (k : Int))) (fun _ => onSidewalkY) (fun _ => mps 3)
    (fun k => m ((k : Int) + 5)) silent (padBefore := false)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := speaksAbout) : Scenario :=
  { name := name
    rule := "LVMC_11_40_180_C_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.horn", "sig.siren"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the run of observations with the pedestrian ahead of the rider begins before the recording") (window := none) ]

end TrafficSpecWitness.LVMC_11_40_180_C_o2
