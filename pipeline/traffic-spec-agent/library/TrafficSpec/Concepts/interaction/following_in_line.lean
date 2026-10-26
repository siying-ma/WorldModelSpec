/-
  drv.interaction.following_in_line — The road user f runs in the line of travel of the road user l, behind it, at the observation: the two headings are aligned within the heading-alignment tolerance the caller sets, l's body lies ahead of f's by a longitudinal distance, taken between the nearest points of the two bodies in f's own frame, that is positive and at most the reach the caller sets, and the lateral offset of l's reference point from f's, across f's heading, is at most the line offset the caller sets, so that the one runs in the other's line rather than beside it. The tolerances are the observer's: the alignment tolerance, stated as a cosine, absorbs the bend of the way and the heading noise of a sampled trajectory without admitting a body that points across the way; the reach names the longitudinal distance within which the leading body is the one being followed; the line offset names the lateral distance within which the one body is in the other's line of travel rather than abreast of it. None of the three says how much space is enough. The concept is a relation at an instant, read from the two bodies' headings, the gap between their nearest points and the lateral offset of their reference points: it carries no judgement that the gap is reasonable, prudent or safe, says nothing about the speed of either body, nothing about how long the one has run behind the other, and nothing about any lane, marking, device or way. It is not an overtaking, not a collision course, not a contact, and not a verdict of following too closely. It is read without lane membership, so it decides the relation on a roadway the scene carries without lanes exactly as within a lane.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the two headings are aligned within the heading-alignment tolerance the caller sets: atoms ['rel.same_direction'], concepts []
    l's body lies ahead of f's by a longitudinal distance, taken between the nearest points of the two bodies in f's own frame, that is positive and at most the reach the caller sets: atoms ['rel.surface_gap'], concepts []
    the lateral offset of l's reference point from f's, across f's heading, is at most the line offset the caller sets: atoms ['rel.bearing'], concepts []

  How each element is written:

    "the two headings are aligned within the heading-alignment tolerance the caller sets" —
    `.atom "rel_same_direction" [f, l] [heading_alignment_cosine]`. The atom is headings aligned,
    and it takes the tolerance as its own parameter, a cosine: the concept's
    `heading_alignment_cosine` formal is passed straight into that position, so the tolerance
    stated as a cosine is the caller's and no angle, degree or conversion of one is written here.
    The atom is read of the ordered pair (f, l), as every reading of this body is, but the
    alignment it states is symmetric in the two headings, so the order carries nothing on this
    span. Nothing of a closing distance is read, which is `rel.oncoming`'s business and not this
    one's, and no heading of either body is read on its own: a body whose heading the source does
    not observe leaves this reading unknown.

    "l's body lies ahead of f's by a longitudinal distance, taken between the nearest points of
    the two bodies in f's own frame, that is positive and at most the reach the caller sets" — the
    longitudinal component of `rel.surface_gap` of the ordered pair (f, l), which is the atom's
    distance between the nearest points of the two bodies taken along f's own heading, under two
    comparisons: `> 0` for "positive", which is where the leading body stands clear ahead of the
    following one, and `≤ following_reach` for "at most the reach the caller sets". The order of
    the arguments carries the frame: `rel.surface_gap f l` is read in f's frame, as the contract
    asks. Zero is the only literal of this file, and it is zero. The lateral component of the same
    atom is not written: it is taken between the nearest points of the bodies and so reads near
    nothing for two bodies abreast, which is the record's reason for reading the offset across the
    heading from `rel.bearing` instead.

    "the lateral offset of l's reference point from f's, across f's heading, is at most the line
    offset the caller sets" — the magnitude of the lateral component of `rel.bearing` of the
    ordered pair (f, l), `≤ line_offset`. The atom is the direction of l from f in f's own frame
    as a pair (longitudinal, lateral) in metres; its lateral component is read by the component
    selector the measure table carries for it, and its magnitude is taken, because the contract
    takes no side: a leader the same distance to either hand of f's line of travel is the same
    distance out of that line. Nothing of the longitudinal component of this atom is read, and no
    lane, lane direction, adjacency or marking is read at all, which is what the contract excludes
    when it says the relation is decided on a roadway the scene carries without lanes exactly as
    within a lane.

  The three readings are conjoined, so the concept holds only where all three hold, is false where
  any one of them is false, and is unknown where none is false and one is unobserved — the atoms'
  own unknowns, which is why a source that declares the gap between the nearest points of two
  bodies absent leaves the relation unknown rather than false. No speed, acceleration, path
  length, elapsed time, window behind, contact, visibility, device, region or class is read, and
  no operator of the trace is written: the body is a statement at the instant, which is what the
  contract says the concept is.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following_in_line

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aF : Arg := .var "f"
def aL : Arg := .var "l"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingAlignmentCosine : Term := .param "heading_alignment_cosine"
def pFollowingReach : Term := .param "following_reach"
def pLineOffset : Term := .param "line_offset"

/-- Zero, in metres: the only literal of this file, and it is zero. -/
def zeroMetres : Term := .lit Q.zero .metre

/-- The longitudinal distance between the nearest points of the two bodies, in f's own frame,
    positive where l's body stands clear ahead of f's. -/
def gapAhead : Term := .measure "rel_surface_gap" [aF, aL, .lit "longitudinal"]

