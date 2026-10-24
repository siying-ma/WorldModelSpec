/-
  drv.control.approach_without_stop_or_yield_sign — The road user comes to an intersection on an approach that no stop sign and no yield sign faces: there is an intersection region and a lane that runs into that intersection which the road user's footprint overlaps at the observation or overlapped at some observation within the window behind that the caller sets, and no stop sign and no yield sign governs that lane. The window is the observer's: it names the stretch of time behind the observation within which the approach the road user came in on is looked for, once the road user has left that approach by entering the intersection, and it is no measure of how recently the road user arrived or of how long an entry may take. The concept is a configuration at an instant, read from the road user's lane membership, from the intersection a lane runs into and from the traffic a device faces. It says nothing about what any device displays: a signal head, a warning sign or a zone sign over the same approach leaves it satisfied, and a covered or dark head is no different from a lit one. It says nothing about whether a public authority erected anything, nothing about the right of one road user to proceed in preference to another, nothing about which way the road user travels, which movement it makes or how fast it goes, and nothing about whether the road user is inside the intersection now. It is not the state of a signal, not a person directing traffic, not the lane a lane leads into, and not a judgement that the road user may proceed. Where no approach lane is found for the road user and the window behind reaches past the start of the trace, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    there is an intersection region and a lane that runs into that intersection: atoms ['st.intersection', 'st.lane', 'st.lane_enters'], concepts []
    which the road user's footprint overlaps at the observation or overlapped at some observation within the window behind: atoms ['rel.occupies'], concepts []
    no stop sign and no yield sign governs that lane: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs'], concepts []

  How each element is written:

    "there is an intersection region and a lane that runs into that intersection" — an existential
    over the scene's intersection regions, `ix`, read as an intersection by its own atom
    (`st_intersection`, of the bound region, so a region whose kind the source cannot tell leaves
    the conjunct unknown rather than silently true), and inside it an existential over the scene's
    lane regions, `la`, read as a lane (`st_lane`) and as an approach to that junction
    (`st_lane_enters la ix` — the intersection a lane runs into at its end, never the lane a lane
    leads into, which is st.lane_connectivity and is not claimed). Both the lane's kind and the
    approach relation are read at the observation; only the road user's membership is looked for
    in the window behind. Nothing demands that the road user be inside the junction now, and
    nothing is read of the junction but that it is an intersection.

    "which the road user's footprint overlaps at the observation or overlapped at some observation
    within the window behind" — `atLast .time approach_window "u" (rel_occupies u la) tt`: the
    value `tt` at the last observation in the window behind at which the footprint overlapped the
    lane. That is true where an overlap is found anywhere in the window (the window behind
    includes the observation itself, so a road user still in its approach lane is decided by its
    present membership), false where the window is covered and no overlap is found, and unknown
    where none is found and the window reaches past the start of the trace — the contract's own
    unknown clause. The window is measured in time, not in path travelled, because the contract
    names a stretch of time, and its length is the caller's parameter.

    "no stop sign and no yield sign governs that lane" — two universals, one over the scene's
    stop-sign devices and one over its yield-sign devices, each re-reading the device's kind of
    the bound device (`dev_stop_sign d`, `dev_yield_sign y`, so a device whose kind the source
    cannot tell leaves the conjunct unknown rather than silently false) and reading which traffic
    it faces through `dev_governs _ la`: no device that is a stop sign governs that lane, and none
    that is a yield sign governs it. The lane is the one just bound — the traffic the sign faces,
    never where a halt is required (dev.position, st.stop_line is not read) and never the junction
    region itself. The test is negative: a lane no device at all is mapped to satisfies it, and
    where the source does not report which traffic a device faces every conjunct over that device
    is unknown and so is the concept.

  Nothing about what a device displays, about who erected it, about the road user's direction,
  movement, speed or presence in the junction, and nothing about any right to proceed is written:
  the contract excludes them and no such atom is read. A signal head, a warning sign or a zone
  sign over the same approach is not a stop sign and not a yield sign, so it leaves the body
  satisfied; a covered or dark head is no different from a lit one, because no indication atom is
  read at all.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.control.approach_without_stop_or_yield_sign

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pApproachWindow : Term := .param "approach_window"

/-- The junction the road user came to, bound inside the body and anchored to the formal through
    the approach lane that runs into it. -/
def aJunction : Arg := .var "ix"
/-- The approach lane the road user came in on, anchored to the formal by `rel_occupies`. -/
def aLane : Arg := .var "la"
/-- A stop sign and a yield sign, each anchored to the approach lane by `dev_governs`. -/
def aStopSign : Arg := .var "d"
def aYieldSign : Arg := .var "y"

/-- There is an intersection region. -/
def anIntersection : Formula :=
  .atom "st_intersection" [aJunction] []

