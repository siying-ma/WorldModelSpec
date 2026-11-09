/-
  drv.interaction.vehicle_file — Road user u is one of a file of road users travelling one behind another at the observation: counting u itself, at least the minimum member count of road users have their heading aligned with u's within the same-direction tolerance, lie ahead of or behind u in the same lane, and are within the file reach of u, a distance the caller sets measured between the nearest points of the bodies. It is a relation of place, direction and spacing at the observation. It says nothing of why the road users travel together, of a common destination or origin, of an organizer, or of their speed: a caller that means a moving file states the motion itself. Not a stand-in for: a chain each of whose consecutive spaces is bounded — the reach is measured from u to each member, so a long file is read through the membership of each road user in turn — the class of the members, which the caller states, or a towed combination, which is one road user drawn by another.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    have their heading aligned with u's within the same-direction tolerance: atoms ['rel.same_direction'], concepts []
      → `rel_same_direction v u` with `same_direction_tolerance` as the atom's own cosine tolerance.
    lie ahead of or behind u in the same lane: atoms ['rel.ahead_behind_in_lane'], concepts []
      → the atom states one road user ahead of another in the lane they share, so "ahead of or
        behind u" is the atom in both directions: `rel_ahead_behind_in_lane v u` (v ahead of u) or
        `rel_ahead_behind_in_lane u v` (u ahead of v, i.e. v behind u).
    are within the file reach of u, a distance the caller sets measured between the nearest points of the bodies: atoms ['rel.surface_gap'], concepts []
      → `rel_surface_gap u v` read without a component, which is the distance between the nearest
        points of the two bodies, at most `file_reach`.

  The count, and u itself: the body counts the road users of the observation that are members of
  u's file — u itself, by identity, and every other road user of which the three relations above
  hold — and asks for at least `min_member_count` of them. u is counted by identity because the
  three relations do not hold of u with itself (u is neither ahead of nor behind itself), and the
  contract counts u in.

  Readings chosen where the contract leaves the writing open (declared as narrowings below):
    - "within the file reach" is read inclusively: a road user whose body is exactly `file_reach`
      from u's is a member.
    - "counting u itself": u is a member by identity, not through the relations.
    - "ahead of or behind": the one atom read in both directions, as above.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.vehicle_file

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMinMemberCount : Term := .param "min_member_count"
def pFileReach : Term := .param "file_reach"
def pSameDirectionTolerance : Term := .param "same_direction_tolerance"

/-- The road user the count ranges over. -/
def aV : Arg := .var "v"

/-- `v` lies ahead of or behind `u` in the same lane: the atom in both directions. -/
def aheadOrBehind : Formula :=
  .or (.atom "rel_ahead_behind_in_lane" [aV, aU] [])
      (.atom "rel_ahead_behind_in_lane" [aU, aV] [])

/-- The distance between the nearest points of `u`'s body and `v`'s is at most the file reach. -/
def withinReach : Formula :=
  .cmp (.measure "rel_surface_gap" [aU, aV]) .le pFileReach

/-- `v` is a member of `u`'s file: `u` itself, or a road user whose heading is aligned with `u`'s
    within the tolerance, which lies ahead of or behind `u` in the same lane and whose body is
    within the file reach of `u`'s. -/
def member : Formula :=
  .or (.same aV aU)
      (.and (.atom "rel_same_direction" [aV, aU] [pSameDirectionTolerance])
            (.and aheadOrBehind withinReach))

/-- At least the minimum member count of the road users of the observation, `u` included, are
    members of `u`'s file. -/
def body : Formula :=
  .cmp (.aggregate .count "v" member (.lit Q.zero .count)) .ge pMinMemberCount

def concept : Concept :=
  { id := "drv.interaction.vehicle_file"
    contract := "Road user u is one of a file of road users travelling one behind another at the observation: counting u itself, at least the minimum member count of road users have their heading aligned with u's within the same-direction tolerance, lie ahead of or behind u in the same lane, and are within the file reach of u, a distance the caller sets measured between the nearest points of the bodies. It is a relation of place, direction and spacing at the observation. It says nothing of why the road users travel together, of a common destination or origin, of an organizer, or of their speed: a caller that means a moving file states the motion itself. Not a stand-in for: a chain each of whose consecutive spaces is bounded — the reach is measured from u to each member, so a long file is read through the membership of each road user in turn — the class of the members, which the caller states, or a towed combination, which is one road user drawn by another."
    definition := none
    args := [("u", .track)]
    params := [⟨"min_member_count", .count⟩, ⟨"file_reach", .metre⟩, ⟨"same_direction_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "are within the file reach of u, a distance the caller sets measured between the nearest points of the bodies"
          why := "The gap is read without a component — the distance between the nearest points of the two bodies — and the bound is inclusive: a road user whose body is exactly the file reach from u's is a member. The contract says `within` without fixing the boundary."
          kind := "reading" }
      , { span := "counting u itself"
          why := "u is counted as a member by identity (`same v u`), not by the three relations holding of u with itself: u is neither ahead of nor behind itself, so the conjunction would exclude it and no file could ever reach its member count. Every other road user is counted only through the relations."
          kind := "reading" }
      , { span := "lie ahead of or behind u in the same lane"
          why := "rel.ahead_behind_in_lane states one road user ahead of another along the direction of the lane they share, so the clause is written as that atom in both directions: v ahead of u, or u ahead of v (v behind u)."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.vehicle_file
