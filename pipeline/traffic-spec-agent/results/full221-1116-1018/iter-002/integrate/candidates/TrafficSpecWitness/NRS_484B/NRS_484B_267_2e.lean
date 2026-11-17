/-
  Witnesses for NRS_484B_267_2e.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - A straight east-bound carriageway along x (−500 m … 1500 m). Four lanes 4 m wide: lane 11
    (ordinal 1, leftmost looking east, y 12–16), 12 (y 8–12), 13 (y 4–8), 14 (y 0–4); roadway 20
    covers y 0–16; highway 30 covers y −4–20; every lane and the roadway lie on highway 30.
    The two-lane variant keeps lanes 11 and 12 (count 2). The two-way variant (branch_4) has
    east lanes 11 (ordinal 1, y 4–8) and 12 (ordinal 2, y 0–4) and west lanes 21 (ordinal 1,
    y 8–12) and 22 (ordinal 2, y 12–16) on one undivided roadway 20 (y 0–16).
  - Subject: track 1, a motor vehicle 5 m × 2 m, heading east, usually at 20 m/s from x = 0.
  - Approached vehicle: track 2, an official vehicle of a regulatory agency (the run's reading
    leaves every class unresolved for DEF-NRS-484A-020::authorized_emergency_vehicle, so a police
    car's membership is unknown; the regulatory-agency limb is the one a witness can decide) with
    a red flashing front warning lamp, usually 100 m ahead at 15 m/s, closing.
  - Trace: 10 observations one second apart (0 … 9 s); every witness speaks about 7 … 9 s, where
    the 6 s look-back window is covered.
  - Reading figures the scenes are built against: reach 150 m (centre distances 55–140 m);
    lane-change window 6 s; headways dry 2 s / wet 3 s / ice 6 s at 20 m/s give 40 / 60 / 120 m
    (gaps used: ≈25 m blocked, ≈50 m between dry and wet, ≈70 m between wet and ice); visibility
    1000 m clear vs 80 m in fog (below 20 m/s × 6 s = 120 m).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_2e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_2e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def ext : Q × Q × Q := (cm 250, m 1, cm 75)

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def laneOf (id : RegionId) (y0 y1 : Int) (dir : Vec) (l r : Option RegionId) (ord cnt : Nat) : Structure :=
  { Build.lane id (box (-500) y0 1500 y1) dir l r (some ord) (some cnt) with ways := some [30] }

def roadwayOf (y0 y1 : Int) : Structure :=
  { Build.rect 20 .roadway (m (-500)) (m y0) (m 1500) (m y1) with ways := some [30] }

def highwayOf (y0 y1 : Int) : Structure := Build.rect 30 .highway (m (-500)) (m y0) (m 1500) (m y1)

def fourLanes : List Structure :=
  [ laneOf 11 12 16 Build.east none (some 12) 1 4
  , laneOf 12 8 12 Build.east (some 11) (some 13) 2 4
  , laneOf 13 4 8 Build.east (some 12) (some 14) 3 4
  , laneOf 14 0 4 Build.east (some 13) none 4 4
  , roadwayOf 0 16
  , highwayOf (-4) 20 ]

def twoLanes : List Structure :=
  [ laneOf 11 12 16 Build.east none (some 12) 1 2
  , laneOf 12 8 12 Build.east (some 11) none 2 2
  , roadwayOf 8 16
  , highwayOf 4 20 ]

def twoWay : List Structure :=
  [ laneOf 11 4 8 Build.east none (some 12) 1 2
  , laneOf 12 0 4 Build.east (some 11) none 2 2
  , laneOf 21 8 12 Build.west none (some 22) 1 2
  , laneOf 22 12 16 Build.west (some 21) none 2 2
  , roadwayOf 0 16
  , highwayOf (-4) 20 ]

def redFront : WarningLamp := { colour := .red, mode := .flashing, facing := .front }

/-- The subject: a motor vehicle heading east, no warning lamps. -/
def subj (x y v : Int) : RoadUser :=
  Build.withSignals (Build.user 1 [.motorVehicle] (m x, m y) Build.east (mps v) ext)
    (fun s => { s with warningLamps := some [] })

/-- The approached vehicle: a regulatory-agency official vehicle, red front lamp flashing when lit. -/
def official (x y : Int) (h : Vec) (v : Int) (lampsOn : Bool := true) : RoadUser :=
  Build.withSignals
    { Build.user 2 [.officialVehicle] (m x, m y) h (mps v) ext with officialKind := some .regulatoryAgency }
    (fun s => { s with warningLamps := some (if lampsOn then [redFront] else []) })

/-- Other traffic: a truck heading east, no warning lamps. -/
def truck (track : TrackId) (x y v : Int) : RoadUser :=
  Build.withSignals (Build.user track [.truck] (m x, m y) Build.east (mps v) ext)
    (fun s => { s with warningLamps := some [] })

def dry : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false, visibility := some (m 1000) }

