/-
  Witnesses for NRS_484B_600_1c.

  The geometry. A straight two-lane carriageway running east, 300 m long: lane 1 is the near lane
  (y from 0 to 4 m), lane 2 the far one (y from 4 to 8 m), region 3 the roadway that covers both,
  and region 9 the highway the three lie on (`ways := [9]`). Region 4 is a lane of the same shape
  that lies on no public way (`ways := []`), for the scene in which the portion traversed is no
  portion of a highway. The subject (track 1, a motor vehicle, 4 m by 2 m) runs along the centre of
  lane 1 at y = 2 m, so its reference point is inside lane 1, the roadway and the highway; every
  scene observes the occupancy of every body it builds and the governance of every device it
  builds. Speed-limit signs are devices 11 and 12; each states its value and kind and the regions
  whose traffic it governs. Three instants a second apart; the rule looks nowhere into the past, so
  no padding and no window are needed.

  Every figure here is the witness's own and appears nowhere in the rule. The posted values are
  25 mph (11.176 m/s), 45 mph and the speeds 40, 35 and 15 mph, each clear of the bound it tests;
  the halted subject stands at exactly 0 m/s, well inside the reading's standstill tolerance of
  0.1 m/s, while every moving subject runs two orders of magnitude above it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mph (n : Int) : Q := Units.mph n

-- Binders ↦ tracks: v ↦ 1

/-- The near lane, on highway 9. -/
def laneA : Structure :=
  { Build.lane 1 [(m 0, m 0), (m 300, m 0), (m 300, m 4), (m 0, m 4)] Build.east with
    ways := some [9] }

/-- The far lane, on highway 9. -/
def laneB : Structure :=
  { Build.lane 2 [(m 0, m 4), (m 300, m 4), (m 300, m 8), (m 0, m 8)] Build.east with
    ways := some [9] }

/-- The roadway both lanes make up, on highway 9. -/
def roadway : Structure :=
  { Build.rect 3 .roadway (m 0) (m 0) (m 300) (m 8) with ways := some [9] }

/-- A lane of the same shape that lies on no public way. -/
def laneOffWay : Structure :=
  { Build.lane 4 [(m 0, m 0), (m 300, m 0), (m 300, m 4), (m 0, m 4)] Build.east with
    ways := some [] }

/-- The highway the carriageway lies on. -/
def highway : Structure := Build.rect 9 .highway (m 0) (m (-4)) (m 300) (m 12)

/-- A highway elsewhere in the scene, which the subject neither occupies nor travels on. -/
def otherHighway : Structure := Build.rect 9 .highway (m 0) (m 20) (m 300) (m 30)

/-- The subject along the centre of the near lane. -/
def subjectAt (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 2) Build.east speed (m 2, m 1, m 1)

/-- The subject at the `k`-th instant, from `x0` metres at `step` metres a second. -/
def runner (k : Nat) (x0 step : Int) (speed : Q) : RoadUser :=
  subjectAt (m (x0 + step * Int.ofNat k)) speed

/-- `forbid` (violated): A maximum-kind speed-limit sign governs the lane the subject occupies; the subject runs along that lane at a speed above the sign's stated value. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 18 (mph 40) ]
      [ laneA, highway ]
      [ Build.speedLimit 11 [1] (mph 25) .maximum ]

/-- `permit` (compliant): The same lane and the same governing maximum-kind sign; the subject's speed stays below the sign's stated value throughout. No other road user is present in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 7 (mph 15) ]
      [ laneA, highway ]
      [ Build.speedLimit 11 [1] (mph 25) .maximum ]

/-- `idle` (not_applicable): The subject runs along a highway on which the source records the governance of every device and no speed-limit sign governs any region the subject occupies, so no posted limit applies to the portion traversed. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 18 (mph 40) ]
      [ laneA, laneB, highway ]
      [ Build.speedLimit 11 [2] (mph 25) .maximum ]

/-- `blind` (unknown): The subject runs fast along a lane beside a sign head the source records, but the source does not observe speed-limit signs or their stated values, so whether a posted maximum is exceeded cannot be told. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 18 (mph 40) ]
      [ laneA, highway ]
      [ Build.speedLimit 11 [1] (mph 25) .maximum ]

/-- `branch_1` (violated): Two signs govern regions the subject occupies, a maximum-kind sign on the roadway and a lower zone-kind sign on the lane; the subject's speed lies between the two values, above the lower posted maximum. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 16 (mph 35) ]
      [ laneA, roadway, highway ]
      [ Build.speedLimit 11 [3] (mph 45) .maximum
      , Build.speedLimit 12 [1] (mph 25) .zone ]

/-- `branch_2` (not_applicable): A minimum-kind speed-limit sign governs the lane the subject occupies and no other speed-limit sign does; the subject runs faster than that sign's stated value, which the words do not reach. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 18 (mph 40) ]
      [ laneA, highway ]
      [ Build.speedLimit 11 [1] (mph 25) .minimum ]

/-- `branch_3` (not_applicable): The subject stands halted in the lane under the governing
    maximum-kind sign, so it neither drives nor operates and the duty does not arise. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m 100) Q.zero ]
      [ laneA, highway ]
      [ Build.speedLimit 11 [1] (mph 25) .maximum ]

/-- `branch_4` (not_applicable): A maximum-kind sign governs the lane the subject runs along, but
    the source records that lane as lying on no public way, so the portion traversed is no portion
    of a highway. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k 40 18 (mph 40) ]
      [ laneOffWay, otherHighway ]
      [ Build.speedLimit 11 [4] (mph 25) .maximum ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.speed_limit_sign"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_600_1c
