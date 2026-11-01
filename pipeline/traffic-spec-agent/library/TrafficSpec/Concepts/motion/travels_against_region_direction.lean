/-
  drv.motion.travels_against_region_direction — The road user is travelling against the direction of travel designated for a given region at this observation: its footprint overlaps that region, the region carries a designated direction of travel, and the component of its velocity along that direction is negative with magnitude greater than speed_tolerance, the bound within which a sampled velocity counts as no motion along the direction. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes motion opposed to the designated direction; it is not a judgement of which side of a centre line or of the roadway the body is on, not a turn, a reversing manoeuvre or a lane change (a body that backs along a one-way street still moves against the direction when its velocity does), and it says nothing about the kind of the region — a region that carries a direction need not be a one-way roadway. Where the region carries no direction, or the direction is a zero vector, the concept is unknown, as that atom's contract requires.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps that region: atoms ['rel.occupies'], concepts []
    the region carries a designated direction of travel: atoms ['st.lane_direction'], concepts []
    the component of its velocity along that direction: atoms ['kin.velocity'], concepts []

  How each element is written.
    "its footprint overlaps that region" — `rel_occupies u r`, the anchoring relation, on the
      region the caller passes: the body never quantifies over a region of its own, so `r` is read
      exactly where the contract speaks of that region.
    "the region carries a designated direction of travel" — the two components of
      `st_lane_direction r`. Where no carrier covers the region, or its direction is the zero
      vector, that atom is unknown; the comparison it feeds is then unknown, which is the unknown
      the contract requires, and nothing in the body turns it into a false.
    "the component of its velocity along that direction" — the dot product
      `v.x·d.x + v.y·d.y` of `kin_velocity u` with `st_lane_direction r`. `kin.heading` is not
      read: a body may point one way and move another, and the words speak of travel.
    "is negative with magnitude greater than speed_tolerance" — the component strictly below
      `−speed_tolerance`, the formal parameter the caller fills.

  Readings chosen (declared as narrowings below).
    1. The component is the dot product with the direction *as the atom is read* — normalised to
       within a factor of at least 1 and below 1 + 2·10⁻⁶ (`st.lane_direction`'s contract), not
       with an exactly unit vector, since no operator takes a vector's length. So the component is
       the true component along the designated direction to within that factor.
    2. "negative with magnitude greater than speed_tolerance" is written strictly: a component of
       exactly `−speed_tolerance` is no motion along the direction, as the parameter's own meaning
       ("at or below which a sampled reading counts as no motion") states.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.travels_against_region_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The components of `u`'s velocity in the world frame. -/
def velX : Term := .measure "kin_velocity" [aU, .lit "x"]
def velY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The components of the direction of travel designated for `r`, read normalised. -/
def dirX : Term := .measure "st_lane_direction" [aR, .lit "x"]
def dirY : Term := .measure "st_lane_direction" [aR, .lit "y"]

/-- The component of `u`'s velocity along the direction designated for `r`: the dot product of the
    velocity with that direction, unknown wherever either atom is. -/
def componentAlongDirection : Term := .add (.mul velX dirX) (.mul velY dirY)

/-- The footprint overlaps the caller's region, and the component of the velocity along the
    direction designated for it is below `−speed_tolerance`: motion opposed to that direction. -/
def body : Formula :=
  .and (.atom "rel_occupies" [aU, aR] [])
       (.cmp componentAlongDirection .lt (.neg pSpeedTolerance))

def concept : Concept :=
  { id := "drv.motion.travels_against_region_direction"
    contract := "The road user is travelling against the direction of travel designated for a given region at this observation: its footprint overlaps that region, the region carries a designated direction of travel, and the component of its velocity along that direction is negative with magnitude greater than speed_tolerance, the bound within which a sampled velocity counts as no motion along the direction. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes motion opposed to the designated direction; it is not a judgement of which side of a centre line or of the roadway the body is on, not a turn, a reversing manoeuvre or a lane change (a body that backs along a one-way street still moves against the direction when its velocity does), and it says nothing about the kind of the region — a region that carries a direction need not be a one-way roadway. Where the region carries no direction, or the direction is a zero vector, the concept is unknown, as that atom's contract requires."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of its velocity along that direction"
          why := "written as the dot product of kin.velocity with st.lane_direction as that atom is read — normalised to within a factor of at least 1 and below 1 + 2·10⁻⁶, not an exactly unit vector, since no operator takes a vector's length; the component is therefore the component along the designated direction to within that factor."
          kind := "reading" }
      , { span := "is negative with magnitude greater than speed_tolerance"
          why := "written strictly: the component is below −speed_tolerance, so a component of exactly −speed_tolerance counts as no motion along the direction, as the parameter's meaning (the magnitude 'at or below which a sampled reading counts as no motion') states."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.travels_against_region_direction
