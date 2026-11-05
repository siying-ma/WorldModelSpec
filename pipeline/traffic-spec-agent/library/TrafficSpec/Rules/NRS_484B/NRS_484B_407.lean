/-
  NRS_484B_407 — NRS-484B-407

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): shall not be turned so as to proceed in the opposite direction
    s3 (condition): upon any curve,
    s4 (standard): or upon the approach to or near the crest of a grade,
    s5 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.velocity'], derived []
    s2: atoms ['kin.speed'], derived ['drv.motion.direction_reversal']
    s3: atoms ['st.curvature', 'st.roadway', 'rel.occupies'], derived []
    s5: atoms ['st.sight_along_way', 'st.highway', 'rel.occupies'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 500 ft — 500 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:

    s1 — `clsSubject` is the admitted aggregate, `ru_aggregate` of the binder with the id
      DEF-NRS-484A-320::vehicle and nothing else; the classes it covers are never spelled. The
      element's second atom, kin.velocity, carries the record's reading of the passive 'shall not
      be turned' (who turns the vehicle is not observable, so the duty is read through the
      vehicle's own controlled motion): `inMotion` says the subject's velocity vector is not the
      zero vector — one of its two components differs from zero — and stands in the applicability
      beside the recognized act. Zero is the only magnitude it names.

    s2 — the manoeuvre is `drv.motion.direction_reversal` of the subject, called with the
      reading's window and tolerances (p.direction_reversal_window,
      p.direction_reversal_opposition_tolerance, p.motion_speed_tolerance); the concept reads
      kin.speed over its window, so the element's atom is the call's. The occasion the record
      declares makes the act an event: `.rises` of the concept, so the section is engaged once, at
      the observation at which the reversal is recognized, and not at the later observations at
      which the concept still holds.

    s3 — 'upon any curve' is `st.curvature` of a roadway region the subject occupies standing
      above p.curvature_resolution, the roadway being anchored to the subject by `rel.occupies`:
      the rule reads the bend of the road the subject is on, never a road elsewhere in the scene.
      The magnitude is the source's resolution only; no sharpness is required, as 'any curve' says.

    s4 — the operationalization: a region of kind `st.crest` whose ground distance from the
      subject's body (`st.region_geometry`, the distance accessor) is at most
      p.crest_approach_reach. It is written inside the same `rel.occupies`/`st.roadway` selection
      as s3, which is how the convention anchors the crest to the road the subject is on, and it
      is joined to s3 by `or`: the place condition is a curve or the approach to, or the
      neighbourhood of, a crest. The reach is the same on either side of the crest, as 'near'
      requires, because the distance is a magnitude.

    s5 — 'cannot be seen … within 500 feet' is `st.sight_along_way` of the subject along a highway
      region it occupies (`st.highway`, `rel.occupies`) below the 500 feet the text states, written
      through `Units.feet`. The atom is already 'the smaller of the two directions', which is
      'from either direction'.

    The duty — the recognized reversal is not made at a forbidden place. s3/s4 and s5 are read at
    the same moment of the act (`occasion.spans`: both `some_moment`), so they stand inside one
    window together with the under-way formula: the window behind of length
    p.direction_reversal_window, and `drv.motion.turning` on kin.yaw_rate, which tells an
    observation inside the act from one before it began. `forbiddenPlaceWhileTurning` is the
    'some moment' form `¬ holdsFor(¬(U ∧ φ ∧ ψ))`, and the obligation is its negation: at no
    moment while the vehicle is being turned do the place condition and the sight condition both
    hold.

  Narrowings: none. Every span is written with the atoms the record maps it to, and the choices
  above (the zero-velocity reading of kin.velocity on the subject span, the anchoring of the crest
  inside the subject's roadway selection) are the record's own mapping and conventions, not
  readings narrower than the words.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_407

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrestApproachReach : Term := .param "p.crest_approach_reach"
def pCurvatureResolution : Term := .param "p.curvature_resolution"
def pDirectionReversalOppositionTolerance : Term := .param "p.direction_reversal_opposition_tolerance"
def pDirectionReversalWindow : Term := .param "p.direction_reversal_window"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
/-- No speed at all: the only magnitude the motion reading names. -/
def zeroSpeed : Term := .lit Q.zero .metrePerSecond
/-- The distance the text itself states (s5). -/
def fiveHundredFeet : Term := .lit (Units.feet 500) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the vehicle's own controlled motion — its velocity is not the zero vector. -/
def inMotion : Formula :=
  .or (.not (.cmp (.measure "kin_velocity" [vSubject, .lit "x"]) .eq zeroSpeed))
      (.not (.cmp (.measure "kin_velocity" [vSubject, .lit "y"]) .eq zeroSpeed))

/-- s2: the vehicle has turned about so as to travel back the way it came. -/
def reversal : Formula :=
  .derived "drv_motion_direction_reversal" [vSubject]
    [pDirectionReversalWindow, pDirectionReversalOppositionTolerance, pMotionSpeedTolerance]

/-- The occasion's `under_way`: the vehicle's body is turning at this observation. -/
def turning : Formula :=
  .derived "drv_motion_turning" [vSubject] [pYawRateTolerance]

/-- s3 and s4: upon a curve of the roadway the subject occupies, or upon the approach to or near
    the crest of a grade (within p.crest_approach_reach of a region of kind st.crest). -/
def uponCurveOrNearCrest : Formula :=
  .existsRegion (.lit "roadway") "road"
    (.and (.atom "st_roadway" [.var "road"] [])
      (.and (.atom "rel_occupies" [vSubject, .var "road"] [])
        (.or (.cmp (.measure "st_curvature" [.var "road"]) .gt pCurvatureResolution)
             (.existsRegion (.lit "crest") "crest"
               (.and (.atom "st_crest" [.var "crest"] [])
                 (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "crest"])
                       .le pCrestApproachReach))))))

