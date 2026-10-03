/-
  drv.motion.complete_cessation — True of one road user at an observation when its movement has ceased there: its speed is at or below a stated tolerance and has been so throughout a stated hold time ending at the observation. It renders the required sense of a stop, "complete cessation from movement", as an absolute observed over sampled measurements, within the tolerance and the hold time the caller sets. Unit: none - a condition on one road user; frame: ground plane, speed as the magnitude of velocity in the world frame. Not a stand-in for: a deceleration or a lit brake lamp, which are a rate and an actuation and not a cessation; the prohibited sense of stopping, which is any halting even momentarily; a parked or standing vehicle, whose purpose this concept does not read; or the place at which the cessation occurs, which the calling rule states on its own span.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed is at or below a stated tolerance: atoms ['kin.speed'], concepts []
    has been so throughout a stated hold time ending at the observation: atoms ['kin.speed'], concepts []

  How the two elements are written.
    "its speed is at or below a stated tolerance" is `kin_speed a ≤ stop_speed_tolerance`: the
    measured magnitude of velocity held against the caller's bound, non-strictly, because the
    contract says "at or below".
    "has been so throughout a stated hold time ending at the observation" is the window operator
    `holdsFor .time stop_hold_time` over that same comparison. The window is the formula language's
    own; it reads no atom, so `kin.time` is not claimed. `holdsFor` includes the observation itself
    among the observations of the window it ranges over, so the first element is not a second
    conjunct: the whole body is the one comparison under the one window, and the body is true at an
    observation exactly when every sampled measurement in the hold time behind it, that observation
    included, is within the tolerance.

  Narrowings (readings the contract leaves open).
    "throughout a stated hold time ending at the observation" — read as the *time* measure, not the
    path measure. A cessation from movement is a dwell in time; a path window of a body that has
    ceased to move would never advance and could not end. Declared in `narrowings` below.
    The same span carries the sampling policy Core fixes for every window: the body is unknown, not
    false, where the trace does not reach a whole hold time back, and where the observations inside
    the window are more than half a hold time apart. That is Core's finite-trace policy ("unobserved
    is unknown"), not a choice of this file, and so is not declared a narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.complete_cessation

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pStopSpeedTolerance : Term := .param "stop_speed_tolerance"
private def pStopHoldTime : Term := .param "stop_hold_time"

/-- "its speed is at or below a stated tolerance": the measured speed of `a` against the bound. -/
private def withinTolerance : Formula :=
  .cmp (.measure "kin_speed" [aA]) .le pStopSpeedTolerance

/-- "… and has been so throughout a stated hold time ending at the observation": that same
    comparison at every observation of the time window of length `stop_hold_time` behind the
    observation, the observation itself included. -/
private def body : Formula :=
  .holdsFor .time pStopHoldTime "a" withinTolerance

def concept : Concept :=
  { id := "drv.motion.complete_cessation"
    contract := "True of one road user at an observation when its movement has ceased there: its speed is at or below a stated tolerance and has been so throughout a stated hold time ending at the observation. It renders the required sense of a stop, \"complete cessation from movement\", as an absolute observed over sampled measurements, within the tolerance and the hold time the caller sets. Unit: none - a condition on one road user; frame: ground plane, speed as the magnitude of velocity in the world frame. Not a stand-in for: a deceleration or a lit brake lamp, which are a rate and an actuation and not a cessation; the prohibited sense of stopping, which is any halting even momentarily; a parked or standing vehicle, whose purpose this concept does not read; or the place at which the cessation occurs, which the calling rule states on its own span."
    definition := some "DEF-NRS-484A-255"
    args := [("a", .track)]
    params := [⟨"stop_speed_tolerance", .metrePerSecond⟩, ⟨"stop_hold_time", .second⟩]
    body := .formula body
    residues := ["The definition's qualifier selects which statutory duty the word 'stop' carries in a given line. The concept states the physical cessation and leaves that selection to the rule that calls it; the prohibited sense, NRS 484A.260's 'any halting, even momentarily, of a vehicle', is a different notion and is not this concept."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ ⟨"has been so throughout a stated hold time ending at the observation",
         "The hold is read as a window in time, not in path travelled: a cessation from movement is a dwell of a stated duration, and a path window of a body whose movement has ceased would not advance and so could never close. The caller's `stop_hold_time` is therefore seconds."⟩ ]
    supersedes := none }

end TrafficSpec.Concepts.motion.complete_cessation
