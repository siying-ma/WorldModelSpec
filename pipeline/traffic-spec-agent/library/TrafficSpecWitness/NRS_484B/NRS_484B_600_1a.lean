/-
  Witnesses for NRS_484B_600_1a.

  The map (metres, +x east, +y north; every figure here is the witness's own and appears nowhere in
  the rule):

  - way 1 is a public highway running east, a kilometre of it (x in [-100, 900]), 20 m between its
    boundary lines (y in [-10, 10]);
  - lane 11 is its eastbound lane, lying on way 1: a strip from the way's centre northward whose
    polygon is as wide as the width the source declares for it (3.6 m at the reference width, 3.5 m
    on the wet bend of `forbid`, 2.4 m where the lane is narrow), carrying the curvature the source
    declares at the subject's place (zero on a straight stretch, 0.001 per metre on a gentle bend,
    0.01 per metre on the bend of `forbid` and `branch_4`);
  - the subject is track 1, a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 0.75 m),
    travelling east at the middle of that lane, with the sight distance along way 1 that the source
    declares for it; where another vehicle is in the scene it is track 2, the same body, in the same
    lane ahead of the subject, so that the gap between the two bodies is the distance between their
    centres less their two half-lengths;
  - occupancy is the footprint's: the subject's body lies inside the lane and inside the way, except
    in `idle`, where it stands 8 m north of the way's centre, on the way but clear of the lane.

  Each trace is three observations a second apart, the subject carried east at its speed. No formula
  of this rule looks back or ahead, so no trace is padded and no witness names a window.

  The figures against the run's reading (reaction time 1.5 s, deceleration 3.5 m/s² dry and
  1.8 m/s² adverse, reference lane width 3.6 m, admissible lateral acceleration 3.0 m/s²): the
  distance a vehicle needs to halt is 154 m from 28 m/s dry and 260 m adverse, 127 m from 25 m/s
  dry, 87 m from 20 m/s dry, and 357 m from 30 m/s dry in a 2.4 m lane; a bend of 0.01 per metre
  imposes 7.8 m/s² at 28 m/s and one of 0.001 per metre 0.78 m/s².
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
/-- The public way, between its boundary lines. -/
def way : Structure := Build.rect 1 .highway (m (-100)) (m (-10)) (m 900) (m 10)

/-- The eastbound lane of that way: `w` wide, of curvature `curv` at the subject's place, lying on
    way 1. -/
def laneOf (w curv : Q) : Structure :=
  let base :=
    Build.lane 11 [(m (-100), Q.zero), (m 900, Q.zero), (m 900, w), (m (-100), w)] Build.east
  { base with
      ways := some [1]
      curvature := some curv
      lane := base.lane.map (fun l => { l with width := some w }) }

/-- The lane widths the sources declare, with the subject's place at the middle of each. -/
def wReference : Q := cm 360
def yReference : Q := cm 180
def wForbid : Q := cm 350
def yForbid : Q := cm 175
def wNarrow : Q := cm 240
def yNarrow : Q := cm 120

/-- The curvatures the sources declare: a straight stretch, a gentle bend, and a bend of 0.01 per
    metre. -/
def straight : Q := Q.zero
def gentleBend : Q := Units.ratio 1 1000
def bend : Q := Units.ratio 1 100

-- ---------------------------------------------------------------------------------------------
-- The bodies, the weather and the traces
-- ---------------------------------------------------------------------------------------------
/-- The subject at `(x, y)`, travelling east at `speed`, seeing `sight` along way 1. -/
def car (x y speed sight : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (x, y) Build.east speed (m 2, m 1, cm 75) with
      sightAlongWay := some [(1, sight)] }

/-- Another vehicle, in the same lane and travelling the same way. -/
def ahead (x y speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, y) Build.east speed (m 2, m 1, cm 75)

/-- The surface, the weather and the visibility distance, all declared. -/
def conditions (wet ice precip : Bool) (vis : Q) : Env :=
  { wetRoad := some wet, iceOrSnow := some ice, precipitation := some precip,
    visibility := some vis }

/-- Three observations a second apart: the subject travelling east at `speed` along the lane `w`
    wide of curvature `curv`, with `sight` along the way, under `env`, with whatever other road
    users the scene holds. -/