/-- The road user's footprint overlaps the lane at the observation, or overlapped it at some
    observation within the window behind: the value at the last observation in that window at
    which the footprint overlapped the lane. Unknown where no such observation is found and the
    window reaches past the start of the trace. -/
def cameInOn : Formula :=
  .atLast .time pApproachWindow "u" (.atom "rel_occupies" [aU, aLane] []) .tt

/-- No stop sign governs that lane. -/
def noStopSignFaces : Formula :=
  .forallDevice (.lit "stop_sign") "d"
    (.not (.and (.atom "dev_stop_sign" [aStopSign] [])
      (.atom "dev_governs" [aStopSign, aLane] [])))

/-- No yield sign governs that lane. -/
def noYieldSignFaces : Formula :=
  .forallDevice (.lit "yield_sign") "y"
    (.not (.and (.atom "dev_yield_sign" [aYieldSign] [])
      (.atom "dev_governs" [aYieldSign, aLane] [])))

/-- A lane that runs into that intersection which the road user's footprint overlaps, and which no
    stop sign and no yield sign governs. -/
def approachWithoutSign : Formula :=
  .and (.atom "st_lane" [aLane] [])
    (.and (.atom "st_lane_enters" [aLane, aJunction] [])
      (.and cameInOn (.and noStopSignFaces noYieldSignFaces)))

def body : Formula :=
  .existsRegion (.lit "intersection") "ix"
    (.and anIntersection
      (.existsRegion (.lit "lane") "la" approachWithoutSign))

def concept : Concept :=
  { id := "drv.control.approach_without_stop_or_yield_sign"
    contract := "The road user comes to an intersection on an approach that no stop sign and no yield sign faces: there is an intersection region and a lane that runs into that intersection which the road user's footprint overlaps at the observation or overlapped at some observation within the window behind that the caller sets, and no stop sign and no yield sign governs that lane. The window is the observer's: it names the stretch of time behind the observation within which the approach the road user came in on is looked for, once the road user has left that approach by entering the intersection, and it is no measure of how recently the road user arrived or of how long an entry may take. The concept is a configuration at an instant, read from the road user's lane membership, from the intersection a lane runs into and from the traffic a device faces. It says nothing about what any device displays: a signal head, a warning sign or a zone sign over the same approach leaves it satisfied, and a covered or dark head is no different from a lit one. It says nothing about whether a public authority erected anything, nothing about the right of one road user to proceed in preference to another, nothing about which way the road user travels, which movement it makes or how fast it goes, and nothing about whether the road user is inside the intersection now. It is not the state of a signal, not a person directing traffic, not the lane a lane leads into, and not a judgement that the road user may proceed. Where no approach lane is found for the road user and the window behind reaches past the start of the trace, it is unknown."
    definition := none
    args := [("u", .track)]
    params := [⟨"approach_window", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "which the road user's footprint overlaps at the observation or overlapped at some observation within the window behind that the caller sets"
          why := "Written as `atLast` over the time window behind, with the overlap as the condition and `tt` as the value: true where an overlap with that lane is found at any observation of the window, false where the window is covered and none is found, unknown where none is found and the window reaches past the start of the trace — the contract's own unknown clause. The window behind includes the observation itself, so the disjunct 'at the observation' needs no clause of its own; the language's other bounded look-back, `holdsFor`, would demand the overlap at every observation of the window, which the words do not, and its negation would report a truncated window as unknown even where an overlap was found. The window is measured in time, not in path travelled, because the contract names a stretch of time."
          kind := "reading" }
      , { span := "there is an intersection region and a lane that runs into that intersection"
          why := "Both the lane's kind and the approach relation are read at the observation, not within the window: only the road user's membership of the lane is looked for in the window behind. The junction and the lane are quantified over the scene's regions and each is read by its own kind atom, so a region whose kind the source cannot tell leaves the conjunct unknown rather than silently true. Nothing requires the lane to be unique: where the road user's footprint overlaps several approach lanes of the junction, the concept holds as soon as one of them is faced by neither sign, which is what an existential over the lanes says."
          kind := "reading" }
      , { span := "no stop sign and no yield sign governs that lane"
          why := "Written as two universals over the scene's stop-sign and yield-sign devices, each re-reading the bound device's kind, rather than as a negated existential: the forms agree on true and false, and both report unknown where the source does not say which traffic a device faces. The test is the negative one the words state — the body does not additionally demand that any device exist or that any device be mapped to the lane, so an approach no device is mapped to satisfies the clause. 'Governs that lane' is read as the traffic the device faces (dev.governs of the approach lane), not as the device's position beside the lane and not as the junction region the lane runs into."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.control.approach_without_stop_or_yield_sign
