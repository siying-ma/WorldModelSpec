/-
  Witnesses for NRS_484B_440_1_o2.

  The carriageway: a rural highway (region 10) from x = -100 to 100 m, y = -6 to 12 m; on it a
  roadway (11, y 0–8 m) of two eastbound lanes, lane 12 (y 0–4 m) and lane 13 (y 4–8 m), each 4 m
  wide unless a scene says otherwise, and a shoulder (14, y -3–0 m) outside the roadway. In
  `branch_2` the roadway is lane 12 alone (y 0–4 m).
  The bodies: the car (track 1, half-extents 2 m × 1 m) stands at (0, 2) in lane 12, heading east;
  the truck (track 2, half-extents 5 m × 1.25 m) is, by scene, halted alongside at (0, 6) in
  lane 13, halted 40 m ahead at (40, 6) in lane 13 (overlap -33 m), moving at 10 m/s alongside in
  lane 13, or halted alongside at (0, -1.5) on the shoulder.
  The instants: three, one second apart. The free passage width is broken by a 2.5 m lane and kept
  by a 4 m one; a halted body has speed zero and a moving one 10 m/s. Every figure here is the
  witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_440_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_440_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def hwId : RegionId := 10

def highway : Structure := Build.rect hwId .highway (m (-100)) (m (-6)) (m 100) (m 12)

def roadway (y1 : Q) : Structure :=
  { Build.rect 11 .roadway (m (-100)) (m 0) (m 100) y1 with ways := some [hwId] }

def laneAt (id : RegionId) (y0 y1 : Q) (width : Option Q) : Structure :=
  { Build.rect id .lane (m (-100)) y0 (m 100) y1 with
      ways := some [hwId]
      lane := some { direction := some Build.east, width := width } }

def shoulder : Structure :=
  { Build.rect 14 .shoulder (m (-100)) (m (-3)) (m 100) (m 0) with ways := some [hwId] }

/-- The two-lane carriageway; `w2` the width of lane 13, `w1` of lane 12. -/
def twoLanes (w1 w2 : Option Q) : List Structure :=
  [ highway, roadway (m 8), laneAt 12 (m 0) (m 4) w1, laneAt 13 (m 4) (m 8) w2, shoulder ]

def oneLane : List Structure :=
  [ highway, roadway (m 4), laneAt 12 (m 0) (m 4) (some (m 4)), shoulder ]

def car (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east speed (m 2, m 1, cm 75)

def truck (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 2 [.truck, .motorVehicle] pos Build.east speed (m 5, cm 125, m 2)

def asms (district disabled immovable : Bool) : List (AsmId × Bool) :=
  [ ("asm.business_or_residence_district", district)
  , ("asm.vehicle_disabled", disabled)
  , ("asm.disabled_vehicle_immovable", immovable) ]

def sceneTrace (users : Nat → List RoadUser) (structures : List Structure)
    (district disabled immovable : Bool := false) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) structures []
      (assumptions := asms district disabled immovable)

def w4 : Option Q := some (m 4)

/-- `forbid` (violated): On a rural highway with two lanes, district assumption false and disabled assumptions false, a car halts in one lane while a truck halts alongside it in the other lane. -/
def forbidTrace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero, truck (m 0, m 6) Q.zero]) (twoLanes w4 w4)

/-- `permit` (compliant): The car halts in one lane; the other lane, wider than the free passage width, is free alongside it. -/
def permitTrace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero, truck (m 40, m 6) Q.zero]) (twoLanes w4 w4)

/-- `idle` (not_applicable): The car drives along the highway without halting. -/
def idleTrace : Trace :=
  sceneTrace (fun k => [car (m (10 * Int.ofNat k), m 2) (Units.metresPerSecond 10)]) (twoLanes w4 w4)

/-- `blind` (unknown): The car halts in one lane of a two-lane highway; the source supplies no lane widths. -/
def blindTrace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero]) (twoLanes none none)

/-- `branch_1` (compliant): The car halts in one lane of a two-lane highway and no other road user is in the scene. -/
def branch_1Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero]) (twoLanes w4 w4)

/-- `branch_2` (violated): The car halts on a highway whose roadway has a single lane, so no lane is left opposite it. -/
def branch_2Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero]) oneLane

/-- `branch_3` (compliant): the truck drives past alongside the halted car in the other lane: a moving road user leaves the lane free. -/
def branch_3Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero, truck (m 0, m 6) (Units.metresPerSecond 10)]) (twoLanes w4 w4)

/-- `branch_4` (compliant): the truck halts alongside the car on the shoulder, not in the other lane. -/
def branch_4Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero, truck (m 0, cm (-150)) Q.zero]) (twoLanes w4 w4)

/-- `branch_5` (violated): the car halts alone, but the other lane is 2.5 m wide, narrower than the free passage width. -/
def branch_5Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero]) (twoLanes w4 (some (cm 250)))

/-- `branch_6` (not_applicable): as `forbid`, but the car is disabled and cannot be moved from where it stands. -/
def branch_6Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero, truck (m 0, m 6) Q.zero]) (twoLanes w4 w4)
    (disabled := true) (immovable := true)

/-- `branch_7` (not_applicable): as `forbid`, but the stretch lies in a business or residence district. -/
def branch_7Trace : Trace :=
  sceneTrace (fun _ => [car (m 0, m 2) Q.zero, truck (m 0, m 6) Q.zero]) (twoLanes w4 w4)
    (district := true)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_440_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_width"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_440_1_o2
