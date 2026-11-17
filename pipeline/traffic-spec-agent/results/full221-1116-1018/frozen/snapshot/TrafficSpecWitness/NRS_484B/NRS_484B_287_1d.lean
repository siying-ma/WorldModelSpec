/-
  Witnesses for NRS_484B_287_1d.

  Geometry (metres, +x east, +y north): intersection 1 is the square (-10,-10)–(10,10). Four
  approach lanes run into it: lane 2 northbound from the south (0..4, -50..-10), lane 3 eastbound
  from the west (-50..-10, -4..0), lane 4 southbound from the north (-4..0, 10..50), lane 5
  westbound from the east (10..50, 0..4); each records `enters := 1`. Sidewalk 6 lies north-west of
  the intersection (-50..-12, 12..15). Crosswalk 7 (branch_1 only) is a marked diagonal band from
  the south-west corner to the north-east corner of the intersection.

  The pedestrian (track 1, half extents 0.3 × 0.3 × 0.9 m) walks at 1.4 m/s, sampled at 1 s.
  - north-east heading (3/5, 4/5): |cos| with the north-south lanes 0.8, with the east-west lanes
    0.6 — both at most 0.94 (across) and above 0.26 (not at right angles): diagonal.
  - east heading: |cos| 1 with the east-west lanes (along), 0 with the north-south ones: not
    diagonal.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_287_1d
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_287_1d

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 30, cm 30, cm 90)
def walk : Q := cm 140
def northEast : Vec := (Units.ratio 3 5, Units.ratio 4 5)

def intersection : Structure := Build.rect 1 .intersection (m (-10)) (m (-10)) (m 10) (m 10)

def approaches : List Structure :=
  [ Build.lane 2 [(m 0, m (-50)), (m 4, m (-50)), (m 4, m (-10)), (m 0, m (-10))] Build.north
      (enters := some 1)
  , Build.lane 3 [(m (-50), m (-4)), (m (-10), m (-4)), (m (-10), m 0), (m (-50), m 0)] Build.east
      (enters := some 1)
  , Build.lane 4 [(m (-4), m 10), (m 0, m 10), (m 0, m 50), (m (-4), m 50)] Build.south
      (enters := some 1)
  , Build.lane 5 [(m 10, m 0), (m 50, m 0), (m 50, m 4), (m 10, m 4)] Build.west
      (enters := some 1) ]

def sidewalk : Structure := Build.rect 6 .sidewalk (m (-50)) (m 12) (m (-12)) (m 15)

def diagonalCrosswalk : Structure :=
  { Build.region 7 .crosswalk [(m (-10), m (-8)), (m (-8), m (-10)), (m 10, m 8), (m 8, m 10)]
    with marked := some true }

/-- The pedestrian walking north-east from (-2, -2), inside the intersection. -/
def diagonalWalker (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (cm (-200 + 84 * k), cm (-200 + 112 * k)) northEast walk body

/-- `forbid` (violated): Lanes running into intersection x run north-south and east-west; a pedestrian inside x walks north-east at 1.4 m/s, oblique to every entering lane, with no crosswalk under its footprint. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ diagonalWalker k ]
      (intersection :: approaches)
      [ ]

/-- `permit` (compliant): A pedestrian inside x near its edge walks east at 1.4 m/s: across the north-south lanes at right angles, so the motion is not diagonal. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (-500 + 140 * k), m (-8)) Build.east walk body ]
      (intersection :: approaches)
      [ ]

/-- `idle` (not_applicable): The pedestrian walks along a sidewalk and its footprint overlaps no intersection. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (-3000 + 140 * k), cm 1350) Build.east walk body ]
      (intersection :: sidewalk :: approaches)
      [ ]

/-- `blind` (unknown): The pedestrian is inside x with no marked crosswalk under it, but its velocity is not observed, so whether it moves diagonally cannot be told. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (diagonalWalker k) (fun kin => { kin with velocity := none }) ]
      (intersection :: approaches)
      [ ]

/-- `branch_1` (compliant): A pedestrian inside x walks north-east within a marked diagonal crosswalk. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ diagonalWalker k ]
      (intersection :: diagonalCrosswalk :: approaches)
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_287_1d"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.NRS_484B_287_1d
