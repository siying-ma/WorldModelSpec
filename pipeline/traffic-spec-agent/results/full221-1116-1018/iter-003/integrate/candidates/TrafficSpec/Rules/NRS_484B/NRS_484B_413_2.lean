/-
  NRS_484B_413_2 — NRS-484B-413-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously
    s2 (condition): during not less than the last 100 feet traveled
    s3 (condition): in a business or residential district
    s4 (condition): and not less than the last 300 feet traveled
    s5 (condition): in any other area
    s6 (trigger): prior to changing the course
    s7 (subject): of a vehicle.
    s8 (condition): This rule shall be observed, regardless of the weather.

  Elements (span → atoms, derived):
    s1: atoms ['sig.turn_indicator', 'sig.hand_signal', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['kin.path_length'], derived []
    s4: atoms ['kin.path_length'], derived []
    s6: atoms ['rel.occupies', 'st.lane'], derived ['drv.lane.heading_left_of_carrier', 'drv.lane.heading_right_of_carrier']
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  Literals the text states (each written through its Units constructor):
    s2: 100 ft — 100 feet
    s4: 300 ft — 300 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s7/subject class: ru_aggregate(subject, "DEF-NRS-484A-320::vehicle").
    s6 (trigger): some lane l (quantifier kind "lane", st.lane) the subject occupies (rel_occupies)
      on which drv_lane_heading_left_of_carrier or drv_lane_heading_right_of_carrier, with
      p.course_departure_sin_tol and p.halt_speed_tolerance, rises; read under definedWhen
      "the subject occupies some lane", so where it occupies none the trigger is unknown.
    s1 (obligation): sig_turn_indicator(subject, side) or sig_hand_signal(subject, side), the side
      being that of the departure; the obligation repeats the applicability's whole lane selection
      (occupied lane with a rising departure) for every such lane, left and right separately.
    s2/s3, s4/s5: two branches, asm.business_or_residence_district with holdsFor .path 100 ft, and
      its negation with holdsFor .path 300 ft, over the subject's path (kin.path_length).
    s8: residue (no restriction).
  No choice beyond the record's own reading was needed: narrowings is empty.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCourseDepartureSinTol : Term := .param "p.course_departure_sin_tol"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- s2, s4: the stated window lengths, written through their Units constructor. -/
def last100Feet : Term := .lit (Units.feet 100) .metre
def last300Feet : Term := .lit (Units.feet 300) .metre

/-- s3/s5: the area classification at the judged observation. -/
def inDistrict : Formula := .asm "asm.business_or_residence_district"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s6: the subject occupies lane `l`. -/
def occupiesLane : Formula := .atom "rel_occupies" [vSubject, .var "l"] []

/-- s6: the heading departs to the left / right of lane `l`'s designated direction. -/
def headingLeft : Formula :=
  .derived "drv_lane_heading_left_of_carrier" [vSubject, .var "l"]
    [pCourseDepartureSinTol, pHaltSpeedTolerance]
def headingRight : Formula :=
  .derived "drv_lane_heading_right_of_carrier" [vSubject, .var "l"]
    [pCourseDepartureSinTol, pHaltSpeedTolerance]

/-- s6: the course change begins here on lane `l`, to the left / right. -/
def departsLeft : Formula := .and occupiesLane (.rises headingLeft)
def departsRight : Formula := .and occupiesLane (.rises headingRight)

/-- s1: the signal to `side` (turn indicator or hand signal). -/
def signalTo (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit side] [])
      (.atom "sig_hand_signal" [vSubject, .lit side] [])

/-- s1–s5: the signal given continuously over the last 100 ft (s2, s3) or the last 300 ft (s4, s5)
    of the subject's path. -/
def signalledOver (side : String) : Formula :=
  .or (.and inDistrict (.holdsFor .path last100Feet "subject" (signalTo side)))
      (.and (.not inDistrict) (.holdsFor .path last300Feet "subject" (signalTo side)))

/-- Applicability: s6 (trigger), read where the subject occupies some lane. -/
def applicability : Formula :=
  .definedWhen
    (.existsRegion (.lit "lane") "l" occupiesLane)
    (.existsRegion (.lit "lane") "l" (.or departsLeft departsRight))

/-- Obligation: s1 with s2–s5; for every occupied lane on which the course departs, the signal to
    the side of the departure over the window behind. -/
def obligation : Formula :=
  .and
    (.forallRegion (.lit "lane") "l" (.implies departsLeft (signalledOver "left")))
    (.forallRegion (.lit "lane") "l" (.implies departsRight (signalledOver "right")))

def rule : Rule :=
  { id := "NRS_484B_413_2"
    laws := ["NRS-484B-413-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district", "asm.business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := ["The words exclude the weather as a ground for any other duty; the duty is the same whatever the weather, so they add no restriction."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_2
