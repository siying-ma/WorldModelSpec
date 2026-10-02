/-
  drv.interaction.precedence_granted — True of an ordered pair of road users (a, b) at an observation when a's conduct leaves b free to proceed: throughout the window (s) ending at the observation, a stays clear of b — the closest approach the two bodies' reference points are predicted to reach within the horizon, under their velocities at each observation, stays above the clearance margin — and b is not made to brake for a, its deceleration never passing the induced-deceleration bound. The definition it renders calls the right-of-way the right of one road user "to proceed in a lawful manner in preference to another", owed where direction, speed and proximity "give rise to the danger of a crash" "unless one grants precedence to the other"; the danger of a crash is an absolute no scene carries, so it is observed only within the look-back window (s), the prediction horizon (s), the clearance margin (m) and the induced-deceleration bound (m/s^2) the caller sets, which are the concept's parameters and never figures of its own. The direction, the speed and the proximity the definition names are the positions and the velocities the prediction runs on: the concept reads them only through that prediction, and states no threshold of its own on a heading, on a speed or on the present separation of the two bodies. The order of the pair matters: a grants, b receives. Unknown where the window is truncated, where an input of the prediction is unobserved, or where b's longitudinal acceleration is unobserved. Not a stand-in for: a halt, which is a complete cessation and neither necessary nor sufficient here; the entitlement itself, which party holds the right-of-way, which is a legal allocation the caller makes and no scene shows; a collision, which is rel.contact; or the lawfulness of either party's conduct.

  The contract is the definition `DEF-NRS-484A-210`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the closest approach the two bodies' reference points are predicted to reach within the horizon, under their velocities at each observation, stays above the clearance margin: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance'], concepts []
    its deceleration never passing the induced-deceleration bound: atoms ['kin.accel_longitudinal'], concepts []

  How the elements are written.

    "the closest approach the two bodies' reference points are predicted to reach within the
    horizon, under their velocities at each observation, stays above the clearance margin" →
    `.implies (.derived "prim_closest_approach_within" [a, b] [horizon])
              (.cmp (.quantity "prim_closest_approach_distance" [a, b] [horizon]) .gt margin)`.
    The two primitives are the whole of the span and nothing else is read for it. The first is
    "the centres approach each other within the horizon", the second "the centre distance at
    closest approach; undefined when the centres do not approach within the horizon" — so the
    second is defined exactly where the first is true, and the implication is the only shape that
    pairs them without reading the undefined value. Its sense is the element's own: a is not clear
    exactly where an approach is predicted within the horizon AND the distance at it is within the
    margin, and nowhere else. "stays above" is `.gt`, the contract's own word, against the caller's
    margin as a parameter. Both primitives take the horizon as their one parameter, the caller's
    again. Neither the positions nor the velocities are read a second time as leaves of this
    concept: they are the primitives' own inputs, and a leaf over kin.heading, kin.speed or
    rel.surface_gap would state a threshold on a direction, a speed or the present separation that
    the contract does not state. prim.closest_approach_time is not read: its contract already
    bounds it by the horizon, so a leaf over it decides nothing the pair above does not.

    "its deceleration never passing the induced-deceleration bound" →
    `.cmp (.measure "kin_accel_longitudinal" [b]) .ge (.neg (.param "induced_decel"))`.
    kin.accel_longitudinal is the signed acceleration along the road user's own heading in m/s²,
    read of `b`, the receiving party — the order of the pair is carried here and in the primitives'
    argument order and nowhere else. The caller's bound is a positive magnitude, so "never passing"
    it downwards is the signed acceleration staying at or above its negation, written `.neg` on the
    parameter and not as a figure of this file. No brake lamp is read: sig.brake_lamp is "not a
    stand-in for a halt or a deceleration".

    "throughout the window (s) ending at the observation" → `.holdsFor .time (.param "window") "a"`
    over the conjunction of the two. `holdsFor` is "φ at every observation in the window of length d
    behind this one", and `.time` makes the window a length of trace time. The window subject is the
    formal `a`; a time window does not use it. Core's `holdsFor` is unknown (windowTruncated) where
    the window reaches past the start of the trace, which is the contract's first unknown; the
    primitives are undefined where kin.position or kin.velocity is unobserved, and the comparison
    on kin.accel_longitudinal is unknown where that atom is unobserved, which are the other two.

  CONSEQUENCE (choices the contract did not dictate; appended to `residues` below).

    1. Where no closest approach is predicted within the horizon at an observation — the two
       reference points are separating, or their relative velocity is zero, or the approach lies
       beyond the horizon — prim.closest_approach_distance is undefined there. The implication
       makes that observation count as "a stayed clear", not as undecided: the concept reports a
       verdict rather than unknown wherever the prediction is defined and finds no approach. The
       contract names only the unobserved input as an unknown, so this is the reading's choice and
       not its words.
    2. Because `holdsFor` is defined on the observed instants only, the concept also reports
       unknown where the observations inside the window are more than half the window apart — a
       sampling gap the contract does not speak of, to be read as "not decided", never as
       precedence granted and never as a failure to grant it.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.precedence_granted

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aA : Arg := .var "a"
private def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pWindow : Term := .param "window"
private def pHorizon : Term := .param "horizon"
private def pClearanceMargin : Term := .param "clearance_margin"
private def pInducedDecel : Term := .param "induced_decel"

