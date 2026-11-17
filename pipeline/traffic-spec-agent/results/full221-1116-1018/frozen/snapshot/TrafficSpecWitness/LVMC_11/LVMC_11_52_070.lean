/-
  Witnesses for LVMC_11_52_070.

  Geometry (the witness's own figures; none appears in the rule):
  - lane 1: eastbound lane, x −100…200 m, y 0…4 m, direction east;
  - lane 3: westbound lane across the street, x −100…200 m, y −4…0 m, direction west;
  - bay 2: a marked parking space beside lane 1, x 40…46 m, y 4…10 m, angle 45° (angled), or a
    parallel bay y 4…6.5 m, angle 0° (idle);
  - bay 4: an angled bay (45°) further along, x 80…86 m, y 4…10 m, not occupied (branch_4);
  - sign 10/11: regulatory signs (angle_parking, or no_parking in branch_4), legend unconditional;
  - the car (track 1, a motor vehicle, 4.8 m × 1.8 m) at (43, 5): its body overlaps both bay 2
    and lane 1, stated as occupancy since its reference point lies in one polygon.
  Instants: every 10 s over 300 s (31 scenes); the verdict is judged from 70 s on, so the 60 s
  standing window (p.standing_min_duration) is covered at every judged instant. Headings: "against"
  is (−1, 1) (north-west, dot with east −1), "with" is (1, 1) (north-east, dot +1), bounds of the
  dot product's sign by a clear margin; at rest the speed is 0 against the 0.1 m/s tolerance.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_070
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_070

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def lane1 : Structure :=
  Build.lane 1 [(m (-100), m 0), (m 200, m 0), (m 200, m 4), (m (-100), m 4)] Build.east
def lane3 : Structure :=
  Build.lane 3 [(m (-100), m (-4)), (m 200, m (-4)), (m 200, m 0), (m (-100), m 0)] Build.west

def angledBay (id : RegionId) (x0 : Int) : Structure :=
  { Build.rect id .parkingSpace (m x0) (m 4) (m (x0 + 6)) (m 10) with
      parkingAngle := some (Units.degrees 45), designation := some .general }
def parallelBay : Structure :=
  { Build.rect 2 .parkingSpace (m 40) (m 4) (m 46) (cm 650) with
      parkingAngle := some (Units.degrees 0), designation := some .general }

def regSign (id : DeviceId) (code : SignCode) (governs : List RegionId) : Device :=
  { Build.sign id .regulatorySign governs with code := some code, conditions := some {} }

def against : Vec := (m (-1), m 1)
def withTraffic : Vec := (m 1, m 1)

def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading speed (cm 240, cm 90, cm 75)

/-- A car at rest at (43, 5) for 300 s, observed every 10 s. -/
def standing (heading : Vec) (structures : List Structure) (devices : List Device)
    (occ : List (TrackId × RegionId)) : Trace :=
  Build.trace 31 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 43, m 5) heading Q.zero] structures devices (some occ)

/-- `forbid` (violated): A car has backed into an angled bay (angle 45 degrees) on a street whose lane carries an angle_parking sign; its rear overlaps the lane and its heading is opposite the lane's direction; it stays at rest for 5 minutes. -/
def forbidTrace : Trace :=
  standing against [lane1, angledBay 2 40] [regSign 10 .angleParking [1]] [(1, 1), (1, 2)]

/-- `permit` (compliant): A car stands for 5 minutes in the same angled bay with its heading 45 degrees off the lane's direction, pointing forward with traffic: the dot product with the lane's direction is positive. -/
def permitTrace : Trace :=
  standing withTraffic [lane1, angledBay 2 40] [regSign 10 .angleParking [1]] [(1, 1), (1, 2)]

/-- `idle` (not_applicable): A car is parked parallel to the curb on a street with no angle_parking sign and no angled bay: the rule does not apply. -/
def idleTrace : Trace :=
  standing Build.west [lane1, parallelBay] [] [(1, 1), (1, 2)]

/-- `blind` (unknown): A car is parked in an angled bay at an angle_parking sign, but the source does not supply headings (kin.heading absent): where its front points is unknown. -/
def blindTrace : Trace :=
  standing against [lane1, angledBay 2 40] [regSign 10 .angleParking [1]] [(1, 1), (1, 2)]

/-- `branch_1` (compliant): A car pulls into the angled bay heading against the lane's direction, halts 20 seconds to let a passenger out and leaves: it neither stands nor parks for the standing duration. -/
def branch_1Trace : Trace :=
  Build.trace 16 0 (Units.seconds 10) fun k t =>
    let halted := 7 ≤ k && k ≤ 9
    let pos : Vec :=
      if k < 7 then (m (43 + 10 * (7 - (k : Int))), m 2)
      else if halted then (m 43, m 5)
      else (m (43 - 10 * ((k : Int) - 9)), m 2)
    let speed := if halted then Q.zero else Units.metresPerSecond 1
    Build.scene t (some 1) [car pos Build.west speed] [lane1, angledBay 2 40]
      [regSign 10 .angleParking [1]] (some (if halted then [(1, 1), (1, 2)] else [(1, 1)]))

/-- `branch_2` (violated): the angled-bay limb alone — no sign; the car stands in the angled bay
    across lane 1 facing against the lane's direction. -/
def branch_2Trace : Trace :=
  standing against [lane1, angledBay 2 40] [] [(1, 1), (1, 2)]

/-- `branch_3` (violated): the sign limb alone — an angle_parking sign governs lane 1, no bay is
    marked; the car stands in lane 1 facing against its direction. -/
def branch_3Trace : Trace :=
  standing against [lane1] [regSign 10 .angleParking [1]] [(1, 1)]

/-- `branch_4` (not_applicable): the car stands in lane 1 facing against it; lane 1 carries a
    no_parking sign, not an angle_parking one; the angle_parking sign governs lane 3 across the
    street, which the car does not occupy; the angled bay 4 further along is not occupied. -/
def branch_4Trace : Trace :=
  standing against [lane1, lane3, angledBay 4 80]
    [regSign 10 .noParking [1], regSign 11 .angleParking [3]] [(1, 1)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (70000, 300000)) : Scenario :=
  { name := name
    rule := "LVMC_11_52_070"
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
  , witness "blind" blindTrace (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace .compliant (window := some (70000, 150000))
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_52_070
