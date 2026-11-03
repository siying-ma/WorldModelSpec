/-
  drv.motion.turn_left — The road user has turned to the left at this observation: the signed heading change over the window behind, left positive, integrated from the body's rate of change of heading, is at least min_heading_change. The concept denotes the change of the body's own direction of travel and nothing else: it is not a turn indicator or an arm signal, not an intention or a preparation to turn, not the region the body turns out of or into (which junction, lane or roadway is the caller's to state), and not a judgement that the turn is lawful, permitted or safe. The bound is one-sided above because a turn carried further is still a turn to the left at this observation: a quarter, a half and a whole circle to the left all satisfy it, so a caller that must tell a reversal of direction apart from an ordinary turn states that separately. It is the recognition of the turn and not its whole duration: the observation at which the heading change in the window first reaches the bound is the observation at which the act is recognized, and the later observations at which the window still carries that change are not a further turn. The window is the time over which the heading change is integrated and min_heading_change the magnitude of change to the left at which a turn is told from lane keeping, from following a bend and from the yaw of a lane change.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind, left positive, integrated from the body's rate of change of heading, is at least min_heading_change: atoms ['prim.heading_change'], concepts []

  How the element is written: the span is one comparison, `prim.heading_change u window ≥
  min_heading_change`. The primitive is itself "the signed heading change (degrees, left positive)
  of a road user over the window behind the observation, integrated from kin.yaw_rate", so the sign
  convention, the window behind and the integration are the primitive's and the concept claims no
  kinematic atom beside it; the comparison is `≥`, the bound one-sided above, so a turn carried
  further still satisfies it; and where the primitive cannot form the integral (a truncated window,
  a sampling gap, a missing yaw rate) the comparison is unknown rather than false.

  The reading chosen where the contract left the writing open (declared as a narrowing):
  the contract's sentence on recognition. The body is the defining sentence, so it holds at every
  observation whose window behind carries a change of at least min_heading_change, not at the first
  such observation alone. The contract's "recognition" sentence tells a caller which observation to
  treat as the act — the first, a rising edge of this concept — when it counts turns; it does not
  make the concept false while the turn is still being carried out. A caller that needs the single
  recognizing instant takes `rises` of the call.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turn_left

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinHeadingChange : Term := .param "min_heading_change"

/-- The signed heading change over the window behind, left positive (`prim.heading_change`
    integrates it from the body's yaw rate), is at least `min_heading_change`. One comparison, one
    leaf: the bound is one-sided above, so a quarter, a half and a whole circle to the left all
    satisfy it, and where the primitive cannot form the integral the comparison is unknown. -/
def body : Formula :=
  .cmp (Term.quantity "prim_heading_change" [aU] [pWindow]) .ge pMinHeadingChange

def concept : Concept :=
  { id := "drv.motion.turn_left"
    contract := "The road user has turned to the left at this observation: the signed heading change over the window behind, left positive, integrated from the body's rate of change of heading, is at least min_heading_change. The concept denotes the change of the body's own direction of travel and nothing else: it is not a turn indicator or an arm signal, not an intention or a preparation to turn, not the region the body turns out of or into (which junction, lane or roadway is the caller's to state), and not a judgement that the turn is lawful, permitted or safe. The bound is one-sided above because a turn carried further is still a turn to the left at this observation: a quarter, a half and a whole circle to the left all satisfy it, so a caller that must tell a reversal of direction apart from an ordinary turn states that separately. It is the recognition of the turn and not its whole duration: the observation at which the heading change in the window first reaches the bound is the observation at which the act is recognized, and the later observations at which the window still carries that change are not a further turn. The window is the time over which the heading change is integrated and min_heading_change the magnitude of change to the left at which a turn is told from lane keeping, from following a bend and from the yaw of a lane change."
    definition := none
    args := [("u", .track)]
    params := [⟨"window", .second⟩, ⟨"min_heading_change", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "It is the recognition of the turn and not its whole duration: the observation at which the heading change in the window first reaches the bound is the observation at which the act is recognized, and the later observations at which the window still carries that change are not a further turn"
          why := "The body states the defining sentence — the heading change in the window behind is at least min_heading_change — and so holds at every observation whose window carries that change, not at the first one alone: the contract calls the first such observation the one at which the act is recognized, which is a statement about counting turns (a caller that counts acts counts rising edges of this concept), not a further condition on the observation judged. Written as a rising edge the concept would be false while the turn is still being carried out, which the defining sentence does not say."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.turn_left
