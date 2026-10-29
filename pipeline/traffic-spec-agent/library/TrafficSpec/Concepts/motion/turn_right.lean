/-
  drv.motion.turn_right — The road user has changed its direction of travel to the right: the signed heading change over the recognition window behind the observation, in degrees with left positive and measured in the world frame, is at or below the negative of the turn threshold. The concept denotes the completed change of direction, recognized at the observation at which the accumulated change first reaches the threshold and holding at the later observations whose window still covers it; a change that overshoots, carrying the road user through more than the threshold within the window, is still this change of direction, while one carried out over a span longer than the window is not one manoeuvre and is not denoted. Not a stand-in for: a change of direction to the other side, which is the opposite sense of the same signed quantity and is a concept of its own; a lane change, which shifts the body across the carriageway without such a heading change; the turn indicator or an arm signal, which are what a road user displays rather than what it does; a declared intention to turn; or occupancy of a junction, which a road user crossing straight ahead also has.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the recognition window behind the observation, in degrees with left positive: atoms ['prim.heading_change'], concepts []
      `prim_heading_change u turn_window` is that quantity: the signed heading change of the road
      user (degrees, left positive) integrated from the yaw rate over the window of length
      `turn_window` behind the observation. Its window parameter is the recognition window the
      contract names; it is unknown where the window is truncated, sampled too sparsely, or a yaw
      rate inside it is missing, so an unobserved yaw rate leaves the concept unknown, never false.

  The whole body is one comparison: that signed change is at or below the negative of the turn
  threshold — `.le` for "at or below", and `.neg turn_heading_change` because the parameter carries
  the magnitude of the change and left is positive, so the rightward sense is the negative end of
  the same signed quantity. Nothing else is read: no formal is tested for the sense of the turn, no
  state of motion is required, and no cap bounds an overshoot, since a change through more than the
  threshold within the window is still this change of direction. Equally, nothing of the indicator,
  the hand signal, a declared intention or junction occupancy enters the body — the contract
  excludes each of them. A change carried out over a span longer than the window is not denoted of
  itself: only what the window behind the observation holds is integrated.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turn_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTurnWindow : Term := .param "turn_window"
def pTurnHeadingChange : Term := .param "turn_heading_change"

/-- The signed heading change of the road user (degrees, left positive) over the recognition window
    behind the observation, integrated from the yaw rate. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pTurnWindow]

/-- The signed change is at or below the negative of the turn threshold: with left positive, that
    is the rightward sense carried through at least the threshold within the window. -/
def body : Formula :=
  .cmp headingChange .le (.neg pTurnHeadingChange)

def concept : Concept :=
  { id := "drv.motion.turn_right"
    contract := "The road user has changed its direction of travel to the right: the signed heading change over the recognition window behind the observation, in degrees with left positive and measured in the world frame, is at or below the negative of the turn threshold. The concept denotes the completed change of direction, recognized at the observation at which the accumulated change first reaches the threshold and holding at the later observations whose window still covers it; a change that overshoots, carrying the road user through more than the threshold within the window, is still this change of direction, while one carried out over a span longer than the window is not one manoeuvre and is not denoted. Not a stand-in for: a change of direction to the other side, which is the opposite sense of the same signed quantity and is a concept of its own; a lane change, which shifts the body across the carriageway without such a heading change; the turn indicator or an arm signal, which are what a road user displays rather than what it does; a declared intention to turn; or occupancy of a junction, which a road user crossing straight ahead also has."
    definition := none
    args := [("u", .track)]
    params := [⟨"turn_window", .second⟩, ⟨"turn_heading_change", .degree⟩]
    body := .formula body
    residues := ["The integrated heading change does not tell a turn apart from a bend of the same angle traversed within the window; no atom of the ontology carries the road's alignment along a travelled path."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turn_right