def driving (w y curv speed sight : Q) (env : Env)
    (others : Q → List RoadUser := fun _ => []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let x := Q.mul speed (Q.ofInt (Int.ofNat k))
    Build.scene t (some 1) (car x y speed sight :: others x) [way, laneOf w curv] [] none env

/-- `forbid` (violated): A car travels a wet two-lane highway at 28 m/s through a bend of 0.01 per metre curvature, its lane 3.5 m wide, with the sight distance along the way 90 m and no road user ahead within that distance. At the adverse-surface deceleration and after the reaction time it could not halt within 90 m from 28 m/s, and the bend alone would impose more than the admissible lateral acceleration at that speed. -/
def forbidTrace : Trace :=
  driving wForbid yForbid bend (mps 28) (m 90) (conditions true false false (m 2000))

/-- `permit` (compliant): The same highway, dry, straight, its lane 3.6 m wide, the sight distance along the way 200 m and the visibility unrestricted, with no other road user anywhere in the scene: the car travels at 20 m/s, from which it could halt well within 200 m at the dry-surface deceleration after the reaction time, and the verdict is decided with the subject alone. -/
def permitTrace : Trace :=
  driving wReference yReference straight (mps 20) (m 200) (conditions false false false (m 2000))

/-- `idle` (not_applicable): The same car stands at rest at the kerb of the highway for the whole trace, its speed below the motion tolerance, so it is not being driven or operated and the rule lays no duty on it. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car (m 0) (m 8) (mps 0) (m 200)]
      [way, laneOf wReference straight] [] none (conditions false false false (m 2000))

/-- The surface state no source of `blind` declares; the visibility is declared. -/
def blindEnv : Env := { visibility := some (m 2000) }

/-- `blind` (unknown): The car travels the same highway at 28 m/s with the sight distance and the curvature observed, but the source declares no surface state at all - neither wet road, ice or snow, nor precipitation - so which deceleration the bound is computed at cannot be decided and the rule reports unknown. -/
def blindTrace : Trace :=
  driving wReference yReference gentleBend (mps 28) (m 200) blindEnv

/-- `branch_1` (violated): A dry, straight highway with the sight distance along the way 250 m, but the car follows another vehicle in its own line of travel at a longitudinal body gap of 12 m while travelling at 25 m/s: the clear distance ahead is the gap, not the sight distance, and from 25 m/s it could not halt within 12 m at the dry-surface deceleration after the reaction time. -/
def branch_1Trace : Trace :=
  driving wReference yReference straight (mps 25) (m 250) (conditions false false false (m 2000))
    (fun x => [ahead (Q.add x (m 16)) yReference (mps 25)])

/-- `branch_2` (violated): A dry, straight highway, no road user ahead and the sight distance along the way 250 m, but the lane the car occupies is 2.4 m wide against a 3.6 m reference, and it travels at 30 m/s: the width available reduces the bound in that ratio and its speed is above the reduced bound. -/
def branch_2Trace : Trace :=
  driving wNarrow yNarrow straight (mps 30) (m 250) (conditions false false false (m 2000))

/-- `branch_3` (violated): a dry, straight highway with the sight distance along the way 250 m, but
    fog cuts the visibility to 60 m while the car travels at 25 m/s: the clear distance ahead is the
    visibility distance, and from 25 m/s it could not halt within 60 m. -/
def branch_3Trace : Trace :=
  driving wReference yReference straight (mps 25) (m 250) (conditions false false false (m 60))

/-- `branch_4` (violated): a dry highway, the sight distance along the way 250 m and the lane of the
    reference width, but the car takes a bend of 0.01 per metre at 28 m/s: it could halt within the
    clear distance ahead, and the bend alone would impose more than the admissible lateral
    acceleration. -/
def branch_4Trace : Trace :=
  driving wReference yReference bend (mps 28) (m 250) (conditions false false false (m 2000))

/-- `branch_5` (violated): the sight distance along the way 200 m, the lane of the reference width
    and a gentle bend, the car at 28 m/s - a speed from which it could halt within 200 m on a dry
    surface - but the surface is wet, and at the adverse deceleration it could not. -/
def branch_5Trace : Trace :=
  driving wReference yReference gentleBend (mps 28) (m 200) (conditions true false false (m 2000))

/-- `branch_6` (violated): the same scene, the surface icy or snow-covered rather than wet. -/
def branch_6Trace : Trace :=
  driving wReference yReference gentleBend (mps 28) (m 200) (conditions false true false (m 2000))

/-- `branch_7` (violated): the same scene, the surface neither wet nor icy but precipitation
    falling. -/
def branch_7Trace : Trace :=
  driving wReference yReference gentleBend (mps 28) (m 200) (conditions false false true (m 2000))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
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
  , witness "blind" blindTrace (.unknown []) ["env.wet_road", "env.ice_or_snow", "env.precipitation"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
