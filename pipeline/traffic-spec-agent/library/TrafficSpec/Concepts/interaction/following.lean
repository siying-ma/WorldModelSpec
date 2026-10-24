/-
  drv.interaction.following — The road user f travels behind the road user l in the same line of travel at the observation: both footprints overlap one and the same lane, l's body lies ahead of f's along that lane's direction, the two headings are aligned within the alignment tolerance the caller sets, and the longitudinal distance between the two bodies is at most the reach the caller sets. It is a relation at an instant between two road users: it says nothing about how long f has been behind l, nothing about whether either is moving, and nothing about whether the distance between them is enough - how much space a follower owes is the business of the law that calls the concept. It is not an overtaking, not a lane change, and not a centre-to-centre proximity.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    both footprints overlap one and the same lane: atoms ['st.lane', 'rel.occupies'], concepts []
    l's body lies ahead of f's along that lane's direction: atoms ['rel.ahead_behind_in_lane'], concepts []
    the two headings are aligned within the alignment tolerance: atoms ['rel.same_direction'], concepts []
    the longitudinal distance between the two bodies is at most the reach: atoms ['rel.surface_gap'], concepts []

  How each element is written:

    "both footprints overlap one and the same lane" — an existential over the scene's lane regions:
    a region `ln` of the scene that is a lane (`st_lane`), whose footprint f overlaps
    (`rel_occupies f ln`) and whose footprint l overlaps (`rel_occupies l ln`). The quantifier's
    kind is not the claim: `st.lane` is read of the bound region explicitly, so a region whose
    kind the source cannot tell leaves the conjunct unknown rather than silently true.
    NARROWING: "one and the same lane" is read as *there is a lane both occupy*, not as *each
    occupies exactly one lane, and it is the same one*.

    "l's body lies ahead of f's along that lane's direction" — `rel_ahead_behind_in_lane l f`,
    which is "l is ahead of f in the lane they share"; the subject is l, so the order is (l, f).

    "the two headings are aligned within the alignment tolerance" — `rel_same_direction f l`
    with the concept's own `following_alignment_tolerance` as the atom's tolerance parameter.

    "the longitudinal distance between the two bodies is at most the reach" — the `longitudinal`
    component of `rel_surface_gap`, the distance between the nearest points of the two bodies,
    at most `following_reach`. NARROWING: the gap's components are in the subject's frame and
    the contract does not say whose; the follower f is the subject, so the longitudinal axis is
    f's. With the headings aligned to within the tolerance the element above already requires,
    l's frame differs from f's by at most that tolerance.

  Nothing about duration, motion, or sufficiency of the gap is written: the contract excludes them.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aF : Arg := .var "f"
def aL : Arg := .var "l"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pFollowingReach : Term := .param "following_reach"
def pFollowingAlignmentTolerance : Term := .param "following_alignment_tolerance"

/-- The lane f and l share, bound inside the body and anchored to both formals by `rel_occupies`. -/
def aLane : Arg := .var "ln"

/-- Both footprints overlap one and the same lane. -/
def sharedLane : Formula :=
  .and (.atom "st_lane" [aLane] [])
    (.and (.atom "rel_occupies" [aF, aLane] [])
      (.atom "rel_occupies" [aL, aLane] []))

/-- l's body lies ahead of f's along that lane's direction. -/
def leaderAhead : Formula := .atom "rel_ahead_behind_in_lane" [aL, aF] []

/-- The two headings are aligned within the alignment tolerance the caller sets. -/
def headingsAligned : Formula :=
  .atom "rel_same_direction" [aF, aL] [pFollowingAlignmentTolerance]

/-- The longitudinal distance between the two bodies is at most the reach the caller sets. -/
def withinReach : Formula :=
  .cmp (.measure "rel_surface_gap" [aF, aL, .lit "longitudinal"]) .le pFollowingReach

def body : Formula :=
  .existsRegion (.lit "lane") "ln"
    (.and sharedLane
      (.and leaderAhead
        (.and headingsAligned withinReach)))

def concept : Concept :=
  { id := "drv.interaction.following"
    contract := "The road user f travels behind the road user l in the same line of travel at the observation: both footprints overlap one and the same lane, l's body lies ahead of f's along that lane's direction, the two headings are aligned within the alignment tolerance the caller sets, and the longitudinal distance between the two bodies is at most the reach the caller sets. It is a relation at an instant between two road users: it says nothing about how long f has been behind l, nothing about whether either is moving, and nothing about whether the distance between them is enough - how much space a follower owes is the business of the law that calls the concept. It is not an overtaking, not a lane change, and not a centre-to-centre proximity."
    definition := none
    args := [("f", .track), ("l", .track)]
    params := [⟨"following_reach", .metre⟩, ⟨"following_alignment_tolerance", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "both footprints overlap one and the same lane"
          why := "Written as an existential over the scene's lane regions: there is a lane that is a lane (st.lane, read of the bound region, not assumed from the quantifier's kind) and whose footprint both f and l overlap. 'One and the same' is read as sharing a lane, not as each road user occupying exactly one lane; a vehicle straddling a lane line still follows another in a lane the two share."
          kind := "reading" }
      , { span := "the longitudinal distance between the two bodies is at most the reach the caller sets"
          why := "rel.surface_gap resolves into a longitudinal and a lateral component in the subject's frame, and the contract does not say whose frame. The follower f is taken as the subject, so the longitudinal axis is f's heading; the element above already requires the two headings to be aligned within the tolerance, so l's axis differs by at most that tolerance."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.following
