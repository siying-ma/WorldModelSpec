/-
  Witnesses for LVMC_11_16_040.

  Geometry (all figures the witness's own; none appears in the rule):
    - intersection j (id 10): square x, y ∈ [-10, 10] m, on the ways hwMain (20, x ∈ [-100, 100],
      y ∈ [-10, 10]) and hwCross (21, x ∈ [-10, 10], y ∈ [-100, 100]); its sight distance is
      200 m unless a scene says otherwise.
    - laneW (30): eastbound approach x ∈ [-80, -10], y ∈ [-10, 0], entering j.
    - laneS (31): northbound approach x ∈ [0, 10], y ∈ [-80, -10], entering j.
    - subject (track 1, motor vehicle, half extents 2 × 1 × 0.75 m) drives east along y = -3 from
      x = -61, observed every second; path length is the distance from the trace start.
      Fast runs: 10 m/s (≈ 22.4 mph), in j at t = 6 s and 7 s, nine scenes.
      Slow runs: 5 m/s (≈ 11.2 mph), in j at t = 11 … 14 s, sixteen scenes.
      The 100 ft (30.48 m) path window behind the entry starts 30 m (fast) / 30 m (slow) of path
      before it, well inside the trace, and is sampled every 10 m / 5 m.
    - restricted view: the subject's sight along hwCross is 20 m (hedge) or 15 m (wall), along
      hwMain 200 m.
    - car 2 (branch_2): a stationary motor vehicle at (5, -20) in laneS on hwCross, 8 m from j.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_040
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_16_040

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def jId : RegionId := 10
def hwMain : RegionId := 20
def hwCross : RegionId := 21
def laneW : RegionId := 30
def laneS : RegionId := 31

def structures (jSight : Q) : List Structure :=
  [ { Build.rect jId .intersection (m (-10)) (m (-10)) (m 10) (m 10) with
        sightDistance := some jSight, ways := some [hwMain, hwCross] }
  , Build.rect hwMain .highway (m (-100)) (m (-10)) (m 100) (m 10)
  , Build.rect hwCross .highway (m (-10)) (m (-100)) (m 10) (m 100)
  , Build.lane laneW [(m (-80), m (-10)), (m (-10), m (-10)), (m (-10), m 0), (m (-80), m 0)]
      Build.east (enters := some jId)
  , Build.lane laneS [(m 0, m (-80)), (m 10, m (-80)), (m 10, m (-10)), (m 0, m (-10))]
      Build.north (enters := some jId) ]

def subjectAt (v : Int) (k : Nat) (sMain sCross : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (m (-61 + v * (k : Int)), m (-3)) Build.east
      (Units.metresPerSecond v) (m 2, m 1, cm 75) (some (m (v * (k : Int)))) with
    sightAlongWay := some [(hwMain, sMain), (hwCross, sCross)] }

def car2 : RoadUser :=
  Build.user 2 [.motorVehicle] (m 5, m (-20)) Build.north Q.zero (m 2, m 1, cm 75) (some Q.zero)

structure Setup where
  n : Nat
  v : Int
  sCross : Q := m 20
  sMain : Q := m 200
  jSight : Q := m 200
  others : List RoadUser := []
  devices : Nat → List Device := fun _ => []
  rels : List MeasuredRelation := []

def mkTrace (c : Setup) : Trace :=
  Build.trace c.n 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      (Build.scene t (some 1) (subjectAt c.v k c.sMain c.sCross :: c.others)
        (structures c.jSight) (c.devices k))
      c.rels

/-- 10 m/s run: nine scenes, in j at 6 s and 7 s. -/
def fast : Setup := { n := 9, v := 10 }
/-- 5 m/s run: sixteen scenes, in j at 11 … 14 s. -/
def slow : Setup := { n := 16, v := 5 }
def fastWindow : Timestamp × Timestamp := (6000, 7000)
def slowWindow : Timestamp × Timestamp := (11000, 14000)

def stopSign (id : DeviceId) (r : RegionId) : Device :=
  { Build.sign id .stopSign [r] with conditions := some {} }
def yieldSign (id : DeviceId) (r : RegionId) : Device :=
  { Build.sign id .yieldSign [r] with conditions := some {} }

/-- `forbid` (violated): Uncontrolled intersection, hedges limit sight along the cross street to 20 m during the last 100 ft of the subject's approach; it traverses j above fifteen mph. -/
def forbidTrace : Trace := mkTrace fast

/-- `permit` (compliant): Same, traversing j at or below fifteen mph. -/
def permitTrace : Trace := mkTrace slow

/-- `idle` (not_applicable): Same restricted view, but a traffic signal (circular_green) governs the subject's approach lane. -/
def idleTrace : Trace :=
  mkTrace { fast with devices := fun _ => [Build.signal 50 [laneW] [.circularGreen]] }

/-- `blind` (unknown): Uncontrolled intersection; the source does not supply sight along the ways, and the subject traverses above fifteen mph. -/
def blindTrace : Trace := mkTrace fast

/-- `branch_1` (compliant): Uncontrolled intersection, no other road user in the scene; a wall limits sight along one cross way below one hundred feet during the last 100 ft of the approach; the subject traverses at or below fifteen mph. -/
def branch_1Trace : Trace := mkTrace { slow with sCross := m 15 }

/-- `branch_2` (violated): sight along both ways and of j is clear, but car 2 on the cross way 8 m from j is not visible from the subject; 10 m/s through j. -/
def branch_2Trace : Trace :=
  mkTrace { fast with sCross := m 200, others := [car2],
                      rels := [Build.relation 1 2 (fun r => { r with visible := some false })] }

/-- `branch_3` (violated): sight along both ways clear, no other road user, but j's sight distance (10 m) is below the subject's distance to j during the approach; 10 m/s through j. -/
def branch_3Trace : Trace := mkTrace { fast with sCross := m 200, jSight := m 10 }

/-- `branch_4` (not_applicable): restricted view, a stop sign governs j itself. -/
def branch_4Trace : Trace := mkTrace { fast with devices := fun _ => [stopSign 51 jId] }

/-- `branch_5` (not_applicable): restricted view, a yield sign governs the cross approach laneS. -/
def branch_5Trace : Trace := mkTrace { fast with devices := fun _ => [yieldSign 52 laneS] }

/-- `branch_6` (violated): restricted view, the only signal (on the subject's approach) is dark: not traffic-controlled; 10 m/s through j. -/
def branch_6Trace : Trace :=
  mkTrace { fast with devices := fun _ => [Build.signal 50 [laneW] [.dark]] }

/-- A signal head showing flashing red while the subject is on its approach (to 5 s) and dark
    from its entry into j on (an outage). -/
def redThenDark (id : DeviceId) (r : RegionId) (k : Nat) : Device :=
  Build.signal id [r] (if k ≤ 5 then [.flashingRed] else [.dark])

/-- `branch_9` (not_applicable): through street: at the observation before entry the cross approach laneS is governed by a flashing-red signal and the subject's laneW by nothing; the head goes dark as the subject enters j, so j is not traffic-controlled then. -/
def branch_9Trace : Trace :=
  mkTrace { fast with devices := fun k => [redThenDark 54 laneS k] }

/-- `branch_11` (not_applicable): restricted view, a traffic signal (circular_green) governs j itself. -/
def branch_11Trace : Trace :=
  mkTrace { fast with devices := fun _ => [Build.signal 50 [jId] [.circularGreen]] }

/-- `branch_12` (not_applicable): restricted view, a stop sign governs the cross approach laneS. -/
def branch_12Trace : Trace := mkTrace { fast with devices := fun _ => [stopSign 51 laneS] }

/-- `branch_13` (not_applicable): restricted view, a yield sign governs j itself. -/
def branch_13Trace : Trace := mkTrace { fast with devices := fun _ => [yieldSign 52 jId] }

/-- `branch_15` (violated): flashing-red heads on both laneS and the subject's laneW during the approach, both dark from its entry: its own approach was controlled, so no through street, and j is not traffic-controlled when traversed; 10 m/s through j. -/
def branch_15Trace : Trace :=
  mkTrace { fast with devices := fun k => [redThenDark 54 laneS k, redThenDark 55 laneW k] }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Timestamp × Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_16_040"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated fastWindow
  , witness "permit" permitTrace .compliant slowWindow
  , witness "idle" idleTrace .notApplicable fastWindow
  , witness "blind" blindTrace (.unknown []) fastWindow ["st.sight_along_way"]
  , witness "branch_1" branch_1Trace .compliant slowWindow
  , witness "branch_2" branch_2Trace .violated fastWindow
  , witness "branch_3" branch_3Trace .violated fastWindow
  , witness "branch_4" branch_4Trace .notApplicable fastWindow
  , witness "branch_5" branch_5Trace .notApplicable fastWindow
  , witness "branch_6" branch_6Trace .violated fastWindow
  , witness "branch_9" branch_9Trace .notApplicable fastWindow
  , witness "branch_11" branch_11Trace .notApplicable fastWindow
  , witness "branch_12" branch_12Trace .notApplicable fastWindow
  , witness "branch_13" branch_13Trace .notApplicable fastWindow
  , witness "branch_15" branch_15Trace .violated fastWindow ]

end TrafficSpecWitness.LVMC_11_16_040
