/-
  drv.interaction.following_on_way — The road user f travels behind the road user l along one and the same public way at the observation: both footprints overlap one and the same public way; neither body is at rest, each one's speed standing above the motion tolerance the caller sets; the cosine of the angle between the directions the two bodies point is at least the alignment tolerance the caller sets; the two move alike with respect to the direction they point, either both forward or both rearward; the offset of l's reference point from f's, taken in f's frame, lies ahead of f along f's own direction of travel by at least the ordering resolution the caller sets, f's direction of travel being the direction f points where f moves forward and the opposite direction where f moves rearward; and the lateral component of that offset is at most the abreast reach the caller sets. The motion tolerance is the observer's: a sampled speed never stands exactly at zero, so the caller sets the magnitude below which a measured speed counts as no movement at all. The alignment tolerance is the observer's too and is a ratio between -1 and 1: it names how nearly the two bodies must point one way for them to count as travelling in one line, absorbing the bend of the way and the noise of a sampled heading. The ordering resolution is the observer's: it names the longitudinal offset below which one reference point does not stand clear of the other along the direction of travel. The abreast reach is the observer's: it names the lateral offset within which the one body travels in the line of the other rather than beside it, and it is no measure of how safe either position is. The concept is a relation at an instant, read from the two bodies' membership of one public way, from their speeds, from the directions they point, from the directions they move and from the offset between their reference points: it says nothing about lanes, lane markings, lane designations, junctions or any device; nothing about how long the one has been behind the other; nothing about either body's acceleration or about whether either is closing on the other; and nothing about whether the space between the two bodies is sufficient, which is the business of the law that calls the concept. The offset it reads is between the two reference points and is not the clearance between the two bodies, which is shorter by about their half-lengths. It is not an overtaking, not a halt, not a contact between the bodies, not a following within one marked lane, and it carries no judgement that the position is safe or lawful.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    both footprints overlap one and the same public way: atoms ['st.highway', 'rel.occupies'], concepts []
    neither body is at rest, each one's speed standing above the motion tolerance the caller sets: atoms [], concepts ['drv.motion.at_rest']
    the cosine of the angle between the directions the two bodies point is at least the alignment tolerance the caller sets: atoms ['rel.same_direction'], concepts []
    the two move alike with respect to the direction they point, either both forward or both rearward: atoms [], concepts ['drv.motion.backing']
    the offset of l's reference point from f's, taken in f's frame, lies ahead of f along f's own direction of travel by at least the ordering resolution the caller sets: atoms ['rel.bearing'], concepts []
    the lateral component of that offset is at most the abreast reach the caller sets: atoms ['rel.bearing'], concepts []

  How each element is written:

    "both footprints overlap one and the same public way" — one existential over the highways of
    the scene, `.existsRegion (.lit "highway") "w" …`, whose body reads one and the same region `w`
    through `rel_occupies` for each of the two formals: `rel_occupies f w` and `rel_occupies l w`.
    Because both readings are of the one bound region, the way the one footprint overlaps is the
    way the other overlaps, which is what "one and the same public way" says. `st_highway w` is
    read of that region by its own atom as well, so that a region whose kind the source cannot
    tell leaves the reading unknown rather than letting the quantifier pass it over silently.
    st.highway is "the entire public way between its boundary lines, including sidewalks and
    shoulders", so nothing here asks for a roadway, a lane or an improved part of the way; the
    bound region `w` is anchored to the formal `f` through `rel_occupies f w`. The five conjuncts
    that read the pair of bodies and no region stand beside the existential, not inside it (see
    the narrowing).

    "neither body is at rest, each one's speed standing above the motion tolerance the caller
    sets" — the negation of `drv.motion.at_rest` on each formal in turn, each call given this
    concept's motion tolerance as its halt tolerance: `.not (.derived "drv_motion_at_rest" [f]
    [motion_speed_tolerance])` and the same for `l`. at_rest is "the magnitude of its velocity is
    at or below the speed tolerance the caller sets", so its negation is the speed standing
    strictly above that tolerance, which is the contract's own wording; and at_rest says "nothing
    about where on the road it stands" and "nothing about why it stopped", so nothing of place or
    purpose comes in with it. No speed is read by this body directly.

    "the cosine of the angle between the directions the two bodies point is at least the alignment
    tolerance the caller sets" — `.atom "rel_same_direction" [f, l] [heading_alignment_cosine]`,
    the atom whose parameter is "the cosine of the largest angle allowed, a ratio between -1 and
    1". The formal parameter carries the ratio unit the atom's parameter requires and is passed
    through unaltered: no angle is converted, nothing is compared against a degree. rel.oncoming,
    the opposed case, is not read.

    "the two move alike with respect to the direction they point, either both forward or both
    rearward" — `drv.motion.backing` read of each formal, and the two required to agree:
    `.or (.and (backing f) (backing l)) (.and (.not (backing f)) (.not (backing l)))`. backing is
    "the road user moves in the direction opposite to the one its body points", so "rearward" is
    backing and "forward" is its negation; its contract is "not the selected gear" and "not the
    reversing or brake lamps", so only the motion itself is read. The tolerance it takes is this
    concept's motion tolerance (see the narrowing).

    "the offset of l's reference point from f's, taken in f's frame, lies ahead of f along f's own
    direction of travel by at least the ordering resolution the caller sets" — rel.bearing is the
    "direction of b from a in a's frame", carried in metres, and its components are selected by
    the atom's own component literals: `.measure "rel_bearing" [f, l, .lit "x"]` is the
    longitudinal component of l's reference point from f's in f's frame, `.lit "y"` the lateral
    one (positive to the left). Where f moves forward, f's direction of travel is the direction it
    points and the longitudinal component is taken as it stands; where f moves rearward, the
    direction of travel is the opposite of the direction it points and the sign is taken the other
    way round, which is written `.cond (backing f) (.neg longitudinal) longitudinal` — the reason
    drv.motion.backing is read beside the bearing. That signed component is compared `.ge` against
    the ordering resolution in metres.

    "the lateral component of that offset is at most the abreast reach the caller sets" — the
    lateral component of the same bearing, `.cmp (.abs (.measure "rel_bearing" [f, l, .lit "y"]))
    .le abreast_reach`: the magnitude of the component, since the component is signed to either
    hand (see the narrowing), against the formal parameter in metres.

  The unknowns are the atoms': an unobserved occupancy leaves the membership of a way unknown, a
  region whose kind is untold leaves `st_highway` unknown, an unreported speed leaves at_rest
  unknown, an unreported heading or velocity leaves the alignment and backing unknown, and a
  bearing the source can neither measure nor compute leaves both comparisons with the offset
  unknown. Nothing of the body reads a lane, a lane marking, a lane designation, a junction, a
  device, an acceleration, a closing rate, a duration or a contact, which is what the contract
  excludes; nothing reads a clearance between the bodies, the offset being between the two
  reference points; and no operator of the body looks behind or ahead of the observation, the
  concept being a relation at an instant.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following_on_way

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aF : Arg := .var "f"
def aL : Arg := .var "l"

/-- The public way the body quantifies over: bound inside the body, not a formal. -/
def aW : Arg := .var "w"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"
def pHeadingAlignmentCosine : Term := .param "heading_alignment_cosine"
def pOrderingResolution : Term := .param "ordering_resolution"
def pAbreastReach : Term := .param "abreast_reach"

/-- The region the body speaks about is a public way: read by its own atom, so that a region whose
    kind the source cannot tell leaves the reading unknown rather than silently decided. -/
def isWay : Formula := .atom "st_highway" [aW] []

/-- The road user's footprint overlaps the bound way. -/
def occupiesWay (a : Arg) : Formula := .atom "rel_occupies" [a, aW] []

/-- Both footprints overlap one and the same public way: one bound region, read for each formal. -/
def onOneWay : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and isWay (.and (occupiesWay aF) (occupiesWay aL)))

/-- The road user is not moving: the concept of the catalogue, given this concept's motion
    tolerance as its halt tolerance. -/
def atRest (a : Arg) : Formula := .derived "drv_motion_at_rest" [a] [pMotionSpeedTolerance]

/-- Neither body is at rest: each one's speed stands above the motion tolerance. -/
def bothMoving : Formula := .and (.not (atRest aF)) (.not (atRest aL))

/-- The cosine of the angle between the directions the two bodies point is at least the alignment
    tolerance: the atom's tolerance is that cosine, and the formal parameter is passed to it
    unaltered. -/
def headingsAligned : Formula :=
  .atom "rel_same_direction" [aF, aL] [pHeadingAlignmentCosine]

/-- The road user moves in the direction opposite to the one its body points: the concept of the
    catalogue, given this concept's motion tolerance as its backing tolerance. -/
def backing (a : Arg) : Formula := .derived "drv_motion_backing" [a] [pMotionSpeedTolerance]

/-- The two move alike with respect to the direction they point: both rearward, or both forward. -/
def moveAlike : Formula :=
  .or (.and (backing aF) (backing aL))
      (.and (.not (backing aF)) (.not (backing aL)))

/-- The longitudinal component of the offset of l's reference point from f's, in f's frame. -/
def offsetLongitudinal : Term := .measure "rel_bearing" [aF, aL, .lit "x"]

/-- The lateral component of that offset, in f's frame (positive to the left). -/
def offsetLateral : Term := .measure "rel_bearing" [aF, aL, .lit "y"]

/-- The same component taken along f's own direction of travel: as it stands where f moves
    forward, with its sign reversed where f moves rearward. -/
def offsetAlongTravel : Term :=
  .cond (backing aF) (.neg offsetLongitudinal) offsetLongitudinal

/-- l's reference point stands clear of f's ahead along f's direction of travel, by at least the
    ordering resolution the caller sets. -/
def leaderAhead : Formula := .cmp offsetAlongTravel .ge pOrderingResolution

/-- The lateral component of the offset is at most the abreast reach the caller sets. -/
def inLineNotAbreast : Formula := .cmp (.abs offsetLateral) .le pAbreastReach

/-- f travels behind l along one and the same public way at the observation. -/
def body : Formula :=
  .and onOneWay
    (.and bothMoving
      (.and headingsAligned
        (.and moveAlike (.and leaderAhead inLineNotAbreast))))

def concept : Concept :=
  { id := "drv.interaction.following_on_way"
    contract := "The road user f travels behind the road user l along one and the same public way at the observation: both footprints overlap one and the same public way; neither body is at rest, each one's speed standing above the motion tolerance the caller sets; the cosine of the angle between the directions the two bodies point is at least the alignment tolerance the caller sets; the two move alike with respect to the direction they point, either both forward or both rearward; the offset of l's reference point from f's, taken in f's frame, lies ahead of f along f's own direction of travel by at least the ordering resolution the caller sets, f's direction of travel being the direction f points where f moves forward and the opposite direction where f moves rearward; and the lateral component of that offset is at most the abreast reach the caller sets. The motion tolerance is the observer's: a sampled speed never stands exactly at zero, so the caller sets the magnitude below which a measured speed counts as no movement at all. The alignment tolerance is the observer's too and is a ratio between -1 and 1: it names how nearly the two bodies must point one way for them to count as travelling in one line, absorbing the bend of the way and the noise of a sampled heading. The ordering resolution is the observer's: it names the longitudinal offset below which one reference point does not stand clear of the other along the direction of travel. The abreast reach is the observer's: it names the lateral offset within which the one body travels in the line of the other rather than beside it, and it is no measure of how safe either position is. The concept is a relation at an instant, read from the two bodies' membership of one public way, from their speeds, from the directions they point, from the directions they move and from the offset between their reference points: it says nothing about lanes, lane markings, lane designations, junctions or any device; nothing about how long the one has been behind the other; nothing about either body's acceleration or about whether either is closing on the other; and nothing about whether the space between the two bodies is sufficient, which is the business of the law that calls the concept. The offset it reads is between the two reference points and is not the clearance between the two bodies, which is shorter by about their half-lengths. It is not an overtaking, not a halt, not a contact between the bodies, not a following within one marked lane, and it carries no judgement that the position is safe or lawful."
    definition := none
    args := [("f", .track), ("l", .track)]
    params := [⟨"motion_speed_tolerance", .metrePerSecond⟩, ⟨"heading_alignment_cosine", .ratio⟩, ⟨"ordering_resolution", .metre⟩, ⟨"abreast_reach", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "both footprints overlap one and the same public way"
          why := "Written as one existential over the highways of the scene, `.existsRegion (.lit \"highway\") \"w\"`, whose body reads the one bound region twice, once for each formal, so that the way the one footprint overlaps is the way the other overlaps. `st_highway w` is read of the bound region by its own atom beside the two occupancies, so that a region whose kind the source cannot tell leaves the reading unknown rather than being passed over silently by the quantifier. Two choices the contract leaves open are declared here. First, the five conjuncts that read the pair of bodies and no region — the two motions, the alignment of the headings, the agreement of the two directions of movement and the two components of the offset — stand beside the existential and not inside it: they do not speak about a way, and putting them inside would make a scene with several highways report unknown where one way answers the membership and another does not, which is an artefact of the quantifier rather than anything the contract says. Second, no further condition is put on the way: its roadway, its lanes, its shoulders, its markings and its geometry are not read, the contract asking only that one and the same public way be overlapped by both footprints."
          kind := "reading" }
      , { span := "neither body is at rest, each one's speed standing above the motion tolerance the caller sets"
          why := "Written as the negation of `drv.motion.at_rest` on each formal, `.not (.derived \"drv_motion_at_rest\" [f] [motion_speed_tolerance])` and the same for `l`, rather than by reading either speed here. The concept's own words are 'the magnitude of its velocity is at or below the speed tolerance the caller sets', so its negation is the speed standing strictly above that tolerance, which is what 'standing above the motion tolerance' says, and the boundary case — a speed exactly at the tolerance — counts as at rest and so not following. The contract's single motion tolerance is passed as the concept's halt tolerance: both are the magnitude below which a measured speed counts as no movement at all, in the same unit, and the record declares no second tolerance."
          kind := "reading" }
      , { span := "the cosine of the angle between the directions the two bodies point is at least the alignment tolerance the caller sets"
          why := "The contract says 'at least', and the atom's own reading is that the cosine lies strictly above its tolerance. The span is written through the atom as it stands, `.atom \"rel_same_direction\" [f, l] [heading_alignment_cosine]`, so the boundary case — the cosine exactly equal to the tolerance the caller sets — counts as not aligned rather than as aligned. The narrowing touches that single boundary and nothing else: the tolerance is the observer's, set to absorb the bend of the way and the noise of a sampled heading, so a caller who wants the boundary included sets a tolerance slightly below it. The alternative, writing the comparison as a cosine of our own against the parameter, is not open to the body, which reads the headings only through this atom."
          kind := "reading" }
      , { span := "the two move alike with respect to the direction they point, either both forward or both rearward"
          why := "Written as the agreement of `drv.motion.backing` on the two formals, `.or (.and (backing f) (backing l)) (.and (.not (backing f)) (.not (backing l)))`: 'rearward' is the concept holding and 'forward' is its negation, there being no third way of moving with respect to the direction a body points that the concept distinguishes. Two choices are declared. First, drv.motion.backing takes a backing speed tolerance of its own and this concept's record declares no formal for it; the contract's motion tolerance is passed to it, both being a magnitude of speed in metres per second below which a sampled velocity does not stand clear of none, rather than a magnitude of this file's own, which the body may not carry. Second, the agreement is written as a disjunction of the two cases rather than as an equivalence, so that where the one body's movement is decided and the other's is not the reading is unknown, as it should be, and where both are decided it is exactly 'both forward or both rearward'."
          kind := "reading" }
      , { span := "the offset of l's reference point from f's, taken in f's frame, lies ahead of f along f's own direction of travel by at least the ordering resolution the caller sets"
          why := "rel.bearing carries 'the direction of b from a in a's frame' as a pair of components in metres, and the body selects them by the atom's own component literals: for this atom the first component, `.lit \"x\"`, is the longitudinal offset in f's frame and the second, `.lit \"y\"`, the lateral one, positive to the left. The contract's 'f's own direction of travel' is written `.cond (backing f) (.neg longitudinal) longitudinal`: the component as it stands where f moves forward, its sign reversed where f moves rearward, which is the reading the contract itself states. The comparison is `.ge`, so the boundary case — the offset exactly the ordering resolution — counts as standing clear, as 'by at least' says. The offset is read between the two reference points and no clearance between the bodies is read, the contract excluding that."
          kind := "reading" }
      , { span := "the lateral component of that offset is at most the abreast reach the caller sets"
          why := "The lateral component of the bearing is signed — positive where l stands to f's left, negative where it stands to f's right — while the abreast reach the contract describes is a reach 'within which the one body travels in the line of the other rather than beside it', which is the same on either hand. The span is therefore written on the magnitude of the component, `.cmp (.abs (.measure \"rel_bearing\" [f, l, .lit \"y\"])) .le abreast_reach`: a signed comparison would admit any offset however far to f's right and bound only offsets to its left, which the contract's words do not say. The comparison is `.le`, so the boundary case — the lateral offset exactly the abreast reach — counts as travelling in the line of the other, as 'at most' says."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.following_on_way
