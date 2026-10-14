/-
  Witnesses for NRS_484B_307_6a.

  The scene is one signalised crossroads, built once and shared by every witness.

  Geometry (metres, +x east, +y north; the carriageway runs east):
  - region 10, a highway, the rectangle x ∈ [-200, 200], y ∈ [-14, 14];
  - region 11, a lane of it, x ∈ [-200, 0], y ∈ [-3, 3], running east, entering region 12;
  - region 12, the intersection, x ∈ [0, 14], y ∈ [-14, 14];
  - device 20, a traffic signal head governing region 11, its indications stated per instant;
  - track 1, a motor vehicle 5 m long and 1.8 m wide, heading east along y = 0.

  Occupancy is stated and not derived, because a body astride the stop line overlaps its lane and
  the intersection at once while its reference point lies in one of them: on the approach the
  vehicle occupies the highway and the lane, and at the instant of entry the highway, the lane and
  the intersection.

  Instants: eight observations one second apart, from t = 20 s to t = 27 s, padded with ten
  seconds of the first scene and three of the last, so that the six-second look-back of the rule
  is covered at every instant each witness speaks about. Every witness names that range
  (20 s … 27 s) as its window: outside it the padding's first instant has no previous observation
  and its earliest look-backs are truncated.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_6a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_6a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1
def carT : TrackId := 1
def hwyR : RegionId := 10
def laneR : RegionId := 11
def ixR : RegionId := 12
def headD : DeviceId := 20

/-- The highway, the approach lane that runs into the intersection, and the intersection. -/
def highway : Structure := Build.rect hwyR .highway (m (-200)) (m (-14)) (m 200) (m 14)
def approach : Structure :=
  Build.lane laneR [(m (-200), m (-3)), (m 0, m (-3)), (m 0, m 3), (m (-200), m 3)]
    Build.east (enters := some ixR)
def junction : Structure := Build.rect ixR .intersection (m 0) (m (-14)) (m 14) (m 14)

def structures : List Structure := [highway, approach, junction]

/-- The one head, governing the approach lane; what it displays is the witness's business. -/
def signalHead (indications : List SignalIndication) : Device :=
  Build.signal headD [laneR] indications

/-- Half-length, half-width, half-height of the vehicle. -/
def halfExtent : Q × Q × Q := (cm 250, cm 90, cm 75)

def car (x : Q) (speed : Q) : RoadUser :=
  Build.user carT [.motorVehicle] (x, m 0) Build.east speed halfExtent

/-- On the approach: the body overlaps the highway and its lane. -/
def onApproach : List (TrackId × RegionId) := [(carT, hwyR), (carT, laneR)]
/-- Astride the stop line: the body overlaps the highway, its lane and the intersection. -/
def acrossTheLine : List (TrackId × RegionId) := [(carT, hwyR), (carT, laneR), (carT, ixR)]

def sceneAt (t : Timestamp) (x : Q) (speed : Q) (indications : List SignalIndication)
    (occupies : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some carT) [car x speed] structures [signalHead indications] (some occupies)

/-- Ten seconds of the first scene before, three of the last after, one second apart. -/
def padded (τ : Trace) : Trace := Build.pad τ (Units.seconds 10) (Units.seconds 3) (Units.seconds 1)

/-- The approach that does not stop: 8 m/s, from x = -55 m to x = 1 m, where the body is astride
    the stop line and overlaps the intersection. -/
def rollingX (k : Nat) : Q := m (8 * (k : Int) - 55)

/-- `forbid` (violated): A single vehicle approaches a signalised crossroads on a lane that one signal head governs; no other road user is anywhere in the scene. The trace begins well before the window behind, so no window is truncated, and every atom the rule reads is observed. The head displays circular yellow alone at each observation of the approach, then circular red; at the first observation after the red appears, the vehicle's footprint, which did not overlap the intersection region at the previous observation, overlaps it. -/
def forbidTrace : Trace :=
  padded <| Build.trace 8 20000 (Units.seconds 1) fun k t =>
    sceneAt t (rollingX k) (Units.metresPerSecond 8)
      (if k ≤ 5 then [.circularYellow] else [.circularRed])
      (if k ≤ 6 then onApproach else acrossTheLine)

/-- The approach that stops: braking from 8 m/s to rest at x = -26 m, clear of the intersection. -/
def brakingX (k : Nat) : Q :=
  m (match k with
     | 0 => -55
     | 1 => -47
     | 2 => -40
     | 3 => -34
     | 4 => -30
     | 5 => -27
     | _ => -26)

def brakingSpeed (k : Nat) : Q :=
  Units.metresPerSecond (match k with
     | 0 => 8
     | 1 => 8
     | 2 => 7
     | 3 => 6
     | 4 => 4
     | 5 => 2
     | _ => 0)

/-- `permit` (compliant): The same vehicle, the same head and the same governed lane, every atom observed and the trace running well before the window behind. The head shows circular yellow alone, then circular red; the vehicle brakes and stands with its footprint clear of the intersection region at every observation for which the red is displayed, so it comes to overlap that region at no such observation. -/
def permitTrace : Trace :=
  padded <| Build.trace 8 20000 (Units.seconds 1) fun k t =>
    sceneAt t (brakingX k) (brakingSpeed k)
      (if k ≤ 5 then [.circularYellow] else [.circularRed])
      onApproach

/-- `idle` (not_applicable): The same vehicle on the same governed lane, every atom observed, the trace running well before the window behind so that the look-back is covered at every observation. The head displays circular green at every observation of that window and at the observation of entry, having shown no yellow anywhere in it, and the vehicle crosses into the intersection region on the green. -/
def idleTrace : Trace :=
  padded <| Build.trace 8 20000 (Units.seconds 1) fun k t =>
    sceneAt t (rollingX k) (Units.metresPerSecond 8)
      [.circularGreen]
      (if k ≤ 6 then onApproach else acrossTheLine)

/-- `blind` (unknown): The forbid scene exactly - the head mapped, its yellow and then its red read at every observation, the vehicle's footprint crossing into the intersection region - except that the source's manifest declares the device-to-lane governance relation absent. Which lane the head applies to is never read, so whether this head is the one the subject's traffic faces is never decided, and the rule neither clears nor convicts. -/
def blindTrace : Trace := forbidTrace

/-- The instants every witness speaks about: the eight observations of the approach. -/
def speaksAbout : Timestamp × Timestamp := (20000, 27000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_307_6a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := some speaksAbout }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"] ]

end TrafficSpecWitness.NRS_484B_307_6a