/-- The lateral offset of l's reference point from f's, across f's heading: the lateral component
    of l's bearing from f, in metres, positive to the left. -/
def lateralOffset : Term := .measure "rel_bearing" [aF, aL, .lit "y"]

/-- The two headings are aligned within the tolerance the caller sets, stated as a cosine. -/
def headingsAligned : Formula :=
  .atom "rel_same_direction" [aF, aL] [pHeadingAlignmentCosine]

/-- l's body lies ahead of f's by a longitudinal distance that is positive and at most the reach
    the caller sets. -/
def aheadWithinReach : Formula :=
  .and (.cmp gapAhead .gt zeroMetres) (.cmp gapAhead .le pFollowingReach)

/-- The lateral offset of l's reference point from f's, taken as a magnitude because the contract
    takes no side, is at most the line offset the caller sets. -/
def withinLine : Formula :=
  .cmp (.abs lateralOffset) .le pLineOffset

/-- f runs in l's line of travel, behind it, at the observation. -/
def body : Formula :=
  .and headingsAligned (.and aheadWithinReach withinLine)

def concept : Concept :=
  { id := "drv.interaction.following_in_line"
    contract := "The road user f runs in the line of travel of the road user l, behind it, at the observation: the two headings are aligned within the heading-alignment tolerance the caller sets, l's body lies ahead of f's by a longitudinal distance, taken between the nearest points of the two bodies in f's own frame, that is positive and at most the reach the caller sets, and the lateral offset of l's reference point from f's, across f's heading, is at most the line offset the caller sets, so that the one runs in the other's line rather than beside it. The tolerances are the observer's: the alignment tolerance, stated as a cosine, absorbs the bend of the way and the heading noise of a sampled trajectory without admitting a body that points across the way; the reach names the longitudinal distance within which the leading body is the one being followed; the line offset names the lateral distance within which the one body is in the other's line of travel rather than abreast of it. None of the three says how much space is enough. The concept is a relation at an instant, read from the two bodies' headings, the gap between their nearest points and the lateral offset of their reference points: it carries no judgement that the gap is reasonable, prudent or safe, says nothing about the speed of either body, nothing about how long the one has run behind the other, and nothing about any lane, marking, device or way. It is not an overtaking, not a collision course, not a contact, and not a verdict of following too closely. It is read without lane membership, so it decides the relation on a roadway the scene carries without lanes exactly as within a lane."
    definition := none
    args := [("f", .track), ("l", .track)]
    params := [⟨"heading_alignment_cosine", .ratio⟩, ⟨"following_reach", .metre⟩, ⟨"line_offset", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the lateral offset of l's reference point from f's, across f's heading, is at most the line offset the caller sets"
          why := "Written as the magnitude of the lateral component of `rel.bearing f l`, `.abs (rel_bearing f l \"y\") ≤ line_offset`. Two choices the contract leaves open are made here. First, the magnitude: the atom's lateral component is signed, positive to the left of f's heading, and the contract takes no side — it asks only whether the one body is in the other's line of travel 'rather than beside it' — so the offset is read as a distance and a leader the same distance to either hand of f's line answers the comparison alike. Without the magnitude the comparison would admit every leader to the right of f's line, however far out of it. Second, the component selector: the measure table spells the components of `rel.bearing` `\"x\"` and `\"y\"` for the pair (longitudinal, lateral) the atom carries in f's frame, so the lateral offset across f's heading is the `\"y\"` component of `rel.bearing f l`, in metres. The comparison is `≤`, the contract's 'at most', and the bound is the formal parameter, so no distance of this file's own enters."
          kind := "reading" }
      , { span := "l's body lies ahead of f's by a longitudinal distance, taken between the nearest points of the two bodies in f's own frame, that is positive and at most the reach the caller sets"
          why := "Written as two comparisons on one reading, the longitudinal component of `rel.surface_gap f l`: `> 0` and `≤ following_reach`. The argument order gives the frame the contract names (the atom's components are taken in the first argument's frame), and the aheadness of the leading body is read from the positivity of that component alone, exactly as the contract words it: nothing further is conjoined for it — not the longitudinal sign of `rel.bearing`, not `rel.ahead_behind_in_lane`, not an order of arrival — because the contract enumerates what the concept is read from as the two headings, the gap between the nearest points and the lateral offset of the reference points, and reading a fourth thing would decide the relation on more than it allows. 'Positive' is written strictly (`> 0`), so two bodies whose nearest points touch or overlap along f's heading do not answer this span, which is the contract's 'not a contact'; 'at most' is written inclusively (`≤`). The zero of the first comparison is carried in metres, the unit of the quantity compared."
          kind := "reading" }
      , { span := "the two headings are aligned within the heading-alignment tolerance the caller sets"
          why := "Written as the single atom `rel.same_direction` over the two formals, with the concept's `heading_alignment_cosine` formal passed into the atom's own tolerance position, a ratio. The atom tests the cosine of the angle between the two headings strictly above that tolerance; the strictness is the atom's, not a choice of this file, and it is declared here because it decides the boundary case of a heading exactly at the largest angle the caller allows, which the contract leaves open. No angle in degrees is written and no heading is read on its own, so a body whose heading the source does not observe leaves this reading unknown rather than false."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.following_in_line
