/-
  drv.motion.turn_left — The road user has changed its direction of travel to the left: the signed heading change over the recognition window behind the observation, in degrees with left positive and measured in the world frame, is at or above the turn threshold. The concept denotes the completed change of direction, recognized at the observation at which the accumulated change first reaches the threshold and holding at the later observations whose window still covers it; a change that overshoots, carrying the road user through more than the threshold within the window, is still this change of direction, while one carried out over a span longer than the window is not one manoeuvre and is not denoted. Not a stand-in for: a change of direction to the other side, which is the opposite sense of the same signed quantity and is a concept of its own; a lane change, which shifts the body across the carriageway without such a heading change; the turn indicator or an arm signal, which are what a road user displays rather than what it does; a declared intention to turn; or occupancy of a junction, which a road user crossing straight ahead also has.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the recognition window behind the observation, in degrees with left positive: atoms ['prim.heading_change'], concepts []
      `prim_heading_change u turn_window` is that quantity: the signed heading change in degrees,
      left positive, integrated from the yaw rate over the window of length `turn_window` behind
      the observation. The recognition window of the contract is the primitive's window, so the
      formal parameter `turn_window` is passed as the primitive's one parameter; nothing else is
      read, and the primitive's own inputs (the yaw rate, the sampling of the trace) are not
      claimed again here.

  The whole body is one comparison of that quantity with the threshold:
    prim_heading_change(u, turn_window) ≥ turn_heading_change.
  Nothing in it is a choice the contract left open, so no narrowing is declared:
    - "at or above the turn threshold" is `.ge`, the non-strict comparison, including the
      observation at which the accumulated change exactly reaches the threshold;
    - the comparison is on the signed quantity, not on its magnitude, because the contract fixes
      the sign convention ("left positive") and names the change to the other side as a concept of
      its own: a change to the right is a negative value and fails the comparison, with no test of
      any formal needed;
    - an overshoot is a larger value within the same window and holds by the same comparison; a
      change spread over a span longer than the window never accumulates to the threshold inside
      the window, and so is not denoted — both come from the window, not from an added test;
    - "recognized at the observation at which the accumulated change first reaches the threshold
      and holding at the later observations whose window still covers it" is what a comparison
      evaluated at each observation already says, so no temporal operator is written around it;
    - where the window is truncated, sampled too sparsely or a yaw rate is missing the primitive is
      unknown, and the comparison is then unknown rather than false.
  Nothing of the turn indicator, a hand signal, a declared intention or occupancy of a junction is
  read: the contract excludes each of them.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turn_left

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTurnWindow : Term := .param "turn_window"
def pTurnHeadingChange : Term := .param "turn_heading_change"

/-- The signed heading change of the road user, in degrees with left positive, integrated over the
    recognition window behind the observation: the window's length is the formal parameter. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pTurnWindow]

/-- The change of direction is recognized where that signed change is at or above the threshold. -/
def body : Formula := .cmp headingChange .ge pTurnHeadingChange

def concept : Concept :=
  { id := "drv.motion.turn_left"
    contract := "The road user has changed its direction of travel to the left: the signed heading change over the recognition window behind the observation, in degrees with left positive and measured in the world frame, is at or above the turn threshold. The concept denotes the completed change of direction, recognized at the observation at which the accumulated change first reaches the threshold and holding at the later observations whose window still covers it; a change that overshoots, carrying the road user through more than the threshold within the window, is still this change of direction, while one carried out over a span longer than the window is not one manoeuvre and is not denoted. Not a stand-in for: a change of direction to the other side, which is the opposite sense of the same signed quantity and is a concept of its own; a lane change, which shifts the body across the carriageway without such a heading change; the turn indicator or an arm signal, which are what a road user displays rather than what it does; a declared intention to turn; or occupancy of a junction, which a road user crossing straight ahead also has."
    definition := none
    args := [("u", .track)]
    params := [⟨"turn_window", .second⟩, ⟨"turn_heading_change", .degree⟩]
    body := .formula body
    residues := ["The integrated heading change does not tell a turn apart from a bend of the same angle traversed within the window; no atom of the ontology carries the road's alignment along a travelled path."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- none: the contract dictates the one comparison this body writes (header)
    supersedes := none }

end TrafficSpec.Concepts.motion.turn_left
