/-
  Witnesses for NRS_484B_208_1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - An eastbound controlled-access carriageway (region 10, x −500…1500 m, y −1…13 m) with three
    lanes heading east: lane 11 (y 8…12, ordinal 1 of 3, leftmost: left is north), lane 12
    (y 4…8, ordinal 2) and lane 13 (y 0…4, ordinal 3). A maximum speed-limit sign (device 100) of
    29 m/s governs the three lanes.
  - Instants every second, 0…30 s. The subject (track 1, a car, half-extents 2 × 1 × 1 m) drives
    east at 24 m/s, x = 24·t. In the base timeline it is in the middle lane (y = 6) at t = 0 and
    has moved into the leftmost lane (y = 10) from t = 1 s: at t = 0 it is not in the extreme left
    lane, so the history the rule's `since` reads starts decided.
  - The faster car (track 2, a car, 2 × 1 × 1 m) comes from 80 m behind in the leftmost lane at
    32 m/s, x = −80 + 32·t, until t = 8 s, then follows at 24 m/s (x = 176 + 24·(t − 8)), 16 m
    centre to centre behind the subject.
  - Dry surface, no rain, visibility 1000 m: at 24 m/s the reading's stopping distance is
    24·2 + 24²/12 = 96 m dry, 24·3 + 24²/8 = 144 m wet, 24·6 + 24²/2 = 432 m on ice.
  - The subject shows no warning lamp and no siren (observed), so the emergency-vehicle exception
    is decided false whatever the reading says of its class.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_208_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_208_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def caId : RegionId := 10
def l1 : RegionId := 11
def l2 : RegionId := 12
def l3 : RegionId := 13
def ixId : RegionId := 60
def obstacleId : RegionId := 70

def xw : Q := m (-500)
def xe : Q := m 1500

def controlledAccess : Structure := Build.rect caId .controlledAccess xw (m (-1)) xe (m 13)
def laneL1 : Structure :=
  Build.lane l1 [(xw, m 8), (xe, m 8), (xe, m 12), (xw, m 12)] Build.east none (some l2) (some 1) (some 3)
def laneL2 : Structure :=
  Build.lane l2 [(xw, m 4), (xe, m 4), (xe, m 8), (xw, m 8)] Build.east (some l1) (some l3) (some 2) (some 3)
def laneL3 : Structure :=
  Build.lane l3 [(xw, m 0), (xe, m 0), (xe, m 4), (xw, m 4)] Build.east (some l2) none (some 3) (some 3)
/-- The leftmost lane as a high-occupancy lane. -/
def hovL1 : Structure := { laneL1 with kind := .reservedLane, reservedClass := some .highOccupancy }

def speedSign : Device := Build.speedLimit 100 [l1, l2, l3] (mps 29) .maximum

def dry : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false, visibility := some (m 1000) }

def quiet : Signals := { warningLamps := some [], siren := some false }

structure Cfg where
  subjClasses : List RoadUserClass := [.motorVehicle]
  subjY : Nat → Q := fun k => if k == 0 then m 6 else m 10
  subjSig : Nat → Signals := fun _ => quiet
  subjEmergency : Option EmergencyKind := none
  subjOfficial : Option OfficialKind := none
  subjOccupants : Option Nat := none
  fastY : Option Q := some (m 10)
  others : Nat → List RoadUser := fun _ => []
  l1Reserved : Bool := false
  structures : List Structure := []
  devices : List Device := []
  env : Env := dry
  city : Bool := false
  intents : List DeclaredIntent := []

def subjectAt (c : Cfg) (k : Nat) : RoadUser :=
  let u := Build.user 1 c.subjClasses (m (24 * (k : Int)), c.subjY k) Build.east (mps 24) (m 2, m 1, m 1)
  { u with sig := c.subjSig k, emergencyKind := c.subjEmergency, officialKind := c.subjOfficial,
           occupants := c.subjOccupants }

def fastX (k : Nat) : Q := if k < 8 then m (-80 + 32 * (k : Int)) else m (176 + 24 * ((k : Int) - 8))
def fastSpeed (k : Nat) : Q := if k < 8 then mps 32 else mps 24
def fastAt (y : Q) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (fastX k, y) Build.east (fastSpeed k) (m 2, m 1, m 1)

