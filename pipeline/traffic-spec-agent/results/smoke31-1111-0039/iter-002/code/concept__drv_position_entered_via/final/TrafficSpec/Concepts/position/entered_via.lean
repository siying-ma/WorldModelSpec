/-
  drv.position.entered_via — Road user x is inside region r on its current entry and came in through region c: x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began (the footprint overlapping r there and not at the observation before), and at that beginning x's footprint also overlapped c. The state is recognized at each observation of the current overlap and ends at the first observation at which x's footprint does not overlap r. Unknown where the beginning of the current overlap is not observed: an overlap already under way at x's first observation, or an overlap of r unobserved at every observation back to x's first one, so that the search for the beginning reaches x's first observation without finding it; or an unobserved overlap of r or c at an observation that decides it. Not denoted: that c is an approach to r (the caller states the entry topology), the direction x moved, or where x was before the beginning.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began: atoms ['rel.occupies'], concepts []
    at that beginning x's footprint also overlapped c: atoms ['rel.occupies'], concepts []
    an overlap of r unobserved at every observation back to x's first one, so that the search for the beginning reaches x's first observation without finding it: atoms ['rel.occupies'], concepts []

  How each is written:
    the overlap of r: `atom rel_occupies [x, r]`, the first argument of `since` (held at every
      observation after the beginning up to the judged one) and, under `rises`, the beginning.
    the overlap of c at the beginning: `atom rel_occupies [x, c]`, conjoined with the rise of the
      overlap of r in the second argument of `since`, so it is read at that beginning only.
    the search into the past: `since` itself, whose head is the unobserved past: where the overlap
      of r is unknown back to x's first observation, or already true there (its rise there is
      unknown, there being no observation before), the search ends unknown.

  The whole: `since (occupies x r) (rises (occupies x r) ∧ occupies x c)`. A beginning of the
  overlap of r without c makes the second argument false there, and before it the overlap of r is
  false, so the state is false for the whole current overlap; it is false wherever x does not
  overlap r (there neither argument holds). No choice beyond the contract's words was needed.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.entered_via

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"
def aC : Arg := .var "c"

/-- x's footprint overlaps r. -/
def onR : Formula := .atom "rel_occupies" [aX, aR] []

/-- x's footprint overlaps c. -/
def onC : Formula := .atom "rel_occupies" [aX, aC] []

/-- The overlap of r begins here (true here, not at the observation before), x also overlapping c. -/
def entryViaC : Formula := .and (.rises onR) onC

/-- A beginning through c here, or an earlier one since which x has overlapped r throughout. -/
def body : Formula := .since onR entryViaC

def concept : Concept :=
  { id := "drv.position.entered_via"
    contract := "Road user x is inside region r on its current entry and came in through region c: x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began (the footprint overlapping r there and not at the observation before), and at that beginning x's footprint also overlapped c. The state is recognized at each observation of the current overlap and ends at the first observation at which x's footprint does not overlap r. Unknown where the beginning of the current overlap is not observed: an overlap already under way at x's first observation, or an overlap of r unobserved at every observation back to x's first one, so that the search for the beginning reaches x's first observation without finding it; or an unobserved overlap of r or c at an observation that decides it. Not denoted: that c is an approach to r (the caller states the entry topology), the direction x moved, or where x was before the beginning."
    definition := none
    args := [("x", .track), ("r", .region), ("c", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.position.entered_via
