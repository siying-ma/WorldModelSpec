/-
  Witnesses for NRS_484B_253_o1.

  Geometry (every figure the witness's own, none in the rule): intersection X = region 10, the
  square x, y ∈ [−10, 10] m. Three approach lanes enter it:
    11 (c1)  the subject's approach from the south, x ∈ [0, 4], y ∈ [−60, −10], direction north;
    12 (c2)  the opposing approach from the north, x ∈ [−4, 0], y ∈ [10, 60], direction south;
    13       a cross-street approach from the east, x ∈ [10, 60], y ∈ [0, 4], direction west.
  Bodies are cars of half-length 2 m, half-width 1 m. Instants are 1 s apart; occupancy is stated
  per scene. The subject (track 1) declares int.left_turn at X (true, or false in `idle`).
  At k = 0 the subject is on lane 11 only (not in X), so every `since` look-back is decided there.
  Conflict figures (reading: horizon 3 s, centre clearance 3 m, halt tolerance 0.1 m/s):
    forbid/blind k=1: subject (2, 2) westbound 2 m/s, v (−2, 13) southbound 5 m/s on lane 12:
      closest approach at 63/29 ≈ 2.17 s, centre distance ≈ 0.37 m.
    branch_3 k=1: v (−2, 7) inside X: closest approach ≈ 1.14 s at ≈ 1.85 m.
    branch_2 k=1: v (13, 2) westbound 8 m/s on lane 13 behind the subject: ≈ 1.83 s at 0 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Intersection X. -/
def intersection : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
/-- c1: the subject's approach from the south, northbound, entering X. -/
def southApproach : Structure :=
  Build.lane 11 [(m 0, m (-60)), (m 4, m (-60)), (m 4, m (-10)), (m 0, m (-10))] Build.north (enters := some 10)
/-- c2: the opposing approach from the north, southbound, entering X. -/
def northApproach : Structure :=
  Build.lane 12 [(m (-4), m 10), (m 0, m 10), (m 0, m 60), (m (-4), m 60)] Build.south (enters := some 10)
/-- A cross-street approach from the east, westbound, entering X. -/
def eastApproach : Structure :=
  Build.lane 13 [(m 10, m 0), (m 60, m 0), (m 60, m 4), (m 10, m 4)] Build.west (enters := some 10)

def roadMap : List Structure := [intersection, southApproach, northApproach, eastApproach]

/-- A car at (x, y) m with a heading and a speed in m/s. -/
def car (track : TrackId) (x y : Int) (h : Vec) (speed : Int) : RoadUser :=
  Build.user track [.motorVehicle] (m x, m y) h (Units.metresPerSecond speed) (m 2, m 1, cm 75)

/-- The subject's declaration of int.left_turn at X. -/
def leftTurn (b : Bool) : List DeclaredIntent :=
  [{ vehicle := 1, target := 10, values := [("int.left_turn", b)] }]

def sceneAt (t : Timestamp) (users : List RoadUser) (occ : List (TrackId × RegionId)) (turn : Bool := true) : Scene :=
  Build.scene t (some 1) users roadMap [] (occupies := some occ) (intents := leftTurn turn)

/-- `forbid` (violated): The subject overlaps X and declares int.left_turn at X; v approaches on c2, whose st.lane_direction is opposed to that of the subject's entry carrier c1; the subject moves into its turn with kin.speed above p.halt_speed_tolerance while its closest approach to v lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    if k == 0 then
      sceneAt t [car 1 2 (-12) Build.north 5, car 2 (-2) 18 Build.south 5] [(1, 11), (2, 12)]
    else
      sceneAt t [car 1 2 2 Build.west 2, car 2 (-2) 13 Build.south 5] [(1, 10), (2, 12)]

/-- `permit` (compliant): Same scene; the subject stays at rest in X until v has passed, then turns. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [car 1 2 (-12) Build.north 5, car 2 (-2) 13 Build.south 5] [(1, 11), (2, 12)]
    | 1 => sceneAt t [car 1 2 (-2) Build.north 0, car 2 (-2) 7 Build.south 5] [(1, 10), (2, 10)]
    | 2 => sceneAt t [car 1 2 (-2) Build.north 0, car 2 (-2) (-3) Build.south 5] [(1, 10), (2, 10)]
    | _ => sceneAt t [car 1 2 2 Build.west 2, car 2 (-2) (-14) Build.south 5] [(1, 10)]

/-- `idle` (not_applicable): The subject crosses X with int.left_turn declared false at X (its plan goes straight). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t [car 1 2 (-12) Build.north 5] [(1, 11)] (turn := false)
    | 1 => sceneAt t [car 1 2 0 Build.north 5] [(1, 10)] (turn := false)
    | _ => sceneAt t [car 1 2 12 Build.north 5] [] (turn := false)

/-- `blind` (unknown): Left-turning subject in X, opposing v in conflict; kin.speed is absent, so whether the subject proceeds into the conflict is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): The subject turns left in X with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    if k == 0 then sceneAt t [car 1 2 (-12) Build.north 5] [(1, 11)]
    else sceneAt t [car 1 2 2 Build.west 2] [(1, 10)]

/-- `branch_2` (compliant): v approaches from a cross street (its carrier's direction perpendicular to c1's) on a conflicting path; the subject turns: v does not approach from the opposite direction. -/
def branch_2Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    if k == 0 then
      sceneAt t [car 1 2 (-12) Build.north 5, car 2 21 2 Build.west 8] [(1, 11), (2, 13)]
    else
      sceneAt t [car 1 2 2 Build.west 2, car 2 13 2 Build.west 8] [(1, 10), (2, 13)]

/-- `branch_3` (violated): v came from c2 and is now within X (no longer on c2); the subject moves
    into its turn while in conflict with v: the "within the intersection" limb (g). -/
def branch_3Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    if k == 0 then
      sceneAt t [car 1 2 (-12) Build.north 5, car 2 (-2) 13 Build.south 5] [(1, 11), (2, 12)]
    else
      sceneAt t [car 1 2 2 Build.west 2, car 2 (-2) 7 Build.south 5] [(1, 10), (2, 10)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o1
