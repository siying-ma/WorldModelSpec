/-
  Witnesses for NRS_484B_440_1_o1.

  Geometry (world frame, +x east, +y north, metres): highway 1 spans x ∈ [-100, 100],
  y ∈ [-20, 20]. Roadway 2 lies on it from y = 3.7 down to the roadway's south edge (−3.7, or −11.1
  in `permit`); eastbound lane 4 is y ∈ [−3.7, 0], westbound lane 5 y ∈ [0, 3.7]. Shoulder 3 is the
  3 m strip south of the roadway's edge, on highway 1. The car (track 1, half-extents 2.4 × 0.9 m)
  stands at (0, −1.85) heading east at speed 0: its body's south side is at y = −2.75, 0.95 m from
  the shoulder (8.35 m in `permit`). Every scene declares the three assumptions; three instants
  1 s apart (0.5 s in `branch_3`). No rule look-back, so no window.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_440_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_440_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def asms (district disabled : Bool) : List (AsmId × Bool) :=
  [ ("asm.business_or_residence_district", district)
  , ("asm.vehicle_disabled", disabled)
  , ("asm.disabled_vehicle_immovable", disabled) ]

/-- The highway, its roadway (south edge at `edge`), the two lanes and the shoulder below `edge`. -/
def structures (edge : Q) : List Structure :=
  [ Build.rect 1 .highway (m (-100)) (m (-20)) (m 100) (m 20)
  , { Build.rect 2 .roadway (m (-100)) edge (m 100) (cm 370) with ways := some [1] }
  , { Build.rect 3 .shoulder (m (-100)) (Q.sub edge (m 3)) (m 100) edge with ways := some [1] }
  , { Build.lane 4 [(m (-100), cm (-370)), (m 100, cm (-370)), (m 100, m 0), (m (-100), m 0)] Build.east
      with ways := some [1] }
  , { Build.lane 5 [(m (-100), m 0), (m 100, m 0), (m 100, cm 370), (m (-100), cm 370)] Build.west
      with ways := some [1] } ]

/-- The car, halted in the eastbound lane. -/
def car : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, cm (-185)) Build.east Q.zero (cm 240, cm 90, cm 75)

/-- A halt of the car with the given others, devices, shoulder edge and assumptions. -/
def haltTrace (others : List RoadUser) (devices : List Device) (edge : Q := cm (-370))
    (district disabled : Bool := false) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) (car :: others) (structures edge) devices
      (assumptions := asms district disabled)

/-- `forbid` (violated): On a rural highway, asm.business_or_residence_district declared false and both disabled assumptions declared false, a car halts in the right lane for a minute; a free shoulder lies beside it within the reach; no other road user and no device is present. -/
def forbidTrace : Trace := haltTrace [] []

/-- `permit` (compliant): The same halt on a highway with no shoulder within the reach of the car's body. -/
def permitTrace : Trace := haltTrace [] [] (edge := cm (-1110))

/-- `idle` (not_applicable): The same halt with asm.business_or_residence_district declared true. -/
def idleTrace : Trace := haltTrace [] [] (district := true)

/-- `blind` (unknown): The forbid scene with no speed observed, so whether the car is halted is unknown. -/
def blindTrace : Trace := Build.masked (Build.manifest ["kin.speed"]) forbidTrace

/-- `branch_1` (compliant): The car halts in the lane behind a stopped truck within the queue standstill gap, with a free shoulder beside it. -/
def branch_1Trace : Trace :=
  haltTrace [Build.user 2 [.truck] (cm 940, cm (-185)) Build.east Q.zero (m 5, cm 125, cm 150)] []

/-- `branch_2` (not_applicable): The car halts in the lane with asm.vehicle_disabled and asm.disabled_vehicle_immovable declared true. -/
def branch_2Trace : Trace := haltTrace [] [] (disabled := true)

/-- `branch_3` (compliant): a pedestrian crossing 3 m ahead of the car walks towards its path,
    closest approach 3 m within 2.5 s: the car halts to avoid conflict. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let ped := Build.user 2 [.pedestrian] (m 3, Q.sub (cm 65) (cm (50 * k))) Build.south (m 1)
      (cm 30, cm 30, cm 90)
    Build.scene t (some 1) [car, ped] (structures (cm (-370))) [] (assumptions := asms false false)

/-- `branch_4` (compliant): a traffic signal governing the car's lane shows circular red. -/
def branch_4Trace : Trace := haltTrace [] [Build.signal 10 [4] [.circularRed]]

/-- `branch_5` (compliant): a stop sign governs the car's lane. -/
def branch_5Trace : Trace := haltTrace [] [Build.sign 11 .stopSign [4]]

/-- `branch_6` (compliant): a yield sign governs the car's lane. -/
def branch_6Trace : Trace := haltTrace [] [Build.sign 12 .yieldSign [4]]

/-- `branch_7` (compliant): a police officer directing the car's lane signals stop. -/
def branch_7Trace : Trace :=
  haltTrace [] [{ Build.device 13 .humanDirection [4] with
    humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_8` (compliant): a truck stands on the shoulder alongside the car, so halting off the
    roadway is not practicable. -/
def branch_8Trace : Trace :=
  haltTrace [Build.user 2 [.truck] (m 1, cm (-520)) Build.east Q.zero (m 5, cm 125, cm 150)] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_440_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant ]

end TrafficSpecWitness.NRS_484B_440_1_o1
