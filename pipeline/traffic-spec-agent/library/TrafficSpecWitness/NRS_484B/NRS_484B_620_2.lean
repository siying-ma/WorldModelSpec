/-
  Witnesses for NRS_484B_620_2.

  The geometry. One straight way running east, declared by every scene to lie outside any city
  limits (`asm.outside_city_limits` true): the highway region 10, a rectangle 600 m long and 24 m
  wide; on it the roadway region 11 (12 m wide, `ways := [10]`), and for the branch witnesses the
  single lane region 12 (6 m wide, direction east, `ways := [10]`) instead of the roadway. The
  subject is track 1, a motor vehicle 4 m by 2 m, travelling east along the middle of the region it
  occupies and advancing 20 m between the three observations, one second apart.

  The devices: zone sign 1, of the speed_zone kind, not an end sign, with a legend that states no
  further restriction (`conditions := some {}`), governing the travel region; speed limit sign 2,
  of the maximum kind, stating 25 mph, governing the same region.

  The speeds: 40 mph where the witness breaks the stated maximum, 20 mph where it keeps it — a
  clear margin either side of the 25 mph the sign states. Every figure here is the witness's own
  and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_620_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_620_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mph (n : Int) : Q := Units.mph n

-- Binders ↦ tracks: m ↦ 1

/-- The way the trace declares to lie outside any city limits. -/
def way : Structure := Build.rect 10 .highway (m 0) (m (-12)) (m 600) (m 12)

/-- The roadway of that way. -/
def carriageway : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-6)) (m 600) (m 6) with ways := some [10] }

/-- A single lane of that way (the branch witnesses' travel region). -/
def travelLane : Structure :=
  { Build.lane 12 [(m 0, m 0), (m 600, m 0), (m 600, m 6), (m 0, m 6)] Build.east with
      ways := some [10] }

/-- The subject at observation `k`, travelling east at `speed` along `y`. -/
def subject (speed : Q) (y : Q) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (50 + 20 * (k : Int)), y) Build.east speed (m 2, m 1, m 1)

/-- The zone sign that marks the speed zone over `governs`. -/
def zone (governs : List RegionId) : Device :=
  Build.zoneSign 1 governs .speedZone false (some {})

/-- The speed limit sign installed for `governs`, stating `v` as a maximum. -/
def limit (governs : List RegionId) (v : Q) : Device :=
  Build.speedLimit 2 governs v .maximum

def declared : List (AsmId × Bool) := [("asm.outside_city_limits", true)]

/-- `forbid` (violated): The trace declares the way to lie outside any city limits. A zone sign of the speed_zone kind and a speed limit sign stating a maximum govern the roadway; the subject, a motor vehicle, travels inside that stretch at a speed above the stated value. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 40) (m 2) k ]
      [ way, carriageway ]
      [ zone [11], limit [11] (mph 25) ]
      (assumptions := declared)

/-- `permit` (compliant): The same declared way, the same zone and sign, and the subject's speed inside the zone stays below the stated value at every observation. No other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 20) (m 2) k ]
      [ way, carriageway ]
      [ zone [11], limit [11] (mph 25) ]
      (assumptions := declared)

/-- `idle` (not_applicable): The trace declares the way to lie outside any city limits, but no zone sign and no speed limit sign governs the roadway the subject travels; no speed zone has been established there, so the node does not engage. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 40) (m 2) k ]
      [ way, carriageway ]
      [ ]
      (assumptions := declared)

/-- `blind` (unknown): The subject travels a stretch marked by a speed-zone sign on a declared road, but the source does not observe speed limit signs, so the authorized value for the zone cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 40) (m 2) k ]
      [ way, carriageway ]
      [ zone [11], limit [11] (mph 25) ]
      (assumptions := declared)

/-- `branch_1` (violated): the zone and its maximum sign govern a lane of the declared way rather
    than the whole roadway, and the subject drives that lane above the stated value. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 40) (m 3) k ]
      [ way, travelLane ]
      [ zone [12], limit [12] (mph 25) ]
      (assumptions := declared)

/-- `branch_2` (compliant): the same lane-governed zone, the subject keeping below the stated
    value at every observation. -/
def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subject (mph 20) (m 3) k ]
      [ way, travelLane ]
      [ zone [12], limit [12] (mph 25) ]
      (assumptions := declared)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_620_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("m", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.speed_limit_sign"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_620_2
