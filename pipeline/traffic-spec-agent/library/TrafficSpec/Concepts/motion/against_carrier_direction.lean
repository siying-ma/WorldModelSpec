/-
  drv.motion.against_carrier_direction — A road user moves against the designated direction of a travel carrier at the observation. It holds where the road user is moving (drv.motion.moving with speed_floor) and the component of its velocity along the carrier's designated direction is below minus opposed_cosine times its speed: the angle between its velocity and that direction is wider than the angle whose cosine is minus opposed_cosine. Velocity (kin.velocity) and speed (kin.speed) are in m/s in the world frame; the designated direction (st.lane_direction) is read normalised and is unknown where the carrier carries none. Crossing the carrier, or any motion at a smaller angle to the designated direction than that, is not against it. Not denoted: the road user's heading opposing the carrier (a body backing along a lane faces against it but moves with it), two road users being oncoming, or the road user being on the carrier: the caller states occupancy.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user is moving (drv.motion.moving with speed_floor): atoms [], concepts ['drv.motion.moving']
    Velocity (kin.velocity) and speed (kin.speed) are in m/s in the world frame: atoms ['kin.velocity', 'kin.speed'], concepts []
    the designated direction (st.lane_direction) is read normalised and is unknown where the carrier carries none: atoms ['st.lane_direction'], concepts []

  Written as drv_motion_moving(x; speed_floor) ∧ vx·dx + vy·dy < −(opposed_cosine · speed), with
  kin_velocity of x and st_lane_direction of r read by their "x" and "y" world-frame components
  (st_lane_direction normalised by the evaluator, unknown where r carries none) and kin_speed of x
  as the speed. "below" is strict, as the words say. kin.heading is not read, nor is occupancy of r
  (the caller states it). No narrowing: the contract fixes the reading.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.against_carrier_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"
def pOpposedCosine : Term := .param "opposed_cosine"

/-- The component of `x`'s velocity along `r`'s designated direction (read normalised): the dot
    product of the `kin_velocity` and `st_lane_direction` world-frame components. -/
def alongCarrier : Term :=
  .add (.mul (.measure "kin_velocity" [aX, .lit "x"]) (.measure "st_lane_direction" [aR, .lit "x"]))
       (.mul (.measure "kin_velocity" [aX, .lit "y"]) (.measure "st_lane_direction" [aR, .lit "y"]))

/-- `x` is moving, and that component is below minus `opposed_cosine` times `x`'s speed. -/
def body : Formula :=
  .and (.derived "drv_motion_moving" [aX] [pSpeedFloor])
       (.cmp alongCarrier .lt (.neg (.mul pOpposedCosine (.measure "kin_speed" [aX]))))

def concept : Concept :=
  { id := "drv.motion.against_carrier_direction"
    contract := "A road user moves against the designated direction of a travel carrier at the observation. It holds where the road user is moving (drv.motion.moving with speed_floor) and the component of its velocity along the carrier's designated direction is below minus opposed_cosine times its speed: the angle between its velocity and that direction is wider than the angle whose cosine is minus opposed_cosine. Velocity (kin.velocity) and speed (kin.speed) are in m/s in the world frame; the designated direction (st.lane_direction) is read normalised and is unknown where the carrier carries none. Crossing the carrier, or any motion at a smaller angle to the designated direction than that, is not against it. Not denoted: the road user's heading opposing the carrier (a body backing along a lane faces against it but moves with it), two road users being oncoming, or the road user being on the carrier: the caller states occupancy."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := [⟨"speed_floor", .metrePerSecond⟩, ⟨"opposed_cosine", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.against_carrier_direction
