/-
  drv.interaction.following_in_lane — The road user f travels behind the road user l in one and the same line of travel at the observation: both footprints overlap one and the same lane, l's body lies ahead of f's along that lane's direction, the cosine of the angle between the two headings is at least the alignment tolerance the caller sets, and the longitudinal component of the distance between the nearest points of the two bodies is at most the reach the caller sets. The alignment tolerance is the observer's and is a ratio between -1 and 1: it names how nearly the two bodies must point one way for them to count as in one line of travel, absorbing the bend of the lane and the noise of a sampled heading, and it is no measure of how safe or how lawful the position is. The reach is the observer's too: it names the longitudinal distance within which the body ahead is the one the body behind is travelling behind, and it is no measure of an adequate or an inadequate space between them, which is the business of the law that calls the concept. The concept is a relation at an instant, read from lane membership, from the order of the two bodies along the lane, from the two headings and from the gap between the bodies: it says nothing about how long the one has been behind the other, nothing about either body's speed, nothing about whether either is closing on the other, nothing about any device, marking or junction, and nothing about whether the space between the two bodies is sufficient. It is not an overtaking, not a halt, not a contact between the bodies, and it carries no judgement that the position is safe or lawful.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    both footprints overlap one and the same lane: atoms ['rel.occupies', 'st.lane'], concepts []
    l's body lies ahead of f's along that lane's direction: atoms ['rel.ahead_behind_in_lane'], concepts []
    the cosine of the angle between the two headings is at least the alignment tolerance the caller sets: atoms ['rel.same_direction'], concepts []
    the longitudinal component of the distance between the nearest points of the two bodies is at most the reach the caller sets: atoms ['rel.surface_gap'], concepts []

  How each element is written:

    "both footprints overlap one and the same lane" — one existential over the lanes of the scene,
    `.existsRegion (.lit "lane") "r" …`, whose body reads one and the same region `r` through
    `rel_occupies` for each of the two formals: `rel_occupies f r` and `rel_occupies l r`. Because
    both readings are of the one bound region, the lane the one overlaps is the lane the other
    overlaps, which is what "one and the same lane" says. `st_lane r` is read of that region by its
    own atom as well, so that a region whose kind the source cannot tell leaves the reading unknown
    rather than letting the quantifier pass it over silently; st.lane's exclusion is honoured,
    since nothing here is read as a half of the roadway or as a lateral position within a lane. The
    bound region `r` is anchored to the formal `f` through `rel_occupies f r`. The three conjuncts
    that read the pair of bodies and no region stand beside the existential, not inside it (see the
    narrowing).

    "l's body lies ahead of f's along that lane's direction" — `rel_ahead_behind_in_lane` over the
    pair in the order the atom reads, `.atom "rel_ahead_behind_in_lane" [l, f] []`, which is "l is
    ahead of f in the same lane, along the lane direction": the leader is the first argument and
    the follower the second, so the body behind is f, which is what the contract's "f travels
    behind l" says. rel.bearing is not read, a bearing being no order along a lane, and
    rel.centre_distance is not read at all, its own exclusion naming an order of arrival.

    "the cosine of the angle between the two headings is at least the alignment tolerance the
    caller sets" — `.atom "rel_same_direction" [f, l] [heading_alignment_cosine]`, the atom whose
    parameter is "the cosine of the largest angle allowed, a ratio between -1 and 1" and whose
    reading is that the cosine of the angle between the two headings lies above that tolerance. The
    formal parameter carries the ratio unit the atom's parameter requires, and it is passed through
    unaltered: no angle is converted, nothing is compared against a degree. rel.oncoming, the
    opposed case, is not read.

    "the longitudinal component of the distance between the nearest points of the two bodies is at
    most the reach the caller sets" — `.cmp (.measure "rel_surface_gap" [f, l, "longitudinal"]) .le
    following_reach`: the atom's longitudinal selector, read in the following body's frame, against
    the formal parameter in metres. rel.centre_distance is not read, its own exclusion saying that
    centre-to-centre overstates a clearance between bodies.

  The unknowns are the atoms': an unobserved occupancy leaves the lane membership unknown, a region
  whose kind is untold leaves `st_lane` unknown, an unreported order along the lane leaves
  `rel_ahead_behind_in_lane` unknown, and a gap the source cannot report leaves the comparison with
  the reach unknown. Nothing of the body reads a speed, an acceleration, a closing rate, a
  duration, a device, a marking, a junction or a contact, which is what the contract excludes; and
  no operator of the body looks behind or ahead of the observation, the concept being a relation at
  an instant.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following_in_lane

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aF : Arg := .var "f"
def aL : Arg := .var "l"

/-- The lane the body quantifies over: bound inside the body, not a formal. -/
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingAlignmentCosine : Term := .param "heading_alignment_cosine"
def pFollowingReach : Term := .param "following_reach"

/-- The region the body speaks about is a lane: read by its own atom, so that a region whose kind
    the source cannot tell leaves the reading unknown rather than silently decided. -/
def isLane : Formula := .atom "st_lane" [aR] []

/-- The road user's footprint overlaps the bound lane. -/
def occupiesLane (a : Arg) : Formula := .atom "rel_occupies" [a, aR] []

/-- Both footprints overlap one and the same lane: one bound region, read for each formal. -/
def inOneLane : Formula :=
  .existsRegion (.lit "lane") "r"
    (.and isLane (.and (occupiesLane aF) (occupiesLane aL)))

/-- l's body lies ahead of f's along the lane's direction: the atom reads "the first argument is
    ahead of the second in the same lane", so the leader is written first. -/
def leaderAhead : Formula := .atom "rel_ahead_behind_in_lane" [aL, aF] []

/-- The cosine of the angle between the two headings is at least the alignment tolerance: the
    atom's tolerance is that cosine, and the formal parameter is passed to it unaltered. -/
def headingsAligned : Formula :=
  .atom "rel_same_direction" [aF, aL] [pHeadingAlignmentCosine]

/-- The longitudinal component of the distance between the nearest points of the two bodies, in
    the following body's frame. -/
def longitudinalGap : Term := .measure "rel_surface_gap" [aF, aL, .lit "longitudinal"]

/-- That component is at most the reach the caller sets. -/
def withinReach : Formula := .cmp longitudinalGap .le pFollowingReach

/-- f travels behind l in one and the same line of travel at the observation. -/
def body : Formula :=
  .and inOneLane (.and leaderAhead (.and headingsAligned withinReach))

def concept : Concept :=
  { id := "drv.interaction.following_in_lane"
    contract := "The road user f travels behind the road user l in one and the same line of travel at the observation: both footprints overlap one and the same lane, l's body lies ahead of f's along that lane's direction, the cosine of the angle between the two headings is at least the alignment tolerance the caller sets, and the longitudinal component of the distance between the nearest points of the two bodies is at most the reach the caller sets. The alignment tolerance is the observer's and is a ratio between -1 and 1: it names how nearly the two bodies must point one way for them to count as in one line of travel, absorbing the bend of the lane and the noise of a sampled heading, and it is no measure of how safe or how lawful the position is. The reach is the observer's too: it names the longitudinal distance within which the body ahead is the one the body behind is travelling behind, and it is no measure of an adequate or an inadequate space between them, which is the business of the law that calls the concept. The concept is a relation at an instant, read from lane membership, from the order of the two bodies along the lane, from the two headings and from the gap between the bodies: it says nothing about how long the one has been behind the other, nothing about either body's speed, nothing about whether either is closing on the other, nothing about any device, marking or junction, and nothing about whether the space between the two bodies is sufficient. It is not an overtaking, not a halt, not a contact between the bodies, and it carries no judgement that the position is safe or lawful."
    definition := none
    args := [("f", .track), ("l", .track)]
    params := [⟨"heading_alignment_cosine", .ratio⟩, ⟨"following_reach", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "both footprints overlap one and the same lane"
          why := "Written as one existential over the lanes of the scene, `.existsRegion (.lit \"lane\") \"r\"`, whose body reads the one bound region twice, once for each formal, so that the lane the one footprint overlaps is the lane the other overlaps. `st_lane r` is read of the bound region by its own atom beside the two occupancies, so that a region whose kind the source cannot tell leaves the reading unknown rather than being passed over silently by the quantifier. Two choices the contract leaves open are declared here. First, the three conjuncts that read the pair of bodies and no region — the order along the lane, the alignment of the headings and the gap — stand beside the existential and not inside it: they do not speak about a lane, and putting them inside would make a scene with several lanes report unknown where one lane answers the membership and another does not, which is an artefact of the quantifier rather than anything the contract says. Second, no further condition is put on the lane: its direction, its width, its markings, its neighbours and the roadway it belongs to are not read, the contract asking only that one and the same lane be overlapped by both footprints."
          kind := "reading" }
      , { span := "l's body lies ahead of f's along that lane's direction"
          why := "The atom `rel.ahead_behind_in_lane` is 'a is ahead of / behind b in the same lane, along the lane direction' and carries no region argument, so the order cannot be written against the lane the existential binds: it is read of the pair alone, as `.atom \"rel_ahead_behind_in_lane\" [l, f] []`, with the leader first and the follower second, and the lane is carried by the conjunct beside it. The two conditions are therefore conjoined rather than nested, and the contract's 'that lane's direction' is read as the direction of the lane the two bodies share, which is the only lane the two conjuncts together admit. Nothing of a bearing, a lateral offset or a centre-to-centre distance is read."
          kind := "reading" }
      , { span := "the cosine of the angle between the two headings is at least the alignment tolerance the caller sets"
          why := "The contract says 'at least', and the atom's own reading is that the cosine lies strictly above its tolerance. The span is written through the atom as it stands, `.atom \"rel_same_direction\" [f, l] [heading_alignment_cosine]`, so the boundary case — the cosine exactly equal to the tolerance the caller sets — counts as not aligned rather than as aligned. The narrowing touches that single boundary and nothing else: the tolerance is the observer's, set to absorb the bend of a lane and the noise of a sampled heading, so a caller who wants the boundary included sets a tolerance slightly below it. The alternative, writing the comparison as a cosine of our own against the parameter, is not open to the body, which reads the headings only through this atom."
          kind := "reading" }
      , { span := "the longitudinal component of the distance between the nearest points of the two bodies is at most the reach the caller sets"
          why := "Written as `.cmp (.measure \"rel_surface_gap\" [f, l, \"longitudinal\"]) .le following_reach`: the atom's longitudinal selector, read in the following body's frame (the first argument's), against the formal parameter in metres. Two readings are declared. First, the frame is the follower's rather than the leader's, the contract naming f as the road user whose travelling behind is in question; the component the atom reports is a clearance between the two bodies and not a centre-to-centre distance either way. Second, the comparison is the plain `.le` on the signed component, so where the two bodies overlap along the lane's direction the component is negative and lies within any non-negative reach: the contract bounds the gap from above only and takes no interest in how small it is, that being the business of the law that calls the concept."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.following_in_lane
