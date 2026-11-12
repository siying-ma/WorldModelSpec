/-
  NRS_484B_413_2 — NRS-484B-413-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during
    t4 (condition): not less than the last 100 feet traveled
    t5 (condition): in a business or residential district
    t6 (condition): and not less than the last 300 feet traveled
    t7 (condition): in any other area
    t8 (trigger): prior to changing the course of a vehicle.
    t9 (condition): This rule shall be observed, regardless of the weather.

  Elements (span → atoms, derived):
    t1: atoms ['sig.turn_indicator', 'sig.hand_signal', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t4: atoms ['kin.path_length'], derived []
    t6: atoms ['kin.path_length'], derived []
    t8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.left_turn_from_onset', 'drv.motion.right_turn_from_onset', 'drv.motion.turning_left', 'drv.motion.turning_right']

  Literals the text states (each written through its Units constructor):
    t4: 100 ft — 100 feet
    t6: 300 ft — 300 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    class (t1, t8 "a vehicle"): ru_aggregate ego DEF-NRS-484A-320::vehicle.
    t8: the judged observation is the recognition of a turn from an observed onset,
      drv_motion_left_turn_from_onset or drv_motion_right_turn_from_onset (each holds at its
      recognition only). "prior to": the onset is the observation at which drv_motion_turning_left
      (resp. _right) last rose, turning having held since: `since turning (rises turning ∧ W)`, so
      W is read at that onset and conduct after it is not read.
    t1: the signal on the side of the turn is the turn indicator on that side or an arm signal
      meaning that side; "continuously during" is holdsFor at every observation of the window.
    t4/t5, t6/t7: the window is a .path window of ego (kin.path_length) ending at the onset, of the
      literal 100 ft where asm.business_or_residence_district holds at the onset and 300 ft where it
      does not. Written as H100 ∧ (asm ∨ H300): the 300 ft window contains the 100 ft one (both end
      at the onset), so this is H100 where the assumption holds, H300 where it fails, and, where it
      is undeclared, decided exactly when the two windows decide alike and unknown otherwise, as the
      record states. A window reaching past the recording's start stays unknown (windowTruncated).
    t9: residue (no weather condition restricts the duty).
  No choice beyond the record's own reading was made: `narrowings` is empty.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_2

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"
def pTurnYawTolerance : Term := .param "p.turn_yaw_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's literals: t4's 100 feet and t6's 300 feet. -/
def last100Feet : Term := .lit (Units.feet 100) .metre
def last300Feet : Term := .lit (Units.feet 300) .metre

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- t8: the change of course, recognized from its observed onset. -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_from_onset" [vEgo]
    [pLeftTurnMinAngle, pTurnYawTolerance, pRestSpeedTolerance, pHeadingSinceStepCarlaSceneGraph]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_from_onset" [vEgo]
    [pRightTurnMinAngle, pTurnYawTolerance, pRestSpeedTolerance, pHeadingSinceStepCarlaSceneGraph]

/-- t8: the turning state whose last rise is the turn's observed onset. -/
def turningLeft : Formula :=
  .derived "drv_motion_turning_left" [vEgo] [pTurnYawTolerance, pRestSpeedTolerance]
def turningRight : Formula :=
  .derived "drv_motion_turning_right" [vEgo] [pTurnYawTolerance, pRestSpeedTolerance]

/-- t1: a signal of intention to turn to `side`: the indicator on that side, or an arm signal meaning it. -/
def signalOf (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vEgo, .lit side] [])
      (.atom "sig_hand_signal" [vEgo, .lit side] [])

/-- t4–t7: the signal given at every observation of the last 100 ft travelled (t5, the district
    declared) or of the last 300 ft (t7, any other area). The 300 ft window contains the 100 ft one. -/
def window (side : String) : Formula :=
  .and (.holdsFor .path last100Feet "ego" (signalOf side))
       (.or (.asm "asm.business_or_residence_district")
            (.holdsFor .path last300Feet "ego" (signalOf side)))

/-- t8 "prior to": the window read at the onset of the turning stretch being recognized. -/
def signalledBefore (turning : Formula) (side : String) : Formula :=
  .since turning (.and (.rises turning) (window side))

/-- Applicability: t4 (condition): not less than the last 100 feet traveled; t5 (condition): in a business or residential district; t6 (condition): and not less than the last 300 feet traveled; t7 (condition): in any other area; t8 (trigger): prior to changing the course of a vehicle.; t9 (condition): This rule shall be observed, regardless of the weather. -/
def applicability : Formula := .or leftTurn rightTurn

/-- Obligation: t1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during -/
def obligation : Formula :=
  .and (.implies leftTurn (signalledBefore turningLeft "left"))
       (.implies rightTurn (signalledBefore turningRight "right"))

def rule : Rule :=
  { id := "NRS_484B_413_2"
    laws := ["NRS-484B-413-2"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district", "asm.business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := ["The duty holds in every weather: no condition of the weather restricts it, so the duty is the same whether or not its words hold."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_2
