/-
  drv.motion.turn_right — The road user has turned to the right at this observation: the signed heading change over the window behind, left positive so that a change to the right is negative, integrated from the body's rate of change of heading, is at most the negative of min_heading_change. The concept denotes the change of the body's own direction of travel and nothing else: it is not a turn indicator or an arm signal, not an intention or a preparation to turn, not the region the body turns out of or into (which junction, lane or roadway is the caller's to state), and not a judgement that the turn is lawful, permitted or safe. The bound is one-sided because a turn carried further is still a turn to the right at this observation: a quarter, a half and a whole circle to the right all satisfy it. It is the recognition of the turn and not its whole duration: the observation at which the heading change in the window first reaches the bound is the observation at which the act is recognized, and the later observations at which the window still carries that change are not a further turn. The window is the time over which the heading change is integrated and min_heading_change the magnitude of change to the right at which a turn is told from lane keeping, from following a bend and from the yaw of a lane change.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind, left positive so that a change to the right is negative, integrated from the body's rate of change of heading: atoms ['prim.heading_change'], concepts []

  How the element is written. `prim.heading_change` is the signed heading change in degrees over the
  back window, left positive, integrated from `kin.yaw_rate`; it takes the window length as its
  only parameter and the road user as its only argument. The contract's "a change to the right is
  negative" is that same convention, so "at most the negative of min_heading_change" is the single
  comparison `heading_change ≤ −min_heading_change`: one-sided, so a quarter, a half and a whole
  circle to the right all satisfy it, and no absolute value and no lower bound appear. The body
  reads no region, no indicator and no lane: the junction the body turns out of or into is the
  caller's to state.

  Narrowing. The contract says the act is recognized at the observation where the window's change
  first reaches the bound, and that the later observations carrying the same change are not a
  further turn. That is written as the plain bound at this observation, not as `rises`: the
  contract's first sentence states the concept as what holds "at this observation", and a caller
  that needs the single act counts rising edges of the call (`count`) rather than being handed an
  edge it cannot re-use. Were the edge built into the body, a caller asking whether the body has
  turned right at an observation one instant after the recognition would be told no.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turn_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinHeadingChange : Term := .param "min_heading_change"

/-- The signed heading change of the body over the window behind this observation, in degrees and
    left positive, integrated from its rate of change of heading. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pWindow]

/-- The change over the window behind is at most the negative of `min_heading_change`: a change of
    that magnitude to the right, or more. -/
def body : Formula := .cmp headingChange .le (.neg pMinHeadingChange)

def concept : Concept :=
  { id := "drv.motion.turn_right"
    contract := "The road user has turned to the right at this observation: the signed heading change over the window behind, left positive so that a change to the right is negative, integrated from the body's rate of change of heading, is at most the negative of min_heading_change. The concept denotes the change of the body's own direction of travel and nothing else: it is not a turn indicator or an arm signal, not an intention or a preparation to turn, not the region the body turns out of or into (which junction, lane or roadway is the caller's to state), and not a judgement that the turn is lawful, permitted or safe. The bound is one-sided because a turn carried further is still a turn to the right at this observation: a quarter, a half and a whole circle to the right all satisfy it. It is the recognition of the turn and not its whole duration: the observation at which the heading change in the window first reaches the bound is the observation at which the act is recognized, and the later observations at which the window still carries that change are not a further turn. The window is the time over which the heading change is integrated and min_heading_change the magnitude of change to the right at which a turn is told from lane keeping, from following a bend and from the yaw of a lane change."
    definition := none
    args := [("u", .track)]
    params := [⟨"window", .second⟩, ⟨"min_heading_change", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "It is the recognition of the turn and not its whole duration: the observation at which the heading change in the window first reaches the bound is the observation at which the act is recognized, and the later observations at which the window still carries that change are not a further turn"
          why := "written as the plain bound at this observation, not as a rising edge: the contract states the concept as what holds at this observation, so the body holds at every observation whose window carries the change, and a caller that must count one act rather than many counts rising edges of the call"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.turn_right
