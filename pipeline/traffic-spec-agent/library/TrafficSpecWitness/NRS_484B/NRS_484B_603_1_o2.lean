/-
  Witnesses for NRS_484B_603_1_o2.

  Geometry. One highway region (id 100), x from −100 m to 300 m, y from −6 m to 10 m, with a
  sidewalk strip (id 101) along its south edge (y −6 m to −3 m), both part of the highway. The
  subject (track 1) is a passenger car, half-extents 2.25 m × 0.90 m, heading east along y = 0.
  Pedestrians have half-extents 0.25 m × 0.25 m, a cyclist 0.90 m × 0.30 m. Instants are 0.5 s apart
  where the trace evolves (forbid, permit, blind, branch_1, branch_2); the other branches are one
  observation. The road surface is observed dry unless a branch says otherwise. Every figure here
  is the witness's own and appears nowhere in the rule.

  Against the reading (horizon 3 s, clearance 3 m, decrease threshold 0.3 m/s², halt tolerance
  0.1 m/s, reaction 1.5 s, decelerations dry 6 / wet 4 / ice 1 m/s²):
  - forbid: car at 15 m/s, accel 0; a pedestrian at (18, −3) walks north at 1 m/s onto the
    carriageway: closest approach ≈ 1.2 s ahead at ≈ 1.8 m; gap ≈ 15.6 m (then ≈ 8.1, ≈ 1.0 m),
    dry stopping distance 41.25 m. Violated.
  - permit: the same, the car braking at 4 m/s² (15, 13, 11 m/s). Compliant.
  - blind: forbid, but the source gives no body extent for the car, so no surface gap can be
    computed and none is supplied (rel.surface_gap masked); the car's occupancy is therefore not
    observed (the rule reads only the other user's), and the source reports the bodies not in
    contact (a measured relation Core cannot compute without the extent). Unknown.
  - idle: the subject is a pedestrian on the sidewalk. Not applicable.
  - branch_1: the car alone at 25 m/s. Compliant.
  - branch_2: the car at 5 m/s touching a cyclist ahead of it (bodies overlap). Violated.
  - branch_3: the car creeping at 0.05 m/s (at rest by the tolerance), a pedestrian walking north
    pressed against its side (contact, gap 0; stopping distance 0.075 m > 0). Compliant by rest.
  - branch_4: car at 10 m/s, an oncoming car at (30, 1) at 15 m/s: closest approach 1.2 s at 1 m;
    gap 25.5 m; wet road: D = 15 + 12.5 = 27.5 m > 25.5. Violated.
  - branch_5: as branch_4, road dry but precipitation falling: D = 27.5 m. Violated.
  - branch_6: as branch_4 with the oncoming car at (44, 1), gap 39.5 m; ice: D = 15 + 50 = 65 m.
    Violated (wet 27.5 m or dry 23.3 m would fit).
  - branch_7: as branch_4 on a dry road: D = 15 + 8.33 = 23.33 m ≤ 25.5. Compliant.
  - branch_8: car at 15 m/s, a pedestrian on the highway at (18, 6) walking north: closest
    approach within the horizon but at ≈ 7.2 m, above the clearance. Compliant.
  - branch_9: car at 15 m/s, a car on private land at (18, −9) heading north at 6 m/s, its footprint
    (y −11.25 to −6.75) short of the highway: closest approach ≈ 1.7 m in 1.24 s, but it is not on
    or entering a highway. Compliant.
  - branch_10: car at 15 m/s, a pedestrian standing on the highway 10 m behind it: no approach
    within the horizon. Compliant.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_603_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_603_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def mps2 (n : Int) : Q := Units.metresPerSecondSq n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 100 .highway (m (-100)) (m (-6)) (m 300) (m 10)
def sidewalk : Structure := Build.rect 101 .sidewalk (m (-100)) (m (-6)) (m 300) (m (-3))
def structures : List Structure := [highway, sidewalk]

def envOf (ice wet precip : Bool) : Env :=
  { iceOrSnow := some ice, wetRoad := some wet, precipitation := some precip }
def dry : Env := envOf false false false

def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)
def pedExt : Q × Q × Q := (cm 25, cm 25, cm 90)
def bikeExt : Q × Q × Q := (cm 90, cm 30, cm 90)

/-- A passenger car with its longitudinal acceleration observed. -/
def car (track : TrackId) (pos : Vec) (heading : Vec) (speed accel : Q) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] pos heading speed carExt)
    (fun k => { k with accelLongitudinal := some accel })

def ped (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.pedestrian] pos heading speed pedExt

def sceneOf (t : Timestamp) (users : List RoadUser) (env : Env := dry) : Scene :=
  Build.scene t (some 1) users structures [] (env := env)

/-- The pedestrian of forbid/permit/blind: from (18, −3) north at 1 m/s, 0.5 m per instant. -/
def pedAt (k : Nat) : RoadUser :=
  ped 2 (m 18, Q.add (m (-3)) (Q.mul (cm 50) (Q.ofInt k))) Build.north (mps 1)

