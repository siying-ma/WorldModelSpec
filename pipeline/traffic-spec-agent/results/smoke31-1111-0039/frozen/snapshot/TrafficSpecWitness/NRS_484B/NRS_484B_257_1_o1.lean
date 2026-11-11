/-
  Witnesses for NRS_484B_257_1_o1.

  Geometry (the witness's own figures, in centimetres, +x east): lane c (10) runs east along
  y ∈ [0, 4 m] from x = −120 m to x = 0, where it enters intersection i (20), x ∈ [0, 12 m],
  y ∈ [−6 m, 10 m]. Lane c lies on the approach highway (30); i lies on it and on the through
  highway (31). Where present, stop line s (40) spans x ∈ [−1.5 m, −1.0 m] and crosswalk w (41)
  x ∈ [−4.5 m, −1.5 m] across c; each records c as the carrier whose entrance it marks.
  Vehicle x (track 1) is a motor vehicle 4.5 m long and 1.8 m wide, heading east along y = 2 m;
  its occupancy is stated from its body's extent along x. Observations are 1 s apart; each
  witness speaks about the instants from 1 s on (at 0 s no earlier observation exists to tell
  an entry). The devices: a stop sign (100), a yield sign (101), a police officer (102) and a
  traffic signal (103), each governing the regions its scene lists.
  Against the reading (speed resolution 0.2 m/s, deceleration resolution 0.3 m/s², stop-point
  tolerance 2 m, sight distance 100 m): a halt is 0 m/s; a body counted at the place is 0.5 m
  or 1 m from it; a body outside the zone is at least 3 m away; a slowing is 0.6 m/s² or more.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def cmPerSecond (n : Int) : Q := Units.micrometresPerSecond (n * 10000)
def cmPerSecondSq (n : Int) : Q := Units.micrometresPerSecondSq (n * 10000)

-- Binders ↦ tracks: x ↦ 1

def laneC : RegionId := 10
def interI : RegionId := 20
def approachWay : RegionId := 30
def throughWay : RegionId := 31
def stopLineS : RegionId := 40
def crosswalkW : RegionId := 41

def laneStructure : Structure :=
  { (Build.lane laneC [(cm (-12000), cm 0), (cm 0, cm 0), (cm 0, cm 400), (cm (-12000), cm 400)]
      Build.east (enters := some interI)) with ways := some [approachWay] }

def intersectionI : Structure :=
  { (Build.rect interI .intersection (cm 0) (cm (-600)) (cm 1200) (cm 1000)) with
      ways := some [approachWay, throughWay] }

def approachHighway : Structure := Build.rect approachWay .highway (cm (-12000)) (cm (-600)) (cm 1200) (cm 1000)
def throughHighway : Structure := Build.rect throughWay .highway (cm 0) (cm (-10000)) (cm 1200) (cm 10000)

def stopLineMark : Structure :=
  { (Build.rect stopLineS .stopLine (cm (-150)) (cm 0) (cm (-100)) (cm 400)) with
      entranceOf := [laneC], entranceObserved := true, ways := some [approachWay] }

def crosswalkMark : Structure :=
  { (Build.rect crosswalkW .crosswalk (cm (-450)) (cm 0) (cm (-150)) (cm 400)) with
      entranceOf := [laneC], entranceObserved := true, marked := some true, ways := some [approachWay] }

def stopSignDev (governs : List RegionId) (observed : Bool := true) : Device :=
  { (Build.sign 100 .stopSign governs) with governsObserved := observed, conditions := some {} }
def yieldSignDev (governs : List RegionId) : Device :=
  { (Build.sign 101 .yieldSign governs) with conditions := some {} }
def policeDev (governs : List RegionId) : Device :=
  { (Build.device 102 .humanDirection governs) with
      humanRole := some .policeOfficer, humanIndication := some .proceed }
def greenSignalDev (governs : List RegionId) : Device :=
  { (Build.signal 103 governs [.circularGreen]) with inoperative := some false, uncovered := some true }

/-- Which marks the scene has and which devices govern what. -/
structure WitnessSetup where
  hasStopLine : Bool := true
  hasCrosswalk : Bool := false
  devs : List Device := []

/-- One observation of x: reference point x-coordinate (cm), speed (cm/s), longitudinal
    acceleration (cm/s²), and sight along each way where observed. -/
structure XObs where
  px : Int
  speed : Int
  accel : Int := 0
  sight : Option (List (RegionId × Q)) := none

def halfLength : Int := 225

/-- The regions' extents along x (cm), for the occupancy of x's body. -/
def regionSpans (cfg : WitnessSetup) : List (RegionId × Int × Int) :=
  [(laneC, -12000, 0), (interI, 0, 1200)]
    ++ (if cfg.hasStopLine then [(stopLineS, -150, -100)] else [])
    ++ (if cfg.hasCrosswalk then [(crosswalkW, -450, -150)] else [])

def bodyOccupancy (cfg : WitnessSetup) (px : Int) : List (TrackId × RegionId) :=
  (regionSpans cfg).filterMap fun (r, lo, hi) =>
    if px - halfLength ≤ hi ∧ lo ≤ px + halfLength then some (1, r) else none

def sceneStructures (cfg : WitnessSetup) : List Structure :=
  [laneStructure, intersectionI, approachHighway, throughHighway]
    ++ (if cfg.hasStopLine then [stopLineMark] else [])
    ++ (if cfg.hasCrosswalk then [crosswalkMark] else [])

def vehicleAt (s : XObs) : RoadUser :=
  let u := Build.user 1 [.motorVehicle] (cm s.px, cm 200) Build.east (cmPerSecond s.speed) (cm 225, cm 90, cm 75)
  { (Build.withKin u fun k => { k with accelLongitudinal := some (cmPerSecondSq s.accel) }) with
      sightAlongWay := s.sight }

def traceOf (cfg : WitnessSetup) (obs : List XObs) : Trace :=
  Build.trace obs.length 0 (Units.seconds 1) fun k t =>
    let s := obs.getD k { px := 0, speed := 0 }
    Build.scene t (some 1) [vehicleAt s] (sceneStructures cfg) cfg.devs (occupies := some (bodyOccupancy cfg s.px))

/-- Rolling through at 12 m/s from 85 m upstream; enters i at 7 s with its body across s. -/
def rollThrough : List XObs :=
  ([-8500, -7300, -6100, -4900, -3700, -2500, -1300, -100, 1100] : List Int).map fun p => { px := p, speed := 1200 }

/-- Braking from 8 m/s to a halt with the body 0.5 m short of `front` (the place's upstream edge,
    cm), held for 2 s, then `creep` cm on, then into i. -/
def haltShortOf (front : Int) (entry after : Int) (creep : Int := 95)
    (sight : Option (List (RegionId × Q)) := none) : List XObs :=
  let h := front - 50 - halfLength
  [ { px := h - 3200, speed := 800, sight := sight }
  , { px := h - 2400, speed := 800, sight := sight }
  , { px := h - 1600, speed := 800, accel := -200, sight := sight }
  , { px := h - 900, speed := 600, accel := -200, sight := sight }
  , { px := h - 400, speed := 400, accel := -200, sight := sight }
  , { px := h - 100, speed := 200, accel := -200, sight := sight }
  , { px := h, speed := 0, sight := sight }
  , { px := h, speed := 0, sight := sight }
  , { px := h + creep, speed := 200, accel := 200, sight := sight }
  , { px := entry, speed := 400, accel := 200, sight := sight }
  , { px := after, speed := 600, sight := sight } ]

/-- From 10 m/s, braking at 2 m/s² from 30 m short of s, still slowing into the stopping zone,
    entering i at 4 m/s without halting. -/
def slowThrough : List XObs :=
  [ { px := -4375, speed := 1000 }
  , { px := -3375, speed := 1000, accel := -200 }
  , { px := -2475, speed := 800, accel := -200 }
  , { px := -1775, speed := 600, accel := -200 }
  , { px := -1225, speed := 500, accel := -100 }
  , { px := -755, speed := 440, accel := -60 }
  , { px := -335, speed := 400, accel := -40 }
  , { px := 65, speed := 400 }
  , { px := 465, speed := 400 } ]

/-- `forbid` (violated): dev.stop_sign governs lane c (st.lane_enters c i); stop line s marks c; no officer and no signal. x is first observed 80 m upstream at 12 m/s, never falls to the speed resolution and enters i. -/
def forbidTrace : Trace := traceOf { devs := [stopSignDev [laneC]] } rollThrough

/-- `permit` (compliant): As forbid, but x halts with its body 0.5 m short of s, then enters i. -/
def permitTrace : Trace := traceOf { devs := [stopSignDev [laneC]] } (haltShortOf (-150) (-50) 500)

/-- `idle` (not_applicable): No sign governs c or i; x enters i without halting. -/
def idleTrace : Trace := traceOf { devs := [] } rollThrough

/-- `blind` (unknown): As forbid, but dev.governs is not observed for the stop sign. -/
def blindTrace : Trace := traceOf { devs := [stopSignDev [] (observed := false)] } rollThrough

/-- `branch_1` (compliant): dev.yield_sign governs c; x, moving forward at 10 m/s, decelerates at 2 m/s² 30 m upstream of s and enters i at 4 m/s without halting. -/
def branch_1Trace : Trace := traceOf { devs := [yieldSignDev [laneC]] } slowThrough

/-- `branch_2` (not_applicable): As forbid, but a dev.human_direction with role police_officer governs i while x rolls through. -/
def branch_2Trace : Trace := traceOf { devs := [stopSignDev [laneC], policeDev [interI]] } rollThrough

/-- `history_boundary` (unknown): As forbid, but the recording begins with x 1.5 m short of s at 1 m/s; no halt is recorded before x enters i. -/
def history_boundaryTrace : Trace :=
  traceOf { devs := [stopSignDev [laneC]] }
    (([-525, -430, -330, -230, -130, -30] : List Int).map fun p => { px := p, speed := 100 })

/-- `branch_3` (not_applicable): as forbid, but a traffic signal showing green governs c. -/
def branch_3Trace : Trace := traceOf { devs := [stopSignDev [laneC], greenSignalDev [laneC]] } rollThrough

/-- `branch_4` (compliant): no stop line; crosswalk w marks c; a yield sign governs i; x slows
    as in branch_1, still slowing when its body is 3.2 m and 0.8 m short of w, and crosses w into i. -/
def branch_4Trace : Trace :=
  traceOf { hasStopLine := false, hasCrosswalk := true, devs := [yieldSignDev [interI]] } slowThrough

/-- `branch_5` (compliant): neither a stop line nor a crosswalk marks c; a stop sign governs i;
    x halts with its body 1 m short of i, then enters. -/
def branch_5Trace : Trace :=
  traceOf { hasStopLine := false, devs := [stopSignDev [interI]] } (haltShortOf (-50) (-110) 400)

/-- `branch_6` (compliant): neither mark; a stop sign governs c; x halts 3 m short of i, outside
    the stopping zone, with the through highway in view for 150 m, then creeps in. -/
def branch_6Trace : Trace :=
  traceOf { hasStopLine := false, devs := [stopSignDev [laneC]] }
    (haltShortOf (-250) (-100) 400 (creep := 200) (sight := some [(throughWay, m 150)]))

/-- `branch_7` (not_applicable): as forbid, but a police officer governs c. -/
def branch_7Trace : Trace := traceOf { devs := [stopSignDev [laneC], policeDev [laneC]] } rollThrough

/-- `branch_8` (not_applicable): as forbid, but a traffic signal showing green governs i. -/
def branch_8Trace : Trace := traceOf { devs := [stopSignDev [laneC], greenSignalDev [interI]] } rollThrough

/-- `branch_9` (violated): a stop sign governs c; x slows as in branch_1 but never halts. -/
def branch_9Trace : Trace := traceOf { devs := [stopSignDev [laneC]] } slowThrough

/-- `branch_10` (violated): stop line s marks c; a yield sign governs i; x rolls through at
    12 m/s, neither halting nor slowing. -/
def branch_10Trace : Trace := traceOf { devs := [yieldSignDev [interI]] } rollThrough

/-- `branch_11` (compliant): no stop line; crosswalk w marks c; a stop sign governs c; x halts
    with its body 0.5 m short of w, then crosses w into i. -/
def branch_11Trace : Trace :=
  traceOf { hasStopLine := false, hasCrosswalk := true, devs := [stopSignDev [laneC]] }
    (haltShortOf (-450) (-50) 500)

/-- `branch_12` (violated): no stop line; crosswalk w marks c; a yield sign governs c; x rolls
    through at 12 m/s, neither halting nor slowing. -/
def branch_12Trace : Trace :=
  traceOf { hasStopLine := false, hasCrosswalk := true, devs := [yieldSignDev [laneC]] } rollThrough

/-- `branch_13` (violated): neither mark; a stop sign governs i; x rolls through at 12 m/s. -/
def branch_13Trace : Trace :=
  traceOf { hasStopLine := false, devs := [stopSignDev [interI]] } rollThrough

def witness (name : String) (τ : Trace) (expected : Verdict) (window : Option (Timestamp × Timestamp))
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (some (1000, 8000))
  , witness "permit" permitTrace .compliant (some (1000, 10000))
  , witness "idle" idleTrace .notApplicable (some (1000, 8000))
  , witness "blind" blindTrace (.unknown []) (some (1000, 8000)) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant (some (1000, 8000))
  , witness "branch_2" branch_2Trace .notApplicable (some (1000, 8000))
  , witness "history_boundary" history_boundaryTrace (.unknown []) (some (1000, 5000)) (boundary := "x's approach start on c, the last observation outside the stopping zone upstream of s, lies before the recording.")
  , witness "branch_3" branch_3Trace .notApplicable (some (1000, 8000))
  , witness "branch_4" branch_4Trace .compliant (some (1000, 8000))
  , witness "branch_5" branch_5Trace .compliant (some (1000, 10000))
  , witness "branch_6" branch_6Trace .compliant (some (1000, 10000))
  , witness "branch_7" branch_7Trace .notApplicable (some (1000, 8000))
  , witness "branch_8" branch_8Trace .notApplicable (some (1000, 8000))
  , witness "branch_9" branch_9Trace .violated (some (1000, 8000))
  , witness "branch_10" branch_10Trace .violated (some (1000, 8000))
  , witness "branch_11" branch_11Trace .compliant (some (1000, 10000))
  , witness "branch_12" branch_12Trace .violated (some (1000, 8000))
  , witness "branch_13" branch_13Trace .violated (some (1000, 8000)) ]

end TrafficSpecWitness.NRS_484B_257_1_o1
