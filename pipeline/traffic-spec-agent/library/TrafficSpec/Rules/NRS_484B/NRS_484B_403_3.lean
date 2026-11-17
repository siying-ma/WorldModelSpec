/-
  NRS_484B_403_3 — NRS-484B-403-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not make a U-turn
    s3 (condition): in a business district,
    s4 (exception): except at an intersection
    s5 (exception): or on a divided highway
    s6 (exception): where an appropriate opening or crossing place exists.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.highway'], derived ['drv.motion.u_turn']
    s4: atoms ['rel.occupies', 'st.intersection'], derived []
    s5: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.median_or_divider'], derived []
    s6: atoms ['rel.occupies', 'st.median_or_divider'], derived []

  How each is written:
    s1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (agency reading is the
        record's own narrowing).
    s3: the applicability is the declared assumption `asm.business_district`.
    s2: the occasion — the recognition of the reversal, `rises (drv_motion_u_turn subject …)` with the
        concept's three parameters in its formal order (window, u_turn_min, yaw_tol), while the
        subject occupies some `highway` region (the definition's "upon a highway").
    under way (U): `|kin_yaw_rate subject| > p.turn_yaw_rate_tol`, the occasion's under_way element.
    s4 (throughout): `holdsFor time p.vehicle_turn_window subject (U → ∃ intersection i occupied)`.
    s5 (throughout): `holdsFor … (U → ∃ highway h occupied, ∃ median_or_divider d on_way h)`.
    s6 (some_moment): `¬ holdsFor … ¬(U ∧ ∃ median_or_divider d occupied with the opening attribute,
        lying on (st_on_way) a highway the subject occupies)` — "on that highway" is the highway the
        subject occupies, re-selected in this formula as the record states it.
    The obligation: recognition → s4 ∨ (s5 ∧ s6); where no reversal is recognized it is complied with.

  No choice beyond the record was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_403_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s3 (condition): in a business district. -/
def applicability : Formula := .asm "asm.business_district"

/-- s2: the reversal of direction (drv.motion.u_turn), recognized at this observation. -/
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vSubject] [pVehicleTurnWindow, pUTurnHeadingMin, pTurnYawRateTol]

/-- s2: the subject occupies a highway ("upon a highway"). -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "hw" (.atom "rel_occupies" [vSubject, .var "hw"] [])

/-- The occasion: the reversal recognized while the subject is upon a highway. -/
def occasion : Formula := .and (.rises uTurn) onHighway

/-- The occasion's under_way element: the subject's yaw rate exceeds the turning tolerance. -/
def underWay : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vSubject])) .gt pTurnYawRateTol

/-- s4: the subject occupies an intersection. -/
def atIntersection : Formula :=
  .existsRegion (.lit "intersection") "ix" (.atom "rel_occupies" [vSubject, .var "ix"] [])

/-- s5: the subject occupies a highway on which a median or divider lies. -/
def onDividedHighway : Formula :=
  .existsRegion (.lit "highway") "dh"
    (.and (.atom "rel_occupies" [vSubject, .var "dh"] [])
      (.existsRegion (.lit "median_or_divider") "dv" (.atom "st_on_way" [.var "dv", .var "dh"] [])))

/-- s6: the subject's footprint overlaps a divider region with the opening attribute, lying on a
    highway the subject occupies. -/
def throughOpening : Formula :=
  .existsRegion (.lit "median_or_divider") "op"
    (.and (.atom "rel_occupies" [vSubject, .var "op"] [])
      (.and (.atom "st_median_or_divider_opening" [.var "op"] [])
        (.existsRegion (.lit "highway") "oh"
          (.and (.atom "rel_occupies" [vSubject, .var "oh"] [])
            (.atom "st_on_way" [.var "op", .var "oh"] [])))))

/-- s4 read throughout the reversal. -/
def s4Throughout : Formula :=
  .holdsFor .time pVehicleTurnWindow "subject" (.implies underWay atIntersection)

/-- s5 read throughout the reversal. -/
def s5Throughout : Formula :=
  .holdsFor .time pVehicleTurnWindow "subject" (.implies underWay onDividedHighway)

/-- s6 read at some moment of the reversal. -/
def s6SomeMoment : Formula :=
  .not (.holdsFor .time pVehicleTurnWindow "subject" (.not (.and underWay throughOpening)))

/-- Obligation: s2 (obligation): shall not make a U-turn, except s4, or s5 with s6. -/
def obligation : Formula :=
  .implies occasion (.or s4Throughout (.and s5Throughout s6SomeMoment))

def rule : Rule :=
  { id := "NRS_484B_403_3"
    laws := ["NRS-484B-403-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_district"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_403_3
