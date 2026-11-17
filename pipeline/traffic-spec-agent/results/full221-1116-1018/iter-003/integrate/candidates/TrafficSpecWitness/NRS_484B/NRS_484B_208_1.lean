/-
  Witnesses for NRS_484B_208_1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - A three-lane controlled-access carriageway (region 100) heading east (+x), x from -1000 m to
    3000 m. Lanes 3.5 m wide: L1 (111, leftmost, y 7–10.5 m, centre 8.75), L2 (112, middle,
    y 3.5–7, centre 5.25), L3 (113, rightmost, y 0–3.5, centre 1.75); count 3 in the direction.
  - A maximum speed-limit sign (201) of 29 m/s governs L1, L2 and L3.
  - Instants every 5 s, k = 0 … 6 (t = 5000·k ms): half the 10 s windows of the reading, the
    sampling the windows need. The subject (track 1, a car 5 m × 2 m) runs at 24 m/s at
    x = 120·k m; it is in the middle lane at k = 0 and merges into L1 at k = 1 (t = 5 s), so the
    duty's search into the past starts from an observed instant where the duty's state S is false.
  - The rear car (track 2, a car) is in L1 behind the subject: gap = max(24, G − 40·k) metres centre
    to centre (closing at 8 m/s), at 32 m/s while it closes and 24 m/s once it follows. G = 120
    (80 m behind at t = 5 s, closing until t = 15 s: forbid and the scenes "as forbid") or G = 250
    (closing until t = 25 s: the compliant branches whose exception holds, so that a faster car is
    behind for longer than the move-over time and the exception alone keeps the subject compliant).
  - Reading values used against the geometry: move-over time 10 s; overtake window 10 s, cosine
    0.9; dry stopping distance at 24 m/s = 24·2 + 24²/12 = 96 m, wet 144 m, ice 432 m.
  - Dry clear weather (visibility 2000 m), outside city limits, civil time 08:00, unless a branch
    says otherwise. The subject shows no warning lamp and no siren unless a branch says otherwise.
  - Violation in forbid at t = 15 s: S held at t = 5, 10, 15 since O ∧ S at t = 5, and the rear car
    is behind the subject in L1.
  - Some branches added beyond the plan start their exception at t = 10 s, after O ∧ S held at
    t = 5 s (a declared intention, the civil time, the weather, a truck changing lanes, a police
    officer); fixed devices and map structures are in every scene, as the adapter requires.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_208_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_208_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def yL1 : Q := cm 875
def yL2 : Q := cm 525
def yL3 : Q := cm 175

def carriageway : Structure := Build.rect 100 .controlledAccess (m (-1000)) (m 0) (m 3000) (cm 1050)
def laneL1 (enters : Option RegionId := none) : Structure :=
  Build.lane 111 (box (m (-1000)) (cm 700) (m 3000) (cm 1050)) Build.east none (some 112) (some 1) (some 3) none enters
def laneL2 : Structure :=
  Build.lane 112 (box (m (-1000)) (cm 350) (m 3000) (cm 700)) Build.east (some 111) (some 113) (some 2) (some 3)
def laneL3 : Structure :=
  Build.lane 113 (box (m (-1000)) (m 0) (m 3000) (cm 350)) Build.east (some 112) none (some 3) (some 3)
/-- L1 as a high-occupancy reserved lane. -/
def hovL1 : Structure := { laneL1 with kind := .reservedLane, reservedClass := some .highOccupancy }

def speedSign : Device := Build.speedLimit 201 [111, 112, 113] (Units.metresPerSecond 29) .maximum

def civil (minute : Nat) : CivilTime :=
  { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := minute }

def dryClear : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false
    visibility := some (m 2000), civilTime := some (civil 480) }

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)
def truckExtent : Q × Q × Q := (cm 600, cm 125, cm 200)

