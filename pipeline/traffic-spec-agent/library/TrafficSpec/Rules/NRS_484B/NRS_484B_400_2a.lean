/-
  NRS_484B_400_2a — NRS-484B-400-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    s2 (trigger): intends to turn at an intersection
    s3 (boilerplate): and:
    s4 (condition): Both intersecting highways are two-directional:
    s5 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection', 'st.lane', 'st.lane_enters'], derived ['drv.motion.left_turn']
    s4: atoms ['rel.occupies', 'st.roadway', 'st.one_way_roadway'], derived []
    s5: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'st.intersection'], derived []

  How each span is written:

    s1 — `clsV`: the aggregate word the run's reading declares, carried by `ru_aggregate` with the
      word as the atom's literal argument. The node reads the duty on the vehicle's controlled
      motion (its narrowing of kind `observable_reading`, category agency); nothing of that choice
      is this file's, so no narrowing of s1 is declared here, and the subject span is carried as
      the node maps it.

    s2 — `intersectionEntry` and `turnRecognized`: the junction the subject comes to is the
      intersection region its own footprint comes to overlap (`st_intersection`, `rel_occupies`,
      `rises`), and it is the junction of the lane it approached on (`st_lane`,
      `st_lane_enters`, `approachLaneEnters`). The intention is read through the act
      (the node's narrowing of kind `observable_reading`, category intention): within
      `p.turn_intent_window` ahead of the entry, `drv.motion.left_turn` over
      `p.turn_window` at `p.corner_heading_change` is recognized of the subject's body.

    s4 — `onTwoDirectionalRoadway`: a roadway not restricted to one direction is a region that
      `st_roadway` holds of and `st_one_way_roadway` does not; the two intersecting highways are
      read through the subject's own occupancy (`rel_occupies`) — the roadway it was on at the end
      of its approach and the roadway it is on when the turning is recognized. This is the node's
      own mapping of the condition span, not a choice of this file's: a condition span is carried
      as the node maps it, so no narrowing of s4 is declared.

    s5 — `obligation`, through `atApproachEnd` and `inLaneNearestCentreline`. Two readings of this
      obligation span are declared below as narrowings, because the words leave both open:
        (i)  the approach is read at its end — the last observation within
             `p.approach_lookback_window` behind at which the subject's footprint did not yet
             overlap the junction (`atLast`), not at every observation of the approach;
        (ii) 'that portion of the right half of the highway nearest the centerline' is read as a
             lane: the lane the subject occupies that has no neighbouring lane of its own
             direction on its left (`st_lane_adjacency` with the literal side `left`, under a
             negated existential over lanes). Where the right half carries one lane only, every
             position in that lane satisfies the rule as read.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachLookbackWindow : Term := .param "p.approach_lookback_window"
def pCornerHeadingChange : Term := .param "p.corner_heading_change"
def pTurnIntentWindow : Term := .param "p.turn_intent_window"
def pTurnWindow : Term := .param "p.turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "vehicle"] []

/-- s4: `v` occupies a roadway that is not a roadway on which traffic is restricted to one
    direction — a two-directional highway, read through the roadway the subject is itself on. -/
def onTwoDirectionalRoadway : Formula :=
  .existsRegion (.lit "roadway") "rw"
    (.and (.atom "st_roadway" [.var "rw"] [])
      (.and (.atom "rel_occupies" [vV, .var "rw"] [])
            (.not (.atom "st_one_way_roadway" [.var "rw"] []))))

/-- s5: `v` occupies a lane that has no neighbouring lane of its own direction of travel on its
    left — on a roadway carrying both directions, the lane against the centre line. -/
def inLaneNearestCentreline : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (.atom "st_lane" [.var "l"] [])
      (.and (.atom "rel_occupies" [vV, .var "l"] [])
            (.not (.existsRegion (.lit "lane") "n"
                     (.atom "st_lane_adjacency" [.var "l", .lit "left", .var "n"] [])))))

/-- The end of the approach: `φ` at the last observation within `p.approach_lookback_window`
    behind at which `v`'s footprint did not yet overlap the intersection region `i`. -/
def atApproachEnd (i : Arg) (φ : Formula) : Formula :=
  .atLast .time pApproachLookbackWindow "v" (.not (.atom "rel_occupies" [vV, i] [])) φ

/-- s2: the lane `v` reached the junction `i` on is an approach to `i`. -/
def approachLaneEnters (i : Arg) : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (.atom "st_lane" [.var "l"] [])
      (.and (.atom "st_lane_enters" [.var "l", i] [])
            (atApproachEnd i (.atom "rel_occupies" [vV, .var "l"] []))))

/-- s2 and s4: within `p.turn_intent_window` ahead, a turning of `v`'s body to the left through at
    least `p.corner_heading_change` over `p.turn_window` is recognized, and the roadway `v`
    occupies when it is recognized — the roadway of the highway it turns into — is not restricted
    to one direction. -/
def turnRecognized : Formula :=
  .within .time pTurnIntentWindow "v"
    (.and (.derived "drv_motion_left_turn" [vV] [pTurnWindow, pCornerHeadingChange])
          onTwoDirectionalRoadway)

/-- Applicability: s2 (trigger): intends to turn at an intersection; s4 (condition): Both intersecting highways are two-directional: -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_intersection" [.var "i"] [])
      (.and (.rises (.atom "rel_occupies" [vV, .var "i"] []))
        (.and (approachLaneEnters (.var "i"))
          (.and (atApproachEnd (.var "i") onTwoDirectionalRoadway)
                turnRecognized))))

/-- Obligation: s5 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof. -/
def obligation : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_intersection" [.var "i"] [])
      (.and (.atom "rel_occupies" [vV, .var "i"] [])
            (atApproachEnd (.var "i") inLaneNearestCentreline)))

def rule : Rule :=
  { id := "NRS_484B_400_2a"
    laws := ["NRS-484B-400-2a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "The approach is a stretch of road and a stretch of time, and the words do not say at which of its observations the duty is read. The rule reads it at its end: the lane the subject occupied at the last observation within the look-back window at which its footprint did not yet overlap the junction. A vehicle that travels the whole approach in the wrong lane and pulls across at the last is therefore not caught, which is narrower than the words; a vehicle that changes into the lane against the centre line during its approach is not convicted for the lane it started in."
          kind := "reading" }
      , { span := "s5"
          why := "'that portion of the right half of the highway nearest the centerline' is read as a lane: the lane of the subject's own direction that has no neighbouring lane of that direction on its left. Where the right half carries two or more lanes this is the span's own meaning. Where it carries one lane only, every position in that lane satisfies the rule as read, so a vehicle approaching hugging the outer edge of a wide undivided approach is not caught: the ontology carries no lateral position within a lane, and `st.lane` is expressly not a stand-in for one."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2a
