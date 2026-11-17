/-
  Witnesses for LVMC_11_20_060_o3.

  Geometry (the witness's own figures, nowhere in the rule):
  - roadway 10: x ∈ [-60, 60], y ∈ [0, 10] m, an east–west carriageway;
  - driveway-or-alley entrance 20 (or alley 30 in branch_7): x ∈ [-3, 3], y ∈ [-10, 0], meeting the
    roadway's south edge;
  - the subject (track 1), a car 5 m × 2 m, comes north out of 20; at 1 s its nose is on the
    roadway, and occupancy is stated per scene (a body across two regions);
  - the other car (track 2), 5 m × 2 m, drives east on the roadway at 10 m/s along y = 2.5,
    x = -25 + 10k at instant k (1 s spacing).
  Against the reading (horizon 3 s, centre clearance 3 m, halt tolerance 0.1 m/s): in forbid at
  1 s the subject at (0, -2) moving north at 2 m/s and the car at (-15, 2.5) reach their closest
  approach at about 1.5 s, about 1.5 m apart; at 2 s the same about 0.5 s ahead. In permit the
  subject is halted (0 m/s) while the car passes, and moves again once the car is past (the
  centres then separate: no approach within the horizon).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_20_060_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_20_060_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def roadwayId : RegionId := 10
def drivewayId : RegionId := 20
def alleyId : RegionId := 30

def roadway : Structure := Build.rect roadwayId .roadway (m (-60)) (m 0) (m 60) (m 10)
def driveway : Structure := Build.rect drivewayId .drivewayOrAlleyEntrance (m (-3)) (m (-10)) (m 3) (m 0)
def alley : Structure := Build.rect alleyId .alley (m (-3)) (m (-10)) (m 3) (m 0)

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)