/-- What varies between the scenes (k is the instant index, t = 5·k s). -/
structure Cfg where
  /-- first instant in L1 (before: middle lane) -/
  leftFrom : Nat := 1
  /-- first instant back in the middle lane -/
  leftUntil : Option Nat := none
  /-- the rear car's centre gap at k = 0 (m); `none`: no rear car -/
  rearGap : Option Int := some 120
  rearInMiddle : Bool := false
  city : Bool := false
  subjectClasses : List RoadUserClass := [.motorVehicle]
  officialKind : Option OfficialKind := none
  occupants : Option Nat := none
  lampsAt : Nat → List WarningLamp := fun _ => []
  l1 : Structure := laneL1
  othersAt : Nat → Int → List RoadUser := fun _ _ => []
  structuresAt : Nat → List Structure := fun _ => []
  devicesAt : Nat → List Device := fun _ => []
  envAt : Nat → Env := fun _ => dryClear
  intentsAt : Nat → List DeclaredIntent := fun _ => []

def subjectX (k : Nat) : Int := 120 * (k : Int)

def inLeft (c : Cfg) (k : Nat) : Bool :=
  decide (k ≥ c.leftFrom) && (match c.leftUntil with | some u => decide (k < u) | none => true)

def subjectAt (c : Cfg) (k : Nat) : RoadUser :=
  let u := Build.user 1 c.subjectClasses (m (subjectX k), if inLeft c k then yL1 else yL2) Build.east
    (Units.metresPerSecond 24) carExtent
  let u := Build.withSignals u fun s => { s with warningLamps := some (c.lampsAt k), siren := some false }
  { u with officialKind := c.officialKind, occupants := c.occupants }

def rearAt (c : Cfg) (k : Nat) : List RoadUser :=
  match c.rearGap with
  | none => []
  | some g =>
    let raw := g - 40 * (k : Int)
    let gap := if raw > 24 then raw else 24
    let speed := if raw > 24 then Units.metresPerSecond 32 else Units.metresPerSecond 24
    [Build.user 2 [.motorVehicle] (m (subjectX k - gap), if c.rearInMiddle then yL2 else yL1) Build.east speed carExtent]

