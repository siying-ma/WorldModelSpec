/-
  drv.motion.backing — The road user moves in the direction opposite to the one its body points at the observation: the component of its velocity along its heading is at or below the backing speed tolerance the caller sets, taken negative. The tolerance is the observer's: a sampled velocity never stands exactly at zero along the heading, so the caller sets the magnitude of rearward motion below which a measured velocity does not stand clear of none, and it is no measure of how far or how fast a road user must go backwards to matter, which is the business of the law that calls the concept. The concept is a state of motion at an instant, read from the road user's own velocity and the direction its body points: it says nothing about how long the road user has moved that way, nothing about where on the road it is or what regions its footprint overlaps, nothing about what it is about to do, and nothing about the lawfulness of the movement. It is not the selected gear - a vehicle in a forward gear rolls backwards on a grade and one with reverse selected stands still - not the reversing or brake lamps, not a turning of the body, and not a halt.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along its heading is at or below the backing speed tolerance the caller sets, taken negative: atoms ['kin.velocity', 'kin.heading'], concepts []

  How the element is written:

    "the component of its velocity along its heading" — the inner product of the two vectors the
    ontology carries for the formal `u` in the world frame: `kin_velocity` (the velocity vector,
    m/s) and `kin_heading` (the direction the body points). Both are read component by component
    through the component selector the measured atoms take (`.lit "x"`, `.lit "y"`, the only two
    the accessor decodes), and the inner product is written as the sum of the two products
    `v_x·h_x + v_y·h_y`. This is the signed speed of the body along its own axis: positive where
    the body moves the way it points, negative where it moves the opposite way, which is what
    "the component of its velocity along its heading" names. No normalization is written around
    the heading: the accessor for `kin_heading` returns the unit vector of the field
    (`Geom.unit`), so the product already carries m/s, the unit of the formal parameter, and no
    division by a measured length is needed — nor would one be allowed, a measured magnitude
    being able to stand at zero.

    "is at or below the backing speed tolerance the caller sets, taken negative" — the comparison
    `.le` of that component against `.neg` of the formal parameter `backing_speed_tolerance`.
    The parameter is the magnitude of rearward motion the caller's source can tell from none; the
    bound the component must reach is that magnitude taken negative, so the concept holds exactly
    where the body moves rearward by at least the caller's resolution. A road user moving
    forward, and one standing, have a component at or above zero and can never satisfy the bound
    where the caller sets a positive tolerance.

  Nothing else is read. `kin.gear` is not read — the contract excludes it, and so does the gear
  atom's own contract; no lamp is read (there is no reversing-lamp atom, and `sig.brake_lamp`
  carries nothing about direction); `kin.speed` is a magnitude without sign and `kin.yaw_rate` a
  turning of the body, and neither is claimed nor read. The whole body is one comparison at the
  instant: no window, no look-back, no look-ahead, no region, no other road user.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.backing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pBackingSpeedTolerance : Term := .param "backing_speed_tolerance"

/-- The component of the road user's velocity along the x axis of the world frame, m/s. -/
def velocityX : Term := .measure "kin_velocity" [aU, .lit "x"]

/-- The component of the road user's velocity along the y axis of the world frame, m/s. -/
def velocityY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The x component of the unit vector the road user's body points at. -/
def headingX : Term := .measure "kin_heading" [aU, .lit "x"]

/-- The y component of the unit vector the road user's body points at. -/
def headingY : Term := .measure "kin_heading" [aU, .lit "y"]

/-- The component of the velocity along the heading: the inner product of the velocity vector
    with the unit vector the body points at, in m/s. Signed — negative exactly where the body
    moves opposite to the direction it points. -/
def velocityAlongHeading : Term :=
  .add (.mul velocityX headingX) (.mul velocityY headingY)

/-- The road user moves in the direction opposite to the one its body points: the component of
    its velocity along its heading is at or below the caller's tolerance taken negative. -/
def body : Formula :=
  .cmp velocityAlongHeading .le (.neg pBackingSpeedTolerance)

def concept : Concept :=
  { id := "drv.motion.backing"
    contract := "The road user moves in the direction opposite to the one its body points at the observation: the component of its velocity along its heading is at or below the backing speed tolerance the caller sets, taken negative. The tolerance is the observer's: a sampled velocity never stands exactly at zero along the heading, so the caller sets the magnitude of rearward motion below which a measured velocity does not stand clear of none, and it is no measure of how far or how fast a road user must go backwards to matter, which is the business of the law that calls the concept. The concept is a state of motion at an instant, read from the road user's own velocity and the direction its body points: it says nothing about how long the road user has moved that way, nothing about where on the road it is or what regions its footprint overlaps, nothing about what it is about to do, and nothing about the lawfulness of the movement. It is not the selected gear - a vehicle in a forward gear rolls backwards on a grade and one with reverse selected stands still - not the reversing or brake lamps, not a turning of the body, and not a halt."
    definition := none
    args := [("u", .track)]
    params := [⟨"backing_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of its velocity along its heading"
          why := "Written as the inner product of the two vectors the ontology carries in the world frame: the sum of the products of their x components and of their y components, `kin_velocity` and `kin_heading` each read through the component selector their accessor decodes. The ontology carries no atom for a longitudinal component of velocity, and `kin.speed` is a magnitude that carries no sign, so the signed component along the body axis can only be written as this product. No division by the length of the heading vector is written: the accessor for `kin_heading` returns the unit vector of the field, so the product is already in m/s, the unit of the formal parameter — and a division by a measured length would be unknown wherever that length stood at zero."
          kind := "reading" }
      , { span := "is at or below the backing speed tolerance the caller sets, taken negative"
          why := "Written `.le` against `.neg` of the formal parameter, inclusive: a component standing exactly at minus the tolerance counts as backing, which is what 'at or below' says. The parameter itself is the magnitude of rearward motion the caller's source can tell from none, a positive figure, and the bound is its negation rather than the parameter itself: the comparison is on the signed component, so the sign of the bound is what makes the concept read rearward motion and not forward motion of the same magnitude. A road user moving forward, and one standing, have a component at or above zero and so fail the bound for any positive tolerance the caller sets."
          kind := "reading" }
      , { span := "at the observation"
          why := "No temporal operator is written: the body is one comparison evaluated at the instant, so the concept says nothing about how long the road user has moved that way and nothing about what it is about to do. Where the source does not observe the velocity or the heading at an instant, the comparison is unknown at that instant and never false — the product of an unobserved component with an observed one carries the absence through."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.backing
