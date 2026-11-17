/-
  Witnesses for NRS_484B_223_3c.

  Geometry (the witness's own figures; none appears in the rule). A highway (region 1) runs
  east–west, y ∈ [0, 12] m, x ∈ [-200, 200] m. On it: an eastbound through lane (region 2,
  y ∈ [0, 4]), the centre turn lane (region 3, y ∈ [4, 8], lying on the highway: `ways = [1]`)
  and a westbound through lane (region 4, y ∈ [8, 12]). A private driveway entrance (region 5,
  x ∈ [-3, 3], y ∈ [-20, 0]) lies off the highway to the south. Occupancy follows the reference
  point of the subject (track 1, a motor vehicle, half extents 2.3 × 0.9 × 0.8 m).

  Instants every 1 s from t = 0; a yaw rate is held over the interval before its scene. The turn
  (forbid, permit, blind): the subject waits in the driveway at (0, -10) heading north for
  k = 0 … 9, moves to (0, -5) at k = 10, and turns left 90 degrees over the next interval
  (yaw rate 90 deg/s at k = 11, heading west at (-3, 3) in the eastbound lane). At k = 12 its yaw
  rate is zero in the centre turn lane at (-7, 6): the turn is recognized there, with driveway
  observations (off the highway) inside the 10 s window behind. It then travels west in the
  centre turn lane, 5 m per instant, and moves into the westbound lane.
    forbid: 30 m in the centre lane (k = 12 … 18), in the westbound lane from k = 19: the
      distance in the lane after the turn passes 50 ft (15.24 m) at k = 16 (20 m).
    permit: 10 m in the centre lane (k = 12 … 14), in the westbound lane from k = 15.
    blind:  the forbid trace with kin.yaw_rate unobserved: the turn cannot be recognized.
    idle:   the subject drives straight west in the westbound lane, no yaw, never in the
      centre turn lane.
  Path length is cumulative and never less than the straight-line distance between scenes.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_3c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_3c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highwayId : RegionId := 1
def eastLaneId : RegionId := 2
def centreLaneId : RegionId := 3
def westLaneId : RegionId := 4
def drivewayId : RegionId := 5

def structures : List Structure :=
  [ Build.rect highwayId .highway (m (-200)) (m 0) (m 200) (m 12)
  , { Build.rect eastLaneId .lane (m (-200)) (m 0) (m 200) (m 4) with ways := some [highwayId] }
  , { Build.rect centreLaneId .centreTurnLane (m (-200)) (m 4) (m 200) (m 8) with ways := some [highwayId] }
  , { Build.rect westLaneId .lane (m (-200)) (m 8) (m 200) (m 12) with ways := some [highwayId] }
  , Build.rect drivewayId .drivewayOrAlleyEntrance (m (-3)) (m (-20)) (m 3) (m 0) ]

def half : Q × Q × Q := (cm 230, cm 90, cm 80)

/-- The subject at instant `k` of a turn from the driveway into the centre lane, leaving the
    centre lane for the westbound lane at instant `leave`. -/
def turner (leave : Nat) (k : Nat) : RoadUser :=
  let path : Q :=
    if k ≤ 9 then m 0
    else if k = 10 then m 5
    else if k = 11 then m 14
    else if k < leave then m (20 + 5 * ((k : Int) - 12))
    else m (22 + 5 * ((k : Int) - 12))
  let (pos, hd, yaw) : Vec × Vec × Q :=
    if k ≤ 9 then ((m 0, m (-10)), Build.north, Units.degrees 0)
    else if k = 10 then ((m 0, m (-5)), Build.north, Units.degrees 0)
    else if k = 11 then ((m (-3), m 3), Build.west, Units.degrees 90)
    else
      let x : Q := m (-7 - 5 * ((k : Int) - 12))
      if k < leave then ((x, m 6), Build.west, Units.degrees 0)
      else ((x, m 10), Build.west, Units.degrees 0)
  let spd : Q := if k ≤ 9 then m 0 else Units.metresPerSecond 5
  Build.withKin (Build.user 1 [.motorVehicle] pos hd spd half (some path))
    (fun kin => { kin with yawRate := some yaw })

def turnTrace (n leave : Nat) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turner leave k] structures []

/-- `forbid` (violated): The subject leaves a private driveway, turns left by 85 degrees into the st.centre_turn_lane, travels 30 m in it, then moves to a through lane. -/
def forbidTrace : Trace := turnTrace 22 19

/-- `permit` (compliant): The subject turns left from a driveway into the centre turn lane, travels 10 m in it and merges into the through lane. -/
def permitTrace : Trace := turnTrace 18 15

/-- `idle` (not_applicable): The subject drives straight in a through lane; it makes no left turn into a centre turn lane. -/
def idleTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (100 - 5 * (k : Int)), m 10) Build.west
            (Units.metresPerSecond 5) half (some (m (5 * (k : Int)))))
          (fun kin => { kin with yawRate := some (Units.degrees 0) }) ]
      structures []

/-- `blind` (unknown): The subject comes from a driveway into the centre turn lane and travels 30 m in it, but kin.yaw_rate is not observed. -/
def blindTrace : Trace := turnTrace 22 19

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_3c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (10000, 19000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ { witness "forbid" forbidTrace .violated with window := some (10000, 21000) }
  , { witness "permit" permitTrace .compliant with window := some (10000, 17000) }
  , witness "idle" idleTrace .notApplicable
  , { witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] with window := some (10000, 21000) } ]

end TrafficSpecWitness.NRS_484B_223_3c
