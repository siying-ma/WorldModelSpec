/-
  drv.motion.halted — A road user is at a standstill at the observation. This is the corpus definition of a required stop, "complete cessation from movement", observed on sampled speeds: the road user's speed (kin.speed, m/s) is at or below speed_floor, the source's speed resolution, below which a reading counts as no movement. The state holds at each observation at which the speed is that low, with no minimum duration. Not denoted: where the road user stands, why it stands, or whether its engine runs or a brake is set.

  Based on the posted definition `DEF-NRS-484A-255`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “Stop,” when required, means complete cessation from movement.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user's speed (kin.speed, m/s) is at or below speed_floor: atoms ['kin.speed'], concepts []
      written `kin_speed x ≤ speed_floor` (`.cmp … .le …`), judged at the observation alone: the
      contract states no minimum duration, so no time operator surrounds it. An unobserved speed
      leaves the comparison unknown.

  Choices the contract left open: none (no narrowing).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.halted

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"

/-- The road user's speed is at or below the speed floor, at this observation; no duration. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aX]) .le pSpeedFloor

def concept : Concept :=
  { id := "drv.motion.halted"
    contract := "A road user is at a standstill at the observation. This is the corpus definition of a required stop, \"complete cessation from movement\", observed on sampled speeds: the road user's speed (kin.speed, m/s) is at or below speed_floor, the source's speed resolution, below which a reading counts as no movement. The state holds at each observation at which the speed is that low, with no minimum duration. Not denoted: where the road user stands, why it stands, or whether its engine runs or a brake is set."
    definition := some "DEF-NRS-484A-255"
    args := [("x", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := ["The definition's scope words ('when required') say which duties it serves; the caller is the duty that requires the stop, so the concept carries no condition for them."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.halted
