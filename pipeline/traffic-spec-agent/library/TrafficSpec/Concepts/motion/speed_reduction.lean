/-
  drv.motion.speed_reduction — True of a road user at an observation when it has been slowing throughout the window behind that observation: at every observation in that window its acceleration along heading is at most the negative of the deceleration rate the caller sets. Unit of the parameters: m/s^2 and s; frame: along the road user's own heading, as kin.accel_longitudinal carries it. The notion fixes no magnitude of its own — how hard the slowing must be and for how long is the caller's, which is why the deceleration rate and the window are parameters. Unknown where the window behind the observation is truncated or an acceleration within it is unobserved. Not a stand-in for: a halt, which is a complete cessation and a stronger state; a mean fall of speed over the window, which this pointwise bound is stronger than, since it refuses any re-acceleration within the window; a brake lamp or any other actuation; an intention to stop or to give way; or a deceleration demanded of another road user.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    at every observation in that window its acceleration along heading is at most the negative of the deceleration rate the caller sets: atoms ['kin.accel_longitudinal'], concepts []
    throughout the window behind that observation: atoms ['kin.time'], concepts []

  How the elements are written.

    "at every observation in that window its acceleration along heading is at most the negative of
    the deceleration rate the caller sets" →
    `.cmp (.measure "kin_accel_longitudinal" [u]) .le (.neg (.param "decel_rate"))`.
    kin.accel_longitudinal is the signed acceleration along the road user's own heading in m/s²,
    so the span is one comparison and no other reading of the motion is taken: no speed is read,
    and nothing is differenced. "at most" is `.le`, the contract's own word; the caller's rate is a
    positive magnitude, so the bound it names is its negation, written `.neg` on the parameter and
    not as a figure of this file. This comparison is the body's only leaf, so it is the only thing
    that can fail and the only thing that can be unobserved — which is the contract's unknown.

    "throughout the window behind that observation" → `.holdsFor .time (.param "window") "u" …`.
    `holdsFor` is "φ at every observation in the window of length d behind this one", which is the
    contract's "at every observation in that window", and `.time` makes the window a length of
    trace time, which is what kin.time orders and measures (`Formula.measureAtom .time = kin_time`:
    the window reads the clock and nothing else — the window is trace time, not calendar time).
    The window subject is the formal `u`; a time window does not use it, but it is the only track
    this concept speaks about. Core's `holdsFor` is unknown (windowTruncated) where the window
    reaches past the start of the trace, which is the contract's first unknown.

  CONSEQUENCE (a choice the contract did not dictate; appended to `residues` below). Because
  `holdsFor` is defined on the observed instants only, the concept also reports unknown where the
  observations inside the window are more than half the window apart — a sampling gap the contract
  does not speak of, and which the caller must read as "not decided", never as slowing and never as
  a failure to slow.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.speed_reduction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pDecelRate : Term := .param "decel_rate"
private def pWindow : Term := .param "window"

/-- `u`'s signed acceleration along its own heading is at most the negation of the caller's
    deceleration rate at every observation in the window of that length behind this one. -/
private def body : Formula :=
  .holdsFor .time pWindow "u"
    (.cmp (.measure "kin_accel_longitudinal" [aU]) .le (.neg pDecelRate))

def concept : Concept :=
  { id := "drv.motion.speed_reduction"
    contract := "True of a road user at an observation when it has been slowing throughout the window behind that observation: at every observation in that window its acceleration along heading is at most the negative of the deceleration rate the caller sets. Unit of the parameters: m/s^2 and s; frame: along the road user's own heading, as kin.accel_longitudinal carries it. The notion fixes no magnitude of its own — how hard the slowing must be and for how long is the caller's, which is why the deceleration rate and the window are parameters. Unknown where the window behind the observation is truncated or an acceleration within it is unobserved. Not a stand-in for: a halt, which is a complete cessation and a stronger state; a mean fall of speed over the window, which this pointwise bound is stronger than, since it refuses any re-acceleration within the window; a brake lamp or any other actuation; an intention to stop or to give way; or a deceleration demanded of another road user."
    definition := none
    args := [("u", .track)]
    params := [⟨"decel_rate", .metrePerSecondSq⟩, ⟨"window", .second⟩]
    body := .formula body
    residues := ["The mean fall of speed over the window — the speed at the observation against the speed one window earlier — is not expressible: the formula language has no term for the value of a quantity at an earlier instant (its window operators are Boolean and evaluate their subformula at the past observation), and no primitive computes a speed change over a back window the way prim.heading_change computes a heading change. This record therefore bounds the instantaneous deceleration at every observation in the window, which is strictly stronger: a brief re-acceleration inside the window that a mean would tolerate makes this concept false. A caller that needs the mean rather than a sustained rate needs a prim.speed_change, which is an ontology change for the operator and not something a run may write.",
                 "the window behind the observation is defined on the observed instants only, so the concept reports unknown where the observations inside it are more than half the window apart — a sampling gap the contract does not speak of, to be read as not decided, never as slowing and never as a failure to slow."]  -- the record's, verbatim; append one entry per CONSEQUENCE in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.speed_reduction
