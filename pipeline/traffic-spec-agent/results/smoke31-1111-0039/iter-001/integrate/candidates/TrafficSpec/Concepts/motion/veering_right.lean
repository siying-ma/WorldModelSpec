/-
  drv.motion.veering_right — Road user x departs to the right of a travel carrier's designated direction at the observation: it moves forward along the carrier while its velocity points to the right of the carrier's direction by more than a tolerance. It holds where x is moving (drv.motion.moving with speed_floor), the component of its velocity (kin.velocity, m/s, world frame) along the carrier's designated direction (st.lane_direction, read normalised) is positive, and the cross product of that direction with the velocity, left positive, is below minus sine_tolerance times x's speed (kin.speed): the sine of the angle from the designated direction to the velocity is below minus sine_tolerance. Unknown where the carrier carries no designated direction. Not denoted: x's heading (a body may point across a carrier while moving along it), motion against the carrier's direction, x being on the carrier (the caller states occupancy), a signal, or how far x has moved sideways.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    x is moving (drv.motion.moving with speed_floor): atoms [], concepts ['drv.motion.moving']
    its velocity (kin.velocity, m/s, world frame): atoms ['kin.velocity'], concepts []
    the carrier's designated direction (st.lane_direction, read normalised): atoms ['st.lane_direction'], concepts []
    x's speed (kin.speed): atoms ['kin.speed'], concepts []

  Written: the conjunction of the three conditions, at one observation, with d the designated
  direction of c (`st_lane_direction c`, components "x" and "y", read normalised by Core) and v the
  velocity of x (`kin_velocity x`, components "x" and "y", m/s, world frame).
    moving   — `drv_motion_moving x` with `speed_floor`;
    forward  — the component of v along d positive: d.x·v.x + d.y·v.y > 0;
    right    — the cross product d × v, left positive, below minus sine_tolerance times x's speed:
               d.x·v.y − d.y·v.x < −(sine_tolerance · kin_speed x). No division by a measurement.
  "Unknown where the carrier carries no designated direction": a direction that is not observed
  leaves both `forward` and `right` unknown, so the conjunction is unknown wherever x is moving.
  No choice beyond the contract's words was made; no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.veering_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aC : Arg := .var "c"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"
def pSineTolerance : Term := .param "sine_tolerance"

/-- x is moving: `drv.motion.moving` with `speed_floor`. -/
def moving : Formula := .derived "drv_motion_moving" [aX] [pSpeedFloor]

/-- The components of c's designated direction (read normalised) and of x's velocity (m/s). -/
def dirX : Term := .measure "st_lane_direction" [aC, .lit "x"]
def dirY : Term := .measure "st_lane_direction" [aC, .lit "y"]
def velX : Term := .measure "kin_velocity" [aX, .lit "x"]
def velY : Term := .measure "kin_velocity" [aX, .lit "y"]

/-- The component of x's velocity along c's designated direction is positive. -/
def forward : Formula :=
  .cmp (.add (.mul dirX velX) (.mul dirY velY)) .gt (.lit (Units.metresPerSecond 0) .metrePerSecond)

/-- The cross product of the direction with the velocity, left positive, is below minus
    sine_tolerance times x's speed. -/
def right : Formula :=
  .cmp (.sub (.mul dirX velY) (.mul dirY velX)) .lt
    (.neg (.mul pSineTolerance (.measure "kin_speed" [aX])))

def body : Formula := .and moving (.and forward right)

def concept : Concept :=
  { id := "drv.motion.veering_right"
    contract := "Road user x departs to the right of a travel carrier's designated direction at the observation: it moves forward along the carrier while its velocity points to the right of the carrier's direction by more than a tolerance. It holds where x is moving (drv.motion.moving with speed_floor), the component of its velocity (kin.velocity, m/s, world frame) along the carrier's designated direction (st.lane_direction, read normalised) is positive, and the cross product of that direction with the velocity, left positive, is below minus sine_tolerance times x's speed (kin.speed): the sine of the angle from the designated direction to the velocity is below minus sine_tolerance. Unknown where the carrier carries no designated direction. Not denoted: x's heading (a body may point across a carrier while moving along it), motion against the carrier's direction, x being on the carrier (the caller states occupancy), a signal, or how far x has moved sideways."
    definition := none
    args := [("x", .track), ("c", .region)]
    params := [⟨"speed_floor", .metrePerSecond⟩, ⟨"sine_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.veering_right
