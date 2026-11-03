/-
  drv.motion.in_motion — The road user's body is moving at the observation: its measured speed is at least the parameter speed_floor, which is the resolution below which a measured speed is indistinguishable from sensor noise at rest and nothing more — the parameter states when a reading counts as motion at all, never how fast is fast enough for any purpose. The concept is read at the observation itself, not over a window: it states motion here, and says nothing about how long the road user has been moving, where it is moving or in which direction. Where the speed is unobserved it is unknown. Not a stand-in for: a direction of travel, forward or rearward, a speed above any bound, a manoeuvre, the place the motion happens at or the region occupied, a throttle or a brake input, or the negation of a halt of a required duration — a road user at rest for an instant between two movements is not moving at that observation, and that is all this concept says of it.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its measured speed is at least the parameter speed_floor: atoms ['kin.speed'], concepts []
      written `.cmp (.measure "kin_speed" [u]) .ge (.param "speed_floor")`: the measured speed of the
      formal road user `u`, compared with the formal parameter. "at least" is the weak comparison
      `.ge`, so a reading exactly at the floor counts as motion. Where `kin.speed` is unobserved the
      comparison is unknown, which is what the contract asks for.

  The whole body is that one comparison: it is read at the observation the caller judges, with no
  temporal operator, no window and no lookback, as the contract's "read at the observation itself,
  not over a window" requires; nothing of direction, place, region, throttle or brake enters it, and
  no duration of rest is negated.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.in_motion

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"

/-- The road user's measured speed is at least the floor the caller passes. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aU]) .ge pSpeedFloor

def concept : Concept :=
  { id := "drv.motion.in_motion"
    contract := "The road user's body is moving at the observation: its measured speed is at least the parameter speed_floor, which is the resolution below which a measured speed is indistinguishable from sensor noise at rest and nothing more — the parameter states when a reading counts as motion at all, never how fast is fast enough for any purpose. The concept is read at the observation itself, not over a window: it states motion here, and says nothing about how long the road user has been moving, where it is moving or in which direction. Where the speed is unobserved it is unknown. Not a stand-in for: a direction of travel, forward or rearward, a speed above any bound, a manoeuvre, the place the motion happens at or the region occupied, a throttle or a brake input, or the negation of a halt of a required duration — a road user at rest for an instant between two movements is not moving at that observation, and that is all this concept says of it."
    definition := none
    args := [("u", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.in_motion
