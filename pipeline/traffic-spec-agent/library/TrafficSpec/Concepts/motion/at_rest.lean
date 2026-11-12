/-
  drv.motion.at_rest — A road user is at rest at an observation: the observable form of a stop where one is required, "complete cessation from movement". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations.

  Based on the posted definition `DEF-NRS-484A-255`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “Stop,” when required, means complete cessation from movement.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user's speed (kin.speed, m/s) is at or below the speed tolerance: atoms ['kin.speed'], concepts []

  The body is the single comparison kin_speed(a) ≤ speed_tolerance at the observation judged; it
  reads no brake lamp or brake input and no place. No choice beyond the contract's words was made.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.at_rest

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The road user's speed is at or below the speed tolerance at this observation. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aA]) .le pSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.at_rest"
    contract := "A road user is at rest at an observation: the observable form of a stop where one is required, \"complete cessation from movement\". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations."
    definition := some "DEF-NRS-484A-255"
    args := [("a", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["The definition's 'when required' names the occasion a calling rule fixes (where and before what the stop is owed), not a property of the motion."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.at_rest
