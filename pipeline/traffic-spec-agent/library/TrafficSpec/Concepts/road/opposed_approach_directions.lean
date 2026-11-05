/-
  drv.road.opposed_approach_directions — At this observation the designated directions of travel of the two given regions are opposed. The regions are the two the caller singles out and passes in, each carrying a designated direction of travel; the relation holds where the sum of the products of the components of those two directions, each read normalised as the direction atom's contract states, is below the negative of the opposition tolerance. The tolerance is the cosine of the largest angle off exactly opposed still read as opposed, a ratio, and is the concept's own magnitude, a designated direction being recorded only within a bound the caller sets; the bound is one-sided, since the more nearly the two directions are reversed, the more plainly they are opposed. It is unknown where either region carries no designated direction. The concept denotes the relation between the two regions' designated directions only: it is not the presence of any road user on either region, not the heading or the travel of any body, not which of the two regions lies to the left or the right of the other, not the junction either region runs into, and not the lawfulness of travelling on either.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the designated directions of travel of the two given regions are opposed: atoms ['st.lane_direction'], concepts []
      written `.cmp (.add (.mul aX bX) (.mul aY bY)) .lt (.neg pOppositionTolerance)`, where each of
      the four terms is `.measure "st_lane_direction" [<the region formal>, .lit "<component>"]`:
      st.lane_direction is the 'direction of travel designated for a structure a vehicle travels
      in', read of the two regions the caller passes in — the formals `a` and `b` themselves, with
      no region quantifier of this body's, because the contract names both regions as arguments.
      Core reads the atom normalised ('a formula reads it normalised'), so the sum of the products
      of the components is the cosine of the angle between the two designated directions, and the
      contract's 'below the negative of the opposition tolerance' is that sum strictly below
      `.neg` of the formal parameter — the contract's own one-sided bound, with no figure of this
      file's. Where either region carries no designated direction the atom is unknown
      (`absentAtom`: 'a place no carrier covers has none'), so the comparison, and the concept, is
      unknown, as the contract states. Nothing else is read: no road user and no occupancy
      (rel.occupies), no body's heading or travel (kin.heading, kin.velocity), no left/right
      ordering of the two regions (st.lane_adjacency), no junction either runs into
      (st.lane_enters), and no rule — each of these the contract excludes by name.

  Narrowings (choices the contract did not dictate):
    "the sum of the products of the components of those two directions" — written over the two
      components `x` and `y`, the only components Core's `Vec` has, as
      `.add (.mul aX bX) (.mul aY bY)`: the world frame is planar (+x east, +y north), so these
      two products are the whole sum and no third term is dropped.
    "each read normalised as the direction atom's contract states" — written as the bare
      `st_lane_direction` component readings, with no scaling of this body's: the atom's own
      reading already divides by the larger absolute component and then by the length taken to a
      micrometre, so the vector read is the unit vector times a factor in [1, 1 + 2·10⁻⁶), and the
      contract asks for that reading and no other.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.opposed_approach_directions

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pOppositionTolerance : Term := .param "opposition_tolerance"

/-- The east component of the designated direction of travel of region `a`, read normalised as the
    atom's contract states. -/
def aX : Term := .measure "st_lane_direction" [aA, .lit "x"]

/-- The north component of the designated direction of travel of region `a`. -/
def aY : Term := .measure "st_lane_direction" [aA, .lit "y"]

/-- The east component of the designated direction of travel of region `b`. -/
def bX : Term := .measure "st_lane_direction" [aB, .lit "x"]

/-- The north component of the designated direction of travel of region `b`. -/
def bY : Term := .measure "st_lane_direction" [aB, .lit "y"]

/-- The sum of the products of the components of the two regions' designated directions: the
    cosine of the angle between them, each direction read normalised as the atom's contract
    states. Unknown where either region carries no designated direction. -/
def directionProduct : Term := .add (.mul aX bX) (.mul aY bY)

/-- The two regions' designated directions of travel are opposed: the sum of the products of their
    components is below the negative of the opposition tolerance, the cosine of the largest angle
    off exactly opposed still read as opposed. The bound is one-sided, as the contract states. -/
def body : Formula := .cmp directionProduct .lt (.neg pOppositionTolerance)

def concept : Concept :=
  { id := "drv.road.opposed_approach_directions"
    contract := "At this observation the designated directions of travel of the two given regions are opposed. The regions are the two the caller singles out and passes in, each carrying a designated direction of travel; the relation holds where the sum of the products of the components of those two directions, each read normalised as the direction atom's contract states, is below the negative of the opposition tolerance. The tolerance is the cosine of the largest angle off exactly opposed still read as opposed, a ratio, and is the concept's own magnitude, a designated direction being recorded only within a bound the caller sets; the bound is one-sided, since the more nearly the two directions are reversed, the more plainly they are opposed. It is unknown where either region carries no designated direction. The concept denotes the relation between the two regions' designated directions only: it is not the presence of any road user on either region, not the heading or the travel of any body, not which of the two regions lies to the left or the right of the other, not the junction either region runs into, and not the lawfulness of travelling on either."
    definition := none
    args := [("a", .region), ("b", .region)]
    params := [⟨"opposition_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the sum of the products of the components of those two directions"
          why := "Written over the two components `x` and `y`, the only components Core's `Vec` has, as `.add (.mul aX bX) (.mul aY bY)`: the world frame is planar (+x east, +y north), so these two products are the whole sum the contract asks for and no third term is dropped. The comparison is the contract's own one-sided, strict bound ('below the negative of the opposition tolerance'), so `.lt` against `.neg` of the formal parameter."
          kind := "reading" }
      , { span := "each read normalised as the direction atom's contract states"
          why := "Written as the bare `st_lane_direction` component readings, with no scaling of this body's. The atom's own reading already divides the recorded vector by its larger absolute component and then by its length taken to a micrometre, so what a formula reads is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶; the contract asks for that reading and no other, and a renormalisation written here would read something the atom does not denote."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.road.opposed_approach_directions
