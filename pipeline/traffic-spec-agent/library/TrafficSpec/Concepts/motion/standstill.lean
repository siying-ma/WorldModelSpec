/-
  drv.motion.standstill — The road user's body is not moving at the observation: it has come to rest. The corpus definition this contract quotes requires "complete cessation from movement", and over sampled measurements an absolute rest is observed only within a bound the caller sets, so the concept holds at an observation where the measured speed of the road user is at or below the parameter speed_max, which is that bound and nothing more. The concept is read at the observation itself, not over a window: it states rest here, not a halt of any duration. Not a stand-in for: a halt of a required duration, a parked or standing vehicle, the reason the road user is at rest, a brake input or a brake lamp, or a place at which the rest occurred -- the place is the caller's.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the measured speed of the road user is at or below the parameter speed_max: atoms ['kin.speed'], concepts []
      written `kin_speed(u) ≤ speed_max`: the atom is the "magnitude of velocity" of the road user in
      m/s, read at the judged observation, and the comparison is `.le` because the contract's words
      are "at or below", so the bound itself counts as rest. Nothing else stands in the body: the
      contract states rest here and nothing more -- no window, no duration, no brake, no place -- so
      the body is this one comparison and carries no temporal operator and no other atom. Where the
      atom is unobserved the comparison is unknown, which is what the contract's "measured speed"
      requires: unobserved rest is not motion.

  Nothing the contract leaves open had to be chosen: "at or below the parameter speed_max" fixes the
  operator and the bound, and "at the observation" fixes the absence of a window. `narrowings` is
  therefore empty.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.standstill

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedMax : Term := .param "speed_max"

/-- The measured speed of the road user at the observation, in m/s. -/
def speedOfU : Term := .measure "kin_speed" [aU]

/-- Rest at the observation: the measured speed is at or below the caller's resolution for rest. -/
def body : Formula := .cmp speedOfU .le pSpeedMax

def concept : Concept :=
  { id := "drv.motion.standstill"
    contract := "The road user's body is not moving at the observation: it has come to rest. The corpus definition this contract quotes requires \"complete cessation from movement\", and over sampled measurements an absolute rest is observed only within a bound the caller sets, so the concept holds at an observation where the measured speed of the road user is at or below the parameter speed_max, which is that bound and nothing more. The concept is read at the observation itself, not over a window: it states rest here, not a halt of any duration. Not a stand-in for: a halt of a required duration, a parked or standing vehicle, the reason the road user is at rest, a brake input or a brake lamp, or a place at which the rest occurred -- the place is the caller's."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"speed_max", .metrePerSecond⟩]
    body := .formula body
    residues := ["the definition's scope clause says which laws use this sense of the word rather than stating a fact of the scene; it is a condition on the law that calls the concept, and the caller carries it by calling this concept only where a stop is required."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.standstill
