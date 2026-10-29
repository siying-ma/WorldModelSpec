/-
  drv.motion.standstill — The road user is at rest at the observation: it shows "complete cessation from movement", which is recognized as a measured speed at or below the standstill tolerance, the bound within which a sampled speed counts as no movement. The concept denotes the state at one observation, read on the road user's own motion in the world frame; it says nothing of how long the rest lasts. Not a stand-in for: a halt required by a device or a line, which is the calling rule's business; a lit brake lamp, which is an actuation others see; a stopped engine; or a vehicle standing or parked for a purpose, which no motion measurement tells apart from any other rest.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a measured speed at or below the standstill tolerance: atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing. "a measured speed at or below the standstill tolerance" is `kin_speed u` compared to the
  formal parameter `standstill_speed_tolerance` with `le`: the contract's "at or below" is the
  non-strict comparison, so a sampled speed exactly at the tolerance counts as no movement. Nothing
  else is read: the state is at the one observation (no temporal operator), on the road user's own
  motion (the only argument position is the formal `u`), and the tolerance is the caller's figure.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.standstill

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStandstillSpeedTolerance : Term := .param "standstill_speed_tolerance"

/-- The road user's measured speed is at or below the standstill tolerance. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aU]) .le pStandstillSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.standstill"
    contract := "The road user is at rest at the observation: it shows \"complete cessation from movement\", which is recognized as a measured speed at or below the standstill tolerance, the bound within which a sampled speed counts as no movement. The concept denotes the state at one observation, read on the road user's own motion in the world frame; it says nothing of how long the rest lasts. Not a stand-in for: a halt required by a device or a line, which is the calling rule's business; a lit brake lamp, which is an actuation others see; a stopped engine; or a vehicle standing or parked for a purpose, which no motion measurement tells apart from any other rest."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"standstill_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["The definition's scope clause: which halts the word governs is decided by the law that calls the concept, not by the concept, and the companion definition DEF-NRS-484A-260 covers the prohibited sense."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.standstill
