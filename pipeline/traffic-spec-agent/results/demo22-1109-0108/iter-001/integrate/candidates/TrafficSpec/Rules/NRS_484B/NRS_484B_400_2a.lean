/-
  NRS_484B_400_2a — NRS-484B-400-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    i1 (condition): intends to turn
    c1 (condition): at an intersection and:
    c2 (condition): Both intersecting highways are two-directional:
    ob1 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c1: atoms ['rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    c2: atoms ['st.highway', 'st.on_way', 'st.roadway', 'st.lane_direction', 'st.median_or_divider', 'st.intersection', 'rel.occupies', 'st.travel_region', 'st.lane_enters'], derived []
    ob1: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.roadway', 'st.centre_line', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.travel_region', 'st.lane_enters', 'st.intersection', 'prim.region_lateral_offset'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written
  ------------------------
  s1 — the duty binds the vehicle whose controlled motion the ontology reads 'the driver' through:
    `clsV` is the one aggregate atom `ru_aggregate v DEF-NRS-484A-320::vehicle`, never expanded into
    classes.

  i1, c1 — the junction and the declaration: `applicability` binds an intersection `i`
    (`st_intersection`) at which the source's current plan for `v` is a left turn
    (`intent int.left_turn v i`, read at the judged observation, never ahead of it), and the approach
    `a` the subject itself runs to it: a travel region (`st_travel_region`) the subject occupies
    (`rel_occupies`) whose entrance end is that junction (`st_lane_enters a i`). The declaration is
    read at the junction the approach enters, which is the region the obligation speaks of again.

  c2 — 'two-directional' as DEF-NRS-484B-073 defines it, of the way carrying the approach (`w`, bound
    by `st_highway` and `st_on_way a w`) and of the other way meeting at the junction (`w2`, bound by
    `st_on_way i w2`, distinct from `w`): `twoDirectional` states 'undivided' as the absence of any
    `st_median_or_divider` lying on the way (`st_on_way`), and 'vehicles are allowed to proceed in
    opposite directions' as two of the carriers the way carries (`st_on_way`) having opposed
    designated directions (`st_lane_direction`), their normalised dot product at or below the
    negative of `p.same_direction_cosine_tolerance`.

  ob1 — the lateral place, read at every carrier the subject occupies whose entrance end is that
    junction, with the whole selection of that carrier and of its way written again (occupancy, the
    kind, the entrance relation, the junction and the declared intention; the two-directionality of
    the ways is the applicability's and is not restated, which leaves the duty broader there, never
    narrower). For such a carrier `a` on way `w` (`st_highway`, `st_on_way`) the subject must lie in
    the portion of the right half nearest the centre line, read in the ontology's two ways:
      • where the carrier is a recorded lane (`st_lane`), it is the lane with no neighbouring lane of
        its own direction on its left (`st_lane_adjacency`), the leftmost lane looking along the
        lane's designated direction;
      • where it is not, the centre line of the roadway the subject occupies (`st_roadway`,
        `rel_occupies`, `st_centre_line`, `st_on_way`) lies to its left with a signed lateral offset
        (`prim.region_lateral_offset`) of at least `p.lateral_offset_resolution` and at most
        `p.centerline_adjacent_distance`.

  Narrowings declared below (each a choice ob1's words leave open; the record's own narrowings are
  the plan's and are not restated here):
    1. 'ordinal 1 for that direction' is written as 'no neighbouring lane of the same direction on
       the left', the same reading of `st.lane_adjacency` without a magnitude of this file's own.
    2. 'where the carriageway carries no recorded lane' is written as the carrier the subject
       occupies not being a recorded lane, since the duty is read carrier by carrier.
    3. 'The approach ... must be made in' is read at every such carrier, so no carrier that favours
       the subject is picked where it occupies several.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2a

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCenterlineAdjacentDistance : Term := .param "p.centerline_adjacent_distance"
def pLateralOffsetResolution : Term := .param "p.lateral_offset_resolution"
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

-- ---------------------------------------------------------------------------------------------
-- c2: a way is two-directional (undivided, carrying opposite directions)
-- ---------------------------------------------------------------------------------------------

/-- The components of a carrier's designated direction, read normalised. -/
def dirX (c : String) : Term := .measure "st_lane_direction" [.var c, .lit "x"]
def dirY (c : String) : Term := .measure "st_lane_direction" [.var c, .lit "y"]

/-- Two carriers' designated directions are opposed. -/
def opposedDirections (c d : String) : Formula :=
  .cmp (.add (.mul (dirX c) (dirX d)) (.mul (dirY c) (dirY d)))
       .le (.neg pSameDirectionCosineTolerance)

/-- `w` is two-directional: no physical barrier or dividing section lies on it, and two of the
    carriers it carries have opposed designated directions. `sfx` keeps the quantifier variables of
    the two ways apart. -/
def twoDirectional (w sfx : String) : Formula :=
  let md := "md" ++ sfx
  let ca := "ca" ++ sfx
  let cb := "cb" ++ sfx
  .and
    (.not (.existsRegion (.lit "median_or_divider") md
      (.and (.atom "st_median_or_divider" [.var md] [])
            (.atom "st_on_way" [.var md, .var w] []))))
    (.existsRegion (.lit "travel_region") ca
      (.and (.atom "st_on_way" [.var ca, .var w] [])
        (.existsRegion (.lit "travel_region") cb
          (.and (.atom "st_on_way" [.var cb, .var w] [])
            (.and (.not (.same (.var ca) (.var cb)))
                  (opposedDirections ca cb))))))

-- ---------------------------------------------------------------------------------------------
-- Applicability: i1, c1, c2
-- ---------------------------------------------------------------------------------------------

/-- Applicability: i1 (condition): intends to turn; c1 (condition): at an intersection and:; c2 (condition): Both intersecting highways are two-directional: -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_intersection" [.var "i"] [])
     (.and (.intent "int.left_turn" vV (.var "i"))
      (.existsRegion (.lit "travel_region") "a"
        (.and (.atom "rel_occupies" [vV, .var "a"] [])
         (.and (.atom "st_travel_region" [.var "a"] [])
          (.and (.atom "st_lane_enters" [.var "a", .var "i"] [])
           (.existsRegion (.lit "highway") "w"
             (.and (.atom "st_highway" [.var "w"] [])
              (.and (.atom "st_on_way" [.var "a", .var "w"] [])
               (.and (twoDirectional "w" "1")
                (.existsRegion (.lit "highway") "w2"
                  (.and (.atom "st_highway" [.var "w2"] [])
                   (.and (.atom "st_on_way" [.var "i", .var "w2"] [])
                    (.and (.not (.same (.var "w") (.var "w2")))
                          (twoDirectional "w2" "2")))))))))))))))

-- ---------------------------------------------------------------------------------------------
-- Obligation: ob1
-- ---------------------------------------------------------------------------------------------

/-- The lane `a` is the leftmost of its own direction: it is a recorded lane with no neighbouring
    lane of that direction on its left (`st.lane_adjacency`, whose ordinals are counted from the
    left looking along the lane's designated direction). -/
def leftmostLaneOfItsDirection (a : String) : Formula :=
  .and (.atom "st_lane" [.var a] [])
       (.not (.existsRegion (.lit "lane") "ln"
          (.atom "st_lane_adjacency_left" [.var a, .var "ln"] [])))

/-- The centre line of the roadway the subject occupies on way `w` lies to its left, at a signed
    lateral offset the reading's two bounds keep inside the portion nearest that line. -/
def offsetToCentreLine : Term := .quantity "prim_region_lateral_offset" [vV, .var "cl"] []

def besideTheCentreLine (w : String) : Formula :=
  .existsRegion (.lit "roadway") "rw"
    (.and (.atom "st_roadway" [.var "rw"] [])
     (.and (.atom "rel_occupies" [vV, .var "rw"] [])
      (.and (.atom "st_on_way" [.var "rw", .var w] [])
       (.existsRegion (.lit "centre_line") "cl"
         (.and (.atom "st_centre_line" [.var "cl"] [])
          (.and (.atom "st_on_way" [.var "cl", .var w] [])
           (.and (.cmp offsetToCentreLine .ge pLateralOffsetResolution)
                 (.cmp offsetToCentreLine .le pCenterlineAdjacentDistance))))))))

/-- The portion of the right half of way `w` nearest the centre line, at carrier `a`: the leftmost
    lane of the subject's direction where the carrier is a recorded lane, and the place beside the
    centre line where it is not. -/
def portionNearestCentreLine (a w : String) : Formula :=
  .or (leftmostLaneOfItsDirection a)
      (.and (.not (.atom "st_lane" [.var a] [])) (besideTheCentreLine w))

/-- Obligation: ob1 (obligation): The approach for a left turn must be made in that portion of the right half of the highway nearest the centerline thereof. -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "a"
    (.forallRegion (.lit "highway") "w"
      (.implies
        (.and (.atom "rel_occupies" [vV, .var "a"] [])
         (.and (.atom "st_travel_region" [.var "a"] [])
          (.and (.atom "st_highway" [.var "w"] [])
           (.and (.atom "st_on_way" [.var "a", .var "w"] [])
            (.existsRegion (.lit "intersection") "i"
              (.and (.atom "st_intersection" [.var "i"] [])
               (.and (.atom "st_lane_enters" [.var "a", .var "i"] [])
                     (.intent "int.left_turn" vV (.var "i")))))))))
        (portionNearestCentreLine "a" "w")))

def rule : Rule :=
  { id := "NRS_484B_400_2a"
    laws := ["NRS-484B-400-2a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "'that portion of the right half of the highway nearest the centerline thereof' is written, where the carrier is a recorded lane, as the lane with no neighbouring lane of its own direction on its left: st.lane_adjacency counts ordinals from the left looking along the lane's designated direction, so the leftmost lane of that direction is the record's ordinal 1, and the relation states it without a magnitude of this file's own."
          kind := "reading" }
      , { span := "ob1"
          why := "'where the carriageway carries no recorded lane' is written as the approach carrier the subject occupies not being a recorded lane (st.lane): the duty is read carrier by carrier, so the centre-line reading applies exactly at a carrier whose lanes the source does not record."
          kind := "reading" }
      , { span := "ob1"
          why := "'The approach for a left turn must be made in' is read at every carrier the subject occupies whose entrance end is that junction, not at one of them: where it occupies several, no carrier that favours the subject is picked."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2a
