/-
  drv.lane.travels_with_region_direction — At the observation the road user is moving along the structure region given to it in the direction that region designates for travel: its speed is at least speed_floor, so that it is moving at all, and the component of its velocity along the region's designated direction of travel is positive with the cosine of the angle between them at least cos_min. The region is the caller's: the concept reads the direction of that region and of no other. Where the region carries no designated direction, or the direction or the velocity is unobserved, the concept is unknown. Not a stand-in for: occupancy of the region -- the caller states that with its own relation -- the lane the road user ought to be in, a turn or a lane change, the road user's heading where that differs from its velocity, or the legal designation of the way.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along the region's designated direction of travel is positive with the cosine of the angle between them at least cos_min: atoms ['kin.velocity', 'st.lane_direction'], concepts []
      The component of the velocity along the designated direction is the scalar product of the
      velocity with that direction: `kin_velocity u · st_lane_direction r`, written componentwise
      over the two components the measured vector atoms carry (`x`, `y`, the world frame both are
      written in). `st.lane_direction` is read normalised by its own contract — the unit vector up
      to a micrometre of length — so that scalar product is already the component in metres per
      second, and the region whose direction is read is the formal `r` and no other.
      "is positive": the component above zero.
      "the cosine of the angle between them at least cos_min": the cosine is that component divided
      by the speed (the direction being of unit length), and a bound on a quotient is written as a
      bound on a product, since a divisor reads no measured atom and a halted road user's speed is
      zero: the component is at least cos_min times `kin_speed u`. See the narrowing.
    its speed is at least speed_floor, so that it is moving at all: atoms ['kin.speed'], concepts []
      `kin_speed u` at least the formal parameter speed_floor.

  Unknown, not false, follows from the atoms: where the velocity, the speed or the designated
  direction of `r` is unobserved — and where `r` carries no lane direction at all, or a zero one —
  the measured atom is unknown, so the comparison that reads it is, and so is the body.

  No magnitude below is this file's own: parameters are formals the caller fills; the only literal
  is the zero the positivity of the component is stated against.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.travels_with_region_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pCosMin : Term := .param "cos_min"
def pSpeedFloor : Term := .param "speed_floor"

/-- The road user's speed: the magnitude of its velocity. -/
def speed : Term := .measure "kin_speed" [aU]

/-- The components of the road user's velocity, in the world frame (m/s). -/
def vX : Term := .measure "kin_velocity" [aU, .lit "x"]
def vY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The components of the direction region `r` designates for travel, read normalised (no unit). -/
def dX : Term := .measure "st_lane_direction" [aR, .lit "x"]
def dY : Term := .measure "st_lane_direction" [aR, .lit "y"]

/-- The component of the velocity along the designated direction: their scalar product (m/s),
    unknown wherever either vector is. -/
def alongDirection : Term := .add (.mul vX dX) (.mul vY dY)

/-- Zero, in the unit of that component. -/
def zeroSpeed : Term := .lit (Units.metresPerSecond 0) .metrePerSecond

/-- Moving at all, and moving along the direction `r` designates: the component of the velocity on
    that direction positive, and at least cos_min times the speed (the cosine bound). -/
def body : Formula :=
  .and (.cmp speed .ge pSpeedFloor)
    (.and (.cmp alongDirection .gt zeroSpeed)
      (.cmp alongDirection .ge (.mul pCosMin speed)))

def concept : Concept :=
  { id := "drv.lane.travels_with_region_direction"
    contract := "At the observation the road user is moving along the structure region given to it in the direction that region designates for travel: its speed is at least speed_floor, so that it is moving at all, and the component of its velocity along the region's designated direction of travel is positive with the cosine of the angle between them at least cos_min. The region is the caller's: the concept reads the direction of that region and of no other. Where the region carries no designated direction, or the direction or the velocity is unobserved, the concept is unknown. Not a stand-in for: occupancy of the region -- the caller states that with its own relation -- the lane the road user ought to be in, a turn or a lane change, the road user's heading where that differs from its velocity, or the legal designation of the way."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"cos_min", .ratio⟩, ⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the cosine of the angle between them at least cos_min"
          why := "The cosine is the component of the velocity along the designated direction divided by the speed, the direction being of unit length by `st.lane_direction`'s contract (normalised to within a micrometre of length). A divisor reads no measured atom — a halted road user's speed is zero — so the bound on that quotient is written as the bound on a product: the component at least cos_min times `kin_speed u`. The two agree wherever the speed is positive, which the speed_floor conjunct requires, and where the speed is zero the product form is false where the quotient would be undefined: a road user at rest travels in no direction, which is what the contract's own words say the floor is for."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.travels_with_region_direction
