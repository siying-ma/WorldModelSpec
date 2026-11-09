/-
  drv.motion.left_turn — The road user has turned to the left: counting from the onset of the turning — the observation at which its rate of change of heading to the left first rose above the onset yaw rate, a rate the caller sets — the heading change accumulated since that onset reaches at least the turn angle, a size the caller sets, to the left. The concept becomes true at the observation at which that angle is first reached, and it holds at the later observations at which the accumulated change still holds that angle, until a later onset starts the count again; the integration is bounded by the heading step, the largest interval between consecutive observations it may integrate across. Where no such onset is observed, with the rate of change of heading known at every observation from the one before it onwards and no interval between consecutive observations longer than the heading step, the concept is unknown and never false, so a turn begun before the recording is never read as one made within it. It states the turning of the body only: no place, no lane, no way and no destination. Not a stand-in for: a signal or a declared intention, a steering input, the curvature of the road — a body yaws on a straight road whenever it manoeuvres — a lane change, or a reversal of the direction of travel, which is a larger angle and has its own concept.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its rate of change of heading to the left first rose above the onset yaw rate: atoms ['kin.yaw_rate'], concepts []
      → `onset`: `kin_yaw_rate u > onset_yaw_rate`. The atom is the rate of change of heading,
        positive to the left, so "to the left ... above the onset yaw rate" is the plain comparison
        of the signed rate with the parameter, strict ("above").
    the heading change accumulated since that onset: atoms ['kin.yaw_rate'], concepts []
      → `headingChange`: `Term.headingSince u heading_step onset`, the signed heading change (left
        positive) of `u` integrated from the same atom since `onset` last rose definitely, counted
        from zero at that onset, with the heading step as the step bound. The body is
        `headingChange ≥ turn_angle`: "reaches at least the turn angle ... to the left".

  The three sentences the contract spends on the extent are the operator's own semantics and need
  nothing further: the comparison becomes true at the observation at which the accumulated change
  first reaches the angle, stays true while it still holds the angle (a later rate of zero adds
  nothing), and restarts at the next definite rise of the onset. Where no onset is observed with
  the onset known at every observation since — a turn already under way at the first observation,
  or an unknown rate that could hide the onset — `headingSince` is unknown, so the comparison is
  unknown and never false; so are a sampling gap wider than the heading step and a missing rate
  since the onset.

  Narrowing (declared in `narrowings` below): the contract's "first rose" is written as the latest
  such rise before the judged observation, which is what the later words "until a later onset
  starts the count again" direct and what `headingSince` takes as its start.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingStep : Term := .param "heading_step"
def pOnsetYawRate : Term := .param "onset_yaw_rate"
def pTurnAngle : Term := .param "turn_angle"

/-- "its rate of change of heading to the left first rose above the onset yaw rate": the onset the
    heading change is counted from, read as the rise of this comparison. -/
def onset : Formula :=
  .cmp (.measure "kin_yaw_rate" [aU]) .gt pOnsetYawRate

/-- "the heading change accumulated since that onset", integrated from the same atom, bounded by
    the heading step. -/
def headingChange : Term :=
  .headingSince "u" pHeadingStep onset

/-- "the heading change accumulated since that onset reaches at least the turn angle ... to the
    left": the accumulated change, left positive, at or above the turn angle. -/
def body : Formula :=
  .cmp headingChange .ge pTurnAngle

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "The road user has turned to the left: counting from the onset of the turning — the observation at which its rate of change of heading to the left first rose above the onset yaw rate, a rate the caller sets — the heading change accumulated since that onset reaches at least the turn angle, a size the caller sets, to the left. The concept becomes true at the observation at which that angle is first reached, and it holds at the later observations at which the accumulated change still holds that angle, until a later onset starts the count again; the integration is bounded by the heading step, the largest interval between consecutive observations it may integrate across. Where no such onset is observed, with the rate of change of heading known at every observation from the one before it onwards and no interval between consecutive observations longer than the heading step, the concept is unknown and never false, so a turn begun before the recording is never read as one made within it. It states the turning of the body only: no place, no lane, no way and no destination. Not a stand-in for: a signal or a declared intention, a steering input, the curvature of the road — a body yaws on a straight road whenever it manoeuvres — a lane change, or a reversal of the direction of travel, which is a larger angle and has its own concept."
    definition := none
    args := [("u", .track)]
    params := [⟨"heading_step", .second⟩, ⟨"onset_yaw_rate", .degreePerSecond⟩, ⟨"turn_angle", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the observation at which its rate of change of heading to the left first rose above the onset yaw rate"
          why := "The onset is read as the latest observation at which `kin.yaw_rate` of the road user rose definitely above the onset yaw rate (false at the observation before, true there), not the first such rise of the recording: the contract's own words \"until a later onset starts the count again\" make the count restart at every later onset, so \"first rose\" is read relative to the judged observation."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn
