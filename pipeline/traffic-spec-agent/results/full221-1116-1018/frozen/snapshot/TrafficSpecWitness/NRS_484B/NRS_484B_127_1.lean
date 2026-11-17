/-
  Witnesses for NRS_484B_127_1.

  Geometry: a straight eastbound carriageway of two lanes, lane 10 (y ∈ [−2, 2]) and lane 11
  (y ∈ [2, 6]), both from x = −50 m to x = 1000 m. The subject (track 1) drives east along y = 0
  starting at x = 0; the other road user (track 2) drives east ahead of it, its rear `gap` metres
  ahead of the subject's front at the first instant. A car's half-extents are 2 m × 1 m × 0.75 m,
  a bicycle's 0.9 m × 0.3 m × 0.9 m. Three instants at one-second spacing; each body advances by
  its own speed. The road condition is decided (every env atom set) in every scene. In `blind`
  the source observes no extent (hence no footprint or occupancy) of the followed car and supplies
  the 15 m gap and the in-lane order as measured relations; the manifest drops the gap (Core would
  otherwise compute it from the footprints).

  Bounds under the run's reading (dry 2 s / 6 m/s², wet 3 s / 4 m/s², ice 6 s / 1 m/s²), both at
  25 m/s: dry 50 m, wet 75 m, ice 150 m. With the followed car at 30 m/s on a dry road:
  50 + (625 − 900)/12 ≈ 27.1 m.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carCls : List RoadUserClass := [.motorVehicle]
def bikeCls : List RoadUserClass := [.bicycle]

/-- Half-extents (half-length, half-width, half-height) by class. -/
def extentOf (cls : List RoadUserClass) : Q × Q × Q :=
  if cls.contains .bicycle then (cm 90, cm 30, cm 90) else (m 2, m 1, cm 75)

def halfLength (cls : List RoadUserClass) : Q := (extentOf cls).1

def dry : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some false }
def wet : Env := { precipitation := some false, wetRoad := some true, iceOrSnow := some false }
def rain : Env := { precipitation := some true, wetRoad := some false, iceOrSnow := some false }
def icy : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some true }

def lanes : List Structure :=
  [ Build.rect 10 .lane (m (-50)) (m (-2)) (m 1000) (m 2)
  , Build.rect 11 .lane (m (-50)) (m 2) (m 1000) (m 6) ]

/-- The subject (track 1, classes `sc`, speed `vS`) on lane 10; the other road user (track 2,
    classes `oc`, speed `vO`) on the lane centred at `oy`, its rear `gap` m ahead of the subject's
    front at the first instant. -/
def follow (sc oc : List RoadUserClass) (gap vS vO oy : Int) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let kk : Int := k
    let xS := m (vS * kk)
    let xO := Q.add (Q.add (Q.add (halfLength sc) (m gap)) (halfLength oc)) (m (vO * kk))
    Build.scene t (some 1)
      [ Build.user 1 sc (xS, m 0) Build.east (Units.metresPerSecond vS) (extentOf sc)
      , Build.user 2 oc (xO, m oy) Build.east (Units.metresPerSecond vO) (extentOf oc) ]
      lanes
      []
      (env := env)

/-- `forbid` (violated): Dry road; the subject car follows another car in its lane, both at 25 m/s, with a body gap of 15 m. -/
def forbidTrace : Trace := follow carCls carCls 15 25 25 0 dry

/-- `permit` (compliant): Dry road; the subject car follows another car in its lane, both at 25 m/s, with a body gap of 70 m. -/
def permitTrace : Trace := follow carCls carCls 70 25 25 0 dry

/-- `idle` (not_applicable): The subject is a bicycle (a device moved by human power, outside the vehicle aggregate) riding close behind a car. -/
def idleTrace : Trace := follow bikeCls carCls 3 8 8 0 dry

/-- `blind` (unknown): The subject car follows another car in its lane; the source declares rel.surface_gap absent. -/
def blindTrace : Trace :=
  -- The source observes no extent of the followed car (track 2), so neither its footprint nor its
  -- occupancy is known and Core can compute neither the gap nor the in-lane relation for it; the
  -- source supplies both measured (track 2 ahead of track 1 in the lane; a 15 m gap along the
  -- subject's heading), and the manifest drops the gap.
  (follow carCls carCls 15 25 25 0 dry).map fun s =>
    Build.withRelations
      { s with users := s.users.map (fun u =>
                 if u.track == 2 then Build.withKin u fun k => { k with extent := none } else u)
               occupancyObserved := [1]
               occupies := s.occupies.filter (·.1 == 1) }
      [ Build.relation 1 2 fun r => { r with surfaceGap := some (m 15, m 0) }
      , Build.relation 2 1 fun r => { r with aAheadOfB := some true } ]

/-- `branch_1` (compliant): The subject car drives alone on the road: no vehicle is ahead of it in its lane. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let kk : Int := k
    Build.scene t (some 1)
      [ Build.user 1 carCls (m (25 * kk), m 0) Build.east (Units.metresPerSecond 25) (extentOf carCls) ]
      lanes
      []
      (env := dry)

/-- `branch_2` (violated): Icy road (env.ice_or_snow true); both cars at 25 m/s with a body gap of 70 m, which meets the dry bound but not the icy one. -/
def branch_2Trace : Trace := follow carCls carCls 70 25 25 0 icy

/-- `branch_3` (violated): Wet road, no rain; both cars at 25 m/s with a body gap of 60 m: meets the dry bound (50 m), not the wet one (75 m). -/
def branch_3Trace : Trace := follow carCls carCls 60 25 25 0 wet

/-- `branch_4` (violated): Rain falling on a road not reported wet; both cars at 25 m/s with a body gap of 60 m: the wet bound (75 m) applies. -/
def branch_4Trace : Trace := follow carCls carCls 60 25 25 0 rain

/-- `branch_5` (compliant): Dry road; the subject at 25 m/s follows a car pulling away at 30 m/s with a body gap of 35 m: below the equal-speed bound (50 m), above the bound with the leader's speed (≈ 27 m). -/
def branch_5Trace : Trace := follow carCls carCls 35 25 30 0 dry

/-- `branch_6` (compliant): Dry road; the subject car rides 5 m behind a bicycle in its lane: a bicycle is not another vehicle. -/
def branch_6Trace : Trace := follow carCls bikeCls 5 6 6 0 dry

/-- `branch_7` (compliant): Dry road; a car 5 m ahead of the subject travels in the adjacent lane, not the subject's lane. -/
def branch_7Trace : Trace := follow carCls carCls 5 25 25 4 dry

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_1"
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
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant ]

end TrafficSpecWitness.NRS_484B_127_1
