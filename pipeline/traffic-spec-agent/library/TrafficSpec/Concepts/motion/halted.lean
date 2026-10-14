/-
  drv.motion.halted — The road user is not moving at the observation: the magnitude of its velocity is at or below the tolerance the caller sets. This is the observation, over sampled measurements, of “complete cessation from movement”, the absolute the definition states; the tolerance is the observer's, and it is what makes the absolute readable on a sampled track. Unit of the parameter: m/s. Not a stand-in for: a halt of some duration — the concept decides one observation and holds nothing for a dwell; the brake lamp or the service-brake input, which are what others see and what a driver does, not what the body does; or the halting that a prohibition on stopping forbids, which DEF-NRS-484A-260 defines separately as any halting, even momentarily.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity is at or below the tolerance: atoms ['kin.speed'], concepts []
      `kin_speed user` is the magnitude of the velocity in m/s; the comparison is `≤` against the
      formal parameter `speed_tolerance`, because the contract says "at or below", so a reading
      exactly at the tolerance counts as no movement. Nothing else is read: the body is one
      comparison at the observation, so it holds nothing for a dwell, and it reads neither
      `sig.brake_lamp` nor `kin.service_brake`.
      Where `kin.speed` is unobserved the comparison is unknown, not false: a body whose speed was
      not measured is not thereby moving.

  No magnitude below is this file's own: parameters are formals the caller fills.
  No narrowing: the contract names the quantity ("the magnitude of its velocity"), the bound
  ("the tolerance the caller sets") and the strictness ("at or below"); nothing is left open.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.halted

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The magnitude of the user's velocity at the observation is at or below the tolerance. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aUser]) .le pSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.halted"
    contract := "The road user is not moving at the observation: the magnitude of its velocity is at or below the tolerance the caller sets. This is the observation, over sampled measurements, of “complete cessation from movement”, the absolute the definition states; the tolerance is the observer's, and it is what makes the absolute readable on a sampled track. Unit of the parameter: m/s. Not a stand-in for: a halt of some duration — the concept decides one observation and holds nothing for a dwell; the brake lamp or the service-brake input, which are what others see and what a driver does, not what the body does; or the halting that a prohibition on stopping forbids, which DEF-NRS-484A-260 defines separately as any halting, even momentarily."
    definition := some "DEF-NRS-484A-255"
    args := [("user", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["the definition's scoping phrase: it says when the word is read this way, not what the state is. The rule that requires a stop supplies the occasion, and the concept carries only the state of motion."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.halted
