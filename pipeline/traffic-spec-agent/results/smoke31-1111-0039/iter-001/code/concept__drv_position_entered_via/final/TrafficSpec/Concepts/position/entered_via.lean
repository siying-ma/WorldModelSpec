/-
  drv.position.entered_via — Road user x is inside region r on its current entry and came in through region c: x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began (the footprint overlapping r there and not at the observation before), and at that beginning x's footprint also overlapped c. Unknown where the beginning of the current overlap is not observed: an overlap already under way at x's first observation, or an unobserved overlap of r or c at an observation that decides it. Not denoted: that c is an approach to r (the caller states the entry topology), the direction x moved, or where x was before the beginning.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began: atoms ['rel.occupies'], concepts []
    at that beginning x's footprint also overlapped c: atoms ['rel.occupies'], concepts []

  Written as `since (occ x r) (rises (occ x r) ∧ occ x c)`: the beginning of the current overlap is
  the observation at which `rel_occupies x r` rose (true there, false at the observation before), and
  `since` asks that x overlapped c there and that the overlap of r held at every observation after it
  up to the judged one. No later rise can lie between: a rise needs a non-overlap just before it,
  which the run of `occ x r` excludes, so the rise `since` finds is the latest one. Unknown where the
  run of `occ x r` reaches back to x's first observation (`rises` and `since` are truncated there), or
  where an unobserved `rel_occupies` of r or c at the beginning, or of r since, decides it.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.entered_via

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"
def aC : Arg := .var "c"

/-- x's footprint overlaps r. -/
def inR : Formula := .atom "rel_occupies" [aX, aR] []

/-- x's footprint overlaps c. -/
def inC : Formula := .atom "rel_occupies" [aX, aC] []

/-- In r at every observation since the rise of the current overlap of r, at which x also overlapped c. -/
def body : Formula := .since inR (.and (.rises inR) inC)

def concept : Concept :=
  { id := "drv.position.entered_via"
    contract := "Road user x is inside region r on its current entry and came in through region c: x's footprint overlaps r (rel.occupies) at the observation and at every observation since the observation at which this overlap began (the footprint overlapping r there and not at the observation before), and at that beginning x's footprint also overlapped c. Unknown where the beginning of the current overlap is not observed: an overlap already under way at x's first observation, or an unobserved overlap of r or c at an observation that decides it. Not denoted: that c is an approach to r (the caller states the entry topology), the direction x moved, or where x was before the beginning."
    definition := none
    args := [("x", .track), ("r", .region), ("c", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.position.entered_via
