/-
  Witnesses for NRS_484B_267_2b.

  Geometry: an open east-bound carriageway, no structure unless stated. The subject (track 1) is a
  motor vehicle 4.5 m × 1.8 m heading east along y = 0. Track 2, "e", is an official vehicle of a
  regulatory agency (the authorized-emergency-vehicle aggregate admits no class as included in this
  run, so an ambulance would leave the duty's engagement unknown; the regulatory-agency limb is the
  decided one), 4.5 m × 1.8 m, heading east, its centre at y = 2.4 m (body gap 0.6 m) or
  y = 4.5 m (body gap 2.7 m).

  Passing scenes: five instants 1 s apart; the subject's centre runs x = -20 + 10k at 10 m/s, e's
  x = 2k at 2 m/s, so at k = 2 the centres are 4 m apart along x and the bodies overlap by 0.5 m
  (side by side). Closing scenes (branch_1, branch_9): three instants 0.1 s apart.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

def flashingRedFront : List WarningLamp := [{ colour := .red, mode := .flashing, facing := .front }]

def subjectAt (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) Build.east speed carExtent

def eAt (x y : Q) (speed : Q) (sig : Signals → Signals) : RoadUser :=
  Build.withSignals
    { Build.user 2 [.officialVehicle, .motorVehicle] (x, y) Build.east speed carExtent with
        officialKind := some .regulatoryAgency }
    sig

/-- Lamps flashing red to the front; nothing else of e's signals observed. -/
def lampsOn : Signals → Signals := fun g => { g with warningLamps := some flashingRedFront }
/-- Lamps flashing, no hand signal, no turn indicator. -/
def lampsOnIdle : Signals → Signals := fun g =>
  { g with warningLamps := some flashingRedFront, handSignal := some .noSignal, turnIndicator := some .off }
/-- Lamps flashing, an arm signal given, no turn indicator. -/
def lampsOnHand : Signals → Signals := fun g =>
  { g with warningLamps := some flashingRedFront, handSignal := some .left, turnIndicator := some .off }
/-- Lamps flashing, no arm signal, the left indicator lit. -/
def lampsOnIndicator : Signals → Signals := fun g =>
  { g with warningLamps := some flashingRedFront, handSignal := some .noSignal, turnIndicator := some .left }
/-- No warning lamp lit. -/
def lampsOff : Signals → Signals := fun g => { g with warningLamps := some [] }
/-- Warning lamps not observed. -/
def lampsUnseen : Signals → Signals := fun g => { g with warningLamps := none }

def visibility (v : Bool) : List MeasuredRelation :=
  [Build.relation 1 2 (fun r => { r with visible := some v })]

/-- Five instants 1 s apart: the subject at x = sx + sv·k, e at x = ex + ev·k, y = ey. -/
def passTrace (sx sv ex ev : Int) (ey : Q) (sig : Signals → Signals) (vis : Bool)
    (structures : List Structure := []) (devices : List Device := []) : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let ki : Int := Int.ofNat k
    Build.withRelations
      (Build.scene t (some 1)
        [ subjectAt (m (sx + sv * ki)) (Units.metresPerSecond sv)
        , eAt (m (ex + ev * ki)) ey (Units.metresPerSecond ev) sig ]
        structures devices)
      (visibility vis)

/-- `forbid` (violated): e, moving with a lit red flashing front lamp, is ahead of the moving subject
    within reach; the subject passes alongside it with a 0.6 m gap between bodies while they overlap. -/
def forbidTrace : Trace := passTrace (-20) 10 0 2 (cm 240) lampsOn true

/-- `permit` (compliant): as forbid, but e's centre 4.5 m to the side: a 2.7 m gap, centres never
    closer than 4.5 m, no contact. -/
def permitTrace : Trace := passTrace (-20) 10 0 2 (cm 450) lampsOn true

/-- `idle` (not_applicable): as forbid, e's warning lamps off. -/
def idleTrace : Trace := passTrace (-20) 10 0 2 (cm 240) lampsOff true

/-- `blind` (unknown): as forbid, e's warning lamps not observed. -/
def blindTrace : Trace := passTrace (-20) 10 0 2 (cm 240) lampsUnseen true

/-- `branch_1` (violated): the subject (15 m/s) closes from 12 m behind on e (5 m/s) in its path;
    centres meet within about 1.2 s; no overlap alongside, no contact in the trace. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 100) fun k t =>
    let ki : Int := Int.ofNat k
    Build.withRelations
      (Build.scene t (some 1)
        [ subjectAt (cm (150 * ki)) (Units.metresPerSecond 15)
        , eAt (Q.add (m 12) (cm (50 * ki))) Q.zero (Units.metresPerSecond 5) lampsOn ]
        [] [])
      (visibility true)

