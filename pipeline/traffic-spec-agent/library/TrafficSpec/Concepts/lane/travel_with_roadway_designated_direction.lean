/-
  drv.lane.travel_with_roadway_designated_direction — The road user travels along a roadway of the kind named in the direction that roadway is designated for: its footprint overlaps a region of that kind, and the component of its velocity along that region's designated direction of travel is at least the along-roadway speed tolerance the caller sets. The designated direction is a direction of unit length, so the inner product of the velocity with it is already the component in metres per second. The tolerance is the observer's and names the along-roadway speed below which a measured velocity does not stand clear of zero; it is no measure of how fast the road user must go, nor of how long it must have gone that way. The concept is a state of motion at an instant, read from the road user's own velocity and the region's designation: it says nothing about the lawfulness of the direction, nothing about any sign, marking or device that announces or governs the designation, nothing about which other regions the footprint overlaps, and nothing about the compass direction of travel. It is not the road user's heading - a body that points along the roadway while rolling backwards along it does not satisfy it, and one that points across the roadway while drifting along it does - not a lane change, and not a turning. Where the region its footprint overlaps carries no designated direction, the concept is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps a region of that kind: atoms ['rel.occupies', 'st.roadway', 'st.one_way_roadway'], concepts []
    the component of its velocity along that region's designated direction of travel: atoms ['kin.velocity', 'st.lane_direction'], concepts []

  How each element is written:

    "its footprint overlaps a region of that kind" — one existential over the regions of the kind
    the caller names, `.existsRegion (.var "kind") "r" …`, whose body reads that one region's
    overlap with the formal `u` through `rel_occupies u r`. The quantifier's kind is the literal
    formal itself, so the caller's spelling decides which region atom is read: `st_roadway` where
    the formal is filled with `roadway`, `st_one_way_roadway` where it is filled with
    `one_way_roadway` — the two atoms the element claims, each read by the quantifier of the
    region it ranges over (a region whose kind the source cannot tell is a candidate of the
    quantifier and its kind is read as unknown, so such a region never silently decides the
    concept either way). `rel_occupies` is the anchor that makes the region the road user's own
    and not any region of the scene; the region's boundary and the road user's distance to it are
    not read, which is what that atom's contract excludes against `st.region_geometry`. No other
    region kind is quantified over, nothing counts the regions the footprint overlaps and nothing
    excludes a footprint that overlaps others: "which other regions the footprint overlaps" is
    not read at all.

    "the component of its velocity along that region's designated direction of travel" — the inner
    product of the road user's velocity vector with the region's designated direction, written
    component by component over the two atoms' component positions:
    `(kin_velocity u x · st_lane_direction r x) + (kin_velocity u y · st_lane_direction r y)`,
    and compared `.ge` against the formal parameter `along_roadway_speed_tolerance`. The direction
    read is the designation of the one bound region `r`, the region whose overlap the conjunct
    beside it requires, and the velocity read is the formal's own. `kin_heading` is nowhere in the
    body, so a body that points along the roadway while rolling backwards along it gives a
    negative component and fails, and one that points across the roadway while drifting along it
    gives a positive component and holds, as the contract requires; `kin_speed` is not read, since
    it carries no direction, and no device, sign or marking is read. Nothing compares the
    direction with a compass bearing, nothing normalizes it (the contract states it is of unit
    length) and nothing divides by a measured quantity.

  The unknowns are the atoms': an unobserved occupancy leaves the overlap conjunct unknown, an
  unobserved velocity or an unobserved designated direction leaves the comparison unknown, and
  where no region of the kind decides the conjunction true the concept is unknown rather than
  false — which is the contract's last sentence. Nothing of the body looks before or after the
  observation: no window, no edge and no `since`, so the concept is the state of motion at the
  instant the contract says it is, and no lane change or turning is read.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.travel_with_roadway_designated_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aKind : Arg := .var "kind"

/-- The region of the named kind the body quantifies over: bound inside the body, not a formal. -/
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlongRoadwaySpeedTolerance : Term := .param "along_roadway_speed_tolerance"

/-- A component of the road user's own velocity vector, in m/s, in the world frame. -/
def velocityComponent (axis : String) : Term := .measure "kin_velocity" [aU, .lit axis]

/-- A component of the direction of travel the region is designated for: a direction of unit
    length, local to the region that carries it. -/
def designatedDirectionComponent (axis : String) : Term :=
  .measure "st_lane_direction" [aR, .lit axis]

/-- The road user's footprint overlaps the region: the anchor that makes the region its own. -/
def occupiesRegion : Formula := .atom "rel_occupies" [aU, aR] []

