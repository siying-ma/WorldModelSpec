/-
  Witnesses for NRS_484B_777_3.

  Geometry (all figures the witness's own). A roadway (region 10) is a rectangle along +x;
  riders head east at 6 m/s and advance 6 m per 1 s instant. Each rider's half-extent is
  0.9 m long, 0.3 m wide, 0.8 m high, so riders whose centres are 1.1 m apart across the road
  have a body gap of 0.5 m (the reading's p.abreast_gap_max is 1.5 m), and riders 2.2 m apart a
  gap of 1.6 m. Riders level with each other (same x) overlap fully along the heading; headings
  are identical (cosine 1 against 0.9). Speeds of 6 m/s are far above p.halt_speed_tolerance
  (0.1 m/s). The subject is track 1.

  - forbid: riders at y = 0, 1.1, 2.2 m (subject at the edge): gaps 0.5, 0.5, 1.6 m.
  - blind: as forbid, but the source reports no body extent (nor occupancy) for the two other
    riders; the gaps and overlaps of the pairs are supplied as measured relations (Core cannot
    compute them), and the overlap is masked.
  - permit: the subject alone.
  - idle: the three riders on a sidewalk (region 11) beside the roadway.
  - branch_1: a bicycle lane (region 11) inside the roadway begins at x = 20 m; at the first
    instant the three ride single file on the roadway before it (4 m spacing: not side by side,
    compliant), afterwards three abreast inside the lane (excepted, not applicable).
  - branch_2: two riders side by side, gap 0.5 m.
  - branch_3: two riders at y = 0, 1.1 m and a third level with them at y = −7.6 m: gaps 7.0 m
    and 8.1 m to the pair, not in their row.
  - branch_4: as forbid, all three electric bicycles: violated.
  - branch_5: two bicycles and a moped level beside them, subject in the middle: the moped is
    no rider the duty counts, compliant.
  - branch_6: a moped (subject) rides abreast with two bicycles: not one of the duty's riders,
    not applicable.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_777_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_777_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A rider heading east at 6 m/s with a bicycle's body. -/
def rider (id : TrackId) (cls : RoadUserClass) (x y : Q) : RoadUser :=
  Build.user id [cls] (x, y) Build.east (Units.metresPerSecond 6) (cm 90, cm 30, cm 80)

/-- The riders' along-road position at instant `k`. -/
def xAt (k : Nat) : Q := Units.metres (6 * (k : Int))

def roadway : Structure := Build.rect 10 .roadway (m (-50)) (m (-12)) (m 150) (m 12)

/-- Three riders level with each other at the given lateral offsets. -/
def three (k : Nat) (c1 c2 c3 : RoadUserClass) (y1 y2 y3 : Q) : List RoadUser :=
  [ rider 1 c1 (xAt k) y1, rider 2 c2 (xAt k) y2, rider 3 c3 (xAt k) y3 ]

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): Three bicycles ride side by side at 6 m/s on a roadway outside any bicycle lane, headings aligned, body gaps of 0.5 m between neighbours. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (three k .bicycle .bicycle .bicycle (cm 0) (cm 110) (cm 220))
      [ roadway ]
      [ ]

/-- `permit` (compliant): A bicycle rides alone on a roadway: no other rider is in the scene, and the duty is decided for the subject alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider 1 .bicycle (xAt k) (cm 0) ]
      [ roadway ]
      [ ]

/-- `idle` (not_applicable): Three bicycles ride side by side on a sidewalk, overlapping no roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (three k .bicycle .bicycle .bicycle (cm 150) (cm 260) (cm 370))
      [ Build.rect 10 .roadway (m (-50)) (m (-12)) (m 150) (m 0)
      , Build.rect 11 .sidewalk (m (-50)) (m 0) (m 150) (m 6) ]
      [ ]

/-- A measured relation from `a` to `b`: the body gap (along, across) and the overlap along `a`'s
    heading, as a source supplies them where it reports no body extents. -/
def measured (a b : TrackId) (gapLat overlap : Q) : MeasuredRelation :=
  Build.relation a b fun r => { r with surfaceGap := some (Q.zero, gapLat), longitudinalOverlap := some overlap }

/-- `blind` (unknown): As forbid, but the source does not observe the longitudinal overlap of bodies.
    The source reports no body extent for the two other riders (nor their occupancy), so Core
    computes neither the gap nor the overlap of a pair with one of them: it supplies both
    measured (gaps 0.5, 0.5, 1.6 m as in forbid; overlap 1.8 m), and the manifest masks the
    overlap. The subject's body and occupancy are observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let base := Build.scene t (some 1)
        ((three k .bicycle .bicycle .bicycle (cm 0) (cm 110) (cm 220)).map fun u =>
          if u.track = 1 then u else Build.withKin u fun kn => { kn with extent := none })
        [ roadway ]
        [ ]
        (some [(1, 10)])
    Build.withRelations { base with occupancyObserved := [1] }
      [ measured 1 2 (cm 50) (cm 180), measured 2 1 (cm 50) (cm 180)
      , measured 2 3 (cm 50) (cm 180), measured 3 2 (cm 50) (cm 180)
      , measured 1 3 (cm 160) (cm 180), measured 3 1 (cm 160) (cm 180) ]

/-- `branch_1` (compliant): Three bicycles ride side by side within a bicycle lane of the roadway (exception).
    First instant: single file on the roadway before the lane begins (compliant); then three
    abreast inside the lane (excepted). -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (if k = 0 then
        [ rider 1 .bicycle (m 0) (cm 660), rider 2 .bicycle (m (-4)) (cm 660)
        , rider 3 .bicycle (m (-8)) (cm 660) ]
      else
        [ rider 1 .bicycle (Q.add (m 24) (xAt k)) (cm 550)
        , rider 2 .bicycle (Q.add (m 24) (xAt k)) (cm 660)
        , rider 3 .bicycle (Q.add (m 24) (xAt k)) (cm 770) ])
      [ roadway, Build.rect 11 .bicycleLaneOrPath (m 20) (m 5) (m 150) (m 9) ]
      [ ]

/-- `branch_2` (compliant): Two bicycles ride side by side on a roadway, body gap 0.5 m. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider 1 .bicycle (xAt k) (cm 0), rider 2 .bicycle (xAt k) (cm 110) ]
      [ roadway ]
      [ ]

/-- `branch_3` (compliant): Two bicycles ride side by side on a roadway; a third, level with them, rides two lanes away with body gaps of 7 m to each: not in their row. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (three k .bicycle .bicycle .bicycle (cm 0) (cm 110) (cm (-760)))
      [ roadway ]
      [ ]

/-- `branch_4` (violated): three electric bicycles ride abreast on a roadway, gaps 0.5 m. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (three k .electricBicycle .electricBicycle .electricBicycle (cm 0) (cm 110) (cm 220))
      [ roadway ]
      [ ]

/-- `branch_5` (compliant): two bicycles abreast with a moped level beside them; the moped is no
    rider the duty counts. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (three k .bicycle .bicycle .moped (cm 110) (cm 0) (cm 220))
      [ roadway ]
      [ ]

/-- `branch_6` (not_applicable): the subject is a moped riding abreast with two bicycles. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (three k .moped .bicycle .bicycle (cm 0) (cm 110) (cm 220))
      [ roadway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_777_3"
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
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_777_3
