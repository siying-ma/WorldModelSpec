/-
  drv.motion.turning — The road user's heading is changing at the observation: the magnitude of its heading change over the window behind the observation is at least the heading change tolerance, a size the caller sets at the resolution of the source. It is a state the road user is in at each observation of a bending path, in either hand, and it states no direction, no angle reached, no beginning and no place. Not a stand-in for: a completed turn or a manoeuvre recognized from an observed onset — which counts the heading change from that onset and not over a window — a steering input, the curvature of the road, a lane change, or a signal or an intention.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its heading change over the window behind the observation: atoms ['prim.heading_change'], concepts []
      written `Term.abs (Term.quantity "prim_heading_change" [u] [window])`: the primitive is the
      signed heading change (degrees, left positive) over the window behind the observation,
      integrated from the yaw rate, and its own window parameter takes this concept's `window`
      formal unchanged. `abs` is the contract's "magnitude", so the state holds for a bend in
      either hand and the body states no direction. The bound is `≥ heading_change_tolerance`,
      the contract's "at least", so the tolerance itself counts as turning.

  The window is the only lookback: where it reaches past the start of the trace, or is sampled too
  sparsely, or a yaw rate in it is missing, the primitive and so this concept are unknown, never
  false. Nothing else is read: no onset, no steering angle, no curvature, no lane, no signal.

  Narrowings: none. The contract fixes the quantity (the primitive's magnitude), the window (its
  own formal) and the sense of the bound (at least); no choice was left open.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pHeadingChangeTolerance : Term := .param "heading_change_tolerance"

/-- `|prim.heading_change u window| ≥ heading_change_tolerance`: the magnitude of the signed
    heading change over the window behind the observation, at least the tolerance. The primitive
    carries the window as its own parameter, so this concept passes its `window` formal straight
    to it; the absolute value is the contract's "magnitude", which is why a turn in either hand
    counts and the reading states no direction. Unknown wherever the primitive is unknown (the
    window truncated or sparsely sampled, a yaw rate missing). -/
def body : Formula :=
  .cmp (.abs (.quantity "prim_heading_change" [aU] [pWindow])) .ge pHeadingChangeTolerance

def concept : Concept :=
  { id := "drv.motion.turning"
    contract := "The road user's heading is changing at the observation: the magnitude of its heading change over the window behind the observation is at least the heading change tolerance, a size the caller sets at the resolution of the source. It is a state the road user is in at each observation of a bending path, in either hand, and it states no direction, no angle reached, no beginning and no place. Not a stand-in for: a completed turn or a manoeuvre recognized from an observed onset — which counts the heading change from that onset and not over a window — a steering input, the curvature of the road, a lane change, or a signal or an intention."
    definition := none
    args := [("u", .track)]
    params := [⟨"window", .second⟩, ⟨"heading_change_tolerance", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning
