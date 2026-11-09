/-
  drv.motion.standstill — The road user is motionless at the observation: the magnitude of its velocity is at most the speed tolerance, a speed the caller sets, so that a sampled reading at or below it is read as no movement at all. The definition this contract carries requires a “complete cessation from movement”, and because speed is sampled and measured with error, the tolerance is the bound within which a reading is read as that cessation; it is the contract's own magnitude and never a figure. The concept states the motion state at the observation and nothing else. Not a stand-in for: a halt of any duration or a halt repeated over a window, a vehicle standing, parked or waiting, the engine being off or a brake being applied, or a halt at a place a law names — it carries no place, no duration and no control state.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity is at most the speed tolerance: atoms ['kin.speed'], concepts []
      Written as one comparison: `kin_speed u ≤ speed_tolerance`. `kin.speed` is the magnitude of the
      road user's velocity in m/s, which is the quantity the definition's “complete cessation from
      movement” bounds; `at most` is a non-strict bound, so a reading exactly at the tolerance is
      read as that cessation, as the contract says of “a sampled reading at or below it”.
      `kin.velocity` is not read: the contract speaks of movement, not of its direction.

  The body states the motion state at the judged observation alone: no window operator, no place,
  no duration, no control state (`kin.engine_running`, `kin.parking_brake`, `kin.service_brake` and
  `rel.occupies` are deliberately unread — the contract excludes them). Where the speed of `u` is
  unobserved the comparison is unknown, never false.

  No reading was chosen that the contract leaves open, so `narrowings` is empty: the contract fixes
  the quantity (the magnitude of velocity), the direction of the bound (at most) and its source (the
  caller's parameter).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.standstill

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The magnitude of `u`'s velocity is at most the speed tolerance, at the judged observation. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aU]) .le pSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.standstill"
    contract := "The road user is motionless at the observation: the magnitude of its velocity is at most the speed tolerance, a speed the caller sets, so that a sampled reading at or below it is read as no movement at all. The definition this contract carries requires a “complete cessation from movement”, and because speed is sampled and measured with error, the tolerance is the bound within which a reading is read as that cessation; it is the contract's own magnitude and never a figure. The concept states the motion state at the observation and nothing else. Not a stand-in for: a halt of any duration or a halt repeated over a window, a vehicle standing, parked or waiting, the engine being off or a brake being applied, or a halt at a place a law names — it carries no place, no duration and no control state."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["The definition's scope clause tells which of the two posted definitions of the word applies to a given law — the one for a stop that is required rather than prohibited. It is a rule of application, not a condition of the scene, and no observation decides it."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.standstill
