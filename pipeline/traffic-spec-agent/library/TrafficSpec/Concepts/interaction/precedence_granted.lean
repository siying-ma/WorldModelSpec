/-
  drv.interaction.precedence_granted — True of an ordered pair of road users (a, b) at an observation when a is keeping out of b's way: throughout a stated window ending at the observation, the two bodies have stood apart by at least a stated clearance along one of a's two axes, the longitudinal or the lateral component of the gap between their nearest points reaching it, and over that same window the longitudinal component of that gap has stayed at or above the stated clearance less a stated allowance, so that at no observation of the window has a drawn in on b beyond that allowance. Both conditions are read at each observation of the window on its own: each states where the two bodies stood at that observation, and neither is the change of a quantity between two observations. Unit: none - a condition on the ordered pair; frame: ground plane, the components of the gap in a's frame. Not a stand-in for: a right-of-way determination, which is a relation between two road users' rights and is decided by composing the rule that grants it; a's purpose, attention or intent, which are not observable; a halt, which is drv.motion.complete_cessation; or a collision, which is rel.contact.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the two bodies have stood apart by at least a stated clearance along one of a's two axes, the longitudinal or the lateral component of the gap between their nearest points reaching it: atoms ['rel.surface_gap'], concepts []
    the longitudinal component of that gap has stayed at or above the stated clearance less a stated allowance: atoms ['rel.surface_gap'], concepts []

  How the two elements are written.
    Both read one atom, `rel.surface_gap (a, b, <component>)`: "distance between the nearest points
    of two bodies; longitudinal and lateral components in the subject's frame". The subject is the
    first argument, so the components are in a's frame, as the contract's frame clause says, and
    the component is named by the selector literal the atom takes in its third position
    (`"longitudinal"`, `"lateral"`).

    "the two bodies have stood apart by at least a stated clearance along one of a's two axes, the
    longitudinal or the lateral component of the gap between their nearest points reaching it" is
    the disjunction of the two component comparisons with `yield_clearance`, each non-strict,
    because the contract says "at least" and "reaching it".

    "the longitudinal component of that gap has stayed at or above the stated clearance less a
    stated allowance" is the longitudinal component against `yield_clearance - yield_closure_allowance`,
    again non-strict ("at or above"). The bound is a difference of the two formal parameters; no
    magnitude of it lives in this file.

    "throughout a stated window ending at the observation … over that same window" is the one
    window operator `holdsFor .time yield_window` over the conjunction of the two conditions: the
    contract states one window for both ("that same window"), and `holdsFor` includes the
    observation itself among the observations it ranges over, so the conjunction under the one
    window is the whole body. The window operator reads no atom, so `kin.time` is not claimed.

    Nothing here is a change between two observations: each comparison is of a gap with a bound at
    one observation, as the contract's second paragraph requires.

  Narrowings (readings the contract leaves open).
    "throughout a stated window ending at the observation" — read as the *time* measure, not the
    path measure. The window is said to end at the observation and to hold of both conditions
    alike, one of which (the lateral component) a stationary a cannot change at all; a path window
    of an a that has stopped to let b by would never advance and could never close, which is
    exactly the case the concept is for. Declared in `narrowings` below.
    The same span carries the sampling policy Core fixes for every window: the body is unknown, not
    false, where the trace does not reach a whole window back, and where the observations inside
    the window are more than half a window apart. That is Core's finite-trace policy, not a choice
    of this file, and so is not declared a narrowing.
    "along one of a's two axes" — read as the inclusive disjunction: the condition holds when both
    components reach the clearance, not only when exactly one does. "One of" states that one
    component suffices, not that the other must fail; a reading on which standing further apart
    along both axes broke the condition would make a's keeping clear of b harder the clearer it
    kept. Declared in `narrowings` below.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.precedence_granted

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aA : Arg := .var "a"
private def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pYieldClearance : Term := .param "yield_clearance"
private def pYieldWindow : Term := .param "yield_window"
private def pYieldClosureAllowance : Term := .param "yield_closure_allowance"

/-- The longitudinal component of the gap between the nearest points of the two bodies, in a's
    frame. -/
private def gapLongitudinal : Term := .measure "rel_surface_gap" [aA, aB, .lit "longitudinal"]

/-- The lateral component of that same gap, in a's frame. -/
private def gapLateral : Term := .measure "rel_surface_gap" [aA, aB, .lit "lateral"]

/-- "the two bodies have stood apart by at least a stated clearance along one of a's two axes, the
    longitudinal or the lateral component of the gap between their nearest points reaching it":
    either component reaching `yield_clearance` at the observation. -/
private def standApart : Formula :=
  .or (.cmp gapLongitudinal .ge pYieldClearance)
      (.cmp gapLateral .ge pYieldClearance)

/-- "the longitudinal component of that gap has stayed at or above the stated clearance less a
    stated allowance": at this observation a has not drawn in on b beyond the allowance. -/
private def notDrawnIn : Formula :=
  .cmp gapLongitudinal .ge (.sub pYieldClearance pYieldClosureAllowance)

/-- "throughout a stated window ending at the observation … over that same window": both
    conditions at every observation of the time window of length `yield_window` behind the
    observation, the observation itself included. -/
private def body : Formula :=
  .holdsFor .time pYieldWindow "a" (.and standApart notDrawnIn)

def concept : Concept :=
  { id := "drv.interaction.precedence_granted"
    contract := "True of an ordered pair of road users (a, b) at an observation when a is keeping out of b's way: throughout a stated window ending at the observation, the two bodies have stood apart by at least a stated clearance along one of a's two axes, the longitudinal or the lateral component of the gap between their nearest points reaching it, and over that same window the longitudinal component of that gap has stayed at or above the stated clearance less a stated allowance, so that at no observation of the window has a drawn in on b beyond that allowance. Both conditions are read at each observation of the window on its own: each states where the two bodies stood at that observation, and neither is the change of a quantity between two observations. Unit: none - a condition on the ordered pair; frame: ground plane, the components of the gap in a's frame. Not a stand-in for: a right-of-way determination, which is a relation between two road users' rights and is decided by composing the rule that grants it; a's purpose, attention or intent, which are not observable; a halt, which is drv.motion.complete_cessation; or a collision, which is rel.contact."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"yield_clearance", .metre⟩, ⟨"yield_window", .second⟩, ⟨"yield_closure_allowance", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ ⟨"throughout a stated window ending at the observation",
         "The window is read in time, not in path travelled: the concept is of an a that keeps out of b's way, which an a that has stopped does best of all, and a path window of a stationary a would never advance and so could never close. The caller's `yield_window` is therefore seconds."⟩
      , ⟨"along one of a's two axes",
         "Read as the inclusive disjunction: the condition holds when either component reaches the clearance, the case of both reaching it included. 'One of' says that one component suffices, not that the other must fall short; on the exclusive reading standing further apart along both axes would break the condition that a kept clear of b."⟩ ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.precedence_granted
