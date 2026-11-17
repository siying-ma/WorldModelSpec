/-
  Witnesses for NRS_484B_267_2c.

  Geometry. A straight eastbound carriageway along y = 0. The subject (track 1, a motor vehicle,
  half-extents 2 m × 0.9 m × 0.75 m) drives east from x = 0. The approached vehicle (track 2) is
  an official vehicle of a regulatory agency (classes motor_vehicle and official_vehicle, kind
  regulatory_agency; half-extents 3 m × 1 m × 1 m), on the same line ahead, east-facing, with a
  red flashing front warning lamp lit. Both bodies lie on y = 0, so the surface gap is purely
  longitudinal: gap = x₂ − 3 − (x₁ + 2). Three instants 100 ms apart; positions advance with the
  speeds. The source supplies only `visible` (from 1 to 2); distances, bearings and gaps are
  Core's, computed from the bodies.

  Why the approached vehicle is a regulatory-agency vehicle and not an ambulance: under the run's
  reading DEF-NRS-484A-020::authorized_emergency_vehicle includes no class (every vehicle class is
  unresolved), so an ambulance's membership is unknown and a scene built on one cannot be decided.
  The regulatory-agency limb of the same disjunction decides the scenes the node plans.

  Stopping distances (reading: T 1.5 s, dry 6, wet 4, ice 1 m/s²):
    forbid   v 20 m/s dry: 30 + 33.3 = 63.3 m > gaps 40 → 37 m.
    permit   v  5 m/s dry: 7.5 + 2.1 = 9.6 m < gap 40 m.
    branch_2 v  8 m/s ice: 12 + 32 = 44 m > gaps 35 → 33.4 m (dry would be 17.3 m: compliant).
    branch_3 v 14 m/s wet: 21 + 24.5 = 45.5 m > gap 41 m (dry would be 37.3 m: compliant).
    branch_4 as branch_3, rain falling on a road not reported wet.
    branch_5 v 20 m/s dry: 63.3 m > gaps 40 → 36 m.
  Centre distances 45–47 m, well inside the 150 m reach; the approached vehicle is ahead
  (longitudinal bearing positive).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_2c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_2c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Position along the carriageway at instant `k`: start plus `k` steps. -/
def at_ (x0 step : Q) (k : Nat) : Q := Q.add x0 (Q.mul (Q.ofInt (Int.ofNat k)) step)

def dry : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some false }
def icy : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some true }
def wet : Env := { precipitation := some false, wetRoad := some true, iceOrSnow := some false }
def raining : Env := { precipitation := some true, wetRoad := some false, iceOrSnow := some false }

def subjectAt (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v (m 2, cm 90, cm 75)

/-- The regulatory-agency vehicle with its red flashing front lamp; `f` sets its other signals. -/
def agencyAt (x v : Q) (f : Signals → Signals := id) : RoadUser :=
  { Build.withSignals (Build.user 2 [.motorVehicle, .officialVehicle] (x, Q.zero) Build.east v (m 3, m 1, m 1))
      (fun s => f { s with warningLamps := some [{ colour := .red, mode := .flashing, facing := .front }]
                           handSignal := some .noSignal
                           turnIndicator := some .off })
    with officialKind := some .regulatoryAgency }

def withVisible (s : Scene) (vis : Bool) : Scene :=
  Build.withRelations s [Build.relation 1 2 (fun r => { r with visible := some vis })]

/-- The two-vehicle scene. -/
def pair (t : Timestamp) (subj other : RoadUser) (env : Env)
    (structures : List Structure := []) (devices : List Device := []) : Scene :=
  withVisible (Build.scene t (some 1) [subj, other] structures devices (env := env)) true

def dt : Q := Units.milliseconds 100

/-- `forbid` (violated): Dry road. The subject vehicle moves toward an ambulance (authorized emergency vehicle) ahead of it within the approach reach; the ambulance moves with a red front warning lamp flashing. The subject's speed gives a stopping distance (reaction plus braking) longer than the surface gap to the ambulance.
    (Built with a regulatory-agency vehicle: see the header.) -/
def forbidTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (m 2) k) (Units.metresPerSecond 20))
           (agencyAt (at_ (m 45) (cm 50) k) (Units.metresPerSecond 5)) dry

/-- `permit` (compliant): Same scene, but the subject has slowed so that its stopping distance is shorter than the surface gap to the ambulance. -/
def permitTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (cm 50) k) (Units.metresPerSecond 5))
           (agencyAt (at_ (m 45) (cm 50) k) (Units.metresPerSecond 5)) dry

