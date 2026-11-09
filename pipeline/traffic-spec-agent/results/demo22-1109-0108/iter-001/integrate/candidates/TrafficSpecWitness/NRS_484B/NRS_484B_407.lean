/-
  Witnesses for NRS_484B_407.

  The geometry, once built. A highway region (`way`, id 10, 1200 m by 60 m) carries one or two
  roadway regions (ids 11 and 12) and, where a witness needs one, a crest region (id 20: a 4 m band
  across the carriageway, with its reference point on the centre line and its boundary polygon).
  Each roadway carries the two figures the source records for it: the magnitude of its horizontal
  curvature (zero on a tangent, 1/50 m on a bend of 50 m radius, twenty times the resolution of the
  reading) and its sight distance (60 m, well short of the 500 feet the text states, or 400 m, well
  beyond them). Where a witness needs the subject to leave one roadway for another, the two are
  either the halves of a divided highway, 2 m of median apart (`occasion_s3`, `occasion_s5`: the
  sweep carries the body from the one to the other), or two stretches of one carriageway meeting at
  x = 5 m, which the straight run before the onset crosses (`occasion_s3_outside`,
  `occasion_s5_outside`).

  The subject (track 1) is a motor car 5 m long and 2 m wide running at 4 m/s, which is 0.2 m of
  path per observation. Every trace is sampled at 50 ms, the period of the run's acquisition
  profile, so the heading change the rule accumulates is never read across a wider interval. The
  body runs straight east until the onset observation; from there its heading turns by one rotation
  step per observation — cos 840/841, sin 41/841, which is 2.794362050 degrees, the exact rational
  rotation that a recorded yaw rate of 55.887241 deg/s turns over 50 ms — and its place advances
  0.2 m along the heading each interval, so the path is the arc of that rate: a turning radius of
  about 4.1 m and a reversal of 150 degrees, the angle of the reading, fifty-four observations after
  the onset. `permitTrace` holds that rate for ten observations only (28 degrees, far below the
  angle) and then runs straight again. A heading component is recorded to the nanometre, so the
  recorded direction does not grow without bound as the rotation is iterated; the figures the rule
  reads are decided by metres.

  A sweep of 150 degrees carries a body about twice its turning radius, some 4 m here, so no
  witness can show a crest leaving the approach distance of 150 m within the manoeuvre itself: in
  `occasion_s4` the crest region stands within that distance at the onset and at every later
  observation of the act (by 11 m or more), and it is `occasion_s4_outside` that shows the span held
  outside the act — there the straight run before the onset carries the body from 5 m within the
  approach distance to 5 m beyond it, and the act begins only then.

  Every witness names the instants it speaks about: the rule searches the past from the onset of the
  manoeuvre, so each window begins at the onset observation and ends at the last observation of the
  trace. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_407
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_407

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- The sampling period of the trace: one scene every 50 ms. -/
def step : Q := Units.milliseconds 50
/-- The subject's speed, and the path it covers in one interval at that speed. -/
def speed : Q := Units.metresPerSecond 4
def advance : Q := cm 20

/-- The exact rational rotation of one observation: cos 840/841, sin 41/841 (840² + 41² = 841²). -/
def cosStep : Q := Units.ratio 840 841
def sinStep : Q := Units.ratio 41 841
/-- That rotation's angle, 2.794362050 degrees, written as a count of nanodegrees since `Units`
    carries no angle finer than the degree. -/
def stepAngle : Q := Q.div (Units.degrees 2794362050) (Q.ofInt 1000000000)
/-- The rate of change of heading the source records during the sweep: one rotation step per
    interval, 55.887241 deg/s. -/
def sweepYawRate : Q := Q.div stepAngle step

/-- A heading component as the source records it, to the nanometre. -/
def grid (q : Q) : Q := Q.mk' ((q.num * 1000000000) / Int.ofNat q.den) 1000000000

/-- The heading after one rotation step. -/
def rotateStep (h : Vec) : Vec :=
  (grid (Q.sub (Q.mul cosStep h.1) (Q.mul sinStep h.2)),
   grid (Q.add (Q.mul sinStep h.1) (Q.mul cosStep h.2)))

/-- The heading at the observation after `k`: one rotation step where the sweep covers the interval
    that ends there, the heading it had otherwise. -/
def headingNext (onset turnSteps k : Nat) (h : Vec) : Vec :=
  if onset ≤ k + 1 ∧ k + 1 ≤ onset + turnSteps then rotateStep h else h

/-- The place after one interval of running along the heading recorded at its end. -/
def nextPlace (p h : Vec) : Vec := (Q.add p.1 (Q.mul advance h.1), Q.add p.2 (Q.mul advance h.2))

/-- The rate of change of heading at observation `k`: zero before the onset and after the sweep,
    one rotation step over the interval that ends there during it. -/
def yawAt (onset turnSteps k : Nat) : Q :=
  if onset ≤ k ∧ k ≤ onset + turnSteps then sweepYawRate else Q.zero

