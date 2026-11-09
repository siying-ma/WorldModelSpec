/-
  drv.position.direction_component — The component, in metres per second, of a road user's velocity along the designated direction of travel of a structure region: positive where the road user moves with that direction, negative where it moves against it, and near zero where it stands or moves across it. The region's direction is read normalised, as its atom states, so the value is a speed along that direction. The quantity is geometric only: it does not state that the road user is on the region, that the region is the one a law names, or how far the road user is from it, and a caller states those with its own relations. Unknown where the road user's velocity is absent and where the region carries no designated direction — a centre turn lane carries none, and a place no carrier covers has none. Not a stand-in for: the direction the body points, which a road user may hold while moving another way, the road user's speed, which is unsigned, or an angle between the two directions.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a road user's velocity: atoms ['kin.velocity'], concepts []
    the designated direction of travel of a structure region: atoms ['st.lane_direction'], concepts []

  How the words are written.
    "a road user's velocity" — `kin_velocity u`, read component by component: the measured atom is a
    vector and a formula reads a vector atom through a component literal ("x", "y"), the two
    world-frame components (+x east, +y north). Nothing else of the road user's motion is read: not
    `kin_speed` (unsigned) and not `kin_heading` (the direction the body points), both of which the
    contract rules out.
    "the designated direction of travel of a structure region" — `st_lane_direction r`, likewise by
    component. The region is the formal `r`, the one the caller singles out; the body quantifies over
    no region of its own, so it says nothing about the road user being on `r` or about which region a
    law names — "geometric only", as the contract has it.
    "The component ... along the designated direction" — the planar scalar projection: vx·dx + vy·dy.
    The atom's own contract says a formula reads the direction normalised, so the second factor is a
    unit vector and the sum is a speed along it, signed: positive with the designation, negative
    against it, zero where the road user stands or moves across it. No magnitude is compared here, so
    "near zero" is the caller's business and the concept takes no parameter.
    Unknown. Both atoms are read unguarded, so the product and hence the sum is unknown exactly where
    either is: a velocity the source does not observe, and a region with no designated direction (a
    centre turn lane, a place no carrier covers, a zero vector). No `definedWhen` is needed and none is
    written: adding one would only duplicate what the arithmetic already gives.

  Narrowing declared below: the projection as a two-component sum (see `narrowings`).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.position.direction_component

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- A component of the road user's velocity, in m/s, in the world frame. -/
def velocity (k : String) : Term := .measure "kin_velocity" [aU, .lit k]

/-- A component of the region's designated direction of travel, read normalised (unit vector). -/
def direction (k : String) : Term := .measure "st_lane_direction" [aR, .lit k]

/-- The scalar projection of the velocity on the designated direction: vx·dx + vy·dy, in m/s,
    signed with the designation. Unknown wherever either atom is unobserved. -/
def body : Term :=
  .add (.mul (velocity "x") (direction "x"))
       (.mul (velocity "y") (direction "y"))

def concept : Concept :=
  { id := "drv.position.direction_component"
    contract := "The component, in metres per second, of a road user's velocity along the designated direction of travel of a structure region: positive where the road user moves with that direction, negative where it moves against it, and near zero where it stands or moves across it. The region's direction is read normalised, as its atom states, so the value is a speed along that direction. The quantity is geometric only: it does not state that the road user is on the region, that the region is the one a law names, or how far the road user is from it, and a caller states those with its own relations. Unknown where the road user's velocity is absent and where the region carries no designated direction — a centre turn lane carries none, and a place no carrier covers has none. Not a stand-in for: the direction the body points, which a road user may hold while moving another way, the road user's speed, which is unsigned, or an angle between the two directions."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "The component, in metres per second, of a road user's velocity along the designated direction of travel of a structure region"
          why := "Written as the planar scalar projection vx·dx + vy·dy over the two world-frame components the vector atoms expose (`kin_velocity`, `st_lane_direction`, each read with a component literal), the direction being the normalised one its atom states. The contract names a component along a direction without saying how it is formed; this is the only reading the available atoms allow, and it leaves the height out because the world is planar."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.position.direction_component
