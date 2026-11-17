/-
  NRS_484B_407 — NRS-484B-407

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): shall not be turned so as to proceed in the opposite direction
    s3 (condition): upon any curve,
    s4 (condition): or upon the approach to or near the crest of a grade,
    s5 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.u_turn']
    s3: atoms ['rel.occupies', 'st.roadway', 'st.curvature'], derived []
    s4: atoms ['st.crest', 'st.region_geometry'], derived []
    s5: atoms ['st.sight_distance'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 500 ft — 500 feet

  How each span is written:
    s1: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` as the class of `subject`.
    s2: the obligation is `¬ drv_motion_u_turn(subject; p.vehicle_turn_window, p.u_turn_heading_min,
        p.turn_yaw_rate_tol)`: a reversal recognized where the rule is engaged is a violation.
    s3: some roadway region the subject occupies (`rel_occupies`) has `st_curvature` above
        p.curvature_resolution.
    s4: some crest region lies at a ground distance (`st_region_geometry_distance`, the accessor
        of st.region_geometry) of at most p.crest_near_reach from the subject's body.
    s5: some roadway region the subject occupies has `st_sight_distance` below 500 ft. "At its
        place" is the roadway region the subject occupies: the sight-distance atom is read of a
        region, and the place of the subject on the road is the roadway it occupies (rel.occupies
        and st.roadway are the node's claims, from s3). No other vehicle is quantified (the
        record's perception reading).
    Occasion (boundary "window", s3/s4/s5 read `some_moment`): with
        U = |kin_yaw_rate(subject)| > p.turn_yaw_rate_tol (the reversal under way) and
        φ = (s3 ∨ s4) ∧ s5, the applicability is
        ¬ holdsFor time p.vehicle_turn_window subject ¬(U ∧ φ):
        one common observation in the act's window behind carries U and the whole condition.

  No choice beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_407

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrestNearReach : Term := .param "p.crest_near_reach"
def pCurvatureResolution : Term := .param "p.curvature_resolution"
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- s5's literal: 500 feet. -/
def sightLimit : Term := .lit (Units.feet 500) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3: upon any curve — the subject occupies a roadway region whose curvature exceeds the
    resolution. -/
def onCurve : Formula :=
  .existsRegion (.lit "roadway") "curveWay"
    (.and (.atom "rel_occupies" [vSubject, .var "curveWay"] [])
          (.cmp (.measure "st_curvature" [.var "curveWay"]) .gt pCurvatureResolution))

/-- s4: on the approach to or near the crest of a grade — a crest region within the reach of the
    subject's body. -/
def nearCrest : Formula :=
  .existsRegion (.lit "crest") "crest"
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "crest"]) .le pCrestNearReach)

/-- s5: the sight distance at the subject's place (the roadway it occupies) is below 500 ft. -/
def sightShort : Formula :=
  .existsRegion (.lit "roadway") "sightWay"
    (.and (.atom "rel_occupies" [vSubject, .var "sightWay"] [])
          (.cmp (.measure "st_sight_distance" [.var "sightWay"]) .lt sightLimit))

/-- The condition at one observation: (s3 ∨ s4) ∧ s5. -/
def condition : Formula := .and (.or onCurve nearCrest) sightShort

/-- The reversal under way: yaw-rate magnitude above the tolerance. -/
def underWay : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vSubject])) .gt pTurnYawRateTol

/-- Applicability: s3 (condition): upon any curve,; s4 (condition): or upon the approach to or near the crest of a grade,; s5 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.
    Read `some_moment` over the act's window: at one observation in the window behind, the
    reversal is under way and the condition holds. -/
def applicability : Formula :=
  .not (.holdsFor .time pVehicleTurnWindow "subject" (.not (.and underWay condition)))

/-- Obligation: s2 (obligation): shall not be turned so as to proceed in the opposite direction -/
def obligation : Formula :=
  .not (.derived "drv_motion_u_turn" [vSubject]
    [pVehicleTurnWindow, pUTurnHeadingMin, pTurnYawRateTol])

def rule : Rule :=
  { id := "NRS_484B_407"
    laws := ["NRS-484B-407"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_407