def sceneAt (c : Cfg) (k : Nat) (t : Timestamp) : Scene :=
  let fast := match c.fastY with
    | some y => [fastAt y k]
    | none => []
  Build.scene t (some 1) ([subjectAt c k] ++ fast ++ c.others k)
    ([controlledAccess, (if c.l1Reserved then hovL1 else laneL1), laneL2, laneL3] ++ c.structures)
    ([speedSign] ++ c.devices)
    (env := c.env) (assumptions := [("asm.within_city_or_town_limits", c.city)]) (intents := c.intents)

def run (c : Cfg) : Trace := Build.trace 31 0 (Units.seconds 1) fun k t => sceneAt c k t

/-- The subject in the leftmost lane from the first instant (scenes whose exception holds throughout). -/
def inLeftLane : Nat → Q := fun _ => m 10

/-- `forbid` (violated): Three-lane controlled-access highway outside city limits (asm.within_city_or_town_limits false), dry; a maximum speed sign of 29 m/s governs the lanes. The subject car drives in the leftmost lane at 24 m/s; a car approaches from 80 m behind in the same lane at 32 m/s, closes and then follows at 24 m/s; the subject stays in the leftmost lane for 30 s with the middle lane empty. -/
def forbidTrace : Trace := run {}

/-- `permit` (compliant): Same scene; the subject signals and moves to the middle lane 5 s after the faster car closes from behind. -/
def permitTrace : Trace :=
  run { subjY := fun k => if k == 0 then m 6 else if k ≤ 5 then m 10 else m 6
        subjSig := fun k => { quiet with turnIndicator := some (if k == 4 || k == 5 then .right else .off) } }

/-- `idle` (not_applicable): The subject car drives in the middle lane at 24 m/s with a faster car behind it. -/
def idleTrace : Trace := run { subjY := fun _ => m 6, fastY := some (m 6) }

/-- `blind` (unknown): Same scene as forbid; the source declares dev.speed_limit_sign absent, so whether the subject is below the posted limit is unknown. -/
def blindTrace : Trace := run {}

/-- `branch_1` (not_applicable): Same scene with the reading placing the highway within city limits (asm.within_city_or_town_limits true). -/
def branch_1Trace : Trace := run { city := true }

/-- `branch_2` (compliant): Same scene; a lane control signal showing red_x governs the middle lane throughout, closing it. -/
def branch_2Trace : Trace :=
  run { subjY := inLeftLane, devices := [{ Build.device 110 .laneControlSignal [l2] with laneControl := some .redX }] }

/-- `branch_3` (compliant): The subject drives in the leftmost lane at 24 m/s with no other road user in the scene. -/
def branch_3Trace : Trace := run { subjY := inLeftLane, fastY := none }

/-- `branch_4` (not_applicable): The subject is an authorized emergency vehicle with its warning lamps flashing, driving in the leftmost lane at 24 m/s with a faster car closing from behind. -/
def branch_4Trace : Trace :=
  run { subjY := inLeftLane
        subjClasses := [.motorVehicle, .emergencyVehicle]
        subjEmergency := some .police
        subjSig := fun _ =>
          { warningLamps := some [ { colour := .red, mode := .flashing, facing := .front }
                                 , { colour := .blue, mode := .flashing, facing := .front } ]
            siren := some false } }

/-- `branch_5` (compliant): Same scene; the middle lane is occupied by a truck travelling alongside the subject at a body gap of 5 m throughout, so moving right is not possible. The truck (track 3, half-extents 6 × 1.25 × 2 m) keeps its front 5 m behind the subject's rear, in the middle lane. -/
def branch_5Trace : Trace :=
  run { subjY := inLeftLane
        others := fun k => [Build.user 3 [.truck] (m (24 * (k : Int) - 13), m 6) Build.east (mps 24) (m 6, cm 125, m 2)] }

