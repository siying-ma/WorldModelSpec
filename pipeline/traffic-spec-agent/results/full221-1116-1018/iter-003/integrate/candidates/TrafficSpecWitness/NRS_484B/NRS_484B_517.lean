/-
  Witnesses for NRS_484B_517.

  Geometry (the witness's own figures, none of them in the rule): one eastbound lane (region 10)
  from x = −200 m to x = 300 m, y ∈ [0, 4] m; a curb zone (region 20) at the lane's curb side,
  x ∈ [100, 120] m, y ∈ [0, 3] m, of kind bus_stop (passenger_loading in `idle`). The subject
  (track 1) is a taxicab-class car (half-extents 2.3 × 0.9 × 0.75 m) on y = 2 m, so it lies in
  both the lane and the zone when its reference point is within the zone's x range.

  Instants every 5 s. Two motions:
  - long halt: the subject is at rest at x = 105 m from t = 0 to t = 100 s (21 instants): from
    t = 60 s on, it has been at rest for the whole 60 s standing duration (parked);
  - brief halt: the subject drives at 2 m/s from x = −35 m (t = 0) to x = 95 m (t = 65 s, outside
    the zone), rests at x = 105 m from t = 70 s to t = 90 s (20 s, well under 60 s, and the 60 s
    window behind each halted instant holds the earlier driving), then drives off at 2 m/s
    (x = 115 m at t = 95 s, then beyond the zone).

  Reading values: halt tolerance 0.1 m/s (rest is 0, driving 2 m/s); queue gap 5 m (branch_3's
  gap 2.4 m, branch_10's 16.8 m); standing duration 60 s; zone entry reach 10 m (branch_10's
  bicycle 4.1 m from the zone).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_517
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_517

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure :=
  Build.lane 10 [(m (-200), m 0), (m 300, m 0), (m 300, m 4), (m (-200), m 4)] Build.east
    (ordinal := some 1) (count := some 1)

def zoneZ (kind : CurbZoneKind) : Structure :=
  { Build.rect 20 .curbZone (m 100) (m 0) (m 120) (m 3) with curbKind := some kind }

def carExt : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The subject at `x` on y = 2 m, heading east, with its doors as given (`none`: unobserved). -/
def subjectAt (x speed : Q) (doors : Option (List DoorSide)) : RoadUser :=
  Build.withSignals (Build.user 1 [.taxicab] (x, m 2) Build.east speed carExt)
    fun s => { s with doorsOpen := doors }

def drive : Q := Units.metresPerSecond 2

/-- Long halt: at rest at x = 105 m throughout. -/
def longX (_k : Nat) : Q × Q := (m 105, Q.zero)

/-- Brief halt: driving in, at rest at x = 105 m for k = 14…18, driving off. -/
def briefX (k : Nat) : Q × Q :=
  if k ≤ 13 then (m (-35 + 10 * (k : Int)), drive)
  else if k ≤ 18 then (m 105, Q.zero)
  else (m (115 + 10 * ((k : Int) - 19)), drive)

def briefHalted (k : Nat) : Bool := 14 ≤ k && k ≤ 18

/-- A trace of `n` instants 5 s apart: the subject's motion, its doors per instant, the zone's kind,
    the other road users and the devices per instant. -/
def mkTrace (n : Nat) (motion : Nat → Q × Q) (doors : Nat → Option (List DoorSide))
    (kind : CurbZoneKind) (others : Nat → List RoadUser) (devices : List Device) : Trace :=
  Build.trace n 0 (Units.seconds 5) fun k t =>
    let (x, v) := motion k
    Build.scene t (some 1) (subjectAt x v (doors k) :: others k) [laneL, zoneZ kind] devices

def closed : Nat → Option (List DoorSide) := fun _ => some []
def curbOpenWhileHalted : Nat → Option (List DoorSide) :=
  fun k => if briefHalted k then some [.curb] else some []
def noOthers : Nat → List RoadUser := fun _ => []

/-- `forbid` (violated): A taxicab-class passenger car halts in a bus_stop curb zone for longer than the standing duration, doors closed; no road user ahead and no stop control governs its lane. -/
def forbidTrace : Trace := mkTrace 21 longX closed .busStop noOthers []

/-- `permit` (compliant): A taxicab-class passenger car halts briefly in a bus_stop curb zone with its curb-side door open and moves off before the standing duration; no other road user is in the scene. -/
def permitTrace : Trace := mkTrace 23 briefX curbOpenWhileHalted .busStop noOthers []

/-- `idle` (not_applicable): A taxicab-class passenger car halts in a passenger_loading curb zone, which is neither a bus stop nor a taxicab stand; no bus_stop or taxicab_stand zone is occupied. -/
def idleTrace : Trace := mkTrace 21 longX closed .passengerLoading noOthers []

/-- `blind` (unknown): A taxicab-class passenger car halts briefly in a bus_stop curb zone and the source does not observe its doors. -/
def blindTrace : Trace := mkTrace 23 briefX (fun _ => none) .busStop noOthers []

/-- `branch_1` (violated): A taxicab-class passenger car halts briefly in a bus_stop curb zone and moves off before the standing duration, its doors closed throughout the halt: it is not loading or unloading passengers; no other road user is in the scene and no stop control governs its lane. -/
def branch_1Trace : Trace := mkTrace 23 briefX closed .busStop noOthers []

/-- `branch_2` (violated): A taxicab-class passenger car halts in a bus_stop curb zone with its curb-side door open and stays halted longer than the standing duration: the stop is not temporary; no other road user is in the scene and no stop control governs its lane. -/
def branch_2Trace : Trace := mkTrace 21 longX (fun _ => some [.curb]) .busStop noOthers []

/-- `branch_3` (compliant): A taxicab-class passenger car halts in a bus_stop curb zone for longer than the standing duration, doors closed, a short queue gap behind a halted vehicle ahead in its lane: a halt to avoid conflict with other traffic. -/
def branch_3Trace : Trace :=
  -- the lead car's rear at 112 − 2.3 = 109.7 m, the subject's front at 107.3 m: a 2.4 m gap
  mkTrace 21 longX closed .busStop
    (fun _ => [Build.user 2 [.motorVehicle] (cm 11200, m 2) Build.east Q.zero carExt]) []

/-- `branch_4` (compliant): the long, doors-closed halt in the bus stop, on a lane a stop sign governs. -/
def branch_4Trace : Trace :=
  mkTrace 21 longX closed .busStop noOthers [Build.sign 30 .stopSign [10]]

/-- `branch_5` (compliant): the long, doors-closed halt in the bus stop, on a lane a yield sign governs. -/
def branch_5Trace : Trace :=
  mkTrace 21 longX closed .busStop noOthers [Build.sign 31 .yieldSign [10]]

/-- `branch_6` (compliant): the long, doors-closed halt in the bus stop, on a lane whose signal shows circular red. -/
def branch_6Trace : Trace :=
  mkTrace 21 longX closed .busStop noOthers [Build.signal 32 [10] [.circularRed]]

/-- `branch_7` (compliant): the long, doors-closed halt, on a lane a railway signal governs with its lights flashing (gate up). -/
def branch_7Trace : Trace :=
  mkTrace 21 longX closed .busStop noOthers
    [{ Build.device 33 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .up }]

/-- `branch_8` (compliant): the long, doors-closed halt, on a lane a railway gate governs, lights dark and gate down. -/
def branch_8Trace : Trace :=
  mkTrace 21 longX closed .busStop noOthers
    [{ Build.device 33 .railwaySignalOrGate [10] with railLights := some .dark, gate := some .down }]

/-- `branch_9` (compliant): the long, doors-closed halt, on a lane a police officer directs with the indication stop. -/
def branch_9Trace : Trace :=
  mkTrace 21 longX closed .busStop noOthers
    [{ Build.device 34 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_10` (compliant): the permit halt with a bicycle (neither bus nor taxicab) at rest ahead in
    the lane outside the zone, 4.1 m from it: no bus or taxicab waits to enter. -/
def branch_10Trace : Trace :=
  mkTrace 23 briefX curbOpenWhileHalted .busStop
    (fun k => if k ≤ 18 then
        [Build.user 3 [.bicycle] (m 125, m 2) Build.east Q.zero (cm 90, cm 30, cm 80)] else []) []

/-- `branch_11` (compliant): the permit halt with three motor vehicles, whose bus or taxicab class the
    reading leaves unresolved, ahead in the lane while the subject is at rest: one at rest inside the
    zone (track 4, centre 116 m, 6.4 m gap to the subject), one at rest 37.7 m beyond it (track 5),
    and one creeping east at 0.5 m/s from 1 m beyond the zone that leaves the 10 m reach (by
    t = 90 s) without entering it (track 6): none waits to enter or is about to enter the zone. -/
def branch_11Trace : Trace :=
  mkTrace 23 briefX curbOpenWhileHalted .busStop
    (fun k => if briefHalted k then
        [ Build.user 4 [.motorVehicle] (m 116, m 2) Build.east Q.zero carExt
        , Build.user 5 [.motorVehicle] (m 160, m 2) Build.east Q.zero carExt
        , Build.user 6 [.motorVehicle]
            (Q.add (cm 12330) (Q.mul (Q.ofInt (Int.ofNat k - 14)) (cm 250)), m 2) Build.east (cm 50) carExt ]
      else []) []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_517"
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
  , witness "blind" blindTrace (.unknown []) ["sig.door_open"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant ]

end TrafficSpecWitness.NRS_484B_517
