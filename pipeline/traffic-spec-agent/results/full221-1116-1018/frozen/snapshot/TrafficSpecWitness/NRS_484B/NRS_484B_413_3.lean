/-
  Witnesses for NRS_484B_413_3.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - One eastbound lane, region 10: x ∈ [−400, 400] m, y ∈ [−2, 2] m, direction east.
  - Cars: half-extents 2.25 m × 0.90 m × 0.75 m (4.5 m long). Subject is track 1, on y = 0.
  - Follower (track 2), when present: a motor vehicle on the subject's lane, 19.5 m centre to
    centre behind it at every frame, so the body gap is 15 m (reach 30 m: kept by 15 m).
  - Lead (track 3), branch_8 only: a halted motor vehicle centred at x = 6.5 m, 2 m of body gap
    ahead of the subject once it has halted at x = 0 (queue gap 5 m: kept by 3 m).
  - Instants: 16 frames at 0.5 s, t = 0 … 7500 ms. The event is at frame 8, t = 4000 ms; the lead
    window (3 s) behind it is [1000, 4000] ms, inside the trace. Every witness judges
    [4000, 7500] ms, so the onsets at frame 0 (no previous observation) are not judged.
  - Halting profile: speed 8 − k m/s for k ≤ 8 (decelerating at 2 m/s², below the 3.4 m/s² sudden
    threshold), at rest (0 m/s, tolerance 0.1 m/s) from frame 8 at x = 0.
  - Sudden profile (branch_1): 15 m/s to frame 8, then −6 m/s² over frames 8–10 (15, 12, 9, 6 m/s),
    6 m/s after: never at rest.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneId : RegionId := 10

def lane1 : Structure :=
  Build.lane laneId [(m (-400), m (-2)), (m 400, m (-2)), (m 400, m 2), (m (-400), m 2)] Build.east

def car : Q × Q × Q := (cm 225, cm 90, cm 75)

def nFrames : Nat := 16
def dt : Q := Units.milliseconds 500
def judged : Option (Timestamp × Timestamp) := some (4000, 7500)