/-- `branch_6` (compliant): The subject, in the leftmost lane, overtakes a truck (track 3) driving at
    14 m/s in the rightmost lane (30 m ahead at t = 0, behind it from t = 4 s), while the faster car
    closes from behind; the pass excuses it, and the instants judged end before the move-over
    window has run from the end of the pass. -/
def branch_6Trace : Trace :=
  run { subjY := inLeftLane
        others := fun k => [Build.user 3 [.truck] (m (30 + 14 * (k : Int)), m 2) Build.east (mps 14) (m 6, cm 125, m 2)] }

/-- `branch_7` (compliant): Same scene; the source declares the subject's plan to turn left at an
    intersection ahead (region 60, x 1200…1240 m). -/
def branch_7Trace : Trace :=
  run { subjY := inLeftLane
        structures := [Build.rect ixId .intersection (m 1200) (m (-1)) (m 1240) (m 13)]
        intents := [{ vehicle := 1, target := ixId, values := [("int.left_turn", true)] }] }

/-- `branch_8` (compliant): Same scene with the leftmost lane a high-occupancy lane; the subject
    carries two persons; the lane's high-occupancy zone sign (device 101) requires two occupants. A
    no-passing zone sign on the same lane (device 102) and a high-occupancy sign on the middle lane
    (device 103), each requiring three, do not bind the subject. -/
def branch_8Trace : Trace :=
  run { subjY := inLeftLane
        subjOccupants := some 2
        l1Reserved := true
        devices :=
          [ Build.zoneSign 101 [l1] .highOccupancyLane false (some { minOccupancy := some 2 })
          , Build.zoneSign 102 [l1] .noPassing false (some { minOccupancy := some 3 })
          , Build.zoneSign 103 [l2] .highOccupancyLane false (some { minOccupancy := some 3 }) ] }

/-- `branch_9` (compliant): Same scene; a barrier (region 70, y 5…7 m) runs along the middle lane,
    2 m to the subject's right. -/
def branch_9Trace : Trace :=
  run { subjY := inLeftLane
        structures := [{ Build.rect obstacleId .obstruction xw (m 5) xe (m 7) with obstructionKind := some .barrier }] }

/-- `branch_10` (compliant): Same scene on a wet road, no rain, visibility 120 m: below the wet
    stopping distance (144 m), above the dry one (96 m). -/
def branch_10Trace : Trace :=
  run { subjY := inLeftLane, env := { dry with wetRoad := some true, visibility := some (m 120) } }

/-- `branch_11` (compliant): Same scene in falling rain on a road not yet wet, visibility 120 m. -/
def branch_11Trace : Trace :=
  run { subjY := inLeftLane, env := { dry with precipitation := some true, visibility := some (m 120) } }

/-- `branch_12` (compliant): Same scene on an icy road, visibility 300 m: below the icy stopping
    distance (432 m), above the dry one. -/
def branch_12Trace : Trace :=
  run { subjY := inLeftLane, env := { dry with iceOrSnow := some true, visibility := some (m 300) } }

/-- `branch_13` (compliant): Same scene; a closed-to-traffic regulatory sign governs the middle lane. -/
def branch_13Trace : Trace :=
  run { subjY := inLeftLane
        devices := [{ Build.sign 111 .regulatorySign [l2] with code := some .closedToTraffic, conditions := some {} }] }

/-- `branch_14` (compliant): Same scene; temporary traffic control (cones) governs the middle lane. -/
def branch_14Trace : Trace :=
  run { subjY := inLeftLane, devices := [Build.device 112 .temporaryTrafficControl [l2]] }

/-- `branch_15` (compliant): Same scene; a police officer directs the middle lane's traffic to stop. -/
def branch_15Trace : Trace :=
  run { subjY := inLeftLane
        devices := [{ Build.device 113 .humanDirection [l2] with humanRole := some .policeOfficer, humanIndication := some .stop }] }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_208_1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.speed_limit_sign"] (window := some (0, 20000))
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant (window := some (0, 14000))
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .compliant
  , witness "branch_14" branch_14Trace .compliant
  , witness "branch_15" branch_15Trace .compliant ]

end TrafficSpecWitness.NRS_484B_208_1
