/-
  Witnesses for LVMC_11_46_030_o1.

  Geometry (the witness's own figures, none of them in the rule):
  - highway w (region 11): x ∈ [-200, 200] m, y ∈ [-12, 12] m;
  - lane g (region 10): eastbound, y ∈ [0, 4], direction east, on w; a westbound lane (region 13),
    y ∈ [-4, 0], on w, ungoverned and never occupied;
  - marked crosswalk c (region 12): x ∈ [0, 4], across the whole way, on w;
  - the subject (track 1), a passenger car (motor_vehicle), half-extents 2 m × 0.9 m × 0.75 m, its
    reference point at y = 2; its body's distance to c is −(x + 2) m while x < −2. Fifty feet is
    15.24 m, so the body is within fifty feet from x > −17.24 m: x = −20 is 18 m away, x = −15 is
    13 m, x = −10 is 8 m — each a margin of more than 2 m from the bound;
  - a school crossing guard (device 20, human_direction) or a crossing warning signal (device 21)
    governs g; it is present at every scene, its warning given or not per scene;
  - one scene a second; a halt is speed 0 against the 0.1 m/s tolerance, motion 2 m/s or more.
  Every witness names the whole trace as its window.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_46_030_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_46_030_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneG : Structure :=
  { Build.lane 10 [(m (-200), m 0), (m 200, m 0), (m 200, m 4), (m (-200), m 4)] Build.east with
    ways := some [11] }

def laneOpposite : Structure :=
  { Build.lane 13 [(m (-200), m (-4)), (m 200, m (-4)), (m 200, m 0), (m (-200), m 0)] Build.west with
    ways := some [11] }

def highwayW : Structure := Build.rect 11 .highway (m (-200)) (m (-12)) (m 200) (m 12)

def crosswalkC : Structure :=
  { Build.rect 12 .crosswalk (m 0) (m (-12)) (m 4) (m 12) with
    ways := some [11]
    marked := some true }

def street : List Structure := [highwayW, laneG, laneOpposite, crosswalkC]

/-- The subject at x (m) with signed speed v (m/s): negative rolls back, heading west. -/
def car (x v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 2) (if v < 0 then Build.west else Build.east)
    (Units.metresPerSecond (Int.ofNat v.natAbs)) (m 2, cm 90, cm 75)

/-- A school crossing guard governing g: stop when warning, proceed otherwise. -/
def guard (warn : Bool) : List Device :=
  [ { Build.device 20 .humanDirection [10] (some (m 6, m 13)) with
      humanRole := some .schoolCrossingGuard
      humanIndication := some (if warn then .stop else .proceed) } ]

/-- A crossing warning signal governing g, active when warning. -/
def warningSignal (warn : Bool) : List Device :=
  [ { Build.device 21 .crossingWarningSignal [10] (some (m (-2), m 13)) with
      active := some warn } ]

def noDevice (_warn : Bool) : List Device := []

/-- A trace from per-second steps (x, signed speed, warning given), over the given structures. -/
def runIn (structs : List Structure) (steps : List (Int × Int × Bool)) (devs : Bool → List Device) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let (x, v, w) := steps.getD k (0, 0, false)
    Build.scene t (some 1) [car x v] structs (devs w)

def run (steps : List (Int × Int × Bool)) (devs : Bool → List Device) : Trace := runIn street steps devs

/-- A crosswalk on w behind the subject's whole approach (x ∈ [−120, −116]). -/
def crosswalkBehind : Structure :=
  { Build.rect 14 .crosswalk (m (-120)) (m (-12)) (m (-116)) (m 12) with
    ways := some [11]
    marked := some true }

/-- A parallel street w2 north of w (y ∈ [25, 55]) and a crosswalk on it at x ∈ [−5, −2], nearer
    ahead along g than c at every scene before the subject reaches it. -/
def highwayW2 : Structure := Build.rect 15 .highway (m (-200)) (m 25) (m 200) (m 55)

def crosswalkOtherWay : Structure :=
  { Build.rect 16 .crosswalk (m (-5)) (m 30) (m (-2)) (m 50) with
    ways := some [15]
    marked := some true }

/-- Steady approach through c at 10 m/s; the warning begins at the second scene. Event at x = −10. -/
def approachSteps : List (Int × Int × Bool) :=
  [ (-80, 10, false), (-70, 10, true), (-60, 10, true), (-50, 10, true), (-40, 10, true)
  , (-30, 10, true), (-20, 10, true), (-10, 10, true), (0, 10, true), (10, 10, true) ]

/-- `forbid` (violated): A straight two-way street w (st.highway) with a lane g (st.lane, direction east, st.on_way w) and a marked crosswalk c across w ahead. A school crossing guard (dev.human_direction, role school_crossing_guard, indication stop) governs g from before the subject appears until after it passes. The subject, a passenger car (ru.motor_vehicle) in g, approaches from far upstream at a steady urban speed and, without halting, comes within fifty feet of c and passes through it; distances, speed and governance observed at every scene.
    The guard governs g at every scene and indicates proceed at the first, stop from the second (the
    warning's onset, observed); the subject passes 80 m upstream at 10 m/s and never halts. -/
def forbidTrace : Trace := run approachSteps guard

/-- `permit` (compliant): As in forbid, but the subject halts (speed at or below the halt tolerance) while its body is farther than fifty feet from c and the guard still indicates stop; later the guard indicates proceed and the subject drives on through the crosswalk.
    The subject halts at x = −50 (48 m from c) for two scenes under the stop, moves on, comes within
    fifty feet at x = −15 (13 m) while the stop is still shown; the guard then indicates proceed and
    the subject drives through c. -/
def permitTrace : Trace :=
  run [ (-80, 10, false), (-70, 10, true), (-60, 8, true), (-50, 0, true), (-50, 0, true)
      , (-45, 5, true), (-35, 10, true), (-25, 10, true), (-15, 10, true), (-5, 10, false)
      , (5, 10, false), (15, 10, false) ] guard

/-- `idle` (not_applicable): Same street and crosswalk, but no warning device and no person directing traffic is in the scene; the subject drives through c without halting. -/
def idleTrace : Trace := run approachSteps noDevice

/-- `blind` (unknown): As in forbid, but the source maps regions without outlines (st.region_geometry absent): the distance from the subject's body to c, and so the event, is unknown. -/
def blindTrace : Trace := run approachSteps guard

/-- `history_boundary` (unknown): The guard indicates stop over g at every scene of the recording; the subject is in g with c ahead from its first observation, is moving at its first observation and comes within fifty feet of c later without any halt recorded; whether it halted for the warning before the recording began is not observed. -/
def history_boundaryTrace : Trace :=
  run (approachSteps.map fun (x, v, _) => (x, v, true)) guard

/-- `branch_1` (violated): As in forbid, but the warning is given by a dev.crossing_warning_signal governing g whose active attribute holds, and no person directs traffic. -/
def branch_1Trace : Trace := run approachSteps warningSignal

/-- `branch_2` (violated): The subject halts farther than fifty feet from c before any warning is given, the guard then steps out with the stop indication, and the subject moves on and comes within fifty feet of c without halting again while the warning lasts.
    Halt at x = −55 while the guard indicates proceed; the subject is moving again when the stop
    begins; event at x = −10. -/
def branch_2Trace : Trace :=
  run [ (-80, 10, false), (-65, 8, false), (-55, 0, false), (-55, 0, false), (-50, 5, false)
      , (-40, 10, true), (-30, 10, true), (-20, 10, true), (-10, 10, true), (0, 10, true)
      , (10, 10, true) ] guard

/-- `branch_3` (violated): the subject halts 48 m from c under the stop, comes within fifty feet
    (13 m, compliant event), rolls back to 20 m and comes within fifty feet again without a new
    halt: the second event's search ends at the first one, so the earlier halt does not count. -/
def branch_3Trace : Trace :=
  run [ (-80, 10, false), (-70, 10, true), (-60, 8, true), (-50, 0, true), (-50, 0, true)
      , (-35, 10, true), (-15, 2, true), (-22, -2, true), (-15, 3, true), (-5, 10, true)
      , (5, 10, true) ] guard

/-- `branch_4` (violated): as in forbid, with a crosswalk on w behind the subject and a crosswalk on a
    parallel street nearer ahead along g: neither displaces c as the nearest crosswalk ahead on w. -/
def branch_4Trace : Trace :=
  runIn (street ++ [crosswalkBehind, highwayW2, crosswalkOtherWay]) approachSteps guard

def witness (name : String) (τ : Trace) (expected : Verdict) (last : Nat)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_46_030_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, last * 1000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 9
  , witness "permit" permitTrace .compliant 11
  , witness "idle" idleTrace .notApplicable 9
  , witness "blind" blindTrace (.unknown []) 9 ["st.region_geometry"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) 9 (boundary := "the approach to c under the guard's warning before the recording's first scene: the warning's onset and the subject's conduct since then")
  , witness "branch_1" branch_1Trace .violated 9
  , witness "branch_2" branch_2Trace .violated 10
  , witness "branch_3" branch_3Trace .violated 10
  , witness "branch_4" branch_4Trace .violated 9 ]

end TrafficSpecWitness.LVMC_11_46_030_o1
