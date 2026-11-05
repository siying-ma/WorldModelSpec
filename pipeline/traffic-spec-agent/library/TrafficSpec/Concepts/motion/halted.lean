/-
  drv.motion.halted — The road user's body is not moving at this observation: it stands still rather than travels. The state is read at the observation itself, from the magnitude of the road user's speed being at or below the tolerance, the reading below which a speed counts as no travel rather than movement; the tolerance is the concept's own magnitude because a speed is observed over sampled measurements only within a bound the caller sets, and a body at rest reads as a small positive speed. The bound is one-sided: the slower the reading, the more plainly the body stands still. The concept denotes the momentary absence of movement only: it is not a duration of standing, not a halt at any particular place, not the reason the body is at rest, not a lamp, a brake input or a gear, and not the lawfulness of stopping where it stands.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    The road user's body is not moving at this observation: atoms ['kin.speed'], concepts []
      written `.cmp (.measure "kin_speed" [aU]) .le pHaltSpeedTolerance`: kin.speed is the
      'magnitude of velocity' (m/s) of the road user, read at the judged observation itself — no
      window, no lookback, no `sinceRise`, because the contract states the state is read at the
      observation and excludes 'a duration of standing'. The comparison is the contract's own
      one-sided bound, 'at or below the tolerance', the tolerance being the formal parameter
      `halt_speed_tolerance` and no figure of this file's. Nothing else is read: no place (no
      region and no occupancy), no reason (kin.engine_running, kin.parking_brake, kin.gear,
      kin.throttle, kin.service_brake), no lamp (sig.brake_lamp), and no rule — each of these the
      contract excludes by name.

  Narrowings (choices the contract did not dictate):
    "the magnitude of the road user's speed" — written as the bare `kin_speed` reading with no
      `Term.abs` around it: the atom's contract is already 'magnitude of velocity', so the
      reading is non-negative by its own denotation and an absolute value would add nothing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.halted

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "halt_speed_tolerance"

/-- The magnitude of the road user's velocity at this observation, in m/s. -/
def speed : Term := .measure "kin_speed" [aU]

/-- The body is not moving at this observation: the magnitude of its speed is at or below the
    tolerance, the reading below which a speed counts as no travel rather than movement. The
    bound is one-sided and inclusive, as the contract's 'at or below' states. -/
def body : Formula := .cmp speed .le pHaltSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.halted"
    contract := "The road user's body is not moving at this observation: it stands still rather than travels. The state is read at the observation itself, from the magnitude of the road user's speed being at or below the tolerance, the reading below which a speed counts as no travel rather than movement; the tolerance is the concept's own magnitude because a speed is observed over sampled measurements only within a bound the caller sets, and a body at rest reads as a small positive speed. The bound is one-sided: the slower the reading, the more plainly the body stands still. The concept denotes the momentary absence of movement only: it is not a duration of standing, not a halt at any particular place, not the reason the body is at rest, not a lamp, a brake input or a gear, and not the lawfulness of stopping where it stands."
    definition := none
    args := [("u", .track)]
    params := [⟨"halt_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the magnitude of the road user's speed"
          why := "Written as the bare `kin_speed` reading of the road user, with no `Term.abs` around it. The atom's contract is 'magnitude of velocity', so the reading is already the magnitude the contract asks for and is non-negative by its own denotation; an absolute value would decide nothing the reading does not. The comparison itself is the contract's stated one-sided, inclusive bound ('at or below the tolerance'), so `.le`."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.halted
