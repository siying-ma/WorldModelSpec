/-
  NRS_484B_413_2 — NRS-484B-413-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    j1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled
    j2 (condition): in a business or residential district
    j3 (condition): and not less than the last 300 feet traveled in any other area
    j4 (trigger): prior to changing the course of a vehicle.
    j5 (condition): This rule shall be observed, regardless of the weather.

  Elements (span → atoms, derived):
    j1: atoms ['sig.turn_indicator', 'sig.hand_signal', 'kin.path_length', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    j3: atoms ['sig.turn_indicator', 'sig.hand_signal', 'kin.path_length'], derived []
    j4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.leftward_course_change', 'drv.motion.rightward_course_change']

  Literals the text states (each written through its Units constructor):
    j1: 100 ft — 100 feet
    j3: 300 ft — 300 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written.

    j4 (trigger), with the aggregate of j1 and j4: the subject's class is the admitted aggregate
      `DEF-NRS-484A-320::vehicle`, carried by `ru_aggregate` with the aggregate id as its literal
      argument (`clsSubject`). The change of course is the pair of catalogued concepts,
      `drv.motion.leftward_course_change` and `drv.motion.rightward_course_change`, each called with
      the node's four manoeuvre parameters in the concepts' formal order (`turnParams`). The record
      reads the act at the observation at which its concept rises, so the applicability is
      `.rises` of either concept: one judged observation per change of course, and the window of
      travelled distance is measured back from it.

    j1 and j3 (the duty and the bound it selects): the signal given is the indicator in the state of
      the hand of the course change, or the arm signal with the meaning of that hand
      (`signalLeft`, `signalRight`) — the record's reading that the signal must be of the same hand
      as the change of course made, so the duty is written hand by hand: the left-hand duty is read
      where the leftward concept rises, the right-hand duty where the rightward one does.
      "given continuously during not less than the last 100 feet traveled" is the length of the
      uninterrupted run of that signal ending at the judged observation (`Term.distanceWhile` over
      the subject's travelled path, which reads `kin.path_length`), compared with the bound the
      district condition of j2/j3 selects: 100 feet where the assumption
      `asm.way_within_business_or_residential_district` holds for the stretch, 300 feet where it does
      not (`requiredRun`, a `Term.cond` over the assumption — j3's "any other area" is the
      complement of j2 and needs no assumption of its own). A selection among bounds is what the
      record asks for, and a comparison over it is decided wherever both bounds decide it alike, so
      a trace that declares the assumption for neither value leaves the duty open (unknown) exactly
      where the choice between the two bounds matters.

    j2 (condition): the assumption, read at the judged observation inside `requiredRun`.

    j5 (condition): the node's residue; no weather atom is read.

  The narrowing declared below is this session's reading on j1: the window is the length of ONE
  uninterrupted run of the signal, so a signal interrupted inside the window does not satisfy the
  duty however far it was given before the interruption.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pTurnMaxCourseChange : Term := .param "p.turn_max_course_change"
def pTurnMinCourseChange : Term := .param "p.turn_min_course_change"
def pTurnWindow : Term := .param "p.turn_window"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

/-- The figures the text states, each through its `Units` constructor. -/
def feet100 : Term := .lit (Units.feet 100) .metre
def feet300 : Term := .lit (Units.feet 300) .metre

/-- The manoeuvre-recognition parameters the two course-change concepts take, in their formal
    order: the window behind, the smallest and the largest course change read as a turn, and the
    speed below which a reading counts as no travel. -/
def turnParams : List Term :=
  [pTurnWindow, pTurnMinCourseChange, pTurnMaxCourseChange, pMotionSpeedTolerance]

/-- The change of course to the left (j4). -/
def leftCourseChange : Formula := .derived "drv_motion_leftward_course_change" [vSubject] turnParams
/-- The change of course to the right (j4). -/
def rightCourseChange : Formula := .derived "drv_motion_rightward_course_change" [vSubject] turnParams

/-- The signal of the left hand: the indicator in the left state, or the arm signal meaning left. -/
def signalLeft : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit "left"] [])
      (.atom "sig_hand_signal" [vSubject, .lit "left"] [])

/-- The signal of the right hand. -/
def signalRight : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit "right"] [])
      (.atom "sig_hand_signal" [vSubject, .lit "right"] [])

/-- The bound the district condition selects (j2, j3): the last 100 feet travelled where the
    stretch is within a business or residential district, the last 300 feet in any other area. -/
def requiredRun : Term :=
  .cond (.asm "asm.way_within_business_or_residential_district") feet100 feet300

/-- The signal `φ` has been given continuously over not less than the bound the district selects,
    measured in the distance the subject has travelled (j1, j3). -/
def signalledOverRun (φ : Formula) : Formula :=
  .cmp (.distanceWhile "subject" φ) .ge requiredRun

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: j2 (condition): in a business or residential district; j3 (condition): and not less than the last 300 feet traveled in any other area; j4 (trigger): prior to changing the course of a vehicle.; j5 (condition): This rule shall be observed, regardless of the weather. -/
def applicability : Formula :=
  .or (.rises leftCourseChange) (.rises rightCourseChange)

/-- Obligation: j1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled -/
def obligation : Formula :=
  .and (.implies (.rises leftCourseChange) (signalledOverRun signalLeft))
       (.implies (.rises rightCourseChange) (signalledOverRun signalRight))

def rule : Rule :=
  { id := "NRS_484B_413_2"
    laws := ["NRS-484B-413-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.way_within_business_or_residential_district"]
    intentions := []
    operationalizations := []
    residues := ["\"This rule shall be observed, regardless of the weather\" imposes no observable condition and restricts the duty in no way: the obligation is the same whatever the weather, so the rule reads no weather atom and drops nothing by leaving these words unread."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "j1"
          why := "\"given continuously during not less than the last 100 feet traveled\" is written as the length of a single uninterrupted run of the signal ending at the observation at which the change of course is recognized, compared with the bound the district condition selects; a signal interrupted inside that window therefore does not satisfy the duty however far it was given before the interruption, and the run must still be given at the judged observation itself."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_2