/-- `branch_2` (not_applicable): e stands at rest, lamps flashing, no hand signal, no indicator. -/
def branch_2Trace : Trace := passTrace (-20) 10 0 0 (cm 240) lampsOnIdle true

/-- `branch_3` (violated): e at rest gives an arm signal visible to the subject, which passes 0.6 m off. -/
def branch_3Trace : Trace := passTrace (-20) 10 0 0 (cm 240) lampsOnHand true

/-- `branch_4` (violated): e at rest shows its left indicator, visible; the subject passes 0.6 m off. -/
def branch_4Trace : Trace := passTrace (-20) 10 0 0 (cm 240) lampsOnIndicator true

/-- `branch_5` (not_applicable): as branch_3, but e is hidden from the subject. -/
def branch_5Trace : Trace := passTrace (-20) 10 0 0 (cm 240) lampsOnHand false

/-- `branch_6` (not_applicable): as forbid, but a police officer directs the lane the subject is in. -/
def branch_6Trace : Trace :=
  passTrace (-20) 10 0 2 (cm 240) lampsOn true
    [Build.rect 100 .lane (m (-60)) (m (-3)) (m 60) (m 6)]
    [{ Build.device 200 .humanDirection [100] with humanRole := some .policeOfficer }]

/-- `branch_7` (not_applicable): the subject is at rest; e drives past it 0.6 m off. -/
def branch_7Trace : Trace := passTrace 0 0 (-20) 10 (cm 240) lampsOn true

/-- `branch_8` (not_applicable): e is 200 m ahead, beyond the approach reach. -/
def branch_8Trace : Trace := passTrace 0 10 200 10 Q.zero lampsOn true

/-- `branch_9` (not_applicable): e (20 m/s) closes from 12 m behind on the subject (10 m/s): e is
    neither ahead of nor alongside the subject, which is not approaching it. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 100) fun k t =>
    let ki : Int := Int.ofNat k
    Build.withRelations
      (Build.scene t (some 1)
        [ subjectAt (m ki) (Units.metresPerSecond 10)
        , eAt (Q.add (m (-12)) (m (2 * ki))) Q.zero (Units.metresPerSecond 20) lampsOn ]
        [] [])
      (visibility true)

/-- `branch_10` (compliant): e drives 5 m ahead in the next lane at the subject's speed: the bodies are
    0.5 m apart along the way, not side by side, so the 0.78 m gap between them is not a passing gap;
    no closing, no contact. -/
def branch_10Trace : Trace := passTrace 0 10 5 10 (cm 240) lampsOn true

/-- `branch_11` (not_applicable): as forbid, but e is a bicycle showing a flashing red lamp: neither
    an authorized emergency vehicle nor an official vehicle. -/
def branch_11Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let ki : Int := Int.ofNat k
    Build.withRelations
      (Build.scene t (some 1)
        [ subjectAt (m (-20 + 10 * ki)) (Units.metresPerSecond 10)
        , Build.withSignals
            (Build.user 2 [.bicycle] (m (2 * ki), cm 240) Build.east (Units.metresPerSecond 2) (cm 90, cm 30, cm 75))
            lampsOn ]
        [] [])
      (visibility true)

/-- `branch_12` (compliant): as permit (the regulatory vehicle, track 2, passed 2.7 m off), and a
    bicycle (track 3) showing a flashing red lamp is passed 1.2 m off on the other side: the duty is
    owed to the regulatory vehicle only. -/
def branch_12Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let ki : Int := Int.ofNat k
    Build.withRelations
      (Build.scene t (some 1)
        [ subjectAt (m (-20 + 10 * ki)) (Units.metresPerSecond 10)
        , eAt (m (2 * ki)) (cm 450) (Units.metresPerSecond 2) lampsOn
        , Build.withSignals
            (Build.user 3 [.bicycle] (m (2 * ki), cm (-240)) Build.east (Units.metresPerSecond 2) (cm 90, cm 30, cm 75))
            lampsOn ]
        [] [])
      (visibility true)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_2b"
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
  , witness "blind" blindTrace (.unknown []) ["sig.warning_lamp"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .notApplicable
  , witness "branch_12" branch_12Trace .compliant ]

end TrafficSpecWitness.NRS_484B_267_2b
