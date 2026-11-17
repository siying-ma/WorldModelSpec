/-
  Witnesses for NRS_484B_517.

  Geometry (the witness's own figures, nowhere in the rule):
  - an eastbound lane (region 20) x ∈ [-1000, 1000] m, y ∈ [0, 4] m;
  - a curb zone (region 10) x ∈ [100, 125] m, y ∈ [0, 2] m, of kind bus_stop unless stated;
  - the subject (track 1), half-extents 2 × 1 × 1 m, at y = 1 m (inside lane and zone where
    x ∈ [100, 125]); 30 observations every 5 s (t = 0 … 145 s).
    For k < 14 (t < 70 s) it drives at 10 m/s, reaching x = 60 m at k = 13 (outside the zone);
    from k = 14 (t = 70 s) it stands at x = 110 m, speed 0. A brief halt ends at k = 17 (t = 85 s,
    15 s of standing, far below the 60 s dwell) and the car drives off at 10 m/s; a long halt lasts
    to the end of the trace (75 s of standing, so from t = 130 s it is parked over 60 s).
  The first 60 s of driving cover the dwell window of every halted observation.

  The run's reading of the admitted aggregates: DEF-NRS-484A-030::bus includes no class and leaves
  every motor-vehicle class unresolved except ru.taxicab; DEF-NRS-484A-270::taxicab includes no
  class and leaves every motor-vehicle class unresolved, ru.taxicab included. The only road user
  decidedly a vehicle and decidedly no bus is one of class taxicab alone, so the "passenger car" of
  the narratives is a car of class taxicab in a bus_stop zone; no road user is ever decidedly a bus
  or a taxicab, and no road user is decidedly not a taxicab.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_517
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_517

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneR : Structure := Build.rect 20 .lane (m (-1000)) (m 0) (m 1000) (m 4)
def zoneR (k : CurbZoneKind) : Structure :=
  { Build.rect 10 .curbZone (m 100) (m 0) (m 125) (m 2) with curbKind := some k }

/-- The subject at observation k: drives in, stands at x = 110 m from k = 14 through `haltEnd`,
    then drives off; `doors k` is its open doors. -/
def subjectAt (classes : List RoadUserClass) (haltEnd : Nat) (doors : Nat → Option (List DoorSide))
    (k : Nat) : RoadUser :=
  let ki : Int := k
  let he : Int := haltEnd
  let (x, v) : Int × Int :=
    if k < 14 then (110 - 50 * (14 - ki), 10)
    else if k ≤ haltEnd then (110, 0)
    else (110 + 50 * (ki - he), 10)
  Build.withSignals
    (Build.user 1 classes (m x, m 1) Build.east (Units.metresPerSecond v) (m 2, m 1, m 1))
    fun s => { s with doorsOpen := doors k }

def closed : Nat → Option (List DoorSide) := fun _ => some []
def curbOpenBriefly : Nat → Option (List DoorSide) := fun k =>
  if k == 15 || k == 16 then some [.curb] else some []

def briefHalt : Nat := 17
def longHalt : Nat := 29

/-- A trace of the subject with a zone kind, other users and devices fixed over time. -/
def mkTrace (classes : List RoadUserClass) (haltEnd : Nat) (doors : Nat → Option (List DoorSide))
    (kind : CurbZoneKind) (others : List RoadUser) (devices : List Device) : Trace :=
  Build.trace 30 0 (Units.seconds 5) fun k t =>
    Build.scene t (some 1) (subjectAt classes haltEnd doors k :: others) [laneR, zoneR kind] devices

/-- A halted motor vehicle (track 2) ahead in the lane, its rear at `rearX`. -/
def queuedAhead (rearX : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (rearX + 2), m 1) Build.east (Units.metresPerSecond 0) (m 2, m 1, m 1)

/-- A halted bus (track 3) in the lane just short of the zone: body x ∈ [84, 96] m, 4 m from it. -/
def busWaiting : RoadUser :=
  Build.user 3 [.bus] (m 90, m 1) Build.east (Units.metresPerSecond 0) (m 6, m 1, m 1)

/-- `forbid` (violated): A passenger car halts in a bus_stop curb zone for longer than the standing duration, doors closed; no road user ahead and no stop control governs its lane. -/
def forbidTrace : Trace := mkTrace [.taxicab] longHalt closed .busStop [] []

/-- `permit` (compliant): A passenger car halts briefly in a bus_stop curb zone with its curb-side door open and moves off before the standing duration; no other road user is in the scene. -/
def permitTrace : Trace := mkTrace [.taxicab] briefHalt curbOpenBriefly .busStop [] []

/-- `idle` (not_applicable): the subject stands in a curb zone that is neither a bus stop nor a
    taxicab stand (passenger_loading). (A bus in a bus stop cannot be decided: the run's reading
    leaves every bus class unresolved for DEF-NRS-484A-030::bus.) -/
def idleTrace : Trace := mkTrace [.taxicab] longHalt closed .passengerLoading [] []

/-- `blind` (unknown): a car halts briefly in a bus_stop zone and the source does not observe its
    doors (masked: sig.door_open). -/
def blindTrace : Trace := mkTrace [.taxicab] briefHalt curbOpenBriefly .busStop [] []

/-- `branch_1` (violated): A passenger car halts briefly in a bus_stop zone with a door open while a bus stands halted just outside the zone within the waiting reach. -/
def branch_1Trace : Trace := mkTrace [.taxicab] briefHalt curbOpenBriefly .busStop [busWaiting] []

/-- `branch_2` (violated): A truck halts briefly in a taxicab_stand zone with a door open: it is no passenger vehicle. -/
def branch_2Trace : Trace := mkTrace [.truck] briefHalt curbOpenBriefly .taxicabStand [] []

-- branch_3 (compliant): long halt in the bus stop; a stop sign governs the lane it occupies.
def branch_3Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop []
  [Build.sign 31 .stopSign [20]]

-- branch_4 (compliant): long halt in the bus stop; a yield sign governs its lane.
def branch_4Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop []
  [Build.sign 32 .yieldSign [20]]

-- branch_5 (compliant): long halt in the bus stop; a signal governing its lane shows circular red.
def branch_5Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop []
  [Build.signal 30 [20] [.circularRed]]

-- branch_6 (compliant): long halt; a railway signal governing its lane flashes, gate up.
def branch_6Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop []
  [{ Build.device 33 .railwaySignalOrGate [20] with railLights := some .flashing, gate := some .up }]

-- branch_7 (compliant): long halt; a railway gate governing its lane is down, lights dark.
def branch_7Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop []
  [{ Build.device 33 .railwaySignalOrGate [20] with railLights := some .dark, gate := some .down }]

-- branch_8 (compliant): long halt; a police officer directing its lane indicates stop.
def branch_8Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop []
  [{ Build.device 34 .humanDirection [20] with humanRole := some .policeOfficer, humanIndication := some .stop }]

-- branch_9 (compliant): long halt 2 m behind a halted vehicle ahead in the lane (a queue).
def branch_9Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop [queuedAhead 114] []

-- branch_10 (violated): long halt with the vehicle ahead 15 m off, beyond the queue gap.
def branch_10Trace : Trace := mkTrace [.taxicab] longHalt closed .busStop [queuedAhead 127] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_517"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (70000, 145000)
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
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_517
