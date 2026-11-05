/-
  drv.lane.travels_with_region_direction — At this observation the road user's travel is not opposed to the direction designated for the given region: the component of its velocity along that region's designated direction is above the negative of the tolerance, the speed below which a velocity component counts as no travel rather than movement. The direction is the one designated for that region, read normalised, and the region is the one the caller singles out and passes in. The bound is one-sided: the larger the component, the more plainly the road user travels with the designated direction, and a body at rest or crossing the direction satisfies the concept, having no travel against it. The tolerance is the concept's own magnitude, a velocity component being observed over sampled measurements only within a bound the caller sets. It is unknown where the region carries no designated direction or the velocity is not observed. The concept denotes the sense of travel along one region's designated direction only: it is not occupancy of the region, not the heading the body points in, not the lane or the hand of the roadway kept, not a manoeuvre, and not the lawfulness of travelling as it does.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the direction designated for the given region: atoms ['st.lane_direction'], concepts []
      written `.measure "st_lane_direction" [aR, .lit "x"]` and `[aR, .lit "y"]`: the atom is the
      designated direction of the carrier the caller passes in as the region formal `r`, and Core
      reads it normalised (`Geom.unit`) before the component literal selects a coordinate, which is
      the contract's "read normalised". The region is the formal itself: the body quantifies over no
      region, because the contract names the region as an argument ("the one the caller singles out
      and passes in"). Where the carrier covers no direction the atom is unknown, and the
      comparison below is then unknown — the contract's "unknown where the region carries no
      designated direction". The body does not read `kin.heading`: the direction read is the
      region's, not the one the body points in.
    the component of its velocity along that region's designated direction: atoms ['kin.velocity'],
      concepts []
      written `.add (.mul vx dx) (.mul vy dy)` over the world-frame components of `kin.velocity`
      (`[aU, .lit "x"]`, `[aU, .lit "y"]`) and of the normalised designated direction: the inner
      product of the velocity with a unit direction is the signed rate, in m/s, at which the body
      travels with that direction. `kin.speed` is not read (it carries no sense) and `kin.heading`
      is not read (a body may point one way and travel another). Where the velocity is not observed
      both components are unknown, so the comparison is unknown.

  The whole body is the one comparison the contract states: that component above the negative of the
  tolerance (`.cmp component .gt (.neg motion_speed_tolerance)`). Nothing else is read: no
  occupancy of the region (`rel.occupies`), no neighbouring lane or hand of the roadway, no
  manoeuvre and no rule. The bound is one-sided, so a body at rest (component 0) and a body
  crossing the direction (component 0) satisfy it, having no travel against the direction.

  Narrowings (choices the contract left open):
    "is above the negative of the tolerance" — read strictly (`.gt`): the tolerance is 'the speed
      below which a velocity component counts as no travel rather than movement', which leaves the
      component exactly at the negative of the tolerance open; the strict reading keeps that
      component on the side of travel against the direction, so that only components the caller's
      tolerance does not cover decide the concept true.
    "read normalised" — the direction is read as Core reads it, divided by its length to a
      micrometre, so the vector read is the unit direction times a factor in [1, 1 + 2·10⁻⁶) and
      the component computed is the true component times that factor. The discrepancy is below two
      parts in a million of the speed and is absorbed by the caller's tolerance; the body adds no
      normalisation of its own, since the language has no square root and the atom is already read
      this way.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.travels_with_region_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"

/-- The east component of the direction designated for the region the caller passes in, read
    normalised (Core normalises `st.lane_direction` before the component is selected). -/
def directionX : Term := .measure "st_lane_direction" [aR, .lit "x"]

/-- The north component of that designated direction, read normalised. -/
def directionY : Term := .measure "st_lane_direction" [aR, .lit "y"]

/-- The east component of the road user's velocity, m/s in the world frame. -/
def velocityX : Term := .measure "kin_velocity" [aU, .lit "x"]

/-- The north component of the road user's velocity, m/s in the world frame. -/
def velocityY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The component of the road user's velocity along the region's designated direction: the inner
    product of the velocity with the normalised designated direction, in m/s, signed — positive
    with the direction, negative against it, zero at rest or crossing it. Unknown where the region
    carries no designated direction or the velocity is not observed. -/
def componentAlongDirection : Term :=
  .add (.mul velocityX directionX) (.mul velocityY directionY)

/-- The road user's travel is not opposed to the direction designated for the region: the component
    of its velocity along that direction is above the negative of the tolerance, the speed below
    which a velocity component counts as no travel rather than movement. The bound is one-sided. -/
def body : Formula :=
  .cmp componentAlongDirection .gt (.neg pMotionSpeedTolerance)

def concept : Concept :=
  { id := "drv.lane.travels_with_region_direction"
    contract := "At this observation the road user's travel is not opposed to the direction designated for the given region: the component of its velocity along that region's designated direction is above the negative of the tolerance, the speed below which a velocity component counts as no travel rather than movement. The direction is the one designated for that region, read normalised, and the region is the one the caller singles out and passes in. The bound is one-sided: the larger the component, the more plainly the road user travels with the designated direction, and a body at rest or crossing the direction satisfies the concept, having no travel against it. The tolerance is the concept's own magnitude, a velocity component being observed over sampled measurements only within a bound the caller sets. It is unknown where the region carries no designated direction or the velocity is not observed. The concept denotes the sense of travel along one region's designated direction only: it is not occupancy of the region, not the heading the body points in, not the lane or the hand of the roadway kept, not a manoeuvre, and not the lawfulness of travelling as it does."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"motion_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "is above the negative of the tolerance"
          why := "Read strictly (`.gt`). The tolerance is 'the speed below which a velocity component counts as no travel rather than movement', which leaves the component exactly at the negative of the tolerance open; the strict reading keeps that component on the side of travel against the designated direction, so that the concept holds only where the component is covered by the caller's tolerance or plainly with the direction. The bound stays one-sided: no upper bound is written, since the larger the component the more plainly the body travels with the direction."
          kind := "reading" }
      , { span := "read normalised"
          why := "The designated direction is read as Core reads `st.lane_direction` (`Geom.unit`: divided by its larger absolute component, then by its length taken to a micrometre), so the vector read is the unit direction times a factor in [1, 1 + 2·10⁻⁶) and the inner product computed is the true velocity component times that factor. The body adds no normalisation of its own — the formula language has no square root, and the atom is already read this way; the discrepancy, below two parts in a million of the speed, is absorbed by the tolerance the caller sets."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.travels_with_region_direction
