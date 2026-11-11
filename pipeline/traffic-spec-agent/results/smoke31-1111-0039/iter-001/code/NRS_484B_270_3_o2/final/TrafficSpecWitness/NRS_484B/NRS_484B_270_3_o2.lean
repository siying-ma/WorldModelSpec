/-
  Witnesses for NRS_484B_270_3_o2.

  Geometry (metres, +x east, +y north): a general-traffic lane L (region 10) on y ∈ [-3.5, 0] and a
  bicycle lane b (region 11) on y ∈ [0, 2], both from x = -100 to x = 100. A driveway or alley
  entrance (region 12) is either far, x ∈ [77, 83], y ∈ [2, 8] (tens of metres beyond the 6 m
  access reach from every body in these scenes), or near, x ∈ [-3, 3], y ∈ [2, 8], beside the spot
  where x turns. Cars have half-extents 2.4 × 0.9 × 0.75 m; the bicycle 0.9 × 0.3 × 0.9 m.

  forbid: x enters b at the second instant and drives 50 m along it at 10 m/s (dt 1 s).
  permit: x drives along L at 10 m/s, its body never reaching b.
  idle: a bicycle rides along b.
  blind: the forbid trace with rel.occupies unobserved, judged from the second instant on (the
    first has no observation before it, so an entry there is unknown for that too).
  branch_1: x turns north across b at 4 m/s (dt 0.5 s) into the near entrance; its body is at
    most 0.6 m from the entrance at every instant.
  branch_2: as forbid but on b from the start, with a police officer directing traffic on b and L.
  branch_3: x moves from L onto b and stands there, speed 0, for 60 s (dt 10 s).
  branch_4: a car z stands in L 15 m ahead of x; x, at 10 m/s, swerves onto b at an instant at
    which its predicted closest approach to z is 1.5 m after 0.5 s (below the 3 m clearance, within
    the 4.1 s horizon) and stays on b past z: compliant before the entry, not applicable after.
  branch_5: an official vehicle (tow) drives along b.
  branch_6: an emergency vehicle (police) drives along b.
  branch_7: x turns onto b at 3 m/s beside the near entrance (its body 0.1 m from it: the entry is
    excused), then stands on b at x = 15, its body 9.6 m from the entrance.
  branch_8: as branch_7 to the entry, then drives on along b at 10 m/s from x = 20, its body at
    least 14.6 m from the entrance.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_3_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_3_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneL : Structure := Build.rect 10 .lane (m (-100)) (cm (-350)) (m 100) (m 0)
def bikeB : Structure := Build.rect 11 .bicycleLaneOrPath (m (-100)) (m 0) (m 100) (m 2)
def drivewayFar : Structure := Build.rect 12 .drivewayOrAlleyEntrance (m 77) (m 2) (m 83) (m 8)
def drivewayNear : Structure := Build.rect 12 .drivewayOrAlleyEntrance (m (-3)) (m 2) (m 3) (m 8)

def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 90)

/-- A passenger car at (px, py). -/
def car (track : TrackId) (classes : List RoadUserClass) (px py : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user track classes (px, py) h v carExtent

/-- `forbid` (violated): x drives 50 m along bicycle lane b at 10 m/s; no driveway or alley entrance within reach, no officer, no conflict at its entry, x is a passenger car of no official class. -/
def forbidTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    let xk : Int := -20 + 10 * (Int.ofNat k - 1)
    Build.scene t (some 1)
      [ if k == 0 then car 1 [.motorVehicle] (m (-30)) (cm (-175)) Build.east (Units.metresPerSecond 10)
        else car 1 [.motorVehicle] (m xk) (m 1) Build.east (Units.metresPerSecond 10) ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `permit` (compliant): x stays in its general-traffic lane and never overlaps a bicycle lane or path. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 [.motorVehicle] (m (-30 + 10 * Int.ofNat k)) (cm (-175)) Build.east (Units.metresPerSecond 10) ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `idle` (not_applicable): x is of the bicycle class (not a motor vehicle) riding in b. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (-30 + 5 * Int.ofNat k), m 1) Build.east (Units.metresPerSecond 5) bikeExtent ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `blind` (unknown): As forbid, but rel.occupies of x and b is not observed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): x crosses b at 4 m/s within 2 m of a st.driveway_or_alley_entrance into which it turns. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ car 1 [.motorVehicle] (m 0) (m (-1 + 2 * Int.ofNat k)) Build.north (Units.metresPerSecond 4) ]
      [ laneL, bikeB, drivewayNear ]
      [ ]

