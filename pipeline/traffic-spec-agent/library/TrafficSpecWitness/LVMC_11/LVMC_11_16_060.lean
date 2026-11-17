/-
  Witnesses for LVMC_11_16_060.

  Geometry: a street (highway region 100, x ∈ [-200, 200], y ∈ [-10, 10]) carrying one eastbound
  lane (region 101, x ∈ [-200, 200], y ∈ [0, 4]). The subject (track 1, a motor vehicle, 4.6 m by
  1.8 m) sits at (0, 2), heading east, in the lane and on the highway, at three instants 1 s apart.
  Speeds: 35 mph (above 25 by 10 mph) or 20 mph (below by 5 mph). Signs: device 10, a speed limit
  sign of 45 mph maximum (idle), of unobserved governance (blind), or a 15 mph minimum (branch_1).
  branch_2 places the subject on a lot outside the highway. Every figure here is the witness's own
  and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_060
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_16_060

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def street : Structure := Build.rect 100 .highway (m (-200)) (m (-10)) (m 200) (m 10)

def eastLane : Structure :=
  Build.lane 101 [(m (-200), m 0), (m 200, m 0), (m 200, m 4), (m (-200), m 4)] Build.east

def subjectAt (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east speed (cm 230, cm 90, cm 75)

def onStreet (speed : Q) : RoadUser := subjectAt (m 0, m 2) speed

def sceneTrace (u : RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [u] structures devices

/-- `forbid` (violated): Subject on a street lane governed by no speed limit sign travels above twenty-five mph. -/
def forbidTrace : Trace :=
  sceneTrace (onStreet (Units.mph 35)) [street, eastLane] []

/-- `permit` (compliant): Same, at or below twenty-five mph. -/
def permitTrace : Trace :=
  sceneTrace (onStreet (Units.mph 20)) [street, eastLane] []

/-- `idle` (not_applicable): The subject's lane is governed by a maximum speed limit sign (45 mph posting). -/
def idleTrace : Trace :=
  sceneTrace (onStreet (Units.mph 35)) [street, eastLane]
    [Build.speedLimit 10 [101] (Units.mph 45) .maximum]

/-- `blind` (unknown): A speed limit sign is present but the source does not observe what it governs; subject above twenty-five mph. -/
def blindTrace : Trace :=
  sceneTrace (onStreet (Units.mph 35)) [street, eastLane]
    [{ Build.speedLimit 10 [] (Units.mph 45) .maximum with governsObserved := false }]

/-- `branch_1` (violated): only a minimum speed limit sign (15 mph) governs the subject's lane — no
    different maximum is posted — and the subject travels at 35 mph. -/
def branch1Trace : Trace :=
  sceneTrace (onStreet (Units.mph 35)) [street, eastLane]
    [Build.speedLimit 10 [101] (Units.mph 15) .minimum]

/-- `branch_2` (not_applicable): the subject is on a lot off the highway, at 35 mph. -/
def branch2Trace : Trace :=
  sceneTrace (subjectAt (m 0, m 50) (Units.mph 35)) [street, eastLane] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_16_060"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_16_060
