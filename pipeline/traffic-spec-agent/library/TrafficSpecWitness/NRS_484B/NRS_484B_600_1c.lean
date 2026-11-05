/-
  Witnesses for NRS_484B_600_1c.

  The geometry. One straight east–west carriageway: a `highway` region (id 10) 400 m long and 24 m
  wide, from (0, −12) to (400, 12); inside it the northern lane A (id 11), from (0, 0) to (400, 10),
  recorded as lying on the highway (`ways := [10]`), and, where a scene needs a second portion, the
  southern lane B (id 12), from (0, −10) to (400, 0), also on that highway. Lane C (id 13) is the
  same lane shape in a scene that holds no highway region at all and records that it lies on no way.

  The bodies. One road user, track 1, the rule's `subject`: a body 4 m long and 1.8 m wide
  (half-extents 2 m, 90 cm), at y = 5 m — inside lane A and inside the highway, so occupancy comes
  from the geometry — heading east, moving along the lane at its stated speed. Each trace holds three
  instants one second apart, the body advancing about one second of travel between them.

  The devices. Speed-limit signs, each with the value it states (m/s, written through `Units.mph`)
  and the regions the source records it as governing. Every figure here — 35 mph posted, 55 mph and
  25 mph driven, the 45 mph minimum, the 15 mph and 20 mph of the bicycle scene — is the witness's
  own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The way: a highway region 400 m by 24 m. -/
def highway : Structure := Build.rect 10 .highway (m 0) (m (-12)) (m 400) (m 12)

/-- The northern lane, on the highway. -/
def laneA : Structure :=
  { Build.lane 11 [(m 0, m 0), (m 400, m 0), (m 400, m 10), (m 0, m 10)] Build.east with
      ways := some [10] }

/-- The southern lane, on the same highway. -/
def laneB : Structure :=
  { Build.lane 12 [(m 0, m (-10)), (m 400, m (-10)), (m 400, m 0), (m 0, m 0)] Build.east with
      ways := some [10] }

/-- A lane the source records as lying on no public way. -/
def laneC : Structure :=
  { Build.lane 13 [(m 0, m 0), (m 400, m 0), (m 400, m 10), (m 0, m 10)] Build.east with
      ways := some [] }

/-- The subject at the `k`-th instant: `step` metres along the lane per instant, at `speed`. -/
def subjectAt (k : Nat) (step : Int) (speed : Q) (classes : List RoadUserClass) : RoadUser :=
  Build.user 1 classes (m (100 + step * (k : Int)), m 5) Build.east speed (m 2, cm 90, cm 75)

/-- `forbid` (violated): A passenger car, the only road user in the scene, travels along a highway. Its class is one the run's reading counts under DEF-NRS-484A-320::vehicle. Its footprint overlaps a lane that the source records as lying on that highway, and a speed-limit sign of kind maximum, which the source records as governing that lane, states a value the car's observed speed exceeds. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 25 (Units.mph 55) [.motorVehicle] ]
      [ highway, laneA ]
      [ Build.speedLimit 20 [11] (Units.mph 35) .maximum ]

/-- `permit` (compliant): The same car, alone in the scene on the same lane of the same highway, travels at a speed below the value stated on the maximum speed-limit sign the source records as governing that lane, and below the value of every other speed-limit sign governing a region its footprint overlaps. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 11 (Units.mph 25) [.motorVehicle] ]
      [ highway, laneA ]
      [ Build.speedLimit 20 [11] (Units.mph 35) .maximum ]

/-- `idle` (not_applicable): The road user on the lane is a pedal bicycle propelled by human power — a device the applicable definition of vehicle leaves out (“except: (1) Devices moved by human power”) — so no class the reading counts under DEF-NRS-484A-320::vehicle holds for it. It rides along the lane faster than the value on the maximum speed-limit sign the source records as governing that lane. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 9 (Units.mph 20) [.bicycle] ]
      [ highway, laneA ]
      [ Build.speedLimit 20 [11] (Units.mph 15) .maximum ]

/-- `blind` (unknown): The car of the forbid scenario travels at the same excessive speed, and the source records a maximum speed-limit sign standing beside the stretch it occupies, but the source's capability manifest declares `dev.governs` absent: which travel regions that sign controls is unobserved, so whether any posting governs the portion of highway being traversed cannot be decided and the rule reports unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 25 (Units.mph 55) [.motorVehicle] ]
      [ highway, laneA ]
      [ Build.speedLimit 20 [11] (Units.mph 35) .maximum ]

/-- `branch_1` (compliant): The only speed-limit sign the source records as governing the lane the car occupies is of kind minimum; the car travels faster than the value that sign states, and no sign of kind maximum or structure_maximum governs any region its footprint overlaps. Driving faster than a posted minimum is not driving faster than a posted maximum, so the duty is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 25 (Units.mph 55) [.motorVehicle] ]
      [ highway, laneA ]
      [ Build.speedLimit 21 [11] (Units.mph 45) .minimum ]

/-- `branch_2` (compliant): A maximum speed-limit sign is recorded as governing only the adjacent lane, which the car's footprint does not overlap; the car travels above that sign's value in its own lane, for which the source records no governing speed-limit sign. The posting is not for the portion the car traverses, so the duty is met. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 25 (Units.mph 55) [.motorVehicle] ]
      [ highway, laneA, laneB ]
      [ Build.speedLimit 22 [12] (Units.mph 35) .maximum ]

/-- `branch_3` (not_applicable): the car traverses no highway at all — the scene holds a lane the
    source records as lying on no public way and no highway region — and speeds past a maximum
    sign governing that lane. There is no portion of highway being traversed, so the clause does
    not engage. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k 25 (Units.mph 55) [.motorVehicle] ]
      [ laneC ]
      [ Build.speedLimit 23 [13] (Units.mph 35) .maximum ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1c"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_600_1c
