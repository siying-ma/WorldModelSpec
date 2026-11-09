/-
  drv.interaction.following — Road user a is following road user b at the observation: b is ahead of a in the same lane along that lane's direction of travel, and the two bodies' headings are aligned within the same-direction tolerance, a cosine the caller sets. It is a relation of place and direction at the observation; it states no gap, no speed, no duration and no intention. Not a stand-in for: the size of the space between the two — a caller that bounds a space reads the gap atom itself — overtaking or passing, two road users abreast in neighbouring lanes, or a towed combination, which is one road user drawn by another.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    b is ahead of a in the same lane along that lane's direction of travel: atoms ['rel.ahead_behind_in_lane'], concepts []
    the two bodies' headings are aligned within the same-direction tolerance: atoms ['rel.same_direction'], concepts []

  How each element is written:
    "b is ahead of a in the same lane along that lane's direction of travel" →
      `rel_ahead_behind_in_lane [b, a]`. The atom's contract is "a is ahead of / behind b in the
      same lane, along the lane direction", i.e. its first argument is ahead of its second, so the
      contract's words are the atom with the formals in the order (b, a).
    "the two bodies' headings are aligned within the same-direction tolerance" →
      `rel_same_direction [a, b]` with the formal parameter `same_direction_tolerance` as the
      atom's only parameter. The atom is the cosine of the angle between the two headings against
      that cosine bound, which is the element's words exactly; the formal parameter is forwarded
      unchanged, so no magnitude is this file's.
  The two are conjoined: the contract joins them with "and", and both are read at the observation,
  so no temporal operator enters. Nothing else is written: no gap, no speed, no duration, no
  intention — those are the contract's exclusions.

  No reading of the contract was left open to this session, so `narrowings` is empty: each element
  has one atom that states its words, and the argument order of each is fixed by the atom's own
  contract (the same-direction atom being symmetric in its two bodies).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSameDirectionTolerance : Term := .param "same_direction_tolerance"

/-- `b is ahead of a in the same lane along that lane's direction of travel`: the atom reads
    "<first> is ahead of <second> in the same lane, along the lane direction", so the contract's
    words are its arguments in the order (b, a). -/
def aheadInLane : Formula := .atom "rel_ahead_behind_in_lane" [aB, aA] []

/-- `the two bodies' headings are aligned within the same-direction tolerance`: the atom's own
    parameter is this concept's formal parameter, passed through unchanged. The relation is
    symmetric in its two bodies (a cosine between the headings), so the subject comes first. -/
def headingsAligned : Formula :=
  .atom "rel_same_direction" [aA, aB] [pSameDirectionTolerance]

/-- Following: the in-lane order and the heading alignment, both at the observation. -/
def body : Formula := .and aheadInLane headingsAligned

def concept : Concept :=
  { id := "drv.interaction.following"
    contract := "Road user a is following road user b at the observation: b is ahead of a in the same lane along that lane's direction of travel, and the two bodies' headings are aligned within the same-direction tolerance, a cosine the caller sets. It is a relation of place and direction at the observation; it states no gap, no speed, no duration and no intention. Not a stand-in for: the size of the space between the two — a caller that bounds a space reads the gap atom itself — overtaking or passing, two road users abreast in neighbouring lanes, or a towed combination, which is one road user drawn by another."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"same_direction_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.following