/-- The subject at (0, y) heading north at `speed`. -/
def subjectAt (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (Q.zero, y) Build.north speed carExtent

/-- The approaching car at instant k: (-25 + 10k, 2.5), heading east at 10 m/s. -/
def approachingCar (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (-25 + 10 * (k : Int)), cm 250) Build.east (Units.metresPerSecond 10) carExtent

def district (b : Bool) : List (AsmId × Bool) := [("asm.business_or_residence_district", b)]

/-- A scene of the subject with the stated occupancy. -/
def sc (t : Timestamp) (users : List RoadUser) (structs : List Structure)
    (occ : List (TrackId × RegionId)) (inDistrict : Bool := true) : Scene :=
  Build.scene t (some 1) users structs [] (occupies := some occ) (assumptions := district inDistrict)

/-- The subject's emerging path: y = -4 + 2k, north at 2 m/s; on the drive only at k = 0, on the
    drive and the roadway from k = 1. -/
def emergingY (k : Nat) : Q := m (-4 + 2 * (k : Int))
def emergingOcc (src : RegionId) (k : Nat) : List (TrackId × RegionId) :=
  if k = 0 then [(1, src)] else [(1, src), (1, roadwayId)]

/-- The emerging pull-out in front of the approaching car (forbid, blind). -/
def pullOutTrace (inDistrict : Bool := true) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sc t [ subjectAt (emergingY k) (Units.metresPerSecond 2), approachingCar k ]
      [ roadway, driveway ]
      (emergingOcc drivewayId k ++ [(2, roadwayId)]) inDistrict

/-- `forbid` (violated): District assumed; the subject pulls out of a driveway into the roadway in front of a car approaching on it; the closest approach falls below the clearance within the horizon while the subject keeps moving. -/
def forbidTrace : Trace := pullOutTrace

/-- `permit` (compliant): Same, but the subject waits at the roadway edge, halted, until the car has passed. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let subj :=
      if k = 0 then subjectAt (m (-4)) (Units.metresPerSecond 2)
      else if k = 3 then subjectAt (m (-2)) (Units.metresPerSecond 2)
      else subjectAt (m (-2)) Q.zero
    sc t [ subj, approachingCar k ] [ roadway, driveway ]
      (emergingOcc drivewayId k ++ [(2, roadwayId)])

/-- `idle` (not_applicable): The subject turns from the roadway into a driveway (it occupied the roadway before the driveway): it is not emerging. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let y : Q := m (5 - 4 * (k : Int))
    let occ : List (TrackId × RegionId) :=
      if k = 0 then [(1, roadwayId)]
      else if k = 1 then [(1, roadwayId), (1, drivewayId)]
      else [(1, drivewayId)]
    sc t [ Build.user 1 [.motorVehicle] (Q.zero, y) Build.south (Units.metresPerSecond 2) carExtent,
           approachingCar k ]
      [ roadway, driveway ] (occ ++ [(2, roadwayId)])

/-- `blind` (unknown): District assumed; the subject emerges in front of an approaching car, but the source does not supply roadway occupancy. -/
def blindTrace : Trace := pullOutTrace

/-- `branch_1` (compliant): District assumed; the subject emerges onto the roadway with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sc t [ subjectAt (emergingY k) (Units.metresPerSecond 2) ] [ roadway, driveway ]
      (emergingOcc drivewayId k)

/-- `branch_2` (violated): the subject waits halted with its nose on the roadway, and a car
    creeping east along the roadway's edge touches it (contact). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let subj :=
      if k = 0 then subjectAt (m (-4)) (Units.metresPerSecond 2) else subjectAt (m (-2)) Q.zero
    let creeper := Build.user 2 [.motorVehicle] (m (-3 + (k : Int)), m 1) Build.east
      (Units.metresPerSecond 1) carExtent
    sc t [ subj, creeper ] [ roadway, driveway ] (emergingOcc drivewayId k ++ [(2, roadwayId)])

/-- `branch_3` (compliant): the subject creeps out at 0.5 m/s while a car approaches on the far
    side of the roadway (y = 8.5): the closest approach lies within the horizon but about 9.7 m
    apart, above the clearance. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let subj := subjectAt (cm (-250 + 50 * (k : Int))) (cm 50)
    let farCar := Build.user 2 [.motorVehicle] (m (-25 + 10 * (k : Int)), cm 850) Build.east
      (Units.metresPerSecond 10) carExtent
    sc t [ subj, farCar ] [ roadway, driveway ] (emergingOcc drivewayId k ++ [(2, roadwayId)])

/-- `branch_4` (compliant): the subject pulls out while a car crosses close by in the unmapped
    parking area beside the driveway (y = -1, not on the roadway): it is not on said roadway. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let offRoad := Build.user 2 [.motorVehicle] (m (-25 + 10 * (k : Int)), m (-1)) Build.east
      (Units.metresPerSecond 10) carExtent
    sc t [ subjectAt (emergingY k) (Units.metresPerSecond 2), offRoad ] [ roadway, driveway ]
      (emergingOcc drivewayId k)

/-- `branch_5` (compliant): the subject pulls out in front of a bicycle riding on the roadway:
    a bicycle is not a vehicle of the aggregate, so this duty does not reach it. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let bike := Build.user 2 [.bicycle] (m (-15 + 5 * (k : Int)), m 2) Build.east
      (Units.metresPerSecond 5) (m 1, cm 30, m 1)
    sc t [ subjectAt (emergingY k) (Units.metresPerSecond 2), bike ] [ roadway, driveway ]
      (emergingOcc drivewayId k ++ [(2, roadwayId)])

/-- `branch_6` (not_applicable): the forbid pull-out, but the place is not in a business or
    residence district. -/
def branch_6Trace : Trace := pullOutTrace false

/-- `branch_7` (violated): the forbid pull-out, emerging from an alley rather than a driveway. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sc t [ subjectAt (emergingY k) (Units.metresPerSecond 2), approachingCar k ]
      [ roadway, alley ]
      (emergingOcc alleyId k ++ [(2, roadwayId)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_20_060_o3"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.LVMC_11_20_060_o3
