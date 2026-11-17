/-
  drv.motion.complete_halt — The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance.

  Based on the posted definition `DEF-NRS-484A-255`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “Stop,” when required, means complete cessation from movement.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed (kin.speed) at or below a tolerance: atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Body: `kin_speed a ≤ speed_tol`, a state at the one observation judged; no window, no place, no
  cause. "At or below" is written `.le`, as the contract says. No narrowing was needed.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.complete_halt

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"

/-- "its speed (kin.speed) at or below a tolerance": the sampled speed of `a` at this observation
    is at most `speed_tol`. Unknown where the speed is not observed. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aA]) .le pSpeedTol

def concept : Concept :=
  { id := "drv.motion.complete_halt"
    contract := "The road user is at rest at the observation — \"complete cessation from movement\" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance."
    definition := some "DEF-NRS-484A-255"
    args := [("a", .track)]
    params := [⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := ["the scope of the definition (a stop that a law requires) is decided by the law that calls the concept, not by the state observed"]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.complete_halt
