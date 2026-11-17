/-
  Witnesses for NRS_484B_307_7a_o2.

  Geometry (metres, +x east, +y north), the witness's own figures:
  - intersection i (10): the square x, y ∈ [-10, 10];
  - left-turn lane c (11): x ∈ [0, 4], y ∈ [-40, -10], northbound, entering i; signal head s (20)
    governs it;
  - the cross street's eastbound approach c2 (12): x ∈ [-40, -14], y ∈ [-10, 0], entering i;
  - crosswalk w (13) on the west leg: x ∈ [-14, -10], y ∈ [-10, 10], recorded as marking c2's
    entrance (outside i's polygon).
  The car (track 1, half-extents 2.5 × 1 m) is at two instants 1 s apart: at 0 s in c at (2, -14)
  heading north at 7 m/s; at 1 s in i at (-4, 4) heading west at 7 m/s, turning left toward w.
  The pedestrian (track 2, half-extents 0.3 m) walks north at 1.3 m/s.
  Against the reading (horizon 3 s, clearance 3 m, halt tolerance 0.1 m/s): in forbid, at 1 s the
  pedestrian at (-12, 2.5) gives a closest approach of the centres about 1.1 s ahead at well under
  1 m; at 0 s the closest approach is 14 m apart. Every scene's footprints lie wholly inside the
  polygon containing their reference point, so occupancy is the geometry's.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_7a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_7a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def intersectionI : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)

def laneC : Structure :=
  { Build.lane 11 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north
      (enters := some 10) with kind := .turnLane, turnSide := some .left }

def laneC2 : Structure :=
  Build.lane 12 [(m (-40), m (-10)), (m (-14), m (-10)), (m (-14), m 0), (m (-40), m 0)] Build.east
    (enters := some 10)

def crosswalkW : Structure :=
  { Build.rect 13 .crosswalk (m (-14)) (m (-10)) (m (-10)) (m 10) with
      marked := some true, entranceOf := [12], entranceObserved := true }

def structures : List Structure := [intersectionI, laneC, laneC2, crosswalkW]

def arrowHead : Device := Build.signal 20 [11] [.circularRed, .flashingYellowArrow .left]
def greenHead : Device := Build.signal 20 [11] [.circularGreen]

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- The car turning left: in c at 0 s, in i heading west at 1 s. -/
def carTurning (k : Nat) : RoadUser :=
  if k == 0 then Build.user 1 [.motorVehicle] (m 2, m (-14)) Build.north (m 7) carExtent
  else Build.user 1 [.motorVehicle] (m (-4), m 4) Build.west (m 7) carExtent

/-- The car enters i and halts there, heading west, at 1 s. -/
def carHalting (k : Nat) : RoadUser :=
  if k == 0 then Build.user 1 [.motorVehicle] (m 2, m (-14)) Build.north (m 7) carExtent
  else Build.user 1 [.motorVehicle] (m (-7), m 4) Build.west (m 0) carExtent

def pedNorth (x y0 y1 : Q) (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (x, if k == 0 then y0 else y1) Build.north (cm 130) pedExtent

/-- The pedestrian of forbid, idle and blind: in crosswalk w, walking north. -/
def pedInCrosswalk (k : Nat) : RoadUser := pedNorth (m (-12)) (cm 120) (cm 250) k

def sceneWith (head : Device) (users : Nat → List RoadUser) : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) structures [head]

/-- `forbid` (violated): Head s governing left-turn lane c displays circular_red with flashing_yellow_arrow(left); a pedestrian walks at 1.3 m/s in the crosswalk marking the entrance of the cross street's approach into i; the car enters i and turns left at 7 m/s toward that crosswalk, the closest approach of their centres 1.1 s ahead at 0.8 m. -/
def forbidTrace : Trace :=
  sceneWith arrowHead fun k => [carTurning k, pedInCrosswalk k]

/-- `permit` (compliant): Same signal; no other road user is in the scene; the car turns left through i. The duty binds the subject alone and is met. -/
def permitTrace : Trace :=
  sceneWith arrowHead fun k => [carTurning k]

/-- `idle` (not_applicable): s displays circular_green alone; the car turns left past a pedestrian. -/
def idleTrace : Trace :=
  sceneWith greenHead fun k => [carTurning k, pedInCrosswalk k]

/-- `blind` (unknown): As forbid, but the source does not record which carriers' entrances the pedestrian's crosswalk marks: whether it is an adjacent crosswalk is unknown. -/
def blindTrace : Trace :=
  sceneWith arrowHead fun k => [carTurning k, pedInCrosswalk k]

/-- `branch_1` (violated): as forbid, but the pedestrian walks inside i itself at x = -8 (not in a
    crosswalk); the turning car's closest approach to it is about 0.6 s ahead at under 1 m. -/
def branch1Trace : Trace :=
  sceneWith arrowHead fun k => [carTurning k, pedNorth (m (-8)) (cm 120) (cm 250) k]

/-- `branch_2` (compliant): as forbid, but the pedestrian is in the crosswalk farther south
    (y = -4 at 1 s): the closest approach lies within the horizon but about 6 m apart. -/
def branch2Trace : Trace :=
  sceneWith arrowHead fun k => [carTurning k, pedNorth (m (-12)) (cm (-530)) (m (-4)) k]

/-- `branch_3` (compliant): the car enters i and halts at (-7, 4); a pedestrian in the crosswalk
    walks east toward it (closest approach 2.7 s ahead at 1 m) without touching it: a halted car
    grants precedence. -/
def branch3Trace : Trace :=
  sceneWith arrowHead fun k =>
    [ carHalting k
    , Build.user 2 [.pedestrian] (if k == 0 then (cm (-1180), m 3) else (cm (-1050), m 3))
        Build.east (cm 130) pedExtent ]

/-- `branch_4` (violated): the car enters i and halts at (-7, 4) with its body overlapping a
    pedestrian standing in i at (-9.6, 4): contact. -/
def branch4Trace : Trace :=
  sceneWith arrowHead fun k =>
    [ carHalting k
    , Build.user 2 [.pedestrian] (cm (-960), m 4) Build.north (m 0) pedExtent ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_7a_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.entrance_of"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant
  , witness "branch_3" branch3Trace .compliant
  , witness "branch_4" branch4Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_7a_o2
