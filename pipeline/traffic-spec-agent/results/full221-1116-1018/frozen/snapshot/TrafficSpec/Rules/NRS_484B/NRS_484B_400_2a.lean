/-
  NRS_484B_400_2a — NRS-484B-400-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    s2 (trigger): intends to turn
    s3 (trigger): at an intersection and:
    s4 (condition): Both intersecting highways are two-directional:
    s5 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.intersection', 'rel.occupies', 'st.lane_enters', 'st.lane', 'st.roadway'], derived []
    s4: atoms ['st.highway', 'st.on_way', 'st.intersection', 'st.median_or_divider', 'st.lane', 'st.roadway', 'st.lane_direction'], derived []
    s5: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'st.lane_enters', 'st.lane_direction', 'st.on_way', 'st.highway', 'st.roadway'], derived []

  How each span is written:
    s1  `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (the binder's class).
    s3  The judged observation e is the subject's entry into an intersection i:
        `rises (rel_occupies subject i)` for some region i of kind `intersection`.
        "The observation before e" is read with `since`: `since (occ i) (¬occ i ∧ X)` at e, where
        occ i rose at e, is X at the observation just before e (the last observation of the
        approach, at which the subject was not yet in i). No window length is read.
    s2  `intent int.left_turn subject i` at the observation before e (`atApproachEnd`), a look
        behind, never ahead.
    s4  Every highway h with `st_on_way i h` is two-directional: no region of kind
        `median_or_divider` lies on h (`st_on_way m h`), and two carriers lying on h — lanes or
        roadway (directed) segments — carry designated directions (`st_lane_direction`, x and y
        components of the normalised vector) whose dot product (their cosine) is at or below
        −p.lane_opposed_direction_cos. The pair is written lane/lane, lane/roadway and
        roadway/roadway: the cosine is symmetric, so roadway/lane is the lane/roadway pair.
    s5  At the observation before e (`atApproachEnd`): the subject occupies a lane c entering i
        (`st_lane_enters c i`) that is the lane nearest the centerline — ordinal 1, written as
        "no lane is c's left neighbour of the same direction" (`st_lane_adjacency c "left" c'`
        false for every lane c'; the accessor decides it false exactly where c is first from the
        left, i.e. ordinal 1, and unknown where neither the neighbour nor the ordinal is observed);
        or, where the subject occupies no lane entering i, a roadway segment c entering i. In both
        cases the subject occupies no lane or roadway segment d lying on a highway that c lies on
        whose direction makes with c's a cosine at or below −p.lane_opposed_direction_cos.
        Writing ordinal 1 through the neighbour relation avoids a bare literal 1 (the node
        declares no literals); the two are the same fact by the contract of st.lane_adjacency
        ("ordinal 1 is the leftmost lane"), so no narrowing is declared for it.
    The obligation restates the applicability's whole selection of i (entry, intention, both
    highways two-directional) and requires the duty at every selected intersection (rule 3c).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pLaneOpposedDirectionCos : Term := .param "p.lane_opposed_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

def kLane : Arg := .lit "lane"
def kRoadway : Arg := .lit "roadway"
def kHighway : Arg := .lit "highway"
def kIntersection : Arg := .lit "intersection"
def kMedian : Arg := .lit "median_or_divider"

/-- rel.occupies: the subject's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- st.on_way: region `r` lies on highway `h`. -/
def onWay (r h : String) : Formula := .atom "st_on_way" [.var r, .var h] []

/-- st.lane_enters: carrier `c` is an approach to intersection `i`. -/
def enters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []

/-- st.lane_direction components of carrier `r`. -/
def dirX (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "x"]
def dirY (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "y"]

/-- The designated directions of `a` and `b` are opposed: cosine at or below −p. -/
def opposed (a b : String) : Formula :=
  .cmp (.add (.mul (dirX a) (dirX b)) (.mul (dirY a) (dirY b))) .le (.neg pLaneOpposedDirectionCos)

/-- X at the observation before the subject's entry into `i` (read where occupancy of `i` rose). -/
def atApproachEnd (i : String) (x : Formula) : Formula :=
  .since (occ i) (.and (.not (occ i)) x)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4: highway `h` is two-directional: undivided, and two carriers on it carry opposed directions. -/
def twoDirectional (h : String) : Formula :=
  .and (.not (.existsRegion kMedian "m" (onWay "m" h)))
    (.or (.existsRegion kLane "a" (.and (onWay "a" h)
            (.existsRegion kLane "b" (.and (onWay "b" h) (opposed "a" "b")))))
      (.or (.existsRegion kLane "a" (.and (onWay "a" h)
              (.existsRegion kRoadway "b" (.and (onWay "b" h) (opposed "a" "b")))))
        (.existsRegion kRoadway "a" (.and (onWay "a" h)
            (.existsRegion kRoadway "b" (.and (onWay "b" h) (opposed "a" "b")))))))

/-- s2, s3, s4: the subject enters `i` here, with int.left_turn declared at `i` at the observation
    before, and every highway `i` lies on is two-directional. -/
def selected (i : String) : Formula :=
  .and (.rises (occ i))
    (.and (atApproachEnd i (.intent "int.left_turn" vSubject (.var i)))
      (.forallRegion kHighway "h" (.implies (onWay i "h") (twoDirectional "h"))))

/-- s5: the subject occupies no lane or roadway segment on a highway carrier `c` lies on whose
    direction is opposed to `c`'s. -/
def noOpposing (c : String) : Formula :=
  .not (.existsRegion kHighway "hc" (.and (onWay c "hc")
    (.or (.existsRegion kLane "d" (.and (occ "d") (.and (onWay "d" "hc") (opposed c "d"))))
         (.existsRegion kRoadway "d" (.and (occ "d") (.and (onWay "d" "hc") (opposed c "d")))))))

/-- s5: the approach into `i` is in the portion of the right half nearest the centerline. -/
def approachNearCentre (i : String) : Formula :=
  .or
    (.existsRegion kLane "c" (.and (occ "c") (.and (enters "c" i)
      (.and (.not (.existsRegion kLane "cl" (.atom "st_lane_adjacency" [.var "c", .lit "left", .var "cl"] [])))
        (noOpposing "c")))))
    (.and (.not (.existsRegion kLane "cn" (.and (occ "cn") (enters "cn" i))))
      (.existsRegion kRoadway "c" (.and (occ "c") (.and (enters "c" i) (noOpposing "c")))))

/-- Applicability: s2 (trigger): intends to turn; s3 (trigger): at an intersection and:; s4 (condition): Both intersecting highways are two-directional: -/
def applicability : Formula := .existsRegion kIntersection "i" (selected "i")

/-- Obligation: s5 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof. -/
def obligation : Formula :=
  .forallRegion kIntersection "i" (.implies (selected "i") (atApproachEnd "i" (approachNearCentre "i")))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2a
