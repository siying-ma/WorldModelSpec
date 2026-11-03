/-
  drv.interaction.behind_in_lane — At the observation the first road user is behind the second in the same line of travel: the second is ahead of the first in the lane they share, measured along that lane's direction, and their headings are aligned within the tolerance the parameter cos_min sets. The concept states the configuration at the observation, not a duration of it, and says nothing about the distance between them: how far behind is the caller's to read. Not a stand-in for: travelling in an adjacent lane, a distance or a clearance between the bodies, a closing or opening gap, overtaking, or which of the two has the right of way.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the second is ahead of the first in the lane they share, measured along that lane's direction: atoms ['rel.ahead_behind_in_lane'], concepts []
    their headings are aligned within the tolerance the parameter cos_min sets: atoms ['rel.same_direction'], concepts []

  How each element is written:
    "the second is ahead of the first in the lane they share, measured along that lane's direction"
      → `rel_ahead_behind_in_lane b a`. The atom's first argument is the road user that is ahead
      ("a is ahead of / behind b in the same lane, along the lane direction"), so the formals are
      given in the order the span states: the second formal, `b`, ahead of the first, `a`. The atom
      carries both halves of the span by itself — the shared lane and the order along its direction
      — so nothing of that span is written elsewhere. (`rel_behind_in_lane a b` is the same atom
      read from `a`'s side; the claimed spelling is used.)
    "their headings are aligned within the tolerance the parameter cos_min sets"
      → `rel_same_direction a b` with the formal parameter `cos_min` as its tolerance: the atom's
      tolerance is itself the cosine of the largest angle still counted as aligned, so the contract's
      parameter is passed straight to it. It is what keeps a road user heading the other way in the
      same lane out of the concept.

  The two elements are conjoined: the contract joins them with "and", and both state the
  configuration at the observation, so the body is a plain conjunction at the judged instant — no
  temporal operator, no window, nothing about the distance between the two bodies.

  Readings chosen that the contract left open: none. The contract fixes which road user is ahead,
  which relation carries the shared lane, and which parameter is the alignment tolerance; the
  tolerance's own comparison (strict, on the cosine) is the atom's and not this file's. Hence
  `narrowings := []`.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.behind_in_lane

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pCosMin : Term := .param "cos_min"

/-- `b` is ahead of `a` in the lane they share, along that lane's direction: the atom's first
    argument is the one ahead. -/
def bAheadOfA : Formula := .atom "rel_ahead_behind_in_lane" [aB, aA] []

/-- The two headings are aligned within `cos_min`, the cosine of the largest angle still counted
    as aligned. -/
def headingsAligned : Formula := .atom "rel_same_direction" [aA, aB] [pCosMin]

def body : Formula := .and bAheadOfA headingsAligned

def concept : Concept :=
  { id := "drv.interaction.behind_in_lane"
    contract := "At the observation the first road user is behind the second in the same line of travel: the second is ahead of the first in the lane they share, measured along that lane's direction, and their headings are aligned within the tolerance the parameter cos_min sets. The concept states the configuration at the observation, not a duration of it, and says nothing about the distance between them: how far behind is the caller's to read. Not a stand-in for: travelling in an adjacent lane, a distance or a clearance between the bodies, a closing or opening gap, overtaking, or which of the two has the right of way."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"cos_min", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.behind_in_lane
