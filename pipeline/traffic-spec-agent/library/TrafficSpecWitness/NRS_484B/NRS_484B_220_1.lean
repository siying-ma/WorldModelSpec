/-
  Witnesses for NRS_484B_220_1.

  The scene is a straight east–west carriageway. Region 2 is the highway, a 24 m wide strip from
  x = −200 m to x = 200 m; region 1 is the one-way roadway on it, 12 m wide, its designated
  direction due east, and it records region 2 as the way it lies on. Device 1 is a regulatory sign
  of catalogue code one_way governing region 1, its legend stating no hours, days, duration or
  class (`conditions := some {}`). Track 1 is the subject, a body 4 m long and 1.8 m wide, driven
  along the roadway at y = 0 (or standing at y = 5 m, by the kerb, in `branch_1`); each trace is
  three instants a second apart and the body's position advances with its velocity.

  The variants: `forbid` drives it west at 7 m/s, against the designated direction by far more than
  the motion tolerance; `permit` east at 11 m/s, with it; `idle` makes it a pedal bicycle; `blind`
  keeps the westward drive but masks st.lane_direction, so the designated direction is unread;
  `branch_1` stands it still; `branch_2` replaces the sign's legend with no_parking, so no one_way
  sign governs the roadway; `branch_3` maps the carriageway as a plain roadway, not a one-way one.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_220_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_220_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

/-- Region 2: the public way the carriageway lies on. -/
def highway : Structure := Build.rect 2 .highway (m (-200)) (m (-12)) (m 200) (m 12)

/-- Region 1: the one-way roadway, designated direction due east, lying on region 2. -/
def oneWayRoad : Structure :=
  { Build.rect 1 .oneWayRoadway (m (-200)) (m (-6)) (m 200) (m 6) with
      lane := some { direction := some Build.east },
      ways := some [2] }

/-- Region 1 as a plain roadway: no one-way restriction on it (`branch_3`). -/
def plainRoad : Structure :=
  { Build.rect 1 .roadway (m (-200)) (m (-6)) (m 200) (m 6) with
      lane := some { direction := some Build.east },
      ways := some [2] }

/-- Device 1: the one_way sign governing region 1. -/
def oneWaySign : Device :=
  { Build.sign 1 .regulatorySign [1] with
      code := some .oneWay,
      conditions := some {} }

/-- Device 1 as a no_parking sign: nothing posts a one-way restriction (`branch_2`). -/
def noParkingSign : Device :=
  { Build.sign 1 .regulatorySign [1] with
      code := some .noParking,
      conditions := some {} }

/-- The subject's half-extents: 2 m half-length, 90 cm half-width, 75 cm half-height. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- A body of `classes` driven along the roadway's centre at `speed` towards `heading`,
    its position advancing from the origin over the instants of the trace. -/
def driver (k : Nat) (classes : List RoadUserClass) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 classes (Build.scale heading (Q.mul speed (Q.ofInt (k : Int))))
    heading speed carExtent (some (Q.mul speed (Q.ofInt (k : Int))))

/-- `forbid` (violated): The subject, a passenger car, occupies a one-way roadway whose designated direction points east and which a one_way regulatory sign governs; its velocity is 7 m/s due west, the component along the designated direction being strongly negative. No other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driver k [.motorVehicle] Build.west (mps 7) ]
      [ oneWayRoad, highway ]
      [ oneWaySign ]

/-- `permit` (compliant): The same one-way roadway and the same governing sign; the subject travels at 11 m/s due east, with the designated direction, and is the only road user in the scene, so the duty is decided for the subject alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driver k [.motorVehicle] Build.east (mps 11) ]
      [ oneWayRoad, highway ]
      [ oneWaySign ]

/-- `idle` (not_applicable): The subject is a pedal bicycle, which the vehicle aggregate's definition leaves out; it rides westward along the same signposted one-way roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driver k [.bicycle] Build.west (mps 5) ]
      [ oneWayRoad, highway ]
      [ oneWaySign ]

/-- `blind` (unknown): The subject, a car, travels westward on a roadway the source maps as one-way and a one_way sign governs, but the source records no designated direction for the region: st.lane_direction is absent, so which way the designation points, and hence the verdict, is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driver k [.motorVehicle] Build.west (mps 7) ]
      [ oneWayRoad, highway ]
      [ oneWaySign ]

/-- `branch_1` (compliant): The subject stands still at the kerb of the signposted one-way roadway, its velocity zero, so its component along the designated direction is within the motion tolerance of zero and it is not travelling against the direction. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 5) Build.east Q.zero carExtent (some Q.zero) ]
      [ oneWayRoad, highway ]
      [ oneWaySign ]

/-- `branch_2` (not_applicable): The one-way roadway is posted by a no_parking sign and by nothing
    else, so no sign of code one_way governs the region the westward-driven car occupies. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driver k [.motorVehicle] Build.west (mps 7) ]
      [ oneWayRoad, highway ]
      [ noParkingSign ]

/-- `branch_3` (not_applicable): The one_way sign governs the carriageway, but the source maps it as
    a plain roadway on which traffic is not restricted to one direction, so the car driven west
    against the designated direction is under no duty here. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driver k [.motorVehicle] Build.west (mps 7) ]
      [ plainRoad, highway ]
      [ oneWaySign ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_220_1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_220_1
