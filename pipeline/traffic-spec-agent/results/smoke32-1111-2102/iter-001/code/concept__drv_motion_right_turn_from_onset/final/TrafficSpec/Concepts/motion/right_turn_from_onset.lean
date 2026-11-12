/-
  drv.motion.right_turn_from_onset — Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true: atoms [], concepts ['drv.motion.turning_right']
    the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound: atoms ['kin.yaw_rate'], concepts []

  The body is the conjunction, at the observation judged, of drv_motion_turning_right(a; yaw_tolerance,
  speed_tolerance) and the rise of the comparison headingSince(a, step, turning_right) ≤ −turn_angle.
  - Onset: headingSince counts from the latest definite rise of turning_right (false before, true
    there), with turning_right known at every observation since; where that rise is not observed
    (the stretch began before the recording, or an unknown turning state could hide it) the heading
    change, and so the concept, is unknown.
  - The continuous stretch: turning_right true here, with its last rise observed and no unknown
    value since, is turning_right true at every observation since that rise (a false value in
    between would make a later rise, which would be the onset), so "holding at every observation
    since the observation at which it last became true" is the conjunct turning_right here together
    with a decided heading change.
  - Recognition, "first reaches": `rises` of the comparison, true where the heading change is at or
    below −turn_angle here and was not at the observation before. Within one stretch the heading
    change only decreases (the yaw rate is at or below −yaw_tolerance at every observation of it),
    and it is zero at the onset, so the observation before a recognition lies in the same stretch
    and the rise is the first observation that reaches the angle. The concept holds there only.
  - A stretch that ends short of the angle never makes the comparison true while turning_right
    holds: no turn. No road geometry, turn indicator or intention is read, so a bend followed
    through the angle counts.
  No choice beyond the contract's words was made.

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

/-- a is turning to the right (drv.motion.turning_right with the yaw tolerance and the speed tolerance). -/
def turning : Formula := .derived "drv_motion_turning_right" [aA] [pYawTolerance, pSpeedTolerance]

/-- The heading change of a (kin.yaw_rate integrated, degrees, left positive, with the step bound)
    since `turning` last became true: zero at that observation, unknown where that rise is not
    observed with `turning` known at every observation since. -/
def headingChange : Term := .headingSince "a" pStep turning

/-- The heading change since the onset is at or below the negative of the turn angle. -/
def reached : Formula := .cmp headingChange .le (.neg pTurnAngle)

/-- a is turning to the right here, and the heading change since the last rise of that state
    reaches the negative of the turn angle here and had not at the observation before. -/
def body : Formula :=
  .and turning (.rises reached)

def concept : Concept :=
  { id := "drv.motion.right_turn_from_onset"
    contract := "Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle."
    definition := none
    args := [("a", .track)]
    params := [⟨"turn_angle", .degree⟩, ⟨"yaw_tolerance", .degreePerSecond⟩, ⟨"speed_tolerance", .metrePerSecond⟩, ⟨"step", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.right_turn_from_onset