/-- a stayed clear of b at this observation: wherever the two reference points are predicted to
    approach each other within the horizon, the centre distance at that closest approach is above
    the caller's clearance margin. Where no approach is predicted within the horizon the antecedent
    is false and the undefined distance decides nothing. -/
private def stayedClear : Formula :=
  .implies (.derived "prim_closest_approach_within" [aA, aB] [pHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [aA, aB] [pHorizon]) .gt pClearanceMargin)

/-- b was not made to brake at this observation: its signed acceleration along its own heading is
    at or above the negation of the caller's induced-deceleration bound. -/
private def notBraked : Formula :=
  .cmp (.measure "kin_accel_longitudinal" [aB]) .ge (.neg pInducedDecel)

/-- Both at every observation in the window of the caller's length behind this one. -/
private def body : Formula :=
  .holdsFor .time pWindow "a" (.and stayedClear notBraked)

def concept : Concept :=
  { id := "drv.interaction.precedence_granted"
    contract := "True of an ordered pair of road users (a, b) at an observation when a's conduct leaves b free to proceed: throughout the window (s) ending at the observation, a stays clear of b — the closest approach the two bodies' reference points are predicted to reach within the horizon, under their velocities at each observation, stays above the clearance margin — and b is not made to brake for a, its deceleration never passing the induced-deceleration bound. The definition it renders calls the right-of-way the right of one road user \"to proceed in a lawful manner in preference to another\", owed where direction, speed and proximity \"give rise to the danger of a crash\" \"unless one grants precedence to the other\"; the danger of a crash is an absolute no scene carries, so it is observed only within the look-back window (s), the prediction horizon (s), the clearance margin (m) and the induced-deceleration bound (m/s^2) the caller sets, which are the concept's parameters and never figures of its own. The direction, the speed and the proximity the definition names are the positions and the velocities the prediction runs on: the concept reads them only through that prediction, and states no threshold of its own on a heading, on a speed or on the present separation of the two bodies. The order of the pair matters: a grants, b receives. Unknown where the window is truncated, where an input of the prediction is unobserved, or where b's longitudinal acceleration is unobserved. Not a stand-in for: a halt, which is a complete cessation and neither necessary nor sufficient here; the entitlement itself, which party holds the right-of-way, which is a legal allocation the caller makes and no scene shows; a collision, which is rel.contact; or the lawfulness of either party's conduct."
    definition := some "DEF-NRS-484A-210"
    args := [("a", .track), ("b", .track)]
    params := [⟨"window", .second⟩, ⟨"horizon", .second⟩, ⟨"clearance_margin", .metre⟩, ⟨"induced_decel", .metrePerSecondSq⟩]
    body := .formula body
    residues := ["whether the receiving road user is proceeding lawfully is a reference to another rule's verdict, which ontology section 9 keeps out of the vocabulary and leaves to rule composition. The contract carries the physical precedence only; a caller that needs the lawfulness of the other party's conduct composes the rule that judges it.", "no scene shows what a driver braked for, and purpose is not observable (section 9). The concept observes only that b's deceleration stays within the bound at every observation of the window, whether or not an approach with a is predicted there; the attribution of that braking to a is carried by the ordering of the pair, not by any observation.", "an absolute no scene carries. It is observed only as a predicted closest approach of the two reference points, inside the caller's clearance margin and within the caller's horizon, under the velocities held constant from each observation; a danger that would arise only from a change of either party's velocity inside the horizon is outside what the concept sees.",
                 "where no closest approach is predicted within the horizon at an observation — the two reference points are separating, or their relative velocity is zero, or the approach lies beyond the horizon — prim.closest_approach_distance is undefined there, and this reading makes that observation count as a having stayed clear rather than as undecided. The concept therefore reports a verdict, and not unknown, wherever the prediction is defined and finds no approach; only an unobserved input of the prediction withholds one.",
                 "the window behind the observation is defined on the observed instants only, so the concept reports unknown where the observations inside it are more than half the window apart — a sampling gap the contract does not speak of, to be read as not decided, never as precedence granted and never as a failure to grant it."]  -- the record's, verbatim; append one entry per CONSEQUENCE in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.precedence_granted
