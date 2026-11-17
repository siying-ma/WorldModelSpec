/-
  Witnesses for NRS_484B_293.

  Geometry (witness's own figures, none in the rule): a marked crosswalk (region 10) is the
  rectangle x ∈ [−2, 2], y ∈ [0, 20] m with its reference point at its centre (0, 10); pedestrians
  cross it northward at 1.3 m/s, so the right half is x > 0. Bodies are 0.5 m long and 0.6 m wide.
  Three instants, 1 s apart; the subject starts at y = 4 m and advances 1.3 m per instant.
  - forbid / blind: the subject at x = −1.5 (crosswalk centre 1.5 m to its right): the cross product
    is 1.3·(−1.5) = −1.95 below −0.3·1.3 = −0.39.
  - permit: the subject at x = +1.5: 1.95 ≥ −0.39.
  - idle: the subject on a sidewalk (region 20, x ∈ [5, 8]), clear of the crosswalk.
  - branch_1: subject at x = −1.5; three pedestrians 2 m ahead at x = −0.9, 0, 0.9 (all right of it);
    the nearest has a surface gap of 1.5 m, the farthest about 2.9 m, all within 3 m.
  - branch_2: the subject at rest (speed 0) at x = −1.5.
  - branch_3: subject at x = −1.5; a barrier (region 30, x ∈ [−0.8, −0.5]) on its right, 0.4 m from
    its body.
  - branch_4: subject at x = −1.5; one pedestrian ahead-right at x = −0.9, 6 m ahead (gap 5.5 m).
  - branch_5: subject at x = −1.5; a barrier (x ∈ [−2.2, −1.9]) on its left, 0.1 m from its body.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_293
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_293

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Walking speed, 1.3 m/s. -/
def walk : Q := Units.micrometresPerSecond 1300000
/-- Half-extents of a pedestrian body. -/
def body : Q × Q × Q := (cm 25, cm 30, cm 90)

/-- The marked crosswalk with its reference point at its centre. -/
def crosswalk : Structure :=
  { Build.rect 10 .crosswalk (m (-2)) (m 0) (m 2) (m 20) with
      position := some (m 0, m 10), marked := some true }

def sidewalk : Structure := Build.rect 20 .sidewalk (m 5) (m 0) (m 8) (m 20)

def barrier (x0 x1 : Q) : Structure :=
  { Build.rect 30 .obstruction x0 (m 0) x1 (m 20) with obstructionKind := some .barrier }

/-- The subject's northward position at instant k. -/
def yAt (k : Nat) (speed : Q) : Q := Q.add (m 4) (Q.mul (Q.ofInt k) speed)

def ped (track : TrackId) (x y speed : Q) : RoadUser :=
  Build.user track [.pedestrian] (x, y) Build.north speed body

def subjectAt (x : Q) (k : Nat) : RoadUser := ped 1 x (yAt k walk) walk

/-- `forbid` (violated): A pedestrian (ru.aggregate pedestrian) walks across a marked crosswalk it occupies (rel.occupies st.crosswalk) at 1.3 m/s (kin.speed); the crosswalk's reference point (st.region_geometry) lies 1.5 m to the right of its velocity; no other road user and no st.obstruction is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt (cm (-150)) k ] [ crosswalk ] [ ]

/-- `permit` (compliant): The same pedestrian walks across the crosswalk with its reference point 1.5 m to the left of its velocity: it moves on the right half. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt (cm 150) k ] [ crosswalk ] [ ]

/-- `idle` (not_applicable): A pedestrian walks along a st.sidewalk and occupies no st.crosswalk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt (cm 650) k ] [ crosswalk, sidewalk ] [ ]

/-- `blind` (unknown): A pedestrian moving in a crosswalk at 1.3 m/s whose velocity is not observed: which half it moves on cannot be read. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.velocity"]) <|
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt (cm (-150)) k ] [ crosswalk ] [ ]

/-- `branch_1` (compliant): The pedestrian moves on the left half of the crosswalk while three other pedestrians occupying the crosswalk lie ahead of it on its right (rel.bearing longitudinal positive, lateral negative) at a surface gap of 1.5 m: the right half is not practicable. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let y := yAt k walk
    Build.scene t (some 1)
      [ subjectAt (cm (-150)) k
      , ped 2 (cm (-90)) (Q.add y (m 2)) walk
      , ped 3 (m 0) (Q.add y (m 2)) walk
      , ped 4 (cm 90) (Q.add y (m 2)) walk ]
      [ crosswalk ] [ ]

/-- `branch_2` (not_applicable): A pedestrian stands at rest (kin.speed 0) on the left half of the crosswalk: it does not move. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped 1 (cm (-150)) (m 4) Q.zero ] [ crosswalk ] [ ]

/-- `branch_3` (compliant): the pedestrian moves on the left half while a barrier (st.obstruction)
    lies on its right 0.4 m from its body: the right half is not practicable. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt (cm (-150)) k ] [ crosswalk, barrier (cm (-80)) (cm (-50)) ] [ ]

/-- `branch_4` (violated): the pedestrian moves on the left half; another pedestrian in the crosswalk
    lies ahead on its right but 5.5 m away, beyond the near reach. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-150)) k, ped 2 (cm (-90)) (Q.add (yAt k walk) (m 6)) walk ]
      [ crosswalk ] [ ]

/-- `branch_5` (violated): the pedestrian moves on the left half; a barrier lies within reach but on
    its left, not its right. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt (cm (-150)) k ] [ crosswalk, barrier (cm (-220)) (cm (-190)) ] [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_293"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_293
