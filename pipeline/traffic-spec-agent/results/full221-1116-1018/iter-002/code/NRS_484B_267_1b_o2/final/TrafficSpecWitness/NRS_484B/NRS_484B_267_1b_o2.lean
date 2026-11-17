/-
  Witnesses for NRS_484B_267_1b_o2.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - highway 10: x ∈ [-200, 200], y ∈ [-10, 10];
  - lane 11 (eastbound): y ∈ [0, 4], on highway 10;
  - paved shoulder 12: y ∈ [-3, 0], on highway 10, right of the lane;
  - regulatory sign 20, code shoulder_use_permitted, governing shoulder 12 (legend read, no
    restriction: `conditions := some {}`).
  - subject 1 (motor vehicle, half-extent 2 × 1 m), heading east: at t = 0 s at (0, 2) at 10 m/s;
    at t = 1 s at (10, y) at 3 m/s; at t = 2 s and 3 s at (12, y) at rest, with y = -1.5 (on the
    shoulder) or y = 1.5 (in the lane, at the roadway edge). complete_halt rises at t = 2 s.
  - approaching vehicle 2, heading east in the lane at 15 m/s from (-40, 2): at t = 2 s at
    (-10, 2), 22 m behind the subject (well within the 100 m reach, far above 0.1 m/s), the
    subject ahead of it in its frame.
  The rule looks back one observation (`rises`); every witness speaks about t ∈ [1 s, 3 s].
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_1b_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_1b_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def structures : List Structure :=
  [ Build.rect 10 .highway (m (-200)) (m (-10)) (m 200) (m 10)
  , { Build.rect 11 .lane (m (-200)) (m 0) (m 200) (m 4) with ways := some [10] }
  , { Build.rect 12 .shoulder (m (-200)) (m (-3)) (m 200) (m 0) with
        paved := some true, ways := some [10] } ]

def shoulderSign : Device :=
  { Build.sign 20 .regulatorySign [12] with
      code := some .shoulderUsePermitted, conditions := some {} }

def officer : Device :=
  { Build.device 21 .humanDirection [11, 12] with
      humanRole := some .policeOfficer, humanIndication := some .proceed }

def redFlashingFront : WarningLamp := { colour := .red, mode := .flashing, facing := .front }

/-- The subject: moving in the lane, then pulling over and at rest from t = 2 s. -/
def subjectAt (k : Nat) (onShoulder : Bool) : RoadUser :=
  let y := if onShoulder then cm (-150) else cm 150
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m 0, m 2) Build.east (Units.metresPerSecond 10) (m 2, m 1, m 1)
  | 1 => Build.user 1 [.motorVehicle] (m 10, y) Build.east (Units.metresPerSecond 3) (m 2, m 1, m 1)
  | _ => Build.user 1 [.motorVehicle] (m 12, y) Build.east Q.zero (m 2, m 1, m 1)

/-- The approaching road user, of the given classes, official kind and lit lamps. -/
def approacher (classes : List RoadUserClass) (kind : Option OfficialKind) (lamps : List WarningLamp)
    (k : Nat) : RoadUser :=
  { Build.user 2 classes (m (-40 + 15 * (k : Int)), m 2) Build.east (Units.metresPerSecond 15) (m 3, m 1, m 1) with
      officialKind := kind
      sig := { warningLamps := some lamps } }

/-- A regulatory-agency official vehicle with a red flashing front lamp. -/
def regulatoryVehicle : Nat → RoadUser :=
  approacher [.officialVehicle, .motorVehicle] (some .regulatoryAgency) [redFlashingFront]

def mkTrace (onShoulder : Bool) (e : Nat → RoadUser) (devices : List Device) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k onShoulder, e k] structures devices

/-- `forbid` (violated): Ambulance e with a lit red flashing front lamp approaches the moving subject within p.emergency_immediate_approach_reach; the subject pulls onto a paved shoulder governed by a shoulder_use_permitted regulatory sign and comes to rest there (complete_halt rises). -/
def forbidTrace : Trace := mkTrace true regulatoryVehicle [shoulderSign]

/-- `permit` (compliant): As forbid, but the subject comes to rest at the roadway edge with its footprint off that shoulder. -/
def permitTrace : Trace := mkTrace false regulatoryVehicle [shoulderSign]

/-- `idle` (not_applicable): No vehicle with lit warning lamps approaches; the subject stops on the signed shoulder. -/
def idleTrace : Trace :=
  mkTrace true (approacher [.officialVehicle, .motorVehicle] (some .regulatoryAgency) []) [shoulderSign]

/-- `blind` (unknown): As forbid, but sig.warning_lamp is not observed, so whether the duty is engaged is unknown. -/
def blindTrace : Trace := mkTrace true regulatoryVehicle [shoulderSign]

/-- `branch_1` (compliant): As forbid, but the paved shoulder carries no shoulder_use_permitted sign: stopping there is allowed. -/
def branch_1Trace : Trace := mkTrace true regulatoryVehicle []

/-- `branch_2` (not_applicable): a bicycle — neither an authorized emergency vehicle nor an official
    vehicle — showing a red flashing lamp closes on the subject, which stops on the signed shoulder. -/
def branch_2Trace : Trace :=
  mkTrace true (approacher [.bicycle] none [redFlashingFront]) [shoulderSign]

/-- `branch_3` (not_applicable): as forbid, but a police officer directs traffic in the lane and on
    the shoulder the subject occupies. -/
def branch_3Trace : Trace := mkTrace true regulatoryVehicle [shoulderSign, officer]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_1b_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 3000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.warning_lamp"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_267_1b_o2
