/-
  drv.motion.right_turn_from_onset — Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle: at the beginning itself where the heading change there, which is zero, already reaches it, and otherwise at the first later observation of the same stretch at which it does. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, a heading change accumulated over an earlier stretch included, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true: atoms [], concepts ['drv.motion.turning_right']
    the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across): atoms ['kin.yaw_rate', 'kin.time'], concepts []

  The body is the rising edge, at the observation judged, of the conjunction of
  drv.motion.turning_right(a) (with the yaw tolerance and the speed tolerance) and the comparison
  headingSince(a, step, turning_right(a)) ≤ −turn_angle. turning_right true here means it has held
  at every observation since it last became true (that rise starts the current run), and
  headingSince counts the heading change from that same rise (zero there; its integration reads
  kin.yaw_rate and the intervals between the kin.time instants, bounded by the step), so the
  conjunction is "the stretch is under way and its heading change has reached the negative of the
  turn angle". Its rise is the recognition observation: at the onset itself when zero already
  reaches −turn_angle (turning_right was false the observation before, so the conjunction was),
  otherwise at the first later observation of the same stretch at which the change reaches it.
  So the concept holds there only. A heading change of an earlier stretch is not counted: the next
  definite rise of turning_right restarts headingSince from zero. Where the onset is not observed
  (the run reaches the trace start, or an unknown turning state hides it) or a yaw rate since it
  is missing, headingSince is unknown and so is the concept. A stretch that ends before the angle
  is reached makes the conjunction false throughout: no turn. No choice beyond the contract's words
  was made.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.right_turn_from_onset

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTurnAngle : Term := .param "turn_angle"
def pYawTolerance : Term := .param "yaw_tolerance"
def pSpeedTolerance : Term := .param "speed_tolerance"
def pStep : Term := .param "step"

/-- The road user moves and its heading turns to the right (with the yaw and speed tolerances). -/
def turningRight : Formula :=
  .derived "drv_motion_turning_right" [aA] [pYawTolerance, pSpeedTolerance]

/-- The heading change of the road user (degrees, left positive) since turning_right last became
    true, integrated from its yaw rate across intervals no longer than the step bound. -/
def headingChange : Term := .headingSince "a" pStep turningRight

/-- The stretch is under way and its heading change has reached the negative of the turn angle
    here, and not at the observation before: the recognition observation. -/
def body : Formula :=
  .rises (.and turningRight (.cmp headingChange .le (.neg pTurnAngle)))

def concept : Concept :=
  { id := "drv.motion.right_turn_from_onset"
    contract := "Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle: at the beginning itself where the heading change there, which is zero, already reaches it, and otherwise at the first later observation of the same stretch at which it does. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, a heading change accumulated over an earlier stretch included, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle."
    definition := none
    args := [("a", .track)]
    params := [⟨"turn_angle", .degree⟩, ⟨"yaw_tolerance", .degreePerSecond⟩, ⟨"speed_tolerance", .metrePerSecond⟩, ⟨"step", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.right_turn_from_onset
