/-
  drv.lane.marked_lane_departure — The road user has moved out of a marked lane it was in: at the observation its footprint does not overlap a lane which its footprint overlapped at some observation within the window behind that the caller sets and a side of which carries a lane marking of a type other than none. The window is the observer's: it names the stretch of time behind the observation within which a lane the road user came from is looked for, and it is no measure of how long a movement may take, of how far the body has gone, or of whether the movement is a lawful one. An overlap at any one observation of that stretch is enough, and the look-back is anchored to no observation of the stretch: the concept asks only that an observation of the stretch be found at which the footprint overlapped the lane. An observation lying strictly between the two ends of the stretch answers the concept exactly as the observation just before this one and exactly as the observation at the far end of the stretch; the concept asks neither that the lane was overlapped at every observation of the stretch, nor that it was overlapped at the observation just before this one, nor that the overlap found is the latest overlap of the stretch, nor that the footprint has lain outside the lane at every observation since an overlap ceased. The stretch must be carried by the trace in full: where the window behind reaches past the start of the trace, the concept is unknown, whether or not an earlier overlap is found in the part of the stretch the trace covers. The concept is read from lane membership and the markings of a lane alone: it says nothing about where the road user went - a neighbouring lane of the same direction, a lane of another direction, a shoulder, a median or any other part of the way satisfies it alike - nothing about the side to which it moved, nothing about which marking lies between two lanes, and nothing about the road user's own turning or speed. It is not the turn indicator or arm signal given for a movement, not an intention to leave the lane, not an overtaking, and it carries no judgement that the movement was made with safety. It holds from the observation at which the lane first ceases to be overlapped, which is where the movement is recognized, until the window behind has passed; those later observations are not a further movement.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint does not overlap a lane which its footprint overlapped: atoms ['rel.occupies', 'st.lane'], concepts []
    a side of which carries a lane marking of a type other than none: atoms ['st.lane_marking'], concepts []
    at some observation within the window behind that the caller sets: atoms ['kin.time'], concepts []
    An overlap at any one observation of that stretch is enough, and the look-back is anchored to no observation of the stretch: atoms ['kin.time', 'rel.occupies'], concepts []
    An observation lying strictly between the two ends of the stretch answers the concept exactly as the observation just before this one: atoms ['kin.time', 'rel.occupies'], concepts []
    The stretch must be carried by the trace in full: where the window behind reaches past the start of the trace, the concept is unknown: atoms ['kin.time'], concepts []

  How each element is written:

    "its footprint does not overlap a lane which its footprint overlapped" — one existential over
    the lanes of the scene, `.existsRegion (.lit "lane") "r" …`, whose body reads one and the same
    region `r` twice through `rel_occupies` over the formal `u`: `.not (rel_occupies u r)` at the
    observation, and the look-back below at an observation of the stretch behind. Because both
    readings are of the one bound region, the lane whose overlap has ceased is the lane that was
    overlapped. `st_lane r` is read of that region by its own atom as well, so that a region whose
    kind the source cannot tell leaves the reading unknown rather than letting the quantifier pass
    it over silently; nothing of an offset from an edge or of a half of the roadway is read, which
    is the atom's exclusion. No other region kind is quantified over and no neighbour, direction,
    adjacency or side of the lane entered is read: where the road user went is not read at all.

    "a side of which carries a lane marking of a type other than none" — the disjunction of the two
    sides the atom carries: `.not (st_lane_marking r "left" "none")` or
    `.not (st_lane_marking r "right" "none")`. Either side marked answers the span. The colour
    position of the atom is not written, so no colour and no judgement of how clear a marking is
    enters; which side carries the marking is never compared with anything, since the concept
    takes no side. A side whose marking the source does not observe makes that side's reading
    unknown, never false (see the narrowing on this span).

    "at some observation within the window behind that the caller sets", "An overlap at any one
    observation of that stretch is enough …", "An observation lying strictly between the two ends
    of the stretch answers the concept exactly as the observation just before this one" — these
    three elements are one and the same existential over the observations of the stretch, written
    as the dual of the window behind:
    `.not (.holdsFor .time lane_departure_window "u" (.not (rel_occupies u r)))`.
    `holdsFor .time` is the window of `lane_departure_window` seconds behind the observation,
    measured on the clock (`kin_time`), and it holds where its body holds at EVERY observation of
    that window; so its negation over the negated occupancy is "at SOME observation of the window
    behind, the footprint overlapped the lane". No observation of the stretch is distinguished:
    not the observation just before, not the one at the far end, not the latest overlap — one
    observation carrying the overlap answers it, wherever in the stretch it lies. Nothing asks the
    overlap to run up to the present observation, nothing asks the footprint to have lain outside
    the lane since, and no `atLast`, `rises`, `since` or `count` is written, each of which would
    anchor the look-back to an observation the contract refuses to anchor it to.

    "The stretch must be carried by the trace in full: where the window behind reaches past the
    start of the trace, the concept is unknown" — a condition of its own, read from the instants
    alone: `.holdsFor .time lane_departure_window "u" (kin_time = kin_time)`, a window behind over
    a condition that reads the instant of the observation and nothing else. That condition holds
    at every observation the trace carries, so the window operator decides the whole of it on
    coverage: true where the trace reaches back over the stretch, unknown (`windowTruncated`)
    where it does not. It guards the existential through `.definedWhen` rather than `.and` (see
    the narrowing), so a stretch the trace does not carry in full is unknown whether or not the
    covered part of it carries an overlap.

  The unknowns are the atoms': an unobserved occupancy leaves both readings of `rel_occupies`
  unknown, an unobserved marking leaves that side unknown, a region whose kind is untold leaves
  `st_lane` unknown, and a window behind that reaches past the start of the trace is unknown by
  the guard above. Nothing of the body reads a turn indicator, a hand signal, a heading, a yaw
  rate, a speed, a device, an intention or another road user, which is what the contract excludes.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.marked_lane_departure

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The lane the body quantifies over: bound inside the body, not a formal. -/
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pLaneDepartureWindow : Term := .param "lane_departure_window"

