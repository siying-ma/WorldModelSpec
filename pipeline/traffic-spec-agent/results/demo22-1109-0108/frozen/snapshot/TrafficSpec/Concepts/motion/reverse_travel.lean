/-
  drv.motion.reverse_travel — The road user is travelling rearward at the observation: the component of its velocity along the direction its body points is at most the negative of the reverse speed tolerance, a speed the caller sets, so that a rearward component smaller than it is read as none. The concept states the direction of the body's motion relative to the direction it points, at the observation only, and says nothing of how long the rearward motion lasts or where it happens. The whole of it is read from the road user's own velocity and the direction its body points, so no structure region, no device and no control state enters it. Not a stand-in for: the gear selected — a body in a forward gear rolls backwards on a grade and one in reverse stands still — a reversing lamp or any other signal, a halt, a turn, the place the motion happens at, or the component of the velocity along a structure region's designated direction of travel, which is a separate quantity read from the region and says nothing of the direction the body points.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along the direction its body points: atoms ['kin.velocity', 'kin.heading'], concepts []
      The component of one vector along another is their inner product with the second taken as a
      unit vector: `v_x · h_x + v_y · h_y` over the two components of the two atoms of the formal
      `u`, with `kin.heading` the direction the body points, which a formula reads normalised (its
      contract: the vector read is the unit vector times a factor of at least 1 and below
      1 + 2·10⁻⁶, exactly the unit vector for an axis-aligned direction), so the product is the
      signed speed in the direction the body points, in m/s. Rearward is that signed speed at most
      the negative of the reverse speed tolerance: `.le (.neg reverse_speed_tolerance)`, so a
      rearward component smaller in magnitude than the tolerance is not read as rearward travel,
      and a forward component never is. Either atom unobserved makes the comparison unknown and
      the body with it, never false.

      No other name enters the body: `kin.speed` is unsigned and says nothing of the direction,
      `kin.gear` is expressly not a stand-in for the direction of motion, and no region, device or
      signal atom is read — in particular neither `st.lane_direction` nor any component along a
      region's designated direction of travel, which the contract names as a separate quantity.

  Readings chosen: none. The contract fixes the quantity (the component of the velocity along the
  heading), the sense of the bound (at most the negative of the tolerance) and the instant it is
  read at (the observation), so nothing here was left open; `narrowings` is empty.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.reverse_travel

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReverseSpeedTolerance : Term := .param "reverse_speed_tolerance"

/-- The component of the road user's velocity along the direction its body points: the inner
    product of its velocity with its heading, which a formula reads normalised. Unknown wherever
    either atom is unobserved. -/
def alongHeading : Term :=
  .add (.mul (.measure "kin_velocity" [aU, .lit "x"]) (.measure "kin_heading" [aU, .lit "x"]))
       (.mul (.measure "kin_velocity" [aU, .lit "y"]) (.measure "kin_heading" [aU, .lit "y"]))

/-- That component is at most the negative of the reverse speed tolerance. -/
def body : Formula :=
  .cmp alongHeading .le (.neg pReverseSpeedTolerance)

def concept : Concept :=
  { id := "drv.motion.reverse_travel"
    contract := "The road user is travelling rearward at the observation: the component of its velocity along the direction its body points is at most the negative of the reverse speed tolerance, a speed the caller sets, so that a rearward component smaller than it is read as none. The concept states the direction of the body's motion relative to the direction it points, at the observation only, and says nothing of how long the rearward motion lasts or where it happens. The whole of it is read from the road user's own velocity and the direction its body points, so no structure region, no device and no control state enters it. Not a stand-in for: the gear selected — a body in a forward gear rolls backwards on a grade and one in reverse stands still — a reversing lamp or any other signal, a halt, a turn, the place the motion happens at, or the component of the velocity along a structure region's designated direction of travel, which is a separate quantity read from the region and says nothing of the direction the body points."
    definition := none
    args := [("u", .track)]
    params := [⟨"reverse_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.reverse_travel