def sc (t : Timestamp) (users : List RoadUser) (structs : List Structure) (devs : List Device := [])
    (env : Env := dry) : Scene :=
  Build.scene t (some 1) users structs devs (env := env)

def tr (f : Int → Timestamp → Scene) : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t => f (Int.ofNat k) t

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): Dry road, four lanes in the subject's direction. The regulatory-agency vehicle with its red front lamp flashing moves in lane 1 ahead of the subject; the subject has been approaching it within the reach for longer than the lane-change window and stays in lane 2, the neighbour of lane 1, while lanes 3 and 4 are open and empty. -/
def forbidTrace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (100 + 15 * x) 14 Build.east 15] fourLanes

/-- `permit` (compliant): Same scene, but the subject drives in lane 3, which is not a neighbour of lane 1. -/
def permitTrace : Trace :=
  tr fun x t => sc t [subj (20 * x) 6 20, official (100 + 15 * x) 14 Build.east 15] fourLanes

/-- `idle` (not_applicable): The subject drives in lane 2 of a four-lane carriageway; no emergency or regulatory-agency vehicle is in the scene. -/
def idleTrace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20] fourLanes

/-- `blind` (unknown): As in forbid, but the source does not observe lane adjacency. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): Two lanes; the vehicle moves in lane 1 about 25 m ahead (inside the 40 m dry headway gap) and the subject in lane 2. The only lane not adjacent to lane 1 is lane 1 itself, not clear: excused. -/
def branch_1Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (20 * x + 30) 14 Build.east 20] twoLanes

/-- `branch_2` (compliant): As in forbid, but the road is covered in snow: excused. -/
def branch_2Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (100 + 15 * x) 14 Build.east 15] fourLanes
    (env := { dry with iceOrSnow := some true })

/-- `branch_3` (compliant): As in forbid, but the lamp is lit only from 5 s: the approach has lasted less than the lane-change window at 7–9 s. -/
def branch_3Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (100 + 15 * x) 14 Build.east 15 (decide (x ≥ 5))] fourLanes

/-- `branch_4` (violated): Undivided two-way roadway, two lanes each way. The regulatory-agency vehicle moves west in lane 21 (leftmost of its direction); the subject, approaching head-on, drives east in lane 11 (leftmost of its direction), while lane 12 is open and empty. -/
def branch_4Trace : Trace :=
  tr fun x t => sc t [subj (10 * x) 6 10, official (140 - 5 * x) 10 Build.west 5] twoWay

/-- `branch_5` (not_applicable): As in forbid, but a police officer directs the traffic of the subject's lane. -/
def branch_5Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (100 + 15 * x) 14 Build.east 15] fourLanes
    [{ Build.device 40 .humanDirection [12] with humanRole := some .policeOfficer, humanIndication := some .proceed }]

/-- A halted official vehicle at 120 m in lane 1, visible to the subject, with the given signals. -/
def halted (hand : HandSignal) (turn : TurnIndicatorState) : RoadUser :=
  Build.withSignals (official 120 14 Build.east 0) (fun s => { s with handSignal := some hand, turnIndicator := some turn })

/-- `branch_6` (violated): The vehicle is halted in lane 1 but its driver gives a visible arm signal (preparing to move); the subject stays in lane 2 with lanes 3 and 4 empty. -/
def branch_6Trace : Trace :=
  tr fun x t => Build.withRelations
    (sc t [subj (10 * x) 10 10, halted .left .off] fourLanes)
    [Build.relation 1 2 (fun r => { r with visible := some true })]

/-- `branch_7` (violated): As branch_6, but no arm signal: the vehicle's left turn indicator is lit. -/
def branch_7Trace : Trace :=
  tr fun x t => Build.withRelations
    (sc t [subj (10 * x) 10 10, halted .noSignal .left] fourLanes)
    [Build.relation 1 2 (fun r => { r with visible := some true })]

