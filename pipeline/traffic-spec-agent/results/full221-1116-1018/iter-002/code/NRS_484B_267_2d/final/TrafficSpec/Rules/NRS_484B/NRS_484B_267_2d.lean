/-
  NRS_484B_267_2d — NRS-484B-267-2d

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,
    s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,
    s3 (trigger): and making use of flashing lights meeting the requirements of
    s4 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    s5 (subject): the driver of any other vehicle shall,
    s6 (exception): except when otherwise directed by a law enforcement officer:
    s7 (condition): If the authorized emergency vehicle or official vehicle of a regulatory agency is moving in the same direction of travel as the driver,
    s8 (obligation): not drive abreast of or overtake the authorized emergency vehicle or official vehicle of a regulatory agency.
    s9 (definitional): As used in this section, “preparing to move” means any indication that is visible to an approaching driver that an authorized emergency vehicle or an official vehicle of a regulatory agency is about to move, including, without limitation: (a) A movement of the vehicle; or (b) The use of hand signals by the driver of the vehicle.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed', 'rel.bearing', 'rel.centre_distance', 'ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle', 'ru.official_vehicle', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []
    s3: atoms ['sig.warning_lamp'], derived [], borrowing ['s4']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['rel.same_direction', 'kin.speed'], derived []
    s8: atoms ['rel.longitudinal_overlap', 'kin.speed'], derived ['drv.interaction.overtake_pass']
    s9: atoms ['kin.speed', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s4: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written.
    s5 (`clsSubject`): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`. 'other' is
      `¬ same subject e` inside the selection of the approached vehicle.
    s1 (`selected`, `approach`, `movingOrPreparing`): the approached vehicle `e` is a road-user
      quantifier, never a binder. `selected e` = not the subject, and either a member of
      `DEF-NRS-484A-020::authorized_emergency_vehicle` (`ru_aggregate`) or `ru_official_vehicle`
      of kind `regulatory_agency`. 'approaching' = `rel_bearing subject e ahead` (longitudinal
      component positive), `rel_centre_distance subject e ≤ p.emergency_approach_reach`, and the
      subject's `kin_speed > p.halt_speed_tolerance`. 'moving' = e's `kin_speed` above the halt
      tolerance; 'preparing to move' (s9) = `rel_visible subject e` and either a hand signal other
      than `no_signal` or a turn indicator other than `off`.
    s3 (`lamp`): `sig_warning_lamp e red flashing`. The record's "facing front" (the borrowed
      "visible from the front") is not written: the formula surface of `sig_warning_lamp` takes a
      colour and a mode only (Semantics.evalAtomE: `[x, col]` or `[x, col, m]`; atomArgSorts allows
      at most two literal positions), so no formula can read a lamp's facing. This is declared as a
      `no_atom` narrowing on s3 (the words cannot be stated), not as a reading; see task_result.md.
    s7 (`condAt`): e's `kin_speed > p.halt_speed_tolerance` and
      `rel_same_direction subject e` with tolerance `p.overtake_same_direction_cos`.
    s6 (`excAt`): some travel region (`existsRegion travel_region`) the subject occupies
      (`rel_occupies`) is governed (`dev_governs`) by a human-direction device
      (`existsDevice human_direction`) whose role is `police_officer`.
    s8 (`abreast`, `pass`): 'drive abreast' = the subject's `kin_speed > p.halt_speed_tolerance`
      and `rel_longitudinal_overlap subject e ≥ 0`; 'overtake' =
      `drv_interaction_overtake_pass subject e [p.overtake_window, p.overtake_same_direction_cos]`.

  The occasion (act drv.interaction.overtake_pass, boundary window p.overtake_window).
    `underWay e` (the record's under_way element) = the subject moves and the vehicle is no longer
    ahead clear of it: `rel_longitudinal_overlap ≥ 0` or the vehicle behind (`rel_bearing … behind`,
    the record's "or the vehicle being behind").
    Overtaking alternative (`appOvertake`): s1, s3, s7 are read `some_moment` and are joined by
    `and`, so they are read at one common observation of the window:
    `¬ holdsFor W subject ¬(underWay ∧ trigAt ∧ condAt)`; s6 is read `throughout`, and the
    alternative is excepted where `holdsFor W subject (underWay → excAt)`.
    Abreast alternative (`appAbreast`): as the record's applicability states it, the trigger at
    some observation of the window behind (up to and including this one), the condition at some
    observation of that window, and the exception at the judged observation.
    The applicability is `∃ e, selected e ∧ (appAbreast e ∨ appOvertake e)`; the obligation
    re-binds e with its whole selection and the alternative's whole applicability:
    `∀ e, selected e → (appAbreast e → ¬ abreast e) ∧ (appOvertake e → ¬ pass e)`.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_2d

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The approached vehicle: a road-user quantifier variable, never a binder. -/
def vE : Arg := .var "e"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEmergencyApproachReach : Term := .param "p.emergency_approach_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- A road user moves: its speed above the halt tolerance. -/
def moving (x : Arg) : Formula := .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- s1/s5: e is another road user, an authorized emergency vehicle or an official vehicle of a
    regulatory agency. -/
def selected : Formula :=
  .and (.not (.same vSubject vE))
    (.or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
         (.and (.atom "ru_official_vehicle" [vE] [])
               (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] [])))

/-- s3 (with s4's borrowed words): a red warning lamp lit on e, flashing. -/
def lamp : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- s1/s9: e moving, or preparing to move — visible from the subject and showing an arm signal or
    a lit turn indicator. -/
def movingOrPreparing : Formula :=
  .or (moving vE)
    (.and (.atom "rel_visible" [vSubject, vE] [])
          (.or (.not (.atom "sig_hand_signal" [vE, .lit "no_signal"] []))
               (.not (.atom "sig_turn_indicator" [vE, .lit "off"] []))))

/-- s1: the subject, moving, has e ahead of it within the approach reach. -/
def approach : Formula :=
  .and (.atom "rel_bearing" [vSubject, vE, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_centre_distance" [vSubject, vE]) .le pEmergencyApproachReach)
          (moving vSubject))

/-- s1 ∧ s3 at one observation. -/
def trigAt : Formula := .and lamp (.and movingOrPreparing approach)

/-- s7 at one observation: e moving with its heading aligned with the subject's. -/
def condAt : Formula :=
  .and (moving vE) (.atom "rel_same_direction" [vSubject, vE] [pOvertakeSameDirectionCos])

/-- s6 at one observation: a police officer directing traffic governs a travel region the subject
    occupies. -/
def excAt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
          (.existsDevice (.lit "human_direction") "d"
            (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
                  (.atom "dev_governs" [.var "d", .var "r"] []))))

/-- The bodies' projections on the subject's heading share length. -/
def sideBySide : Formula := .cmp (.measure "rel_longitudinal_overlap" [vSubject, vE]) .ge zeroMetres

/-- The occasion's under_way element: the subject moves and e is no longer ahead clear of it. -/
def underWay : Formula :=
  .and (moving vSubject) (.or sideBySide (.atom "rel_bearing" [vSubject, vE, .lit "behind"] []))

/-- φ at some observation of the window behind (up to and including this one). -/
def someInWindow (φ : Formula) : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not φ))

/-- The abreast alternative's applicability. -/
def appAbreast : Formula :=
  .and (someInWindow trigAt) (.and (someInWindow condAt) (.not excAt))

/-- The overtaking alternative's applicability: s1, s3, s7 some_moment of the act, s6 not
    throughout it. -/
def appOvertake : Formula :=
  .and (someInWindow (.and underWay (.and trigAt condAt)))
       (.not (.holdsFor .time pOvertakeWindow "subject" (.implies underWay excAt)))

/-- s8: the subject drives abreast of e. -/
def abreast : Formula := .and (moving vSubject) sideBySide

/-- s8: the subject overtakes e. -/
def pass : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vE] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- Applicability: s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,; s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,; s3 (trigger): and making use of flashing lights meeting the requirements of; s6 (exception): except when otherwise directed by a law enforcement officer:; s7 (condition): If the authorized emergency vehicle or official vehicle of a regulatory agency is moving in the same direction of travel as the driver, -/
def applicability : Formula :=
  .existsUser "e" (.and selected (.or appAbreast appOvertake))

/-- Obligation: s8 (obligation): not drive abreast of or overtake the authorized emergency vehicle or official vehicle of a regulatory agency. -/
def obligation : Formula :=
  .forallUser "e"
    (.implies selected
      (.and (.implies appAbreast (.not abreast))
            (.implies appOvertake (.not pass))))

def rule : Rule :=
  { id := "NRS_484B_267_2d"
    laws := ["NRS-484B-267-2d"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'including, without limitation' lists examples of a vehicle moving or preparing to move; the duty is the same whether or not the vehicle is arriving at or leaving the scene of a crash or other incident"]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The borrowed words of s4 ('at least one flashing red warning lamp visible from the front'), which the record reads as a lit sig.warning_lamp red, flashing, facing front: no formula can read a lamp's facing. The formula surface of sig_warning_lamp takes a colour, or a colour and a mode, only (Semantics.evalAtomE: [x, col] or [x, col, m]; atomArgSorts admits at most two literal positions for sig_*), so 'facing front' / 'visible from the front' cannot be stated. Colour red and mode flashing are written; the facing is not, so the trigger as written is weaker than the record's (a lamp lit red and flashing facing only the rear or side would engage it). Either the plan re-maps s3 to a red flashing lamp and files 'visible from the front' as a gap, or Core gives sig_warning_lamp a facing literal."
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_2d