/-- `branch_2` (not_applicable): A dev.human_direction with role police_officer governs b and the lane x occupies; x drives along b. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 [.motorVehicle] (m (-30 + 10 * Int.ofNat k)) (m 1) Build.east (Units.metresPerSecond 10) ]
      [ laneL, bikeB, drivewayFar ]
      [ { Build.device 20 .humanDirection [11, 10] (some (m 0, m 3)) with
            humanRole := some .policeOfficer, humanIndication := some .proceed } ]

/-- `branch_3` (violated): x is halted on b (kin.speed 0) for 60 s, away from any driveway, no officer, no official class. -/
def branch_3Trace : Trace :=
  Build.trace 8 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1)
      [ if k == 0 then car 1 [.motorVehicle] (m (-5)) (cm (-175)) Build.east (Units.metresPerSecond 2)
        else car 1 [.motorVehicle] (m 0) (m 1) Build.east Q.zero ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `branch_4` (compliant): x swerves onto b at the instant a car standing ahead in L is in predicted conflict with it, and keeps to b past it (exception c). -/
def branch_4Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let xk : Int := -20 + 10 * (Int.ofNat k - 1)
    Build.scene t (some 1)
      [ if k == 0 then car 1 [.motorVehicle] (m (-30)) (cm (-175)) Build.east (Units.metresPerSecond 10)
        else car 1 [.motorVehicle] (m xk) (cm 50) Build.east (Units.metresPerSecond 10)
      , car 2 [.motorVehicle] (m (-15)) (m (-1)) Build.east Q.zero ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `branch_5` (not_applicable): x, a tow vehicle of the official class, drives along b (exception d). -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ { car 1 [.motorVehicle, .officialVehicle] (m (-30 + 10 * Int.ofNat k)) (m 1) Build.east (Units.metresPerSecond 10) with
            officialKind := some .tow } ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `branch_6` (not_applicable): x, a police car of the emergency class, drives along b (exception d). -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ { car 1 [.motorVehicle, .emergencyVehicle] (m (-30 + 10 * Int.ofNat k)) (m 1) Build.east (Units.metresPerSecond 10) with
            emergencyKind := some .police } ]
      [ laneL, bikeB, drivewayFar ]
      [ ]

/-- `branch_7` (violated): x turns from L onto b beside the driveway entrance while moving (the entry is excused), then stands on b 12 m beyond it: the standing is not. -/
def branch_7Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ if k == 0 then car 1 [.motorVehicle] (m (-6)) (cm (-175)) Build.east (Units.metresPerSecond 3)
        else if k == 1 then car 1 [.motorVehicle] (m (-3)) (m 1) Build.east (Units.metresPerSecond 3)
        else car 1 [.motorVehicle] (m 15) (m 1) Build.east Q.zero ]
      [ laneL, bikeB, drivewayNear ]
      [ ]

/-- `branch_8` (violated): x turns from L onto b beside the driveway entrance while moving (the entry is excused), then drives on along b well beyond the reach: the driving is not. -/
def branch_8Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ if k == 0 then car 1 [.motorVehicle] (m (-6)) (cm (-175)) Build.east (Units.metresPerSecond 3)
        else if k == 1 then car 1 [.motorVehicle] (m (-3)) (m 1) Build.east (Units.metresPerSecond 3)
        else car 1 [.motorVehicle] (m (20 + 10 * (Int.ofNat k - 2))) (m 1) Build.east (Units.metresPerSecond 10) ]
      [ laneL, bikeB, drivewayNear ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_270_3_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (window := some (1000, 6000))
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_3_o2
