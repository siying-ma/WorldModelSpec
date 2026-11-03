/-
  drv.motion.rearward_motion — The road user is moving backwards at the observation: its body travels in the direction opposite the one it points. The concept holds where the component of the road user's velocity along its own heading is negative and its speed is at least the parameter speed_floor, which is the resolution below which a measured velocity is indistinguishable from noise. It is read at the observation itself, not over a window. Not a stand-in for: the gear selected -- a vehicle in a forward gear rolls backwards on a grade and the motion is read from kinematics -- a halt, a turn, the place the motion happens at, or the distance travelled backwards.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of the road user's velocity along its own heading is negative: atoms ['kin.velocity', 'kin.heading'], concepts []
      Written as the dot product of the velocity with the heading: the velocity's components
      (`kin_velocity` at the selectors "x" and "y", in the world frame, m/s) each multiplied by the
      heading's component on the same axis (`kin_heading`, which a formula reads normalised per its
      contract, so the product is the signed speed along the body's own axis), the two summed and
      required strictly below zero. Both atoms are read at the judged observation: no window, as the
      contract states. The heading's reading convention carries over — a zero heading reads unknown,
      so the concept is unknown where the direction the body points is degenerate; a velocity the
      source does not observe likewise leaves it unknown, never false. `kin.gear` is not read: the
      contract excludes the gear selected as a stand-in for the direction of motion.
    its speed is at least the parameter speed_floor: atoms ['kin.speed'], concepts []
      `kin_speed` (the magnitude of the velocity) at or above the formal parameter `speed_floor`,
      the source's resolution: below it a measured velocity is noise and no rearward motion is
      reported. "at least" is `.ge`, so a speed exactly at the resolution counts as motion.

  Readings this session chose that the contract left open (declared in `narrowings`):
    "the component of the road user's velocity along its own heading is negative" — "negative" is
    read strictly (`.lt` zero): a zero component is motion across the heading or no motion at all,
    not rearward motion. Zero is written through `Q.zero` in m/s, the one magnitude a body may
    carry; every other magnitude is the formal parameter.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.rearward_motion

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"

/-- The direction the body points, normalised by the atom's reading convention, component by
    component in the world frame. -/
def headingX : Term := .measure "kin_heading" [aU, .lit "x"]
def headingY : Term := .measure "kin_heading" [aU, .lit "y"]

/-- The velocity of the body in the world frame, component by component (m/s). -/
def velocityX : Term := .measure "kin_velocity" [aU, .lit "x"]
def velocityY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The component of the velocity along the heading: the dot product of the two, which is the
    signed speed along the axis the body points (m/s, since the heading is read as a unit vector). -/
def alongHeading : Term := .add (.mul velocityX headingX) (.mul velocityY headingY)

/-- The magnitude of the velocity. -/
def speed : Term := .measure "kin_speed" [aU]

/-- No motion along the heading: the zero of the speed scale. -/
def zero : Term := .lit Q.zero .metrePerSecond

/-- Moving backwards: the velocity's component along the heading is negative, and the speed is at
    or above the resolution below which a measured velocity is noise. -/
def body : Formula :=
  .and (.cmp alongHeading .lt zero)
       (.cmp speed .ge pSpeedFloor)

def concept : Concept :=
  { id := "drv.motion.rearward_motion"
    contract := "The road user is moving backwards at the observation: its body travels in the direction opposite the one it points. The concept holds where the component of the road user's velocity along its own heading is negative and its speed is at least the parameter speed_floor, which is the resolution below which a measured velocity is indistinguishable from noise. It is read at the observation itself, not over a window. Not a stand-in for: the gear selected -- a vehicle in a forward gear rolls backwards on a grade and the motion is read from kinematics -- a halt, a turn, the place the motion happens at, or the distance travelled backwards."
    definition := none
    args := [("u", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of the road user's velocity along its own heading is negative"
          why := "read strictly: the component is below zero, so a component of exactly zero (a body moving only across the direction it points, or not moving) is no rearward motion"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.rearward_motion
