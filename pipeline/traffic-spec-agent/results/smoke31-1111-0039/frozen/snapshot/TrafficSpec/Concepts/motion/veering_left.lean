/-
  drv.motion.veering_left — Road user x departs to the left of a travel carrier's designated direction at the observation: it moves forward along the carrier while its velocity points to the left of the carrier's direction by more than a tolerance. It holds where x is moving (drv.motion.moving with speed_floor), the component of its velocity (kin.velocity, m/s, world frame) along the carrier's designated direction (st.lane_direction, read normalised) is positive, and the cross product of that direction with the velocity, left positive, exceeds sine_tolerance times x's speed (kin.speed): the sine of the angle from the designated direction to the velocity is above sine_tolerance. Unknown where the carrier carries no designated direction. Not denoted: x's heading (a body may point across a carrier while moving along it), motion against the carrier's direction, x being on the carrier (the caller states occupancy), a signal, or how far x has moved sideways.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    x is moving (drv.motion.moving with speed_floor): atoms [], concepts ['drv.motion.moving']
    its velocity (kin.velocity, m/s, world frame): atoms ['kin.velocity'], concepts []
    the carrier's designated direction (st.lane_direction, read normalised): atoms ['st.lane_direction'], concepts []
    x's speed (kin.speed): atoms ['kin.speed'], concepts []

  Written as the conjunction of three conditions:
    - `drv_motion_moving x speed_floor`;
    - `dX·vX + dY·vY > 0`, d the components of `st_lane_direction c` (Core reads it normalised),
      v those of `kin_velocity x`: the velocity's component along the designated direction is
      positive;
    - `dX·vY − dY·vX > sine_tolerance · kin_speed x`: the cross product, left positive (+x east,
      +y north, so a counter-clockwise turn from d is positive), above the tolerance times the
      speed; no division by a measurement, as the record states.
  A missing designated direction leaves both comparisons unknown, so the body is unknown wherever
  x is moving; the contract fixes every comparison as strict, and no narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.veering_left

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aC : Arg := .var "c"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"
def pSineTolerance : Term := .param "sine_tolerance"

/-- Components of x's velocity and of c's designated direction (read normalised by Core). -/
def vX : Term := .measure "kin_velocity" [aX, .lit "x"]
def vY : Term := .measure "kin_velocity" [aX, .lit "y"]
def dX : Term := .measure "st_lane_direction" [aC, .lit "x"]
def dY : Term := .measure "st_lane_direction" [aC, .lit "y"]

/-- x is moving (drv.motion.moving with speed_floor). -/
def moving : Formula := .derived "drv_motion_moving" [aX] [pSpeedFloor]

/-- The component of the velocity along the designated direction is positive: d · v > 0. -/
def forward : Formula :=
  .cmp (.add (.mul dX vX) (.mul dY vY)) .gt (.lit Q.zero .metrePerSecond)

/-- The cross product of the direction with the velocity, left positive, exceeds sine_tolerance
    times x's speed: d × v = dX·vY − dY·vX > sine_tolerance · kin_speed x. -/
def leftOfDirection : Formula :=
  .cmp (.sub (.mul dX vY) (.mul dY vX)) .gt (.mul pSineTolerance (.measure "kin_speed" [aX]))

def body : Formula :=
  .and moving (.and forward leftOfDirection)

def concept : Concept :=
  { id := "drv.motion.veering_left"
    contract := "Road user x departs to the left of a travel carrier's designated direction at the observation: it moves forward along the carrier while its velocity points to the left of the carrier's direction by more than a tolerance. It holds where x is moving (drv.motion.moving with speed_floor), the component of its velocity (kin.velocity, m/s, world frame) along the carrier's designated direction (st.lane_direction, read normalised) is positive, and the cross product of that direction with the velocity, left positive, exceeds sine_tolerance times x's speed (kin.speed): the sine of the angle from the designated direction to the velocity is above sine_tolerance. Unknown where the carrier carries no designated direction. Not denoted: x's heading (a body may point across a carrier while moving along it), motion against the carrier's direction, x being on the carrier (the caller states occupancy), a signal, or how far x has moved sideways."
    definition := none
    args := [("x", .track), ("c", .region)]
    params := [⟨"speed_floor", .metrePerSecond⟩, ⟨"sine_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.veering_left