/-- s5: the sight along the way at the subject's place, in the smaller of the two directions, is
    below 500 feet. -/
def outOfSight : Formula :=
  .existsRegion (.lit "highway") "way"
    (.and (.atom "st_highway" [.var "way"] [])
      (.and (.atom "rel_occupies" [vSubject, .var "way"] [])
        (.cmp (.measure "st_sight_along_way" [vSubject, .var "way"]) .lt fiveHundredFeet)))

/-- At some moment of the act — an observation of the window behind at which the vehicle is being
    turned — the place condition and the sight condition both hold. -/
def forbiddenPlaceWhileTurning : Formula :=
  .not (.holdsFor .time pDirectionReversalWindow "subject"
    (.not (.and turning (.and uponCurveOrNearCrest outOfSight))))

/-- Applicability: s3 (condition): upon any curve,; s5 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet. -/
def applicability : Formula := .and inMotion (.rises reversal)

/-- Obligation: s2 (obligation): shall not be turned so as to proceed in the opposite direction; s4 (standard): or upon the approach to or near the crest of a grade, -/
def obligation : Formula := .not forbiddenPlaceWhileTurning

def rule : Rule :=
  { id := "NRS_484B_407"
    laws := ["NRS-484B-407"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "upon the approach to or near the crest of a grade"
          concepts := ["rel.occupies", "st.crest", "st.region_geometry", "st.roadway"]
          params := ["p.crest_approach_reach"]
          convention := "Stopping-sight-distance model (crest vertical curve design). ‘Near’ and ‘the approach to’ are bounded by a reach from the crest: the subject's body lies within p.crest_approach_reach of a region of kind st.crest — ‘the place on a roadway's longitudinal profile where the slope changes from rising to falling in the direction of travel, carried as a region with a reference point and a boundary, so the ground distance from a road user to it is read through st.region_geometry’ — the distance being st.region_geometry's ‘ground distance from a road user's body outline to it (zero when they overlap)’, with st.roadway and rel.occupies anchoring the crest to the road the subject is on. The reach is set by the convention to the stopping sight distance at ordinary highway design speed, the stretch over which a crest withholds the view of the road beyond it; it is the one magnitude the reading sets, and it is the same for a vehicle on either side of the crest, as ‘near’ requires. st.grade is not read in its place: it is ‘not a stand-in for the place of a crest — the slope where a road user is says nothing of a crest ahead of it’."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- every span is written with the atoms the record maps it to; no reading narrower than the words was chosen
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_407