/-- The instant of the observation, as the clock carries it. -/
def timeNow : Term := .measure "kin_time" []

/-- The region the body speaks about is a lane: read by its own atom, so that a region whose kind
    the source cannot tell leaves the reading unknown rather than silently decided. -/
def isLane : Formula := .atom "st_lane" [aR] []

/-- The named side of the lane carries a marking of a type other than none. -/
def markedOnSide (side : String) : Formula :=
  .not (.atom "st_lane_marking" [aR, .lit side, .lit "none"] [])

/-- A side of the lane carries a lane marking of a type other than none: either side answers it. -/
def isMarkedLane : Formula :=
  .or (markedOnSide "left") (markedOnSide "right")

/-- The road user's footprint overlaps the lane. -/
def occupiesLane : Formula := .atom "rel_occupies" [aU, aR] []

/-- At the observation the footprint does not overlap the lane. -/
def outsideLaneNow : Formula := .not occupiesLane

/-- At some observation within the window behind, the footprint overlapped the lane: the dual of
    the window behind, which holds where its body holds at every observation of the window. -/
def occupiedLaneWithinWindow : Formula :=
  .not (.holdsFor .time pLaneDepartureWindow "u" (.not occupiesLane))

/-- A marked lane the footprint overlapped at some observation of the stretch behind and does not
    overlap at the observation. -/
def departedFromLane : Formula :=
  .existsRegion (.lit "lane") "r"
    (.and (.and isLane isMarkedLane)
          (.and outsideLaneNow occupiedLaneWithinWindow))

/-- The stretch behind the observation is carried by the trace in full: the window behind over a
    condition that reads the instant of the observation and nothing else, true at every
    observation the trace carries and unknown where the window reaches past its start. -/
def stretchCarriedByTrace : Formula :=
  .holdsFor .time pLaneDepartureWindow "u" (.cmp timeNow .eq timeNow)

/-- The road user has moved out of a marked lane it was in, read where the stretch behind is
    carried by the trace and unknown where it is not. -/
def body : Formula :=
  .definedWhen stretchCarriedByTrace departedFromLane

