/-
  Witnesses for NRS_484B_477_1a.

  Geometry: an alley (region 10) running east, x from -10 m to 300 m, y from -3 m to 3 m, with
  one lane (region 11, direction east) over the same polygon. The subject (track 1) is a motor
  vehicle 5 m long and 2 m wide, heading east on y = 0. Scenes every 10 s from 0 s to 240 s;
  every witness judges the instants 220 s … 240 s, whose 180 s look-back starts at 40 s or later.

  - Long halt: the subject drives in at 1 m/s (x = 0, 10 m) and is at rest at x = 20 m from 20 s
    on: at 220 s … 240 s it has been at rest 200 … 220 s, beyond the 180 s bound.
  - Short halt (permit): the subject moves at 1 m/s except at rest at x = 60 m from 60 s to 90 s;
    every judged instant has moving observations in its window behind.
  - Queue (branch_2): a second motor vehicle (track 2) at rest at x = 27 m, rear at 24.5 m, 2 m
    ahead of the subject's front (22.5 m), in the same lane; branch_3 puts it at x = 35 m, 10 m
    ahead.
  - Devices (branch_4 … branch_8): one device (20) of each claimed kind governing the lane.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_477_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_477_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def alleyRegion : Structure := Build.rect 10 .alley (m (-10)) (m (-3)) (m 300) (m 3)
def laneRegion : Structure :=
  Build.lane 11 [(m (-10), m (-3)), (m 300, m (-3)), (m 300, m 3), (m (-10), m 3)] Build.east

def body : Q × Q × Q := (cm 250, m 1, cm 75)

def subjectAt (x v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v body

/-- Long halt: drives in, at rest at x = 20 m from 20 s on. -/
def longHalt (k : Nat) : RoadUser :=
  if k < 2 then subjectAt (m (10 * (k : Int))) (Units.metresPerSecond 1)
  else subjectAt (m 20) Q.zero

/-- Short halt: at rest at x = 60 m from 60 s to 90 s, moving at 1 m/s otherwise. -/
def shortHalt (k : Nat) : RoadUser :=
  if k ≤ 6 then subjectAt (m (10 * (k : Int))) (if k = 6 then Q.zero else Units.metresPerSecond 1)
  else if k ≤ 9 then subjectAt (m 60) Q.zero
  else subjectAt (m (60 + 10 * ((k : Int) - 9))) (Units.metresPerSecond 1)

def stdAsm : List (AsmId × Bool) :=
  [("asm.business_district", true), ("asm.local_alley_ordinance", false)]

def mkTrace (subj : Nat → RoadUser) (others : List RoadUser := []) (devices : List Device := [])
    (asms : List (AsmId × Bool) := stdAsm) : Trace :=
  Build.trace 25 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) (subj k :: others) [alleyRegion, laneRegion] devices (assumptions := asms)

def judged : Option (Timestamp × Timestamp) := some (220000, 240000)

/-- `forbid` (violated): A vehicle that drove into an alley (asm.business_district true, asm.local_alley_ordinance false) has been at rest (kin.speed 0) for 200 s; nobody ahead, no device governs its region. -/
def forbidTrace : Trace := mkTrace longHalt

/-- `permit` (compliant): The same vehicle halts 30 s in the alley and drives on: at every observation it has moved within the 180 s window behind. -/
def permitTrace : Trace := mkTrace shortHalt

/-- `idle` (not_applicable): The same long halt in an alley where asm.business_district is false. -/
def idleTrace : Trace :=
  mkTrace longHalt (asms := [("asm.business_district", false), ("asm.local_alley_ordinance", false)])

/-- `blind` (unknown): As in forbid, but the source does not observe region occupancy, so whether the vehicle is in the alley is unknown. -/
def blindTrace : Trace := mkTrace longHalt

/-- `branch_1` (not_applicable): As in forbid with asm.local_alley_ordinance declared true. -/
def branch_1Trace : Trace :=
  mkTrace longHalt (asms := [("asm.business_district", true), ("asm.local_alley_ordinance", true)])

def leader (x : Q) : RoadUser := Build.user 2 [.motorVehicle] (x, Q.zero) Build.east Q.zero body

/-- `branch_2` (compliant): The vehicle stands 200 s in the alley 2 m behind another vehicle ahead of it in the same lane: a queue halt. -/
def branch_2Trace : Trace := mkTrace longHalt [leader (m 27)]

/-- `branch_3` (violated): as branch_2 with the vehicle ahead 10 m away, beyond the queue spacing. -/
def branch_3Trace : Trace := mkTrace longHalt [leader (m 35)]

def governed (k : DeviceKind) : Trace := mkTrace longHalt [] [Build.device 20 k [11]]

/-- `branch_4` (compliant): as forbid, the lane governed by a traffic signal. -/
def branch_4Trace : Trace := governed .trafficSignal
/-- `branch_5` (compliant): as forbid, the lane governed by a stop sign. -/
def branch_5Trace : Trace := governed .stopSign
/-- `branch_6` (compliant): as forbid, the lane governed by a yield sign. -/
def branch_6Trace : Trace := governed .yieldSign
/-- `branch_7` (compliant): as forbid, the lane governed by a railway signal or gate. -/
def branch_7Trace : Trace := governed .railwaySignalOrGate
/-- `branch_8` (compliant): as forbid, the lane governed by a person directing traffic. -/
def branch_8Trace : Trace := governed .humanDirection

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_477_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant ]

end TrafficSpecWitness.NRS_484B_477_1a
