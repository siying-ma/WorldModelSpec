/-
  drv.lane.lane_change — The road user has moved out of one lane into the lane neighbouring it on the named side: at the observation its footprint overlaps a lane, that lane is the neighbour on the named side of a second lane of the same direction, and at some observation within the window behind that the caller sets the road user's footprint overlapped that second lane and not the first. The window is the observer's: it names the stretch of time behind the observation within which the lane the road user came from is looked for, and it is no measure of how long a movement may take to be lawful. The concept is read from lane membership and lane adjacency alone: it is not the turn indicator or arm signal given for a movement, not an intention to change lane, not an overtaking, and it carries no judgement that the movement is safe or lawful. It holds from the observation at which the new lane is first occupied, which is where the movement is recognized, until the window behind has passed; those later observations are not a further movement. Where the window reaches past the start of the trace it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    at the observation its footprint overlaps a lane: atoms ['st.lane', 'rel.occupies'], concepts []
    that lane is the neighbour on the named side of a second lane of the same direction: atoms ['st.lane_adjacency'], concepts []
    the road user's footprint overlapped that second lane and not the first: atoms ['st.lane', 'rel.occupies'], concepts []

  How each element is written:

    "at the observation its footprint overlaps a lane" — an existential over the scene's lane
    regions: a region `ln` that is a lane (`st_lane`, read of the bound region) whose footprint the
    road user overlaps (`rel_occupies u ln`). The quantifier's kind is not the claim: `st.lane` is
    read of the bound region explicitly, so a region whose kind the source cannot tell leaves the
    conjunct unknown rather than silently true.
    NARROWING: "a lane" is read as *there is a lane it overlaps*, not as *it overlaps exactly one
    lane*; a body still astride the line is in the new lane as soon as its footprint reaches it.

    "that lane is the neighbour on the named side of a second lane of the same direction" — a
    second existential, over the same lane regions, binding `ln0`, read as a lane (`st_lane`) and
    related to `ln` by `st_lane_adjacency [ln0, side, ln]`, which is "`ln` is lane `ln0`'s
    neighbour of the same direction on its `side`". The contract makes the second lane the subject
    of the relation ("that lane is the neighbour … of a second lane"), so the lane come from is the
    atom's first argument and the lane now occupied its third; `side` is the concept's literal
    formal, filled by the caller with `left` or `right`. "Of the same direction" is carried by the
    atom itself, whose neighbours are the neighbouring lanes of the same direction; no lane
    direction is read separately, and no marking between the lanes is read at all.

    "at some observation within the window behind that the caller sets the road user's footprint
    overlapped that second lane and not the first" — `rel_occupies u ln0` and not `rel_occupies
    u ln` at one and the same past observation, sought over the window behind of length
    `lane_change_window`, measured in time because the parameter's unit is seconds. The formula
    language has `holdsFor` (at every observation in the window behind) and no existential mirror,
    so "at some observation" is written as its negation: `not (holdsFor .time lane_change_window u
    (not …))`. The three-valued reading is the one the contract states: where the window reaches
    past the start of the trace `holdsFor` is `windowTruncated`, and the negation carries that
    unknown through, so the concept is unknown there rather than false.
    NARROWING: the two halves ("overlapped that second lane", "and not the first") are read at the
    same past observation, not at two different ones.

  Nothing about the turn indicator, the arm signal, an intention, an overtaking or the safety or
  lawfulness of the movement is written: the contract excludes them. Nothing bounds how long the
  movement took: the window is the observer's reach backwards, not a standard.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.lane_change

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aSide : Arg := .var "side"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pLaneChangeWindow : Term := .param "lane_change_window"

/-- The lane occupied at the observation, bound in the body and anchored to `u` by `rel_occupies`. -/
def aLaneNow : Arg := .var "ln"
/-- The lane the road user came from, bound in the body and anchored to `u` by `rel_occupies`. -/
def aLaneBefore : Arg := .var "ln0"

/-- At the observation its footprint overlaps a lane. -/
def occupiesLaneNow : Formula :=
  .and (.atom "st_lane" [aLaneNow] [])
    (.atom "rel_occupies" [aU, aLaneNow] [])

/-- That lane is the neighbour on the named side of a second lane of the same direction. -/
def neighbourOnNamedSide : Formula :=
  .and (.atom "st_lane" [aLaneBefore] [])
    (.atom "st_lane_adjacency" [aLaneBefore, aSide, aLaneNow] [])

/-- The road user's footprint overlapped that second lane and not the first. -/
def cameFromSecondLane : Formula :=
  .and (.atom "rel_occupies" [aU, aLaneBefore] [])
    (.not (.atom "rel_occupies" [aU, aLaneNow] []))

/-- At some observation within the window behind that the caller sets: the window's "at every
    observation" negated, so a window reaching past the start of the trace stays unknown. -/
def cameFromWithinWindow : Formula :=
  .not (.holdsFor .time pLaneChangeWindow "u" (.not cameFromSecondLane))

def body : Formula :=
  .existsRegion (.lit "lane") "ln"
    (.and occupiesLaneNow
      (.existsRegion (.lit "lane") "ln0"
        (.and neighbourOnNamedSide cameFromWithinWindow)))

def concept : Concept :=
  { id := "drv.lane.lane_change"
    contract := "The road user has moved out of one lane into the lane neighbouring it on the named side: at the observation its footprint overlaps a lane, that lane is the neighbour on the named side of a second lane of the same direction, and at some observation within the window behind that the caller sets the road user's footprint overlapped that second lane and not the first. The window is the observer's: it names the stretch of time behind the observation within which the lane the road user came from is looked for, and it is no measure of how long a movement may take to be lawful. The concept is read from lane membership and lane adjacency alone: it is not the turn indicator or arm signal given for a movement, not an intention to change lane, not an overtaking, and it carries no judgement that the movement is safe or lawful. It holds from the observation at which the new lane is first occupied, which is where the movement is recognized, until the window behind has passed; those later observations are not a further movement. Where the window reaches past the start of the trace it is unknown."
    definition := none
    args := [("u", .track), ("side", .literal ["left", "right"])]
    params := [⟨"lane_change_window", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "at the observation its footprint overlaps a lane"
          why := "Written as an existential over the scene's lane regions: there is a region that is a lane (st.lane, read of the bound region, not assumed from the quantifier's kind) whose footprint the road user overlaps. 'A lane' is read as there being a lane it overlaps, not as it overlapping exactly one; a body still astride the line between the two lanes occupies the new lane for this concept."
          kind := "reading" }
      , { span := "the road user's footprint overlapped that second lane and not the first"
          why := "The two halves are read at one and the same past observation: there is an observation in the window behind at which the footprint overlapped the second lane and did not overlap the first, not two separate observations one for each half. A road user whose footprint straddled both lanes at every observation of the window has therefore not moved out of the second lane."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.lane_change