/-- `forbid` (violated): A car at 15 m/s on a dry road holds its speed (zero longitudinal acceleration) while a pedestrian entering the highway ahead is predicted to come within the conflict clearance within the conflict horizon; the surface gap is 15 m, shorter than the car's stopping distance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    sceneOf t
      [ car 1 (Q.mul (cm 750) (Q.ofInt k), m 0) Build.east (mps 15) (mps2 0)
      , pedAt k ]

def permitX : Nat → Q
  | 0 => m 0
  | 1 => m 7
  | _ => m 13

def permitV : Nat → Q
  | 0 => mps 15
  | 1 => mps 13
  | _ => mps 11

/-- `permit` (compliant): The same scene, but the car brakes at 4 m/s^2, its longitudinal acceleration below minus the decrease threshold. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    sceneOf t
      [ car 1 (permitX k, m 0) Build.east (permitV k) (mps2 (-4))
      , pedAt k ]

/-- `idle` (not_applicable): The subject is a pedestrian walking on a sidewalk; it is no vehicle. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    sceneOf t
      [ ped 1 (Q.mul (cm 70) (Q.ofInt k), cm (-450)) Build.east (Units.centimetres 140) ]

/-- `blind` (unknown): As in forbid, but the source does not supply the surface gap between the bodies; the car holds its speed, so whether its stopping distance fits the gap is unobserved. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let s := Build.withRelations
      (sceneOf t
        [ Build.withKin (car 1 (Q.mul (cm 750) (Q.ofInt k), m 0) Build.east (mps 15) (mps2 0))
            (fun kn => { kn with extent := none })
        , pedAt k ])
      [ Build.relation 1 2 (fun r => { r with contact := some false }) ]
    -- the car's own footprint is unknown, so its occupancy is not observed (the rule reads none of it)
    { s with occupancyObserved := [2], occupies := s.occupies.filter (·.1 == 2) }

/-- `branch_1` (compliant): The car is alone on the highway at 25 m/s: no other road user is in the scene, so the duty is decided for the subject alone and met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    sceneOf t
      [ car 1 (Q.mul (cm 1250) (Q.ofInt k), m 0) Build.east (mps 25) (mps2 0) ]

/-- `branch_2` (violated): The car, moving at 5 m/s, touches a cyclist on the highway (rel.contact true). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    sceneOf t
      [ car 1 (Q.mul (cm 250) (Q.ofInt k), m 0) Build.east (mps 5) (mps2 0)
      , Build.user 2 [.bicycle] (Q.add (m 3) (Q.mul (m 2) (Q.ofInt k)), m 0) Build.east (mps 4) bikeExt ]

-- branch_3 (compliant): the car is at rest by the tolerance (0.05 m/s) while a pedestrian pressed
-- against its side is in predicted conflict and in contact: rest decides both conjuncts.
def branch_3Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t =>
    sceneOf t
      [ car 1 (m 0, m 0) Build.east (Units.micrometresPerSecond 50000) (mps2 0)
      , ped 2 (m 0, cm (-115)) Build.north (mps 1) ]

/-- An oncoming car in conflict with the subject at 10 m/s, at `x` metres ahead, 1 m to the left. -/
def oncomingScene (t : Timestamp) (x : Int) (env : Env) : Scene :=
  sceneOf t
    [ car 1 (m 0, m 0) Build.east (mps 10) (mps2 0)
    , car 2 (m x, m 1) Build.west (mps 15) (mps2 0) ] env

-- branch_4 (violated): wet road; the wet stopping distance 27.5 m exceeds the 25.5 m gap.
def branch_4Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t => oncomingScene t 30 (envOf false true false)

-- branch_5 (violated): dry surface reported but precipitation falling; the wet deceleration applies.
def branch_5Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t => oncomingScene t 30 (envOf false false true)

-- branch_6 (violated): ice; the ice stopping distance 65 m exceeds the 39.5 m gap.
def branch_6Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t => oncomingScene t 44 (envOf true false false)

-- branch_7 (compliant): as branch_4 on a dry road; the dry stopping distance 23.3 m fits the 25.5 m gap.
def branch_7Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t => oncomingScene t 30 dry

-- branch_8 (compliant): the pedestrian's predicted closest approach (≈ 7.2 m) is beyond the clearance.
def branch_8Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t =>
    sceneOf t
      [ car 1 (m 0, m 0) Build.east (mps 15) (mps2 0)
      , ped 2 (m 18, m 6) Build.north (mps 1) ]

-- branch_9 (compliant): a car on private land, short of the highway, is not on or entering it.
def branch_9Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t =>
    sceneOf t
      [ car 1 (m 0, m 0) Build.east (mps 15) (mps2 0)
      , car 2 (m 18, m (-9)) Build.north (mps 6) (mps2 0) ]

-- branch_10 (compliant): a pedestrian standing behind the car: no approach within the horizon.
def branch_10Trace : Trace :=
  Build.trace 1 0 (Units.milliseconds 500) fun _k t =>
    sceneOf t
      [ car 1 (m 0, m 0) Build.east (mps 15) (mps2 0)
      , ped 2 (m (-10), m (-2)) Build.north (mps 0) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_603_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant ]

end TrafficSpecWitness.NRS_484B_603_1_o2
