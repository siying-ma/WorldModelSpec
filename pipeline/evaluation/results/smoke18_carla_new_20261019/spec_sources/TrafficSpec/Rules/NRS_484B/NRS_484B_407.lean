/-
  NRS_484B_407 — NRS-484B-407

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): shall not be turned so as to proceed in the opposite direction
    s3 (trigger): upon any curve,
    s4 (boilerplate): or
    s5 (trigger): upon the approach to or near the crest of a grade,
    s6 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.heading_reversal']
    s3: atoms ['st.curvature', 'st.roadway', 'rel.occupies'], derived []
    s5: atoms ['st.crest', 'st.region_geometry'], derived []
    s6: atoms ['st.sight_distance', 'st.roadway', 'rel.occupies'], derived []

  Literals the text states (each written through its Units constructor):
    s6: 500 ft — 500 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written.

  s1 — `clsV`: the binder's class is the aggregate atom with the posted definition's id as its
  literal argument; which classes count under `DEF-NRS-484A-320::vehicle` stays with the reading.

  s2 — `obligation`: the concept `drv.motion.heading_reversal` called on the subject with the
  node's two parameters, in the catalogue's order (window, heading_tolerance). The node's
  `occasion` reads the act as an event, so the act is `.rises`: each turning is judged once, at
  the observation at which the accumulated half turn is first recognized, and the duty is that no
  such recognition arises there.

  s3, s5, s6 — the occasion. The node declares `occasion.act = drv.motion.heading_reversal`,
  `window = p.reversal_window`, `under_way = kin.yaw_rate` and all three spans `some_moment`, so
  the applicability is `.not (.holdsFor .time p.reversal_window v (.not (U ∧ φ)))`: the spans hold
  at some observation of the window behind at which the turning is under way. The node's
  applicability joins (s3 ∨ s5) with s6 by `.and` and reads them at the same occasion — "at that
  same observation the sight distance … is less than 500 feet" — so the three go inside one
  window together, under one `U`.

    `turning` (the `under_way` element) is `|kin.yaw_rate| > p.yaw_rate_resolution`: the magnitude
    stands clear of the source's resolution, the atom's own exclusion keeping it the body's yawing
    and not the bend of the road.

    `uponCurve` (s3) quantifies over the roadways of the scene, holds the quantified region to
    `st.roadway`, anchors it to the subject by `rel.occupies` — the bend is the one the subject is
    upon, not a bend elsewhere — and reads `st.curvature` clear of `p.curvature_resolution`. The
    atom is a magnitude, so a bend to either hand counts, as "any curve" requires.

    `nearCrest` (s5) quantifies over the crest regions, holds the quantified region to `st.crest`,
    and anchors it to the subject by the ground distance `st.region_geometry` reads from the
    subject's body outline to it, within `p.crest_approach_distance` — "the approach to or near".

    `cannotBeSeenWithin500Feet` (s6) quantifies over the roadways again, holds the region to
    `st.roadway` and anchors it to the subject by `rel.occupies` — "such vehicle" — and reads
    `st.sight_distance` of that place below the text's 500 feet.

  Choices the text left open are the node's and are written as the node maps them; no reading of
  this session narrows a span the node carries, so `narrowings` stays empty. The node's own
  narrowings (the observable readings on s2 and s6, and the heading-not-course reading of s2) are
  the plan's and are not restated here.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_407

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrestApproachDistance : Term := .param "p.crest_approach_distance"
def pCurvatureResolution : Term := .param "p.curvature_resolution"
def pReversalHeadingTolerance : Term := .param "p.reversal_heading_tolerance"
def pReversalWindow : Term := .param "p.reversal_window"
def pYawRateResolution : Term := .param "p.yaw_rate_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- The one figure the text states (s6): 500 feet. -/
def fiveHundredFeet : Term := .lit (Units.feet 500) .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The occasion's `under_way` element: the subject's heading is changing — the rate of change of
    heading stands clear of the source's resolution. -/
def turning : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vV])) .gt pYawRateResolution

/-- s3 (trigger): upon any curve — the roadway the subject occupies bends, its curvature standing
    clear of the resolution below which an alignment reads as straight. -/
def uponCurve : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "st_roadway" [.var "r"] [])
      (.and (.atom "rel_occupies" [vV, .var "r"] [])
        (.cmp (.measure "st_curvature" [.var "r"]) .gt pCurvatureResolution)))

/-- s5 (trigger): upon the approach to or near the crest of a grade — the subject's body is within
    the approach distance of a crest region. -/
def nearCrest : Formula :=
  .existsRegion (.lit "crest") "c"
    (.and (.atom "st_crest" [.var "c"] [])
      (.cmp (.measure "st_region_geometry_distance" [vV, .var "c"]) .le pCrestApproachDistance))

/-- s6 (condition): the sight distance of the roadway the subject is upon is less than 500 feet. -/
def cannotBeSeenWithin500Feet : Formula :=
  .existsRegion (.lit "roadway") "w"
    (.and (.atom "st_roadway" [.var "w"] [])
      (.and (.atom "rel_occupies" [vV, .var "w"] [])
        (.cmp (.measure "st_sight_distance" [.var "w"]) .lt fiveHundredFeet)))

/-- The trigger and condition spans at one observation at which the turning is under way:
    (s3 ∨ s5) ∧ s6, under the occasion's `under_way` element. -/
def occasionSpans : Formula :=
  .and turning (.and (.or uponCurve nearCrest) cannotBeSeenWithin500Feet)

/-- Applicability: s3 (trigger): upon any curve,; s5 (trigger): upon the approach to or near the crest of a grade,; s6 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet. -/
def applicability : Formula :=
  .not (.holdsFor .time pReversalWindow "v" (.not occasionSpans))

/-- s2's act: the subject's direction of travel reverses over the reversal window. -/
def headingReversal : Formula :=
  .derived "drv_motion_heading_reversal" [vV] [pReversalWindow, pReversalHeadingTolerance]

/-- Obligation: s2 (obligation): shall not be turned so as to proceed in the opposite direction -/
def obligation : Formula := .not (.rises headingReversal)

def rule : Rule :=
  { id := "NRS_484B_407"
    laws := ["NRS-484B-407"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- no reading of this session narrows a span the node carries
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_407