/-- The body's place and heading at each observation of a run, accumulated once. -/
def bodyStates (onset turnSteps : Nat) : Nat → Nat → Vec → Vec → List (Vec × Vec)
  | 0, _, _, _ => []
  | i + 1, k, p, h =>
    let h' := headingNext onset turnSteps k h
    (p, h) :: bodyStates onset turnSteps i (k + 1) (nextPlace p h') h'

/-- The subject at observation `k`, with the place, heading, speed, path length, extent and rate of
    change of heading the source records. -/
def bodyAt (classes : List RoadUserClass) (p h : Vec) (onset turnSteps k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 classes p h speed (cm 250, m 1, cm 75) (some (cm (20 * Int.ofNat k))))
    (fun kin => { kin with yawRate := some (yawAt onset turnSteps k) })

/-- The public way between its boundary lines: every subject below lies on it. -/
def way : Structure := Build.rect 10 .highway (m (-600)) (m (-30)) (m 600) (m 30)

/-- A roadway region with the curvature and sight distance the source records for it. -/
def carriageway (id : RegionId) (x0 y0 x1 y1 curv sight : Q) : Structure :=
  { Build.rect id .roadway x0 y0 x1 y1 with
      curvature := some curv, sightDistance := some sight }

/-- The footway beside the carriageway: part of the way and no roadway. -/
def footway : Structure := Build.rect 13 .sidewalk (m (-200)) (m 15) (m 400) (m 25)

/-- The crest of the grade at `x`: a band across the carriageway, with its reference point on the
    centre line. -/
def crestAt (x : Q) : Structure :=
  { Build.rect 20 .crest (Q.sub x (m 2)) (m (-10)) (Q.add x (m 2)) (m 10) with
      position := some (x, Q.zero) }

/-- The horizontal curvature (1/m) of a bend of radius `r` metres. -/
def curvatureOfRadius (r : Int) : Q := Q.div (Units.perMetre 1) (m r)
/-- A tangent: the alignment the source records as straight. -/
def tangent : Q := Q.zero
/-- The sight distance of a blind place, and of an open one. -/
def shortSight : Q := m 60
def openSight : Q := m 400

/-- The classes of the subject vehicle: a motor vehicle, a member of the aggregate the node claims. -/
def car : List RoadUserClass := [.motorVehicle]

/-- A run of `n` observations at 50 ms over the structures `sts`. -/
def runTrace (n : Nat) (sts : List Structure) (classes : List RoadUserClass) (x0 y0 : Q)
    (onset turnSteps : Nat) : Trace :=
  let states := bodyStates onset turnSteps n 0 (x0, y0) Build.east
  Build.trace n 0 step fun k t =>
    let pb := states.getD k ((x0, y0), Build.east)
    Build.scene t (some 1) [bodyAt classes pb.1 pb.2 onset turnSteps k] sts []

/-- One carriageway 20 m wide, from x = −200 m to x = 400 m. -/
def oneWay (curv sight : Q) : Structure := carriageway 11 (m (-200)) (m (-10)) (m 400) (m 10) curv sight

/-- `forbid` (violated): The subject runs along a bend whose horizontal curvature stands well above the resolution, and the sight distance of its place falls short of the figure the text states. On that bend it swings through more than the reversal angle and proceeds back the way it came. -/
def forbidTrace : Trace :=
  runTrace 61 [way, oneWay (curvatureOfRadius 50) shortSight] car (m 1) Q.zero 3 60

/-- `permit` (compliant): The same bend with the same short sight distance; the subject turns off into a side way, its accumulated heading change staying far below the reversal angle, and never proceeds in the opposite direction. No other road user is present in the scene. -/
def permitTrace : Trace :=
  runTrace 61 [way, oneWay (curvatureOfRadius 50) shortSight] car (m 1) Q.zero 3 10

/-- `idle` (not_applicable): On a straight and level stretch, no crest region within the approach distance and the place's sight distance well beyond the stated figure, the subject swings through more than the reversal angle and proceeds back the way it came. -/
def idleTrace : Trace :=
  runTrace 61 [way, oneWay tangent openSight] car (m 1) Q.zero 3 60

/-- `blind` (unknown): The subject reverses its direction on a bend whose curvature is recorded, but the source declares no sight distance for the places along it, so whether the vehicle could be seen within the stated distance cannot be told. -/
def blindTrace : Trace :=
  runTrace 61 [way, oneWay (curvatureOfRadius 50) shortSight] car (m 1) Q.zero 3 60

/-- `occasion_s3` (violated): The subject begins the reversal on the bend and completes it where the alignment has run out straight: the curvature stands above the resolution at the onset and the first part of the manoeuvre only, and the sight distance at those same observations falls short of the stated figure. -/
def occasion_s3Trace : Trace :=
  runTrace 61 [way,
    carriageway 11 (m (-200)) (m (-10)) (m 400) Q.zero (curvatureOfRadius 50) shortSight,
    carriageway 12 (m (-200)) (m 2) (m 400) (m 12) tangent shortSight]
    car (m 1) (m (-1)) 3 60

/-- `occasion_s3_outside` (not_applicable): The subject runs along the bend, leaves it, and only then, on a straight stretch with no crest region within the approach distance, swings through more than the reversal angle; the curvature stands above the resolution only at observations before the onset, while the sight distance is short throughout. -/
def occasion_s3_outsideTrace : Trace :=
  runTrace 98 [way,
    carriageway 11 (m (-200)) (m (-10)) (m 5) (m 10) (curvatureOfRadius 50) shortSight,
    carriageway 12 (m 5) (m (-10)) (m 400) (m 10) tangent shortSight]
    car (cm 110) Q.zero 40 60

/-- `occasion_s4` (violated): The subject begins the reversal with the crest region within the approach distance of its body and completes it farther down the grade, beyond that distance; the alignment is straight throughout and the sight distance at the observations near the crest falls short of the stated figure. -/
def occasion_s4Trace : Trace :=
  runTrace 61 [way, oneWay tangent shortSight, crestAt Q.zero] car (m 142) Q.zero 3 60

/-- `occasion_s4_outside` (not_applicable): The subject passes the crest, runs on until the crest region lies beyond the approach distance, and only then swings through more than the reversal angle on a straight stretch; the crest was within the approach distance only at observations before the onset, while the sight distance is short throughout. -/
def occasion_s4_outsideTrace : Trace :=
  runTrace 113 [way, oneWay tangent shortSight, crestAt Q.zero] car (m 149) Q.zero 55 60

/-- `occasion_s5` (violated): The subject reverses its direction on a bend whose curvature stands above the resolution at every observation of the manoeuvre, and the sight distance of its place falls short of the stated figure at the onset and the first part of the manoeuvre, rising above it before the reversal is complete. -/
def occasion_s5Trace : Trace :=
  runTrace 61 [way,
    carriageway 11 (m (-200)) (m (-10)) (m 400) Q.zero (curvatureOfRadius 50) shortSight,
    carriageway 12 (m (-200)) (m 2) (m 400) (m 12) (curvatureOfRadius 50) openSight]
    car (m 1) (m (-1)) 3 60

/-- `occasion_s5_outside` (not_applicable): The subject runs on the bend through a stretch whose sight distance falls short of the stated figure, and begins and completes the reversal farther along the same bend, where the sight distance at its place exceeds the stated figure at every observation from the onset onwards. -/
def occasion_s5_outsideTrace : Trace :=
  runTrace 98 [way,
    carriageway 11 (m (-200)) (m (-10)) (m 5) (m 10) (curvatureOfRadius 50) shortSight,
    carriageway 12 (m 5) (m (-10)) (m 400) (m 10) (curvatureOfRadius 50) openSight]
    car (cm 110) Q.zero 40 60

/-- `branch_1` (not_applicable): a pedal cycle, no member of the aggregate the duty binds, reverses
    its direction on the blind bend of `forbid`. -/
def branch_1Trace : Trace :=
  runTrace 61 [way, oneWay (curvatureOfRadius 50) shortSight] [.bicycle] (m 1) Q.zero 3 60

/-- `branch_2` (not_applicable): the subject turns around on the footway beside the blind bend,
    occupying the way and no roadway. -/
def branch_2Trace : Trace :=
  runTrace 61 [way, oneWay (curvatureOfRadius 50) shortSight, footway] car (m 1) (m 20) 3 60

/-- `branch_3` (not_applicable): a straight stretch whose sight distance is short, with a crest
    region 400 m behind the subject — far beyond the approach distance. -/
def branch_3Trace : Trace :=
  runTrace 61 [way, carriageway 11 (m (-200)) (m (-10)) (m 600) (m 10) tangent shortSight,
    crestAt Q.zero] car (m 405) Q.zero 3 60

def witness (name : String) (τ : Trace) (expected : Verdict) (from_ to_ : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_407"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := some (from_, to_)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 150 3000
  , witness "permit" permitTrace .compliant 150 3000
  , witness "idle" idleTrace .notApplicable 150 3000
  , witness "blind" blindTrace (.unknown []) 150 3000 ["st.sight_distance"]
  , witness "occasion_s3" occasion_s3Trace .violated 150 3000
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable 2000 4850
  , witness "occasion_s4" occasion_s4Trace .violated 150 3000
  , witness "occasion_s4_outside" occasion_s4_outsideTrace .notApplicable 2750 5600
  , witness "occasion_s5" occasion_s5Trace .violated 150 3000
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .notApplicable 2000 4850
  , witness "branch_1" branch_1Trace .notApplicable 150 3000
  , witness "branch_2" branch_2Trace .notApplicable 150 3000
  , witness "branch_3" branch_3Trace .notApplicable 150 3000 ]

end TrafficSpecWitness.NRS_484B_407
