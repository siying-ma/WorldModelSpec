/-
  drv.lane.travel_with_designated_direction — The road user travels along a lane in the direction that lane is designated for: its footprint overlaps a lane, and the component of its velocity along that lane's designated direction of travel is at least the tolerance the caller sets. The tolerance is the observer's and names the along-lane speed below which a measured velocity does not stand clear of zero. The concept is a state of motion at an instant, read from the road user's own velocity and the lane's designation: it says nothing about the lawfulness of the direction, nothing about any sign or marking that announces the designation, and nothing about how long the road user has travelled that way. It is not the road user's heading - a body that points along the lane while rolling backwards along it does not satisfy it, and one that points across the lane while drifting along it does - and it is not a lane change.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps a lane: atoms ['st.lane', 'rel.occupies'], concepts []
    the component of its velocity along that lane's designated direction of travel: atoms ['kin.velocity', 'st.lane_direction'], concepts []

  How each element is written:

    "its footprint overlaps a lane" — an existential over the scene's lane regions: a region `ln`
    that is a lane (`st_lane`, read of the bound region, so a region whose kind the source cannot
    tell leaves the conjunct unknown rather than silently true) and whose footprint the road user
    overlaps (`rel_occupies u ln`). `rel_occupies` is exactly "a road user's footprint overlaps a
    lane / region", so the overlap of the words is the atom's own. Only membership is read of the
    lane, never an offset from its edge, which `st.lane`'s exclusion forbids.
    NARROWING: the lane of the second element is the lane of the first — one binder carries both
    conjuncts. "a lane" is therefore read as *there is a lane the road user overlaps and along
    whose designation it travels*, not as *the one lane it is in*: a body straddling a lane line
    travels with the designated direction when it does so for either lane it overlaps.

    "the component of its velocity along that lane's designated direction of travel" — the inner
    product of the velocity vector `kin_velocity u` with the designation `st_lane_direction ln`,
    component by component: vₓ·dₓ + v_y·d_y. Both are vectors of the world frame (`kin.velocity`
    in m/s, `st.lane_direction` a direction of travel), so the inner product is the along-lane
    speed in m/s, signed: positive with the designation, negative against it.
    NARROWING: the designation is taken as a direction of unit length, which is what the ontology
    records it as, so the inner product *is* the component and no normalisation is written. The
    normalised form would divide by the measured length of the designation, and a division by a
    measured quantity is not written here: it is unknown where that quantity is zero, which is a
    defect rather than a verdict.

    "is at least the tolerance the caller sets" — `.ge` against the formal parameter
    `along_lane_speed_tolerance`, so a velocity whose along-lane component does not stand clear of
    zero by the observer's tolerance does not satisfy the concept. The comparison is signed, which
    is what the contract's exclusions ask for: a body rolling backwards along the lane has a
    negative component and fails it however it points, and a body drifting along the lane satisfies
    it however it points, because the heading is never read.

  Nothing about lawfulness, about a sign or marking, about duration, or about a lane change is
  written: the contract excludes them, and no atom of either is claimed.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.travel_with_designated_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlongLaneSpeedTolerance : Term := .param "along_lane_speed_tolerance"

/-- The lane, bound inside the body and anchored to the formal by `rel_occupies`. -/
def aLane : Arg := .var "ln"

/-- Its footprint overlaps a lane. -/
def occupiesLane : Formula :=
  .and (.atom "st_lane" [aLane] [])
    (.atom "rel_occupies" [aU, aLane] [])

/-- The component of its velocity along that lane's designated direction of travel. -/
def alongLaneComponent : Term :=
  .add
    (.mul (.measure "kin_velocity" [aU, .lit "x"]) (.measure "st_lane_direction" [aLane, .lit "x"]))
    (.mul (.measure "kin_velocity" [aU, .lit "y"]) (.measure "st_lane_direction" [aLane, .lit "y"]))

/-- … is at least the tolerance the caller sets. -/
def alongLaneAtLeastTolerance : Formula :=
  .cmp alongLaneComponent .ge pAlongLaneSpeedTolerance

def body : Formula :=
  .existsRegion (.lit "lane") "ln"
    (.and occupiesLane alongLaneAtLeastTolerance)

def concept : Concept :=
  { id := "drv.lane.travel_with_designated_direction"
    contract := "The road user travels along a lane in the direction that lane is designated for: its footprint overlaps a lane, and the component of its velocity along that lane's designated direction of travel is at least the tolerance the caller sets. The tolerance is the observer's and names the along-lane speed below which a measured velocity does not stand clear of zero. The concept is a state of motion at an instant, read from the road user's own velocity and the lane's designation: it says nothing about the lawfulness of the direction, nothing about any sign or marking that announces the designation, and nothing about how long the road user has travelled that way. It is not the road user's heading - a body that points along the lane while rolling backwards along it does not satisfy it, and one that points across the lane while drifting along it does - and it is not a lane change."
    definition := none
    args := [("u", .track)]
    params := [⟨"along_lane_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its footprint overlaps a lane"
          why := "Written as one existential over the scene's lane regions, binding the lane that both elements speak about: there is a region that is a lane (st.lane read of the bound region, not assumed from the quantifier's kind) whose footprint the road user overlaps and along whose designated direction its velocity reaches the tolerance. 'A lane' is therefore read as some lane it overlaps, not as the one lane it is in: a body straddling a lane line satisfies the concept when it travels with the designation of either lane it overlaps."
          kind := "reading" }
      , { span := "the component of its velocity along that lane's designated direction of travel"
          why := "Written as the inner product of the velocity vector with the lane's designation, component by component, with no normalisation: the ontology records st.lane_direction as a direction of travel, a vector of unit length, so the inner product is already the component in m/s. Dividing by the designation's measured length is not written, because a division by a measured quantity is unknown where that quantity is zero. The product is signed, so travel against the designation gives a negative component and fails the comparison."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.travel_with_designated_direction