/-- Position along x by the trapezoid rule over the speeds (0.5 s steps). -/
def xOf (v : Nat → Q) (x0 : Q) : Nat → Q
  | 0 => x0
  | k + 1 => Q.add (xOf v x0 k) (Q.mul (Q.add (v k) (v (k + 1))) (Q.mk' 1 4))

/-- Halting profile: 8 − k m/s, at rest from frame 8. -/
def haltSpeed (k : Nat) : Q :=
  if k < 8 then Units.metresPerSecond (8 - (k : Int)) else Q.zero
def haltAccel (k : Nat) : Q :=
  if k < 8 then Units.metresPerSecondSq (-2) else Q.zero
def haltX0 : Q := m (-16)

/-- Sudden profile: 15 m/s, −6 m/s² over frames 8–10, 6 m/s after. -/
def suddenSpeed (k : Nat) : Q :=
  if k ≤ 8 then Units.metresPerSecond 15
  else if k ≤ 11 then Units.metresPerSecond (15 - 3 * ((k : Int) - 8))
  else Units.metresPerSecond 6
def suddenAccel (k : Nat) : Q :=
  if 8 ≤ k ∧ k ≤ 10 then Units.metresPerSecondSq (-6) else Q.zero
def suddenX0 : Q := m (-60)

/-- One frame: the subject on its profile with its signals; the follower 15 m of gap behind; the
    lead halted 2 m of gap ahead of the halt point; the devices given. -/
def frame (speed accel : Nat → Q) (x0 : Q) (brake : Nat → Option Bool) (hand : Nat → HandSignal)
    (follower lead : Bool) (devs : List Device) (k : Nat) (t : Timestamp) : Scene :=
  let x := xOf speed x0 k
  let subj :=
    Build.withSignals
      (Build.withKin (Build.user 1 [.motorVehicle] (x, Q.zero) Build.east (speed k) car)
        (fun kn => { kn with accelLongitudinal := some (accel k) }))
      (fun s => { s with brakeLamp := brake k, handSignal := some (hand k) })
  let fol := Build.user 2 [.motorVehicle] (Q.sub x (cm 1950), Q.zero) Build.east (speed k) car
  let ld := Build.user 3 [.motorVehicle] (cm 650, Q.zero) Build.east Q.zero car
  Build.scene t (some 1)
    ([subj] ++ (if follower then [fol] else []) ++ (if lead then [ld] else []))
    [lane1] devs

def unlit : Nat → Option Bool := fun _ => some false
def noArm : Nat → HandSignal := fun _ => .noSignal

def haltTrace (brake : Nat → Option Bool) (hand : Nat → HandSignal) (follower lead : Bool)
    (devs : List Device) : Trace :=
  Build.trace nFrames 0 dt fun k t => frame haltSpeed haltAccel haltX0 brake hand follower lead devs k t

/-- `forbid` (violated): The subject car halts mid-block in its lane with no road user ahead and no device or officer governing its lane; a car is 15 m behind it in the same lane; the brake lamps are not lit and no arm signal is given at any observation of the lead window or at the halt. -/
def forbidTrace : Trace := haltTrace unlit noArm true false []

/-- `permit` (compliant): The subject car halts mid-block with a car 15 m behind in the same lane; its brake lamps are lit from 2 s before the halt. -/
def permitTrace : Trace := haltTrace (fun k => some (decide (4 ≤ k))) noArm true false []

/-- `idle` (not_applicable): The subject car halts mid-block without any signal; no other road user is in the scene. -/
def idleTrace : Trace := haltTrace unlit noArm false false []

/-- `blind` (unknown): The subject car halts mid-block with a car 15 m behind in the same lane; no arm signal is given, and sig.brake_lamp is not observed on this source. -/
def blindTrace : Trace := haltTrace unlit noArm true false []

/-- `branch_1` (violated): The subject car decelerates at 6 m/s^2 without halting while a car is 15 m behind it in the same lane; the brake lamps stay unlit and no arm signal is given. -/
def branch_1Trace : Trace :=
  Build.trace nFrames 0 dt fun k t =>
    frame suddenSpeed suddenAccel suddenX0 unlit noArm true false [] k t

/-- `branch_2` (not_applicable): The subject car halts in a lane governed by a stop sign, with a car 15 m behind, without any signal: the halt is excused under DEF-NRS-484A-260 and the deceleration stays below the sudden threshold. -/
def branch_2Trace : Trace := haltTrace unlit noArm true false [Build.sign 20 .stopSign [laneId]]

/-- `branch_3` (not_applicable): as branch_2, the lane governed by a yield sign. -/
def branch_3Trace : Trace := haltTrace unlit noArm true false [Build.sign 21 .yieldSign [laneId]]

/-- `branch_4` (not_applicable): as branch_2, the lane governed by a traffic signal showing circular red. -/
def branch_4Trace : Trace := haltTrace unlit noArm true false [Build.signal 22 [laneId] [.circularRed]]

/-- `branch_5` (not_applicable): as branch_2, the lane governed by a railway signal flashing, its gate up. -/
def branch_5Trace : Trace :=
  haltTrace unlit noArm true false
    [{ Build.device 23 .railwaySignalOrGate [laneId] with railLights := some .flashing, gate := some .up }]

/-- `branch_6` (not_applicable): as branch_2, the lane governed by a railway gate down, its lights dark. -/
def branch_6Trace : Trace :=
  haltTrace unlit noArm true false
    [{ Build.device 23 .railwaySignalOrGate [laneId] with railLights := some .dark, gate := some .down }]

/-- `branch_7` (not_applicable): as branch_2, the lane governed by a police officer directing stop. -/
def branch_7Trace : Trace :=
  haltTrace unlit noArm true false
    [{ Build.device 24 .humanDirection [laneId] with
        humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_8` (not_applicable): the subject halts 2 m behind a halted car ahead in its lane (a queue), a car 15 m behind it, no signal. -/
def branch_8Trace : Trace := haltTrace unlit noArm true true []

/-- `branch_9` (compliant): the subject halts mid-block with a car 15 m behind; brake lamps unlit, but the stop-or-slow arm signal is given from 2 s before the halt. -/
def branch_9Trace : Trace :=
  haltTrace unlit (fun k => if 4 ≤ k then .stopOrSlow else .noSignal) true false []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_413_3"
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
  , witness "blind" blindTrace (.unknown []) ["sig.brake_lamp"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_413_3