/-- `idle` (not_applicable): The subject drives at speed; no emergency or regulatory-agency vehicle is in the scene. The duty binds the subject alone and does not arise. -/
def idleTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1) [subjectAt (at_ Q.zero (m 2) k) (Units.metresPerSecond 20)] [] [] (env := dry)

/-- `blind` (unknown): As in forbid, but the source does not observe warning lamps, so whether the ambulance uses its flashing lights is unknown. -/
def blindTrace : Trace := forbidTrace

/-- The lane the subject drives in, for `branch_1`. -/
def laneE : Structure :=
  Build.lane 10 [(m (-50), m (-2)), (m 200, m (-2)), (m 200, m 2), (m (-50), m 2)] Build.east

/-- A police officer standing beside the lane, directing its traffic. -/
def officer : Device :=
  { Build.device 100 .humanDirection [10] (some (m 60, m 4)) with
      humanRole := some .policeOfficer
      humanIndication := some .proceed }

/-- `branch_1` (not_applicable): As in forbid, but a police officer directing traffic (dev.human_direction, role police_officer) governs the lane the subject occupies. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (m 2) k) (Units.metresPerSecond 20))
           (agencyAt (at_ (m 45) (cm 50) k) (Units.metresPerSecond 5)) dry [laneE] [officer]

/-- `branch_2` (violated): Icy road (env.ice_or_snow). The subject's speed and gap would allow a stop on a dry surface but not at the ice deceleration; the ambulance ahead is stopped and its driver gives an arm signal, visible from the subject (preparing to move), with its red front lamp flashing. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (cm 80) k) (Units.metresPerSecond 8))
           (agencyAt (m 40) Q.zero (fun s => { s with handSignal := some .left })) icy

/-- `branch_3` (violated): Wet road. The stop would be possible at the dry deceleration but not at
    the wet one; the agency vehicle moves ahead at the subject's speed. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (cm 140) k) (Units.metresPerSecond 14))
           (agencyAt (at_ (m 46) (cm 140) k) (Units.metresPerSecond 14)) wet

/-- `branch_4` (violated): As branch_3, but rain is falling on a road not reported wet. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (cm 140) k) (Units.metresPerSecond 14))
           (agencyAt (at_ (m 46) (cm 140) k) (Units.metresPerSecond 14)) raining

/-- `branch_5` (violated): Dry road. The agency vehicle ahead is stopped, no arm signal, its left
    turn indicator lit (preparing to move), visible from the subject; the subject cannot stop short. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (m 2) k) (Units.metresPerSecond 20))
           (agencyAt (m 45) Q.zero (fun s => { s with turnIndicator := some .left })) dry

/-- A pedestrian walking ahead carrying a red flashing lamp. -/
def lampCarrierAt (x : Q) (track : TrackId := 2) : RoadUser :=
  Build.withSignals (Build.user track [.pedestrian] (x, Q.zero) Build.east (Units.metresPerSecond 1) (cm 30, cm 30, cm 90))
    (fun s => { s with warningLamps := some [{ colour := .red, mode := .flashing, facing := .front }]
                       handSignal := some .noSignal
                       turnIndicator := some .off })

/-- `branch_6` (not_applicable): Dry road. Ahead of the subject a pedestrian, no vehicle, walks
    carrying a red flashing lamp: neither an authorized emergency vehicle nor an official vehicle,
    so the duty does not arise. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    pair t (subjectAt (at_ Q.zero (m 2) k) (Units.metresPerSecond 20))
           (lampCarrierAt (at_ (m 45) (cm 10) k)) dry

/-- `branch_7` (compliant): Dry road. A regulatory-agency vehicle with its red front lamp flashing
    moves 120 m ahead, and the subject can stop short of it; a pedestrian carrying a red flashing
    lamp walks 25 m ahead, inside the subject's stopping distance, but is no vehicle the duty
    names, so only the agency vehicle is measured. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.withRelations
      (Build.scene t (some 1)
        [ subjectAt (at_ Q.zero (m 2) k) (Units.metresPerSecond 20)
        , agencyAt (at_ (m 125) (m 2) k) (Units.metresPerSecond 20)
        , lampCarrierAt (at_ (m 30) (cm 10) k) 3 ] [] [] (env := dry))
      [ Build.relation 1 2 (fun r => { r with visible := some true })
      , Build.relation 1 3 (fun r => { r with visible := some true }) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_2c"
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
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .compliant ]

end TrafficSpecWitness.NRS_484B_267_2c
