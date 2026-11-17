/-
  Witnesses for NRS_484B_287_1e.

  Geometry (+x east, +y north, metres): an intersection (region 10) is the square
  [-10, 10] × [-10, 10]. Two north-south lanes enter it: northbound lane 11 (x ∈ [0, 5],
  y ∈ [-40, -10], direction north) and southbound lane 12 (x ∈ [-5, 0], y ∈ [10, 40],
  direction south). Crosswalk 13 is marked.

  Diagonal scenes: the crosswalk is a strip 4 m wide along the direction (0.6, 0.8) through the
  south-west corner. The pedestrian (track 1, half extents 0.3 × 0.3 × 0.9) walks along it at
  2.5 m/s, heading (0.6, 0.8), sampled every second: (-11.25, -13), (-9.75, -11), (-8.25, -9).
  It enters the intersection at the third instant. Its velocity makes cosine 0.8 with the lanes'
  direction (above the right-angle bound 0.26 and below the crossing bound 0.94). The
  pedestrian head (device 20) stands at (6.75, 11): 25 m straight ahead at the entry, cosine 1,
  inside the 40 m reach.

  Idle: an east-west marked crosswalk 13 ([-14, 10] × [-2, 2]); the pedestrian walks due east
  at 1.5 m/s, (-12.5, 0), (-11, 0), (-9.5, 0): at right angles to the north-south lanes.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_287_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_287_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def intersectionId : RegionId := 10

def intersection : Structure := Build.rect intersectionId .intersection (m (-10)) (m (-10)) (m 10) (m 10)

def lanes : List Structure :=
  [ Build.lane 11 [(m 0, m (-40)), (m 5, m (-40)), (m 5, m (-10)), (m 0, m (-10))] Build.north
      (enters := some intersectionId)
  , Build.lane 12 [(m (-5), m 10), (m 0, m 10), (m 0, m 40), (m (-5), m 40)] Build.south
      (enters := some intersectionId) ]

/-- The diagonal marked crosswalk: a 4 m strip along (0.6, 0.8). -/
def diagonalCrosswalk : Structure :=
  { Build.region 13 .crosswalk
      [(cm (-1265), cm (-1820)), (cm 1135, cm 1380), (cm 815, cm 1620), (cm (-1585), cm (-1580))]
    with marked := some true }

/-- An east-west marked crosswalk. -/
def eastWestCrosswalk : Structure :=
  { Build.rect 13 .crosswalk (m (-14)) (m (-2)) (m 10) (m 2) with marked := some true }

def diagonalHeading : Vec := (Units.ratio 3 5, Units.ratio 4 5)

def pedHead (state : Option PedSignalState) (countdown : Option Bool) : Device :=
  { Build.device 20 .pedestrianSignal [] (some (cm 675, m 11)) with
      pedState := state, countdown := countdown }

/-- The diagonal entry, with the head showing `state` / `countdown`. -/
def diagonalTrace (state : Option PedSignalState) (countdown : Option Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := (Q.add (cm (-1125)) (Q.mul (cm 150) (Q.ofInt k)),
                      Q.add (m (-13)) (Q.mul (m 2) (Q.ofInt k)))
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] pos diagonalHeading (cm 250) (cm 30, cm 30, cm 90) ]
      (intersection :: diagonalCrosswalk :: lanes)
      [ pedHead state countdown ]

/-- `forbid` (violated): At an intersection with a marked diagonal crosswalk, a pedestrian steps from the corner into the intersection walking north-east inside the marking while the pedestrian head ahead of it, 25 m away within the facing cone, shows dont_walk_steady. -/
def forbidTrace : Trace := diagonalTrace (some .dontWalkSteady) (some false)

/-- `permit` (compliant): Same entry, while the faced head shows walk. -/
def permitTrace : Trace := diagonalTrace (some .walk) (some false)

/-- `idle` (not_applicable): The pedestrian enters the intersection walking east, at right angles to the north-south lanes: no diagonal crossing begins. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := (Q.add (cm (-1250)) (Q.mul (cm 150) (Q.ofInt k)), m 0)
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] pos Build.east (cm 150) (cm 30, cm 30, cm 90) ]
      (intersection :: eastWestCrosswalk :: lanes)
      [ { Build.device 20 .pedestrianSignal [] (some (m 14, m 0)) with
            pedState := some .dontWalkSteady, countdown := some false } ]

/-- `blind` (unknown): Same entry as forbid, but the state of the faced pedestrian head is not observed. -/
def blindTrace : Trace := diagonalTrace (some .dontWalkSteady) (some false)

/-- `branch_1` (compliant): Same entry while the faced head shows dont_walk_flashing with its countdown displayed. -/
def branch_1Trace : Trace := diagonalTrace (some .dontWalkFlashing) (some true)

/-- `branch_2` (violated): Same entry while the faced head shows dont_walk_flashing without a countdown. -/
def branch_2Trace : Trace := diagonalTrace (some .dontWalkFlashing) (some false)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_287_1e"
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
  , witness "blind" blindTrace (.unknown []) ["dev.pedestrian_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_287_1e
