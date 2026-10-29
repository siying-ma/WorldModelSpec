/-
  drv.position.approaching_region — The road user is closing on the region named by the region formal: it is outside the region, near it, and moving towards it. At the observation: its body does not overlap that region; the ground distance in metres from its body outline to the region is within the approach reach; and the component of its velocity along the direction from its reference point to the region's reference point, both read in the world frame, exceeds the closing floor. The region is taken as a whole through its reference point, so where the region is wide compared with the distance to it the direction read differs from the direction to the part of the region nearest the road user, and a road user passing close across the face of a wide region may read either way; the concept denotes closing on the region as a whole, not on its nearest part. Not a stand-in for: occupancy of the region, which is the overlap the concept excludes; nearness alone, since a road user standing or receding within the reach is not approaching; a declared intention to enter the region; or a relation between two regions, the reach being between a road user and one region only.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its body does not overlap that region: atoms ['rel.occupies'], concepts []
      The negation of `rel_occupies u r`. Unobserved occupancy leaves the conjunct — and so the
      concept — unknown, never false.
    the ground distance in metres from its body outline to the region is within the approach reach: atoms ['st.region_geometry'], concepts []
      `st_region_geometry_distance u r` (the geometry atom's outline distance, zero on overlap) at
      or below the formal `approach_reach`: "within" is read inclusively.
    the component of its velocity along the direction from its reference point to the region's reference point: atoms ['kin.velocity', 'kin.position', 'st.region_geometry'], concepts []
      The separation vector is the region's reference point (`st_region_geometry r "x"`, `… "y"`)
      minus the road user's (`kin_position u "x"`, `… "y"`), both in the world frame; the velocity
      is read component-wise in the same frame (`kin_velocity u "x"`, `… "y"`). The component the
      contract names is the projection of the velocity on that separation, i.e. the dot product
      divided by the separation's length.

  The one reading this file chooses (declared as a narrowing below): the closing comparison is
  written in signed-square product form. Writing P for the dot product of the velocity with the
  separation vector, D² for the squared length of that separation and F for the closing floor, the
  contract's "P / |D| > F" is written

      P · |P| > F² · D².

  For a non-negative floor — which is what the parameter means, the observer's resolution of
  movement — the two are equivalent: where P ≤ 0 the left side is at most zero and the right side
  at least zero, so both readings are false; where P > 0 the left side is P² and the inequality is
  P² > F² · D², which for non-negative F and |D| is exactly P > F · |D|. The product form is
  written because the formula language has no square root for |D| and because a division by a
  measured separation (zero where the two reference points coincide) would be undefined rather than
  decided. Nothing is read of the road user's heading or speed: the contract compares the direction
  the body moves in with the direction to the region.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.approaching_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pApproachReach : Term := .param "approach_reach"
def pClosingSpeedFloor : Term := .param "closing_speed_floor"

/-- The road user's body does not overlap the region. -/
def outside : Formula := .not (.atom "rel_occupies" [aU, aR] [])

/-- The ground distance from the road user's body outline to the region, in metres. -/
def outlineDistance : Term := .measure "st_region_geometry_distance" [aU, aR]

/-- Near the region: that distance is within the approach reach. -/
def near : Formula := .cmp outlineDistance .le pApproachReach

/-- The road user's velocity, read component-wise in the world frame. -/
def velX : Term := .measure "kin_velocity" [aU, .lit "x"]
def velY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The separation from the road user's reference point to the region's, component-wise in the
    world frame: the region's reference point less the road user's position. -/
def sepX : Term := .sub (.measure "st_region_geometry" [aR, .lit "x"]) (.measure "kin_position" [aU, .lit "x"])
def sepY : Term := .sub (.measure "st_region_geometry" [aR, .lit "y"]) (.measure "kin_position" [aU, .lit "y"])

/-- The velocity projected on the separation: the closing component times the separation's length. -/
def closingTimesSeparation : Term := .add (.mul velX sepX) (.mul velY sepY)

/-- The squared length of the separation. -/
def separationSq : Term := .add (.mul sepX sepX) (.mul sepY sepY)

/-- Moving towards the region: the closing component exceeds the floor, written in signed-square
    product form so that no square root and no division by a measured separation is needed. -/
def closing : Formula :=
  .cmp
    (.mul closingTimesSeparation (.abs closingTimesSeparation))
    .gt
    (.mul (.mul pClosingSpeedFloor pClosingSpeedFloor) separationSq)

/-- Outside the region, within the approach reach of it, and closing on its reference point. -/
def body : Formula := .and (.and outside near) closing

def concept : Concept :=
  { id := "drv.position.approaching_region"
    contract := "The road user is closing on the region named by the region formal: it is outside the region, near it, and moving towards it. At the observation: its body does not overlap that region; the ground distance in metres from its body outline to the region is within the approach reach; and the component of its velocity along the direction from its reference point to the region's reference point, both read in the world frame, exceeds the closing floor. The region is taken as a whole through its reference point, so where the region is wide compared with the distance to it the direction read differs from the direction to the part of the region nearest the road user, and a road user passing close across the face of a wide region may read either way; the concept denotes closing on the region as a whole, not on its nearest part. Not a stand-in for: occupancy of the region, which is the overlap the concept excludes; nearness alone, since a road user standing or receding within the reach is not approaching; a declared intention to enter the region; or a relation between two regions, the reach being between a road user and one region only."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"approach_reach", .metre⟩, ⟨"closing_speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of its velocity along the direction from its reference point to the region's reference point, both read in the world frame, exceeds the closing floor"
          why := "Written in signed-square product form: the dot product of the velocity with the separation from the road user's reference point to the region's, times its own absolute value, is compared with the squared closing floor times the squared length of that separation, instead of dividing the dot product by the separation's length. For a non-negative floor — the meaning the parameter declares — the two readings agree: where the dot product is not positive both are false, and where it is positive the squared inequality is exactly the component above the floor. The product form is used because the language has no square root for the separation's length, and because dividing by a measured separation would be undefined where the two reference points coincide rather than decided."
          kind := "reading" }
      , { span := "the ground distance in metres from its body outline to the region is within the approach reach"
          why := "\"Within\" is read inclusively: the distance at or below the reach counts as within it. The contract's other bound, the closing floor, says \"exceeds\" and is read strictly."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.position.approaching_region