/-- The component of the velocity along the region's designated direction, in m/s: the inner
    product of the velocity with that unit direction. -/
def alongRegionDirection : Term :=
  .add (.mul (velocityComponent "x") (designatedDirectionComponent "x"))
       (.mul (velocityComponent "y") (designatedDirectionComponent "y"))

/-- That component is at least the tolerance the caller sets. -/
def standsClearOfZeroAlongRegion : Formula :=
  .cmp alongRegionDirection .ge pAlongRoadwaySpeedTolerance

/-- A region of the kind the caller names which the footprint overlaps and along whose designated
    direction the velocity's component is at least the tolerance. -/
def body : Formula :=
  .existsRegion aKind "r" (.and occupiesRegion standsClearOfZeroAlongRegion)

def concept : Concept :=
  { id := "drv.lane.travel_with_roadway_designated_direction"
    contract := "The road user travels along a roadway of the kind named in the direction that roadway is designated for: its footprint overlaps a region of that kind, and the component of its velocity along that region's designated direction of travel is at least the along-roadway speed tolerance the caller sets. The designated direction is a direction of unit length, so the inner product of the velocity with it is already the component in metres per second. The tolerance is the observer's and names the along-roadway speed below which a measured velocity does not stand clear of zero; it is no measure of how fast the road user must go, nor of how long it must have gone that way. The concept is a state of motion at an instant, read from the road user's own velocity and the region's designation: it says nothing about the lawfulness of the direction, nothing about any sign, marking or device that announces or governs the designation, nothing about which other regions the footprint overlaps, and nothing about the compass direction of travel. It is not the road user's heading - a body that points along the roadway while rolling backwards along it does not satisfy it, and one that points across the roadway while drifting along it does - not a lane change, and not a turning. Where the region its footprint overlaps carries no designated direction, the concept is unknown."
    definition := none
    args := [("u", .track), ("kind", .literal ["roadway", "one_way_roadway"])]
    params := [⟨"along_roadway_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its footprint overlaps a region of that kind"
          why := "Written as an existential over the regions of the kind the literal formal names, `.existsRegion (.var \"kind\") \"r\"`, with the overlap and the component both read of that one bound region. Two readings the contract leaves open are chosen here. First, the overlap and the designated direction are required of the SAME region: the contract's 'that region's designated direction of travel' speaks of the region the footprint overlaps, so the direction of a region the footprint does not overlap never answers the concept. Second, the quantifier is existential rather than universal: where the footprint overlaps several regions of the kind, one of them whose designated direction carries the component answers the concept, since the contract says nothing about which other regions the footprint overlaps. The kind atoms `st_roadway` and `st_one_way_roadway` are read by the quantifier itself, which conjoins its candidate's kind to the body, rather than by a guard of their own: that is the same reading, and it keeps a region whose kind the source cannot tell undecided instead of letting the quantifier pass it over silently."
          kind := "reading" }
      , { span := "is at least the along-roadway speed tolerance the caller sets"
          why := "Read inclusively, `.ge`: 'at least the tolerance' includes the tolerance itself. The sentence that follows calls the tolerance 'the along-roadway speed below which a measured velocity does not stand clear of zero', which on its own would read strictly; the two are reconciled in favour of the words that state the comparison, so a component exactly at the tolerance satisfies the concept. Nothing of the choice is a magnitude of this file: the bound is the formal parameter, and a caller that wants the strict reading sets a tolerance above the speed it means to exclude."
          kind := "reading" }
      , { span := "the component of its velocity along that region's designated direction of travel"
          why := "Written as the inner product of the two vector atoms, component by component over their `x` and `y` positions, summed with `.add` and multiplied with `.mul`. The contract states the designated direction is of unit length, so no normalization is written: no magnitude of the direction is computed and nothing is divided by a measured quantity, which could be zero and would leave a verdict open rather than decide it. The product is read three-valued: an unobserved velocity component or an unobserved direction component leaves the whole comparison unknown, never false."
          kind := "reading" }
      , { span := "Where the region its footprint overlaps carries no designated direction, the concept is unknown."
          why := "No guard of its own is written for this sentence: it is what the existential already does three-valued. Where a region of the kind is overlapped and its designated direction is unobserved, that region's conjunction is unknown, and the existential over the regions of the kind is unknown unless another region of the kind decides it true. The consequence declared here is that reading's one extra consequence: where the footprint overlaps two regions of the kind, one designated and travelled along and one carrying no designation, the concept holds rather than being unknown — which follows from the existential reading of the span above, under which one region that answers the concept answers it."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.travel_with_roadway_designated_direction
