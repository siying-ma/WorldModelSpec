/-
  drv.position.entered_via — Road user x is inside region r on its current entry and came in through region c: x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began (the footprint overlapping r there and not at the observation before), and at that beginning x's footprint also overlapped c. The state is recognized at each observation of the current overlap and ends at the first observation at which x's footprint does not overlap r. The history boundary is x's first observation: the search for the beginning of the current overlap runs back from the observation through x's observations and no further than its first one. Unknown where the beginning of the current overlap is not observed: an overlap already under way at x's first observation, or an overlap of r unobserved at every observation back to x's first one, so that the search for the beginning reaches x's first observation without finding it; or an unobserved overlap of r or c at an observation that decides it. Not denoted: that c is an approach to r (the caller states the entry topology), the direction x moved, or where x was before the beginning.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began: atoms ['rel.occupies'], concepts []
    at that beginning x's footprint also overlapped c: atoms ['rel.occupies'], concepts []
    an overlap of r unobserved at every observation back to x's first one, so that the search for the beginning reaches x's first observation without finding it: atoms ['rel.occupies'], concepts []

  Written:
    the overlap of r: `atom rel_occupies [x, r]`, the first argument of `since`: held at every
      observation after the beginning up to the judged one.
    the beginning, with c overlapped there: `and (rises (atom rel_occupies [x, r]))
      (atom rel_occupies [x, c])`, the second argument of `since`: the overlap of r here and not
      at the observation before, and the overlap of c at that same observation.
    the unobserved overlap of r at every observation back to x's first one: no formula of its
      own; `since` is `ψ ∨ (φ ∧ since')` with the unobserved past as its head, so a search that
      finds no decided beginning before x's first observation (where whether the overlap rose is
      unknown, the observation before being unobserved) stays unknown, never true or false.

  The whole: `since occR (rises occR ∧ occC)`. At a beginning not through c the search goes on
  past it to the observation before, where r is not overlapped, and the state is false; at the
  first observation at which r is not overlapped it is false, as the contract states.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.entered_via

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"
def aC : Arg := .var "c"

/-- x's footprint overlaps r. -/
def occR : Formula := .atom "rel_occupies" [aX, aR] []

/-- x's footprint overlaps c. -/
def occC : Formula := .atom "rel_occupies" [aX, aC] []

/-- The beginning of the overlap of r (overlapped here and not at the observation before), with c
    overlapped at it. -/
def beginningViaC : Formula := .and (.rises occR) occC

/-- r overlapped here and at every observation since a beginning at which c was also overlapped. -/
def body : Formula := .since occR beginningViaC

def concept : Concept :=
  { id := "drv.position.entered_via"
    contract := "Road user x is inside region r on its current entry and came in through region c: x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began (the footprint overlapping r there and not at the observation before), and at that beginning x's footprint also overlapped c. The state is recognized at each observation of the current overlap and ends at the first observation at which x's footprint does not overlap r. The history boundary is x's first observation: the search for the beginning of the current overlap runs back from the observation through x's observations and no further than its first one. Unknown where the beginning of the current overlap is not observed: an overlap already under way at x's first observation, or an overlap of r unobserved at every observation back to x's first one, so that the search for the beginning reaches x's first observation without finding it; or an unobserved overlap of r or c at an observation that decides it. Not denoted: that c is an approach to r (the caller states the entry topology), the direction x moved, or where x was before the beginning."
    definition := none
    args := [("x", .track), ("r", .region), ("c", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.position.entered_via
