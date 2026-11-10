/-
  NRS_484B_413_2 — NRS-484B-413-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled
    s4 (condition): in a business or residential district
    s5 (condition): and not less than the last 300 feet traveled
    s6 (condition): in any other area
    s7 (trigger): prior to changing the course
    s8 (subject): of a vehicle.
    s9 (condition): This rule shall be observed, regardless of the weather.

  Elements (span → atoms, derived):
    s1: atoms ['sig.turn_indicator', 'sig.hand_signal', 'kin.path_length', 'kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region'], derived ['drv.lane.heading_offset_from_direction']
    s5: atoms ['kin.path_length'], derived []
    s7: atoms ['kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region'], derived ['drv.lane.heading_offset_from_direction']
    s8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  Literals the text states (each written through its Units constructor):
    s1: 100 ft — 100 feet
    s5: 300 ft — 300 feet

  How each span is written:
    s8: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`, the class of x.
    s7: a change of course to a side is, for some travel region c that x occupies, the signed
        departure `drv_lane_heading_offset_from_direction(x, c)` rising above the tolerance (left)
        or below its negative (right) at the judged observation (`rises`). The applicability is
        either change; the obligation selects the region again the same way (occupied travel
        region, the same rise), one implication per side.
    s1/s5: the signal of the side of the change — `sig_turn_indicator` of that side or
        `sig_hand_signal` of that side — at every observation of the `.path` window of x behind
        the change (`holdsFor .path`, which reads kin.path_length).
    s4/s6: the record asks for `Term.cond (asm business_or_residence_district) 100 ft 300 ft` as
        the window's length; `Rule.check` refuses a window length that is not a constant term
        (an assumption is none), so the selection is written at the formula level, equivalently:
        `(asm → holdsFor 100 ft) ∧ (¬asm → holdsFor 300 ft)`.
    s9: residue (no weather condition is read).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCourseChangeSinTolerance : Term := .param "p.course_change_sin_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's literals: 100 feet (s1), 300 feet (s5). -/
def hundredFeet : Term := .lit (Units.feet 100) .metre
def threeHundredFeet : Term := .lit (Units.feet 300) .metre

/-- s4/s6: the district, which selects the window. -/
def district : Formula := .asm "asm.business_or_residence_district"

/-- s1/s4/s5/s6: φ held at every observation of the last 100 ft of x's path in a district, of
    the last 300 ft elsewhere. -/
def heldOverWindow (φ : Formula) : Formula :=
  .and (.implies district (.holdsFor .path hundredFeet "x" φ))
    (.implies (.not district) (.holdsFor .path threeHundredFeet "x" φ))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The signed departure of x's heading from the direction of carrier `c`. -/
def offset : Term :=
  .quantity "drv_lane_heading_offset_from_direction" [vX, .var "c"] []

/-- s7: x occupies a travel region whose direction its heading departs from, beyond the
    tolerance, to the left, first at this observation. -/
def changeLeft : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.atom "rel_occupies" [vX, .var "c"] [])
      (.rises (.cmp offset .gt pCourseChangeSinTolerance)))

/-- s7: the same, to the right. -/
def changeRight : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.atom "rel_occupies" [vX, .var "c"] [])
      (.rises (.cmp offset .lt (.neg pCourseChangeSinTolerance))))

/-- s1: the signal of a side, by indicator or by arm. -/
def signalOf (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vX, .lit side] [])
    (.atom "sig_hand_signal" [vX, .lit side] [])

/-- Applicability: s4 (condition): in a business or residential district; s5 (condition): and not less than the last 300 feet traveled; s6 (condition): in any other area; s7 (trigger): prior to changing the course; s9 (condition): This rule shall be observed, regardless of the weather. -/
def applicability : Formula := .or changeLeft changeRight

/-- Obligation: s1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled -/
def obligation : Formula :=
  .and
    (.implies changeLeft (heldOverWindow (signalOf "left")))
    (.implies changeRight (heldOverWindow (signalOf "right")))

def rule : Rule :=
  { id := "NRS_484B_413_2"
    laws := ["NRS-484B-413-2"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district", "asm.business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := ["The words say the rule holds in every weather; no weather condition restricts or extends the duty, which is the same whether or not it rains, snows or is clear."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_2