/-- `branch_8` (compliant): The vehicle is 25 m ahead in lane 1 (its lane not clear); lanes 3 and 4 are closed by temporary traffic control: no candidate lane is open, excused. -/
def branch_8Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (20 * x + 30) 14 Build.east 20] fourLanes
    [Build.device 41 .temporaryTrafficControl [13, 14]]

/-- `branch_9` (violated): The vehicle moves in lane 3, the subject's right neighbour; lane 1 is open and empty. -/
def branch_9Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (100 + 15 * x) 6 Build.east 15] fourLanes

/-- Traffic alongside: the vehicle 25 m ahead in lane 1, trucks `d` m ahead in lanes 3 and 4. -/
def traffic (x : Int) (d : Int) : List RoadUser :=
  [subj (20 * x) 10 20, official (20 * x + 30) 14 Build.east 20, truck 3 (20 * x + d) 6 20, truck 4 (20 * x + d) 2 20]

/-- `branch_10` (compliant): Wet road; trucks about 50 m from the subject in lanes 3 and 4 (inside the 60 m wet gap): no candidate lane clear, excused. -/
def branch_10Trace : Trace :=
  tr fun x t => sc t (traffic x 55) fourLanes (env := { dry with wetRoad := some true })

/-- `branch_11` (compliant): As branch_10, but rain falling and the surface not reported wet. -/
def branch_11Trace : Trace :=
  tr fun x t => sc t (traffic x 55) fourLanes (env := { dry with precipitation := some true })

/-- `branch_12` (violated): Dry road; trucks about 70 m from the subject in lanes 3 and 4 (beyond the 40 m dry gap): lanes 3 and 4 are clear, the subject stays in lane 2. -/
def branch_12Trace : Trace :=
  tr fun x t => sc t (traffic x 75) fourLanes

/-- `branch_13` (compliant): As in forbid, but fog limits visibility to 80 m, below 20 m/s × 6 s: excused. -/
def branch_13Trace : Trace :=
  tr fun x t => sc t [subj (20 * x) 10 20, official (100 + 15 * x) 14 Build.east 15] fourLanes
    (env := { dry with visibility := some (m 80) })

/-- `branch_14` (not_applicable): As in forbid, but the vehicle in lane 1 with a red flashing lamp is a bicycle: neither an emergency nor a regulatory-agency vehicle. -/
def branch_14Trace : Trace :=
  tr fun x t => sc t
    [ subj (20 * x) 10 20
    , Build.withSignals (Build.user 2 [.bicycle] (m (100 + 15 * x), m 14) Build.east (mps 15) (cm 90, cm 30, cm 75))
        (fun s => { s with warningLamps := some [redFront] }) ] fourLanes

/-- `branch_15` (compliant): The regulatory-agency vehicle moves in lane 4, not adjacent to the subject's lane 2; a bicycle showing a red flashing lamp rides in lane 1, the subject's neighbour: the bicycle is no vehicle the duty names, so lane 2 breaches nothing. -/
def branch_15Trace : Trace :=
  tr fun x t => sc t
    [ subj (20 * x) 10 20
    , official (100 + 15 * x) 2 Build.east 15
    , Build.withSignals (Build.user 5 [.bicycle] (m (80 + 15 * x), m 14) Build.east (mps 15) (cm 90, cm 30, cm 75))
        (fun s => { s with warningLamps := some [redFront] }) ] fourLanes

/-- `branch_16` (compliant): As branch_4, but a truck runs in lane 12 about 5 m from the subject (inside the 20 m dry gap at 10 m/s): the only lane of the subject's direction not adjacent to lane 21 is not clear, excused. -/
def branch_16Trace : Trace :=
  tr fun x t => sc t [subj (10 * x) 6 10, official (140 - 5 * x) 10 Build.west 5, truck 3 (10 * x + 10) 2 10] twoWay

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_2e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (7000, 9000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .violated
  , witness "branch_13" branch_13Trace .compliant
  , witness "branch_14" branch_14Trace .notApplicable
  , witness "branch_15" branch_15Trace .compliant
  , witness "branch_16" branch_16Trace .compliant ]

end TrafficSpecWitness.NRS_484B_267_2e
