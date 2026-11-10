/-
  Witnesses for NRS_484B_450_1c.

  The intersection is region 1, a 20 m square centred on the origin (−10…10 in x and y). The car x
  (track 1) is a passenger car, half-extents 2.25 m × 0.9 m × 0.75 m, heading north. Halted means a
  speed of zero (the reading's tolerance is 0.2 m/s); moving means 10 m/s. Every scene declares
  `asm.halt_required_by_law` (false, except in `branch_4`). Scenes are one second apart (half a
  second in `permit`).

  - forbid: x halted at the centre of the intersection for ten seconds; nothing else present.
  - permit: x crosses the intersection at 10 m/s.
  - idle: x halted at a curb 100 m east of the intersection.
  - blind: x at the centre of the intersection with no speed supplied.
  - branch_1: x halted at the centre waiting to turn left; an oncoming car (track 2) 25 m ahead and
    2 m to the west heads south at 10 m/s: closest approach in 2.5 s at 2 m centre distance (horizon
    3 s, clearance 4 m); its body is 20.5 m ahead of x's, far beyond the 4 m standstill gap.
  - branch_2: x halted at the centre; a police officer (device 20) governing the intersection shows
    stop.
  - branch_3: x halted at the centre; a halted car (track 2) 6.5 m ahead in its lane, a 2 m gap
    between the bodies (standstill gap 4 m); neither moves, so no predicted conflict.
  - branch_4: x halted at the centre; asm.halt_required_by_law declared true.
  - branch_5: x halted at the centre; a signal head (device 30) governing the intersection shows
    circular red.
  - branch_6: x halted at the centre; a stop sign (device 31) governs the intersection.
  - branch_7: x halted at the centre; a yield sign (device 32) governs the intersection.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def asmId : AsmId := "asm.halt_required_by_law"

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

def junction : Structure := Build.rect 1 .intersection (m (-10)) (m (-10)) (m 10) (m 10)

/-- The car x halted at the centre of the intersection. -/
def haltedCar : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) Build.north (Units.metresPerSecond 0) carExtent

/-- A scene with x halted at the centre of the intersection, the other users and devices given. -/
def haltedScene (t : Timestamp) (others : List RoadUser) (devices : List Device)
    (required : Bool := false) : Scene :=
  Build.scene t (some 1) (haltedCar :: others) [junction] devices (assumptions := [(asmId, required)])

/-- `forbid` (violated): A car halts within an intersection for ten seconds; no other road user, officer or device directing a halt is present and asm.halt_required_by_law is declared false. -/
def forbidTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun _k t => haltedScene t [] []

/-- `permit` (compliant): The car crosses the intersection without halting. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (-5 + 5 * (k : Int))) Build.north
          (Units.metresPerSecond 10) carExtent ]
      [ junction ]
      [ ]
      (assumptions := [(asmId, false)])

/-- `idle` (not_applicable): The car halts at the curb well away from any intersection. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 100, m 0) Build.north (Units.metresPerSecond 0) carExtent ]
      [ junction ]
      [ ]
      (assumptions := [(asmId, false)])

/-- `blind` (unknown): A car is within an intersection; the source supplies no speed, so whether it halts is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin haltedCar fun k => { k with speed := none } ]
      [ junction ]
      [ ]
      (assumptions := [(asmId, false)])

/-- `branch_1` (compliant): A car waiting to turn left halts within the intersection while an oncoming car is in predicted conflict with it. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltedScene t
      [ Build.user 2 [.motorVehicle] (m (-2), m 25) Build.south (Units.metresPerSecond 10) carExtent ]
      []

/-- `branch_2` (compliant): A car halts within the intersection at a police officer's stop indication governing the intersection; asm.halt_required_by_law declared false. -/
def officer : Device :=
  { Build.device 20 .humanDirection [1] (some (m 8, m 8)) with
    humanRole := some .policeOfficer, humanIndication := some .stop }

def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => haltedScene t [] [officer]

/-- `branch_3` (compliant): A car halts within the intersection behind a halted car 2 m ahead of it in its queue. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltedScene t
      [ Build.user 2 [.motorVehicle] (m 0, cm 650) Build.north (Units.metresPerSecond 0) carExtent ]
      []

/-- `branch_4` (compliant): A car halts within the intersection where another legal duty requires it (asm.halt_required_by_law declared true). -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => haltedScene t [] [] (required := true)

/-- `branch_5` (compliant): A car halts within the intersection while a signal governing it shows circular red. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltedScene t [] [Build.signal 30 [1] [.circularRed]]

/-- `branch_6` (compliant): A car halts within the intersection governed by a stop sign. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltedScene t [] [Build.sign 31 .stopSign [1]]

/-- `branch_7` (compliant): A car halts within the intersection governed by a yield sign. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltedScene t [] [Build.sign 32 .yieldSign [1]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1c"
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
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant ]

end TrafficSpecWitness.NRS_484B_450_1c
