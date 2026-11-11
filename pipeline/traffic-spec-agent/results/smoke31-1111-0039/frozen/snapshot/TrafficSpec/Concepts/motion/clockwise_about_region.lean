/-
  drv.motion.clockwise_about_region — A road user moves clockwise about a structure region's reference point at the observation, viewed from above in the world frame, whose positive sense of rotation is counter-clockwise (the sense in which a yaw rate is positive). It holds where the road user is moving (drv.motion.moving with speed_floor) and the cross product of the vector from the region's reference point to the road user's reference point with the road user's velocity is negative and larger in magnitude than sine_tolerance times the product of that vector's length and the road user's speed, compared as squares: the sine of the angle from that radius vector to the velocity is below minus sine_tolerance. The region's reference point is read from st.region_geometry, the road user's from kin.position, its velocity from kin.velocity and its speed from kin.speed, in m and m/s. Motion toward or away from the reference point, within the tolerance, is neither sense. Not denoted: travel against a carrier's designated direction, a change of the road user's heading, or the road user being inside the region: the caller states occupancy.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user is moving (drv.motion.moving with speed_floor): atoms [], concepts ['drv.motion.moving']
      written as the call `drv_motion_moving x speed_floor`.
    The region's reference point is read from st.region_geometry, the road user's from kin.position, its velocity from kin.velocity and its speed from kin.speed: atoms ['st.region_geometry', 'kin.position', 'kin.velocity', 'kin.speed'], concepts []
      the radius vector d = kin_position(x) − st_region_geometry(r) by "x" and "y" components
      (the region's reference point, not its boundary or distance); c = dx·vy − dy·vx with v =
      kin_velocity(x); the body is c < 0 (written dx·vy < dy·vx, a zero
      literal carrying no unit of m²/s) ∧ c·c > sine_tolerance²·(dx² + dy²)·kin_speed(x)², the
      contract's comparison "as squares" (both strict, as "negative" and "larger" say). Occupancy
      of r is not read: the caller states it. No narrowing: the contract fixes the reading.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.clockwise_about_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"
def pSineTolerance : Term := .param "sine_tolerance"

/-- The radius vector from `r`'s reference point to `x`'s reference point, by world-frame component. -/
def radiusX : Term := .sub (.measure "kin_position" [aX, .lit "x"]) (.measure "st_region_geometry" [aR, .lit "x"])
def radiusY : Term := .sub (.measure "kin_position" [aX, .lit "y"]) (.measure "st_region_geometry" [aR, .lit "y"])

/-- The two products whose difference is the cross product of the radius vector with `x`'s
    velocity (positive counter-clockwise): dx·vy and dy·vx. -/
def crossPlus : Term := .mul radiusX (.measure "kin_velocity" [aX, .lit "y"])
def crossMinus : Term := .mul radiusY (.measure "kin_velocity" [aX, .lit "x"])

/-- The cross product dx·vy − dy·vx. -/
def cross : Term := .sub crossPlus crossMinus

/-- The squared length of the radius vector. -/
def radiusSq : Term := .add (.mul radiusX radiusX) (.mul radiusY radiusY)

/-- `x`'s speed. -/
def speed : Term := .measure "kin_speed" [aX]

/-- `x` is moving, the cross product is negative, and its square exceeds the square of
    sine_tolerance times the radius length times the speed. -/
def body : Formula :=
  .and (.derived "drv_motion_moving" [aX] [pSpeedFloor])
    (.and (.cmp crossPlus .lt crossMinus)
      (.cmp (.mul cross cross) .gt
        (.mul (.mul pSineTolerance pSineTolerance) (.mul radiusSq (.mul speed speed)))))

def concept : Concept :=
  { id := "drv.motion.clockwise_about_region"
    contract := "A road user moves clockwise about a structure region's reference point at the observation, viewed from above in the world frame, whose positive sense of rotation is counter-clockwise (the sense in which a yaw rate is positive). It holds where the road user is moving (drv.motion.moving with speed_floor) and the cross product of the vector from the region's reference point to the road user's reference point with the road user's velocity is negative and larger in magnitude than sine_tolerance times the product of that vector's length and the road user's speed, compared as squares: the sine of the angle from that radius vector to the velocity is below minus sine_tolerance. The region's reference point is read from st.region_geometry, the road user's from kin.position, its velocity from kin.velocity and its speed from kin.speed, in m and m/s. Motion toward or away from the reference point, within the tolerance, is neither sense. Not denoted: travel against a carrier's designated direction, a change of the road user's heading, or the road user being inside the region: the caller states occupancy."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := [⟨"speed_floor", .metrePerSecond⟩, ⟨"sine_tolerance", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.clockwise_about_region
