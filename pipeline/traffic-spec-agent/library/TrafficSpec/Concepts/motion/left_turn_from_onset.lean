/-
  drv.motion.left_turn_from_onset — Road user a turns to the left from an observed onset: over one continuous stretch in which it moves and its heading turns to the left, its heading changes to the left by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_left (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or above the turn angle. The act's observed beginning is the observation at which drv.motion.turning_left last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the turn angle. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays below the turn angle.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    drv.motion.turning_left (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true: atoms [], concepts ['drv.motion.turning_left']
    the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound: atoms ['kin.yaw_rate'], concepts []

  The body is the rising edge, at the observation judged, of the conjunction of
  drv.motion.turning_left(a) (with the yaw tolerance and the speed tolerance) and the comparison
  headingSince(a, step, turning_left(a)) ≥ turn_angle. turning_left true here means it has held at
  every observation since it last became true (that rise starts the current run), and headingSince
  counts the heading change from that same rise, so the conjunction is "the stretch is under way and
  its heading change has reached the turn angle". Its rise is the observation at which the heading
  change first reaches the turn angle within the stretch: the observation before has either the
  stretch not under way or a heading change below the angle. So the concept holds at the
  recognition observation only. Where the onset is not observed (the run reaches the trace start, or
  an unknown turning state hides it) or a yaw rate since it is missing, headingSince is unknown and
  so is the concept. A stretch that ends before the angle is reached makes the conjunction false
  throughout: no turn. No choice beyond the contract's words was made.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn_from_onset

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTurnAngle : Term := .param "turn_angle"
def pYawTolerance : Term := .param "yaw_tolerance"
def pSpeedTolerance : Term := .param "speed_tolerance"
def pStep : Term := .param "step"

/-- The road user moves and its heading turns to the left (with the yaw and speed tolerances). -/
def turningLeft : Formula :=
  .derived "drv_motion_turning_left" [aA] [pYawTolerance, pSpeedTolerance]

/-- The heading change of the road user since turning_left last became true, with the step bound. -/
def headingChange : Term := .headingSince "a" pStep turningLeft

/-- The stretch is under way and its heading change has reached the turn angle here, and not at the
    observation before: the recognition observation. -/
def body : Formula :=
  .rises (.and turningLeft (.cmp headingChange .ge pTurnAngle))

def concept : Concept :=
  { id := "drv.motion.left_turn_from_onset"
    contract := "Road user a turns to the left from an observed onset: over one continuous stretch in which it moves and its heading turns to the left, its heading changes to the left by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_left (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or above the turn angle. The act's observed beginning is the observation at which drv.motion.turning_left last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the turn angle. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays below the turn angle."
    definition := none
    args := [("a", .track)]
    params := [⟨"turn_angle", .degree⟩, ⟨"yaw_tolerance", .degreePerSecond⟩, ⟨"speed_tolerance", .metrePerSecond⟩, ⟨"step", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn_from_onset
