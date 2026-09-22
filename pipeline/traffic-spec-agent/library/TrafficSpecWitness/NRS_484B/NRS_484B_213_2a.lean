/-
  Witnesses for NRS 484B.213(2)(a).

  One east–west carriageway, 7.2 m wide, cut at the origin by the crest the trigger speaks about.
  West of the origin the scene maps a `roadway` (region 1) — the stretch the subject is on, which
  carries the recorded `sight_distance`, the `grade` that rises and the `curvature`. East of the
  origin, past the crest, it maps the `highway` (region 5), whose `grade` falls: the sign change
  of `st.grade` the ontology calls a crest, and the region `drv.approaching` measures against.
  Two lanes run the whole length — the eastbound lane 2 south of the origin line, the opposing
  lane 3 north of it — with a `centre_line` (region 4) carrying the carriageway's own direction,
  east: the rule's "left" is the left of that. The `idle` scene adds a `one_way_roadway`
  (region 6) and turns lane 3 to run east as well, so that every recorded lane direction agrees.

  Two vehicles, each 4 m long and 1.8 m wide: `a` the subject (track 1) running east at 20 m/s,
  `c` the vehicle that might approach from the opposite direction (track 2) running west at the
  same speed. They start 50 m apart and close to 30 m over three observations a quarter of a
  second apart, so a is 18 m to 8 m short of the crest throughout and a conflict with c is
  predicted 1.25 s to 0.75 s ahead. The recorded sight distance is 20 m: shorter than a's
  stopping distance at 20 m/s under the reading's deceleration and reaction time, and shorter
  than a's separation from c, so c lies in the part of the road a cannot see.

  Occupancy is stated rather than derived, because a reference point lies in one polygon and one
  span this rule reads is about a body lying across two.

  Every figure here is the witness's own geometry and appears nowhere in the rule.

  The four witnesses the plan names, and one more it does not: `curve`, without which nothing
  exercises s5 — in every planned scene the crest limb of the trigger is already true, and the
  curve limb could carry any value without moving a verdict. It is reported in task_result.md.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_2a
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_213_2a

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

/-- `x0` metres, advancing `v` metres each quarter second. -/
private def xAt (x0 v : Int) (k : Nat) : Q := Units.metres (x0 + v * (Int.ofNat k))

-- The carriageway. Region 1 the roadway west of the crest, 2 the eastbound lane, 3 the opposing
-- lane, 4 the centre line, 5 the highway past the crest, 6 the one-way roadway of `idle`.
private def roadwayNear (grade curv : Q) : Structure :=
  { Build.rect 1 .roadway (m (-400)) (cm (-360)) Q.zero (cm 360) with
      grade := some grade, curvature := some curv, sightDistance := some (m 20) }
private def eastLane : Structure :=
  Build.lane 2 [(m (-400), cm (-360)), (m 400, cm (-360)), (m 400, Q.zero), (m (-400), Q.zero)]
    Build.east
private def opposingLane (dir : Vec) : Structure :=
  Build.lane 3 [(m (-400), Q.zero), (m 400, Q.zero), (m 400, cm 360), (m (-400), cm 360)] dir
/-- The dividing line, with the carriageway's direction: the rule's "left" is the left of it. -/
private def centreLine : Structure :=
  { Build.point 4 .centreLine (Q.zero, Q.zero) with lane := some { direction := some Build.east } }
private def beyondCrest (grade : Q) : Structure :=
  { Build.rect 5 .highway Q.zero (cm (-360)) (m 400) (cm 360) with grade := some grade }
private def oneWayRoadway : Structure :=
  Build.rect 6 .oneWayRoadway (m (-400)) (cm (-360)) Q.zero (cm 360)

private def road (grade curv far : Q) (oppDir : Vec) (extra : List Structure) : List Structure :=
  [roadwayNear grade curv, eastLane, opposingLane oppDir, centreLine, beyondCrest far] ++ extra

-- The bodies: half-length, half-width, half-height.
private def body : Q × Q × Q := (m 2, cm 90, cm 75)
private def speed : Q := Units.metresPerSecond 20
private def veh (track : TrackId) (x y : Q) (heading : Vec) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) heading speed body

-- Lane centres, and the straddling offset: a's reference point 0.5 m right of the line, its
-- 0.9 m half-width reaching 0.4 m across it.
private def eastCentre : Q := cm (-180)
private def oppCentre : Q := cm 180
private def straddleY : Q := cm (-50)

/-- Three observations a quarter of a second apart: a closes on the crest from 20 m out, c comes
    the other way in the opposing lane. `aOcc` is the list of regions a's body lies in. -/
private def approach (structures : List Structure) (aY : Q) (aOcc : List RegionId) : Trace :=
  Build.trace 3 0 (Units.milliseconds 250) fun k t =>
    Build.scene t (some 1)
      [ veh 1 (xAt (-20) 5 k) aY Build.east
      , veh 2 (xAt 30 (-5) k) oppCentre Build.west ]
      structures []
      (some ((aOcc.map fun r => ((1 : TrackId), r)) ++ [((2 : TrackId), 5), ((2 : TrackId), 3)]))

/-- The crest: the roadway rises at 5 per cent, the highway past it falls at 5 per cent. -/
private def crestRoad : List Structure := road (Units.percent 5) Q.zero (Units.percent (-5)) Build.west []
/-- No crest — grade level on both sides — but the roadway bends. -/
private def curveRoad : List Structure := road Q.zero (Units.ratio 1 50) Q.zero Build.west []
/-- The crest again, on a one-way roadway whose two lanes both run east. -/
private def oneWayRoad : List Structure :=
  road (Units.percent 5) Q.zero (Units.percent (-5)) Build.east [oneWayRoadway]

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_213_2a"
    trace := τ
    reading := {}
    manifest := Build.manifest absent
    grounding := [("a", 1), ("c", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ -- a crosses wholly into the opposing lane on the blind side of the crest.
    witness "forbid" (approach crestRoad oppCentre [1, 3]) .violated
    -- the same crest and the same short sight distance; a keeps its own lane.
  , witness "permit" (approach crestRoad eastCentre [1, 2]) .compliant
    -- the same scene upon a one-way roadway: the appended subsection 3 lifts the duty.
  , witness "idle" (approach oneWayRoad oppCentre [1, 3]) .notApplicable
    -- the `forbid` scene with `st.grade` unobserved: whether a approaches a crest is undecidable.
  , witness "blind" (approach crestRoad oppCentre [1, 3]) (.unknown []) ["st.grade"]
    -- s5's limb on its own: level road, a bend, and a body across the dividing line.
  , witness "curve" (approach curveRoad straddleY [1, 2, 3]) .violated ]

end TrafficSpecWitness.NRS_484B_213_2a