def sceneAt (c : Cfg) (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    ([subjectAt c k] ++ rearAt c k ++ c.othersAt k (subjectX k))
    ([carriageway, c.l1, laneL2, laneL3] ++ c.structuresAt k)
    ([speedSign] ++ c.devicesAt k)
    (env := c.envAt k)
    (assumptions := [("asm.within_city_or_town_limits", c.city)])
    (intents := c.intentsAt k)

def traceOf (c : Cfg) : Trace := Build.trace 7 0 (Units.seconds 5) fun k t => sceneAt c k t

/-- A compliant scene whose exception holds: the rear car closes until t = 25 s. -/
def longCfg : Cfg := { rearGap := some 250 }

/-- A truck (track 3) in L3 before instant `fromK`, in L2 from it, `ahead` centimetres ahead of the
    subject's centre, at the subject's speed. -/
def truckBeside (ahead : Int) (fromK : Nat) : Nat → Int → List RoadUser := fun k x =>
  [Build.user 3 [.truck] (Q.add (m x) (cm ahead), if k ≥ fromK then yL2 else yL3) Build.east
    (Units.metresPerSecond 24) truckExtent]

def leftTurn (target : RegionId) (v : Bool) : DeclaredIntent :=
  { vehicle := 1, target := target, values := [("int.left_turn", v)] }

/-- An intersection beyond the end of the carriageway, which L1 enters. -/
def junctionAhead : Structure := Build.rect 121 .intersection (m 3000) (m 0) (m 3030) (cm 1050)
/-- Another intersection, which no lane of the scene enters. -/
def junctionElsewhere : Structure := Build.rect 122 .intersection (m 3000) (m 20) (m 3030) (m 50)

def hovSign (minOcc : Nat) : Device :=
  Build.zoneSign 206 [111] .highOccupancyLane false
    (some { windows := [{ startMinute := 420, endMinute := 600 }], minOccupancy := some minOcc })

/-- `forbid` (violated): Three-lane controlled-access highway outside city limits (asm.within_city_or_town_limits false), dry; a maximum speed sign of 29 m/s governs the lanes. The subject car, showing no warning lamp and no siren, drives in the leftmost lane at 24 m/s; a car approaches from 80 m behind in the same lane at 32 m/s, closes and then follows at 24 m/s; the subject stays in the leftmost lane for 30 s with the middle lane empty. -/
def forbidTrace : Trace := traceOf {}

/-- `permit` (compliant): Same scene; the subject signals and moves to the middle lane 5 s after the faster car closes from behind. -/
def permitTrace : Trace := traceOf { leftUntil := some 2 }

/-- `idle` (not_applicable): The subject car drives in the middle lane at 24 m/s with a faster car behind it. -/
def idleTrace : Trace := traceOf { leftFrom := 1000, rearInMiddle := true }

/-- `blind` (unknown): Same scene as forbid; the source declares dev.speed_limit_sign absent, so whether the subject is below the posted limit is unknown. -/
def blindTrace : Trace := traceOf {}

/-- `branch_1` (not_applicable): Same scene with the reading placing the highway within city limits (asm.within_city_or_town_limits true). -/
def branch_1Trace : Trace := traceOf { city := true }

/-- `branch_2` (compliant): Same scene; a lane control signal showing red_x governs the middle lane throughout, closing it. -/
def branch_2Trace : Trace :=
  traceOf { longCfg with devicesAt := fun _ => [{ Build.device 202 .laneControlSignal [112] with laneControl := some .redX }] }

/-- `branch_3` (compliant): The subject drives in the leftmost lane at 24 m/s with no other road user in the scene. -/
def branch_3Trace : Trace := traceOf { rearGap := none }

/-- `branch_4` (compliant): Same scene as forbid; the subject is a highway-maintenance vehicle in road service with an amber warning lamp flashing throughout. -/
def branch_4Trace : Trace :=
  traceOf { longCfg with subjectClasses := [.motorVehicle, .officialVehicle], officialKind := some .highwayMaintenance
                         lampsAt := fun _ => [{ colour := .amber, mode := .flashing, facing := .rear }] }

/-- `branch_5` (compliant): Same scene; the middle lane is occupied by a truck travelling alongside the subject at a body gap of 5 m throughout, so moving right is not possible. -/
def branch_5Trace : Trace := traceOf { longCfg with othersAt := truckBeside 1350 0 }

/-- `branch_6` (compliant): Same scene as forbid; the leftmost lane the subject occupies enters an intersection ahead, and the source declares the subject's plan to turn left at that intersection throughout. -/
def branch_6Trace : Trace :=
  traceOf { longCfg with l1 := laneL1 (some 121), structuresAt := fun _ => [junctionAhead]
                         intentsAt := fun _ => [leftTurn 121 true] }

/-- `branch_7` (violated): Same scene as branch_6, except that the intersection at which the source declares the subject's plan to turn left is one that no region the subject occupies enters and that the subject never occupies. -/
def branch_7Trace : Trace :=
  traceOf { l1 := laneL1 (some 121), structuresAt := fun _ => [junctionAhead, junctionElsewhere]
            intentsAt := fun _ => [leftTurn 121 false, leftTurn 122 true] }

/-- `branch_8` (compliant): the subject overtakes and passes a truck at 14 m/s in L3 (25 m ahead at
    t = 15 s, 25 m behind at t = 20 s), so the overtaking exception holds over t = 10 … 20 s; judged
    over the first 20 s, before a new move-over window completes after the pass. -/
def branch_8Trace : Trace :=
  traceOf { longCfg with othersAt := fun k _ =>
    [Build.user 3 [.truck] (m (175 + 70 * (k : Int)), yL3) Build.east (Units.metresPerSecond 14) truckExtent] }

/-- `branch_9` (compliant): the subject drives through an intersection region laid over L1 from
    x = 200 m (it occupies it from t = 10 s), and the source declares its plan to turn left there
    from t = 10 s (declared absent before). -/
def branch_9Trace : Trace :=
  traceOf { longCfg with structuresAt := fun _ => [Build.rect 121 .intersection (m 200) (cm 700) (m 2000) (cm 1050)]
                         intentsAt := fun k => [leftTurn 121 (decide (k ≥ 2))] }

/-- `branch_10` (compliant): L1 is a high-occupancy lane signed for 07:00–10:00, at least two
    occupants; the subject carries two; the restricted hours begin at t = 10 s (06:59 before). -/
def branch_10Trace : Trace :=
  traceOf { longCfg with l1 := hovL1, occupants := some 2, devicesAt := fun _ => [hovSign 2]
                         envAt := fun k => { dryClear with civilTime := some (civil (if k ≥ 2 then 420 else 419)) } }

/-- `branch_11` (violated): Same HOV lane at 08:00; the subject carries one occupant, so it does not
    meet the lane's conditions. -/
def branch_11Trace : Trace :=
  traceOf { l1 := hovL1, occupants := some 1, devicesAt := fun _ => [hovSign 2] }

/-- `branch_12` (compliant): wet road; from t = 10 s a truck in the middle lane 130 m ahead (body
    gap 121.5 m: above the dry 96 m, below the wet 144 m). -/
def branch_12Trace : Trace :=
  traceOf { longCfg with othersAt := truckBeside 13000 2, envAt := fun _ => { dryClear with wetRoad := some true } }

/-- `branch_13` (compliant): rain falling on a surface not recorded wet; the same truck from t = 10 s. -/
def branch_13Trace : Trace :=
  traceOf { longCfg with othersAt := truckBeside 13000 2, envAt := fun _ => { dryClear with precipitation := some true } }

/-- `branch_14` (compliant): icy road; from t = 10 s a truck in the middle lane 210 m ahead (body gap
    201.5 m: above the wet 144 m, below the ice 432 m). -/
def branch_14Trace : Trace :=
  traceOf { longCfg with othersAt := truckBeside 21000 2, envAt := fun _ => { dryClear with iceOrSnow := some true } }

/-- `branch_15` (compliant): a regulatory sign closed_to_traffic governs the middle lane (a fixed
    device: present in every scene). -/
def branch_15Trace : Trace :=
  traceOf { longCfg with devicesAt := fun _ =>
    [{ Build.sign 203 .regulatorySign [112] with code := some .closedToTraffic }] }

/-- `branch_16` (compliant): a temporary traffic control (cones) governs the middle lane (present in
    every scene). -/
def branch_16Trace : Trace :=
  traceOf { longCfg with devicesAt := fun _ => [Build.sign 204 .temporaryTrafficControl [112]] }

/-- `branch_17` (compliant): from t = 10 s a police officer directs stop on the middle lane. -/
def branch_17Trace : Trace :=
  traceOf { longCfg with devicesAt := fun k =>
    if k ≥ 2 then [{ Build.device 205 .humanDirection [112] with humanRole := some .policeOfficer, humanIndication := some .stop }] else [] }

/-- `branch_18` (compliant): a barrier lies along the middle lane (y 4–6.5 m) from x = 100 m on,
    1.25 m to the subject's right once it is in L1 (the map is the same in every scene; the
    subject, at x = 0 in the middle lane at t = 0, is short of it). -/
def branch_18Trace : Trace :=
  traceOf { longCfg with structuresAt := fun _ =>
    [{ Build.rect 131 .obstruction (m 100) (cm 400) (m 3000) (cm 650) with obstructionKind := some .barrier }] }

/-- `branch_19` (compliant): from t = 10 s fog limits visibility to 60 m (below the dry 96 m). -/
def branch_19Trace : Trace :=
  traceOf { longCfg with envAt := fun k => if k ≥ 2 then { dryClear with visibility := some (m 60) } else dryClear }

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
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant (window := some (0, 20000))
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .compliant
  , witness "branch_14" branch_14Trace .compliant
  , witness "branch_15" branch_15Trace .compliant
  , witness "branch_16" branch_16Trace .compliant
  , witness "branch_17" branch_17Trace .compliant
  , witness "branch_18" branch_18Trace .compliant
  , witness "branch_19" branch_19Trace .compliant ]

end TrafficSpecWitness.NRS_484B_208_1
