/-
  drv.interaction.from_different_ways — The two road users came to one and the same intersection along different public ways at the observation: there is an intersection region and, for each of the two road users, a lane that runs into that intersection which that road user's footprint overlaps at the observation or overlapped at some observation within the window behind that the caller sets, and no public way the first road user's such lane lies on is a way the second road user's such lane lies on. The window is the observer's: it names the stretch of time behind the observation within which the approach a road user came in on is looked for, once the road user has left that approach by entering the intersection, and it is no measure of how long an entry may take or of how recently either arrived. The concept is a configuration at an instant, read from lane membership, from the intersection a lane runs into and from the way a lane lies on: it says nothing about which of the two reached the intersection first, nothing about whether either is inside the intersection now, nothing about the angle at which the ways meet, and nothing about the direction either road user travels or about any device at the junction. It is not a bearing or a heading relation between the two bodies - two road users meeting head on upon one way come from the same way and do not satisfy it - and it is not the lane a lane leads into. Where no approach lane is found for a road user and the window reaches past the start of the trace, the concept is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    there is an intersection region: atoms ['st.intersection'], concepts []
    a lane that runs into that intersection which that road user's footprint overlaps: atoms ['rel.occupies', 'st.lane', 'st.lane_enters'], concepts []
    no public way the first road user's such lane lies on is a way the second road user's such lane lies on: atoms ['st.on_way', 'st.highway'], concepts []

  How each element is written:

    "there is an intersection region" — an existential over the scene's intersection regions,
    `ix`, read as an intersection by its own atom (`st_intersection`, of the bound region, so a
    region whose kind the source cannot tell leaves the conjunct unknown rather than silently
    true). One junction is bound once and both approaches are read of that same `ix`, which is
    what "one and the same intersection" demands.

    "a lane that runs into that intersection which that road user's footprint overlaps" — once per
    road user: an existential over the scene's lane regions (`la` for the first, `lb` for the
    second), each read as a lane (`st_lane`) and as an approach to the bound junction
    (`st_lane_enters _ ix` — the intersection a lane runs into at its end, not the lane a lane
    leads into), and the road user's membership of it read through `rel_occupies`. "At the
    observation or at some observation within the window behind" is written `atLast .time
    approach_window _ (rel_occupies x l) tt`: the value `tt` at the last observation in the window
    behind at which the footprint overlapped the lane. That is true where an overlap is found
    anywhere in the window (the window behind includes the observation itself, so a road user
    still in its approach lane is decided by its present membership), false where the window is
    covered and no overlap is found, and unknown where none is found and the window reaches past
    the start of the trace — the contract's own unknown clause. The two lanes are chosen
    independently of one another; they are tied together only by the junction they both run into
    and by the ways they lie on.

    "no public way the first road user's such lane lies on is a way the second road user's such
    lane lies on" — a universal over the scene's highway regions: no region `w` that is a public
    way (`st_highway`, read of the bound region) is both a way `la` lies on and a way `lb` lies on
    (`st_on_way _ w`, the ontology's membership of a public way). Where the source maps no region
    to the ways it lies on, every such conjunct is unknown and so is the concept.

  Nothing about which of the two arrived first, about either body's presence in the junction now,
  about the angle at which the ways meet, about either body's heading or bearing, or about any
  device at the junction is written: the contract excludes them, and no such atom is read. Two
  road users meeting head on upon one way fail the concept because the one way their approaches
  lie on is shared, not because of any heading relation between them.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.from_different_ways

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pApproachWindow : Term := .param "approach_window"

/-- The one junction both road users came to, bound inside the body and anchored to the formals
    through the approach lanes that run into it. -/
def aJunction : Arg := .var "ix"
/-- The approach lane of each road user, each anchored to its formal by `rel_occupies`. -/
def aLaneA : Arg := .var "la"
def aLaneB : Arg := .var "lb"
/-- A public way, anchored to the approaches by `st_on_way`. -/
def aWay : Arg := .var "w"

/-- There is an intersection region. -/
def anIntersection : Formula :=
  .atom "st_intersection" [aJunction] []

/-- The road user's footprint overlaps the lane at the observation, or overlapped it at some
    observation within the window behind: the value at the last observation in that window at
    which the footprint overlapped the lane. Unknown where no such observation is found and the
    window reaches past the start of the trace. -/
def cameInOn (x lane : Arg) (subject : String) : Formula :=
  .atLast .time pApproachWindow subject (.atom "rel_occupies" [x, lane] []) .tt

/-- A lane that runs into that intersection which that road user's footprint overlaps. -/
def approachOf (x lane : Arg) (subject : String) : Formula :=
  .and (.atom "st_lane" [lane] [])
    (.and (.atom "st_lane_enters" [lane, aJunction] [])
      (cameInOn x lane subject))

/-- This public way is not one both approaches lie on. -/
def notASharedWay : Formula :=
  .not
    (.and (.atom "st_highway" [aWay] [])
      (.and (.atom "st_on_way" [aLaneA, aWay] [])
        (.atom "st_on_way" [aLaneB, aWay] [])))

/-- No public way the first road user's approach lies on is a way the second road user's approach
    lies on. -/
def differentWays : Formula :=
  .forallRegion (.lit "highway") "w" notASharedWay

/-- Both approaches run into the one junction, and they lie on no common way. -/
def bothApproaches : Formula :=
  .existsRegion (.lit "lane") "la"
    (.and (approachOf aA aLaneA "a")
      (.existsRegion (.lit "lane") "lb"
        (.and (approachOf aB aLaneB "b") differentWays)))

def body : Formula :=
  .existsRegion (.lit "intersection") "ix" (.and anIntersection bothApproaches)

def concept : Concept :=
  { id := "drv.interaction.from_different_ways"
    contract := "The two road users came to one and the same intersection along different public ways at the observation: there is an intersection region and, for each of the two road users, a lane that runs into that intersection which that road user's footprint overlaps at the observation or overlapped at some observation within the window behind that the caller sets, and no public way the first road user's such lane lies on is a way the second road user's such lane lies on. The window is the observer's: it names the stretch of time behind the observation within which the approach a road user came in on is looked for, once the road user has left that approach by entering the intersection, and it is no measure of how long an entry may take or of how recently either arrived. The concept is a configuration at an instant, read from lane membership, from the intersection a lane runs into and from the way a lane lies on: it says nothing about which of the two reached the intersection first, nothing about whether either is inside the intersection now, nothing about the angle at which the ways meet, and nothing about the direction either road user travels or about any device at the junction. It is not a bearing or a heading relation between the two bodies - two road users meeting head on upon one way come from the same way and do not satisfy it - and it is not the lane a lane leads into. Where no approach lane is found for a road user and the window reaches past the start of the trace, the concept is unknown."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"approach_window", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "which that road user's footprint overlaps at the observation or overlapped at some observation within the window behind that the caller sets"
          why := "Written as `atLast` over the time window behind, with the overlap as the condition and `tt` as the value: true where an overlap with that lane is found at any observation of the window, false where the window is covered and none is found, unknown where none is found and the window reaches past the start of the trace. The window behind includes the observation itself, so the disjunct 'at the observation' needs no clause of its own; the language's other bounded look-back, `holdsFor`, would demand the overlap at every observation of the window, which the words do not, and its negation would report a truncated window as unknown even where an overlap was found. The window is measured in time, not in path travelled, because the contract names a stretch of time."
          kind := "reading" }
      , { span := "a lane that runs into that intersection"
          why := "Read at the observation, not within the window: the approach relation (st.lane_enters) and the lane's kind are read of the scene the concept is evaluated in, and only the road user's membership of the lane is looked for in the window behind. The two lanes are quantified independently, one per road user, and nothing requires them to be distinct regions — the words give the test for 'different ways' below, and that test is what decides."
          kind := "reading" }
      , { span := "no public way the first road user's such lane lies on is a way the second road user's such lane lies on"
          why := "Written as a universal over the scene's highway regions, each read as a highway by its own atom: no region that is a public way is a way both approaches lie on. 'Public way' is read as the ontology's highway region and 'lies on' as st.on_way, the membership of a public way, not as geometric containment or nearness. The test is the negative one the words state: the body does not additionally demand that each approach lie on some way, so two approaches of which the source maps neither to any way share no way and satisfy the clause — where the source maps a way to neither lane, nothing is unknown and the clause holds."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.from_different_ways