def concept : Concept :=
  { id := "drv.lane.marked_lane_departure"
    contract := "The road user has moved out of a marked lane it was in: at the observation its footprint does not overlap a lane which its footprint overlapped at some observation within the window behind that the caller sets and a side of which carries a lane marking of a type other than none. The window is the observer's: it names the stretch of time behind the observation within which a lane the road user came from is looked for, and it is no measure of how long a movement may take, of how far the body has gone, or of whether the movement is a lawful one. An overlap at any one observation of that stretch is enough, and the look-back is anchored to no observation of the stretch: the concept asks only that an observation of the stretch be found at which the footprint overlapped the lane. An observation lying strictly between the two ends of the stretch answers the concept exactly as the observation just before this one and exactly as the observation at the far end of the stretch; the concept asks neither that the lane was overlapped at every observation of the stretch, nor that it was overlapped at the observation just before this one, nor that the overlap found is the latest overlap of the stretch, nor that the footprint has lain outside the lane at every observation since an overlap ceased. The stretch must be carried by the trace in full: where the window behind reaches past the start of the trace, the concept is unknown, whether or not an earlier overlap is found in the part of the stretch the trace covers. The concept is read from lane membership and the markings of a lane alone: it says nothing about where the road user went - a neighbouring lane of the same direction, a lane of another direction, a shoulder, a median or any other part of the way satisfies it alike - nothing about the side to which it moved, nothing about which marking lies between two lanes, and nothing about the road user's own turning or speed. It is not the turn indicator or arm signal given for a movement, not an intention to leave the lane, not an overtaking, and it carries no judgement that the movement was made with safety. It holds from the observation at which the lane first ceases to be overlapped, which is where the movement is recognized, until the window behind has passed; those later observations are not a further movement."
    definition := none
    args := [("u", .track)]
    params := [⟨"lane_departure_window", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "at some observation within the window behind that the caller sets"
          why := "The formula language carries no existential over the observations of a window behind; it carries `holdsFor`, which is universal over them. The look-back is therefore written as that operator's dual, `.not (.holdsFor .time lane_departure_window \"u\" (.not (rel_occupies u r)))`, which on a covered window is true exactly when some observation of the window carries the overlap, and which reports the operator's own `windowTruncated` where the window is not covered. Two consequences of the operator are declared here. First, its window behind includes the observation itself: that changes nothing, because the same lane is required by the conjunct beside it not to be overlapped at the observation, so the overlap found always lies strictly behind. Second, the operator reports a sampling gap where the observations inside the window are more than half the window apart; that is the library's interpolation-free reading of 'an observation within the stretch', not a condition of this concept. The window is measured in time (`.time`), never in the road user's own path: the contract calls it a stretch of time behind the observation and says it is no measure of how far the body has gone."
          kind := "reading" }
      , { span := "a side of which carries a lane marking of a type other than none"
          why := "Written as the disjunction of the two sides the atom carries, each side as the negation of 'the marking of that side is of type none': `.not (st_lane_marking r \"left\" \"none\")` or the same of the right side. Either side marked answers the span, which is what 'a side of which' says. The negation is read three-valued: where the source does not observe that side's marking the atom is unknown, so the side's reading is unknown and not 'other than none' — an unobserved marking never makes a lane count as marked. The colour position of the atom is left unwritten, since the contract reads the type alone, and no comparison of the marked side with the side the road user moved to is written, since the concept takes no side."
          kind := "reading" }
      , { span := "The stretch must be carried by the trace in full: where the window behind reaches past the start of the trace, the concept is unknown, whether or not an earlier overlap is found in the part of the stretch the trace covers."
          why := "Coverage is written as a condition of its own and guards the existential through `.definedWhen`, not through `.and`. Under the library's Kleene conjunction an unknown coverage beside a false existential would settle to false, and the concept would then report 'no marked lane departed' on a stretch the trace does not carry in full — exactly what this sentence forbids with its 'whether or not an earlier overlap is found'. `.definedWhen` instead carries the coverage condition's own unknown (`windowTruncated`) wherever that condition is not true, and reads the existential where it is. The condition itself is `.holdsFor .time lane_departure_window \"u\" (kin_time = kin_time)`: a window behind over a statement that reads nothing but the instant of the observation it is read at, and so holds at every observation the trace carries. Its whole content is therefore the window operator's own three-valued boundary — true where the trace reaches back over the stretch, unknown where it does not — which is what the contract asks for, read from the instants alone."
          kind := "reading" }
      , { span := "It holds from the observation at which the lane first ceases to be overlapped, which is where the movement is recognized, until the window behind has passed; those later observations are not a further movement."
          why := "No operator is written for this sentence: it states what the window behind already does. The body is read at the instant against the stretch behind it, so it becomes true at the first observation at which the lane ceases to be overlapped and stays true while an overlap of that lane remains inside the stretch, falling false once the last overlap has slid out behind. No `rises`, no `since` and no counting of departures is added: such an operator would make the concept hold at one observation only, or count the run of observations as several movements, and the contract says those later observations are not a further movement rather than that they are not the movement."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.marked_lane_departure
