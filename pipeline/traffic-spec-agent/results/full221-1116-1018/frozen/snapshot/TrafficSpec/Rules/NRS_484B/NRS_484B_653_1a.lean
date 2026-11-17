/-
  NRS_484B_653_1a — NRS-484B-653-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (obligation): It is unlawful for a person to:
    d2 (subject): Drive a vehicle
    d3 (standard): in willful or wanton disregard of the safety of persons or property
    d4 (condition): on a highway
    d5 (condition): or premises to which the public has access.

  Elements (span → atoms, derived):
    d1: atoms ['kin.speed', 'kin.accel_longitudinal'], derived []
    d2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d4: atoms ['rel.occupies', 'st.highway'], derived []

  How each is written:
    d2: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; 'Drive' is the plan's
        observable reading (the vehicle's controlled motion), carried by the motion d1/d3 bound.
    d4: some region of kind `highway` (st.highway; refining kinds included, none excluded) that
        the subject occupies (rel.occupies).
    d5: the declared assumption `asm.public_access_premises`, disjoined with d4.
    d1 + d3 (surrogate operationalization): the duty is violated where
        kin.speed ≥ p.exhibition_speed_min, or
        kin.accel_longitudinal ≥ p.exhibition_accel_min while some road user other than the
        subject (`not same`) has its centre approach the subject's within p.conflict_horizon
        (prim.closest_approach_within) at a closest-approach centre distance at or below
        p.conflict_centre_clearance (prim.closest_approach_distance, read only where the
        approach within the horizon holds, as its contract leaves it undefined otherwise).
    No choice beyond the record's own words was made: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_653_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pExhibitionAccelMin : Term := .param "p.exhibition_accel_min"
def pExhibitionSpeedMin : Term := .param "p.exhibition_speed_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d4: the subject occupies a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vSubject, .var "h"] [])

/-- d5: premises to which the public has access, as the reading declares. -/
def onPublicPremises : Formula := .asm "asm.public_access_premises"

/-- Applicability: d4 (condition): on a highway; d5 (condition): or premises to which the public has access. -/
def applicability : Formula := .or onHighway onPublicPremises

/-- d3, first limb: exhibition speed. -/
def exhibitionSpeed : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .ge pExhibitionSpeedMin

/-- d3, second limb's conflict: another road user whose centre is predicted to come within the
    clearance of the subject's within the horizon. -/
def predictedConflict : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.derived "prim_closest_approach_within" [vSubject, .var "o"] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "o"] [pConflictHorizon])
          .le pConflictCentreClearance)))

/-- d3, second limb: hard acceleration into a predicted conflict. -/
def hardAccelIntoConflict : Formula :=
  .and (.cmp (.measure "kin_accel_longitudinal" [vSubject]) .ge pExhibitionAccelMin)
    predictedConflict

/-- Obligation: d1 (obligation): It is unlawful for a person to:; d3 (standard): in willful or wanton disregard of the safety of persons or property -/
def obligation : Formula := .not (.or exhibitionSpeed hardAccelIntoConflict)

def rule : Rule :=
  { id := "NRS_484B_653_1a"
    laws := ["NRS-484B-653-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.public_access_premises"]
    intentions := []
    operationalizations :=
      [ { standard := "willful or wanton disregard of the safety of persons or property"
          concepts := ["kin.accel_longitudinal", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.exhibition_speed_min", "p.exhibition_accel_min", "p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "Exhibition-driving and traffic-conflict conventions: the driving shows disregard of the safety of persons or property where the vehicle travels at or above p.exhibition_speed_min (beyond any posted limit), or where it accelerates at p.exhibition_accel_min or more while another road user's centre is predicted to come within p.conflict_centre_clearance of its own within p.conflict_horizon (driving hard into a conflict)."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_653_1a
