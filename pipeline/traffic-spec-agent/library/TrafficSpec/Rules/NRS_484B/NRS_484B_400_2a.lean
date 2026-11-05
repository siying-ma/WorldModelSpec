/-
  NRS_484B_400_2a — NRS-484B-400-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    h1 (subject): If the driver of a vehicle
    h2 (condition): intends to turn
    h3 (condition): at an intersection and:
    h4 (condition): Both intersecting highways are two-directional:
    h5 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof.

  Elements (span → atoms, derived):
    h1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    h3: atoms ['st.intersection', 'rel.occupies', 'st.lane_enters', 'st.travel_region'], derived ['drv.position.approaching_intersection']
    h4: atoms ['st.highway', 'st.on_way', 'st.intersection'], derived ['drv.road.two_directional_way']
    h5: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.centre_line', 'st.roadway', 'st.highway', 'st.on_way', 'st.lane_enters', 'st.travel_region', 'prim.region_lateral_offset', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.position.approaching_intersection']

  How each span is written.

    h1 — `clsSubject` is the one atom `ru_aggregate` of the binder with the admitted aggregate's id.

    h3 — `approaches`: a region quantifier over intersections, the kind atom `st_intersection` on
    the bound region (a region whose kind the source cannot tell reaches the quantifier, and the
    atom is what decides it), and `drv.position.approaching_intersection` of the subject at that
    region, which carries `rel.occupies`, `st.lane_enters` and `st.travel_region`.

    h2 — `declaresLeftTurn`: the declared intention `int.left_turn` of the subject at the junction
    h3 binds, read at the judged observation.

    h4 — `bothWaysTwoDirectional`: for every highway the junction lies on (`st_highway`,
    `st_on_way` of the junction on that way, the atom the contract gives for "an intersection lies
    on every way that meets there"), `drv.road.two_directional_way` of that way, bounded by
    `p.opposite_direction_tolerance`.

    h5 — the duty. The junction is selected again, whole: the same `approaches` and the same
    declaration, under a quantifier over every intersection so selected, so that the duty is owed
    at each junction the subject approaches with a declared left turn. Within it:
      · `onApproachCarrier` — the travel region the subject occupies whose entrance end is that
        junction (`rel.occupies`, `st.travel_region`, `st.lane_enters`): the stretch of road on
        which the approach is being made, and the carrier of the subject's own designated
        direction of travel;
      · `onHighway` — the highway (`st.highway`) that both the junction and that carrier lie on
        (`st.on_way`): "the highway" of the words;
      · `inLeftmostLane` — the subject occupies a lane (`st.lane`, `rel.occupies`) lying on that
        highway whose designated direction is the carrier's (`st.lane_direction`) and whose
        ordinal (`st.lane_adjacency`) is at most that of every lane of that direction on that
        highway: the portion of its own half next to the centreline where the road carries lanes;
      · `nearestTheCentreline` — where the subject occupies a roadway (`st.roadway`,
        `rel.occupies`) and no lane of its direction lies on that highway, the centreline
        (`st.centre_line`, `st.on_way`) lies to its left and no farther than the reach: the signed
        lateral offset (`prim.region_lateral_offset`) is above zero and at most
        `p.centreline_proximity_reach`.

  Narrowings this session chose on h5 (each declared in `narrowings` below; the record's own
  narrowings are the plan's and are not restated):

    (i) "its own direction of travel" is read as the designated direction of the approach carrier
    the subject occupies whose entrance end is that junction. No atom the node claims carries the
    subject's own heading, and `st.lane_direction` is the designated direction of a region, so the
    direction of travel is read from the carrier the subject is on rather than from the body.

    (ii) "whose ordinal in that direction is the leftmost" is written as "no lane of that direction
    on that highway has a smaller ordinal". The node declares no literal, so the leftmost ordinal
    is not compared against the figure 1; the comparison is against the ordinals of the other lanes
    of that direction, which the atom's contract ("ordinal 1 is the leftmost lane") makes the same
    selection wherever the ordinals of a direction are recorded.

    (iii) "where no lane region of that direction lies on the roadway it occupies" is written as
    "the subject occupies a roadway and no lane of that direction lies on that highway". No atom
    relates a lane to a roadway — `st.on_way` relates a region to a highway only — and the
    condition of the rule is a two-directional, undivided highway, on which the roadway the subject
    occupies is the roadway of that highway.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCentrelineProximityReach : Term := .param "p.centreline_proximity_reach"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The regions the formulas bind. -/
def aJunction : Arg := .var "junction"
def aWay : Arg := .var "way"
def aCarrier : Arg := .var "carrier"
def aLane : Arg := .var "lane"
def aOther : Arg := .var "other"
def aRoadway : Arg := .var "roadway"
def aCentre : Arg := .var "centre"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- h3: `j` is an intersection the subject is approaching. -/
def approaches (j : Arg) : Formula :=
  .and (.atom "st_intersection" [j] [])
       (.derived "drv_position_approaching_intersection" [vSubject, j] [])

/-- h2, at the place h3 names: the declaration current here is a turn to the left at `j`. -/
def declaresLeftTurn (j : Arg) : Formula := .intent "int.left_turn" vSubject j

/-- h4: every highway the junction lies on is two-directional. -/
def bothWaysTwoDirectional (j : Arg) : Formula :=
  .forallRegion (.lit "highway") "way"
    (.implies (.and (.atom "st_highway" [aWay] []) (.atom "st_on_way" [j, aWay] []))
              (.derived "drv_road_two_directional_way" [aWay] [pOppositeDirectionTolerance]))

/-- Applicability: h2 (condition): intends to turn; h3 (condition): at an intersection and:; h4 (condition): Both intersecting highways are two-directional: -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "junction"
    (.and (approaches aJunction)
      (.and (declaresLeftTurn aJunction)
            (bothWaysTwoDirectional aJunction)))

/-- The two regions carry the same designated direction of travel. -/
def sameDesignatedDirection (a b : Arg) : Formula :=
  .and (.cmp (.measure "st_lane_direction" [a, .lit "x"]) .eq
             (.measure "st_lane_direction" [b, .lit "x"]))
       (.cmp (.measure "st_lane_direction" [a, .lit "y"]) .eq
             (.measure "st_lane_direction" [b, .lit "y"]))

/-- The approach the subject is making: a travel region it occupies whose entrance end is `j`. -/
def onApproachCarrier (j : Arg) (φ : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "carrier"
    (.and (.atom "st_travel_region" [aCarrier] [])
      (.and (.atom "rel_occupies" [vSubject, aCarrier] [])
        (.and (.atom "st_lane_enters" [aCarrier, j] []) φ)))

/-- "the highway": the way both the junction and the approach carrier lie on. -/
def onHighway (j : Arg) (φ : Formula) : Formula :=
  .existsRegion (.lit "highway") "way"
    (.and (.atom "st_highway" [aWay] [])
      (.and (.atom "st_on_way" [j, aWay] [])
        (.and (.atom "st_on_way" [aCarrier, aWay] []) φ)))

/-- The subject is in the lane of its own direction nearest the centreline: a lane it occupies on
    that highway, of the carrier's designated direction, no lane of that direction having a
    smaller ordinal. -/
def inLeftmostLane : Formula :=
  .existsRegion (.lit "lane") "lane"
    (.and (.atom "st_lane" [aLane] [])
      (.and (.atom "rel_occupies" [vSubject, aLane] [])
        (.and (.atom "st_on_way" [aLane, aWay] [])
          (.and (sameDesignatedDirection aLane aCarrier)
            (.forallRegion (.lit "lane") "other"
              (.implies
                (.and (.atom "st_lane" [aOther] [])
                  (.and (.atom "st_on_way" [aOther, aWay] [])
                        (sameDesignatedDirection aOther aCarrier)))
                (.cmp (.measure "st_lane_adjacency" [aLane, .lit "ordinal"]) .le
                      (.measure "st_lane_adjacency" [aOther, .lit "ordinal"]))))))))

/-- No lane of the carrier's designated direction lies on that highway. -/
def noLaneOfItsDirection : Formula :=
  .not (.existsRegion (.lit "lane") "other"
    (.and (.atom "st_lane" [aOther] [])
      (.and (.atom "st_on_way" [aOther, aWay] [])
            (sameDesignatedDirection aOther aCarrier))))

/-- The signed lateral offset of the centreline from the subject (left positive). -/
def offsetToCentre : Term := .quantity "prim_region_lateral_offset" [vSubject, aCentre] []

/-- The centreline of that highway lies to the subject's left, within the proximity reach. -/
def centrelineOnTheLeft : Formula :=
  .existsRegion (.lit "centre_line") "centre"
    (.and (.atom "st_centre_line" [aCentre] [])
      (.and (.atom "st_on_way" [aCentre, aWay] [])
        (.and (.cmp offsetToCentre .gt zeroMetres)
              (.cmp offsetToCentre .le pCentrelineProximityReach))))

/-- Where the road carries no lane of the subject's direction: the subject occupies a roadway and
    the centreline is the mark its own half's innermost portion abuts. -/
def nearestTheCentreline : Formula :=
  .existsRegion (.lit "roadway") "roadway"
    (.and (.atom "st_roadway" [aRoadway] [])
      (.and (.atom "rel_occupies" [vSubject, aRoadway] [])
        (.and noLaneOfItsDirection centrelineOnTheLeft)))

/-- Obligation: h5 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junction"
    (.implies (.and (approaches aJunction) (declaresLeftTurn aJunction))
      (onApproachCarrier aJunction
        (onHighway aJunction
          (.or inLeftmostLane nearestTheCentreline))))

def rule : Rule :=
  { id := "NRS_484B_400_2a"
    laws := ["NRS-484B-400-2a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "h5"
          why := "\"its own direction of travel\" is read as the designated direction of the travel region the subject occupies whose entrance end is that junction: no claimed atom carries the subject's own heading, and st.lane_direction is a region's designated direction, so the direction of travel is read from the approach carrier the subject is on."
          kind := "reading" }
      , { span := "h5"
          why := "\"whose ordinal in that direction is the leftmost\" is written as \"no lane of that direction on that highway has a smaller ordinal\": the node declares no literal, so the ordinal is not compared with the figure 1, and the comparison is made against the ordinals of the other lanes of that direction, which st.lane_adjacency's contract (\"ordinal 1 is the leftmost lane\") makes the same selection wherever the ordinals of a direction are recorded."
          kind := "reading" }
      , { span := "h5"
          why := "\"where no lane region of that direction lies on the roadway it occupies\" is written as \"the subject occupies a roadway and no lane of that direction lies on that highway\": no atom relates a lane to a roadway (st.on_way relates a region to a highway only), and the rule's condition is an undivided two-directional highway, whose roadway is the one the subject occupies."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2a
