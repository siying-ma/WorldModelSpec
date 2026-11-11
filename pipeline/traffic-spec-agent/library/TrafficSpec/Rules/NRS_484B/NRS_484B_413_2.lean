/-
  NRS_484B_413_2 — NRS-484B-413-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled
    f5 (condition): in a business or residential district
    f6 (condition): and not less than the last 300 feet traveled
    f7 (condition): in any other area
    f8 (trigger): prior to changing the course
    f9 (subject): of a vehicle.
    f10 (condition): This rule shall be observed, regardless of the weather.

  Elements (span → atoms, derived):
    f1: atoms ['sig.turn_indicator', 'sig.hand_signal', 'kin.path_length', 'st.lane_direction', 'kin.velocity', 'kin.speed', 'rel.occupies', 'st.travel_region'], derived ['drv.motion.veering_left', 'drv.motion.veering_right']
    f6: atoms ['kin.path_length'], derived []
    f8: atoms ['rel.occupies'], derived ['drv.motion.veering_left', 'drv.motion.veering_right']
    f9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  Literals the text states (each written through its Units constructor):
    f1: 100 ft — 100 feet
    f6: 300 ft — 300 feet

  How each span is written:
    f9  `ru_aggregate x "DEF-NRS-484A-320::vehicle"`, the binder's class.
    f8  The change of course begins at the observation: `rises` of "some travel region c that x
        occupies (`rel_occupies`) with `drv_motion_veering_left (x, c)` or
        `drv_motion_veering_right (x, c)`" (p.speed_resolution, p.course_departure_sine). `rises`
        is that statement here and at no region at the observation before, as the record states.
    f1  A departure to the left (the same selection: a travel region x occupies on which it veers
        left) owes a left signal (`sig_turn_indicator x left` or `sig_hand_signal x left`) at every
        observation of the `.path` window behind (`holdsFor .path … "x"`, read on kin.path_length);
        a departure to the right the right signal. The two are joined by `or`, each conjoined with
        its side's departure, so a departure to both sides at once owes the signal of either.
    f5/f7/f6  The window's length is the f1 literal (100 ft) where
        asm.within_business_or_residence_district holds and the f6 literal (300 ft) where it does
        not. A window length must be a constant term, so the selection is written as two
        implications on the assumption rather than as a `Term.cond` length.
    f10 The record's residue: no environment atom is read.

  No choice beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCourseDepartureSine : Term := .param "p.course_departure_sine"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- The literals of spans f1 and f6. -/
def signalPathInDistrict : Term := .lit (Units.feet 100) .metre
def signalPathElsewhere : Term := .lit (Units.feet 300) .metre

def asmDistrict : Formula := .asm "asm.within_business_or_residence_district"

/-- The carrier `c` that x occupies. -/
def occupiesC : Formula := .atom "rel_occupies" [vX, .var "c"] []

def veerLeftC : Formula :=
  .derived "drv_motion_veering_left" [vX, .var "c"] [pSpeedResolution, pCourseDepartureSine]
def veerRightC : Formula :=
  .derived "drv_motion_veering_right" [vX, .var "c"] [pSpeedResolution, pCourseDepartureSine]

/-- x departs from its direct course (f1, f8): on some travel region it occupies it veers to a side. -/
def departs : Formula :=
  .existsRegion (.lit "travel_region") "c" (.and occupiesC (.or veerLeftC veerRightC))

/-- A departure to the left: the same selection, its left side. -/
def departsLeft : Formula :=
  .existsRegion (.lit "travel_region") "c" (.and occupiesC veerLeftC)

/-- A departure to the right: the same selection, its right side. -/
def departsRight : Formula :=
  .existsRegion (.lit "travel_region") "c" (.and occupiesC veerRightC)

/-- The signal of a side: the turn indicator or an arm signal of that side. -/
def signals (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vX, .lit side] []) (.atom "sig_hand_signal" [vX, .lit side] [])

/-- f1/f5/f6/f7: the signal shown at every observation of the last 100 ft travelled in a business
    or residence district, of the last 300 ft elsewhere. -/
def signalledOver (φ : Formula) : Formula :=
  .and (.implies asmDistrict (.holdsFor .path signalPathInDistrict "x" φ))
       (.implies (.not asmDistrict) (.holdsFor .path signalPathElsewhere "x" φ))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: f8 (trigger): prior to changing the course — the observation at which a departure begins. f5/f6/f7 select the window in the obligation; f10 is a residue. -/
def applicability : Formula := .rises departs

/-- Obligation: f1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled -/
def obligation : Formula :=
  .or (.and departsLeft (signalledOver (signals "left")))
      (.and departsRight (signalledOver (signals "right")))

def rule : Rule :=
  { id := "NRS_484B_413_2"
    laws := ["NRS-484B-413-2"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_business_or_residence_district", "asm.within_business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := ["The duty is the same in every weather: the words exclude no weather and add no condition, so no environment atom is read."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_2
