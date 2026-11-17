/-
  NRS_484B_627_1a — NRS-484B-627-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (subject): If any driver or operator of a motor vehicle
    u2 (trigger): drives or operates a motor vehicle
    u3 (standard): at a speed so slow as to impede the forward movement of
    u4 (trigger): traffic proceeding immediately behind the driver or operator,
    u5 (subject): the driver or operator shall:
    u6 (condition): If the highway has one lane for traveling in each direction
    u7 (standard): and the width of the paved portion permits,
    u8 (obligation): drive to the extreme right side of the highway
    u9 (reference): and, if applicable, comply with the provisions of NRS 484B.630.

  Elements (span → atoms, derived):
    u1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    u2: atoms ['kin.speed', 'ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    u4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.ahead_behind_in_lane', 'rel.surface_gap'], derived []
    u5: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    u6: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.lane', 'st.lane_adjacency', 'st.lane_direction'], derived []
    u8: atoms ['prim.region_lateral_offset', 'st.road_edge', 'st.region_geometry', 'kin.extent', 'rel.occupies', 'st.highway', 'st.on_way'], derived []

  Literals the text states (each written through its Units constructor):
    u6: 1 count — one

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    u1/u5: the subject's class is ru_aggregate with DEF-NRS-484A-130::motor_vehicle.
    u2: kin_speed of the subject above p.halt_speed_tolerance.
    u3: inside a holdsFor .time window of p.left_lane_move_over_time on the subject, at every
        observation: moving (u2); some device of kind speed_limit_sign of kind maximum governing a
        travel_region the subject occupies has a value above speed + p.impeding_speed_margin; a
        traffic road user behind (u4); and for every road user o, not (o ahead of the subject in
        the same lane and surface gap ≤ p.rear_signal_reach).
    u4: some road user t with ru_aggregate DEF-NRS-484A-285::traffic, rel_ahead_behind_in_lane
        (subject, t) — the subject ahead of t — and rel_surface_gap(subject, t) ≤ p.rear_signal_reach.
    u6: a lane l the subject occupies, on a highway w (st_on_way) with st_lane_adjacency count of l
        equal to the text's one; some lane on w whose st_lane_direction dot l's is below
        −p.lane_opposed_direction_cos; every such opposed lane on w has count one.
    u7: on a highway w the subject occupies, a centre line on w and a right road edge on w (a road
        edge on w whose lateral offset from the subject is negative, i.e. to its right): the sum of
        the magnitudes of the two offsets ≥ the subject's width (kin_extent "width") +
        p.free_passage_width. The centre line is the one lying on the occupied highway (st_on_way):
        "the paved portion" is that highway's.
    u8 (obligation): on a highway w the subject occupies, some right road edge of w (the same
        selection as in u7) has |offset| − width/2 ≤ p.pullover_edge_gap; written as
        |offset| + |offset| ≤ width + gap + gap so that no halving literal enters.
    u9: residue (the node's).
  Choices the record left open: the right road edge is selected by the sign of its lateral offset
  (negative = right of the subject's heading), the record's "negative to the right"; the right
  edge is quantified existentially in both formulas (the right-hand edge of the occupied highway).
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_627_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFreePassageWidth : Term := .param "p.free_passage_width"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pImpedingSpeedMargin : Term := .param "p.impeding_speed_margin"
def pLaneOpposedDirectionCos : Term := .param "p.lane_opposed_direction_cos"
def pLeftLaneMoveOverTime : Term := .param "p.left_lane_move_over_time"
def pPulloverEdgeGap : Term := .param "p.pullover_edge_gap"
def pRearSignalReach : Term := .param "p.rear_signal_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's literal "one" (u6): one lane in each direction. -/
def oneLane : Term := .lit (Units.ratio 1 1) .count

def vX : Arg := .lit "x"
def vY : Arg := .lit "y"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- The subject's speed (kin.speed). -/
def speedOf : Term := .measure "kin_speed" [vSubject]

/-- The subject's full width (kin.extent). -/
def widthOf : Term := .measure "kin_extent" [vSubject, .lit "width"]

/-- The surface gap between the subject and road user `v` (rel.surface_gap). -/
def gapTo (v : String) : Term := .measure "rel_surface_gap" [vSubject, .var v]

/-- Signed lateral offset of region `r` from the subject (prim.region_lateral_offset, left positive). -/
def offsetOf (r : String) : Term := .quantity "prim_region_lateral_offset" [vSubject, .var r] []

/-- u2: the motor vehicle moves (speed above the halt tolerance). -/
def moving : Formula := .cmp speedOf .gt pHaltSpeedTolerance

/-- u3: its speed plus the impeding margin is below the value of a maximum speed limit sign
    governing a travel region it occupies. -/
def belowPosted : Formula :=
  .existsDevice (.lit "speed_limit_sign") "d"
    (.and (.atom "dev_speed_limit_sign_kind" [.var "d", .lit "maximum"] [])
      (.and (.existsRegion (.lit "travel_region") "tr"
               (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
                     (.atom "dev_governs" [.var "d", .var "tr"] [])))
            (.cmp (.add speedOf pImpedingSpeedMargin) .lt
                  (.measure "dev_speed_limit_sign_value" [.var "d"]))))

/-- u4: a traffic road user behind the subject in the same lane, the surface gap within reach. -/
def trafficBehind : Formula :=
  .existsUser "t"
    (.and (.atom "ru_aggregate" [.var "t", .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.atom "rel_ahead_behind_in_lane" [vSubject, .var "t"] [])
            (.cmp (gapTo "t") .le pRearSignalReach)))

/-- u3: no road user ahead of the subject in the same lane within reach (it is not held back). -/
def noneAhead : Formula :=
  .forallUser "o"
    (.not (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
                (.cmp (gapTo "o") .le pRearSignalReach)))

/-- u3 with u2 and u4, sustained over the move-over window behind. -/
def impeding : Formula :=
  .holdsFor .time pLeftLaneMoveOverTime "subject"
    (.and moving (.and belowPosted (.and trafficBehind noneAhead)))

/-- The dot product of the designated directions of lanes `a` and `b` (st.lane_direction). -/
def dirDot (a b : String) : Term :=
  .add (.mul (.measure "st_lane_direction" [.var a, vX]) (.measure "st_lane_direction" [.var b, vX]))
       (.mul (.measure "st_lane_direction" [.var a, vY]) (.measure "st_lane_direction" [.var b, vY]))

/-- Lane `o` lies on way `w` and its designated direction is opposed to lane `l`'s. -/
def opposedOn (l o w : String) : Formula :=
  .and (.atom "st_on_way" [.var o, .var w] [])
       (.cmp (dirDot l o) .lt (.neg pLaneOpposedDirectionCos))

def countOf (r : String) : Term := .measure "st_lane_adjacency_count" [.var r]

/-- u6: the subject occupies a lane lying on a highway whose count in its direction is one; some
    lane of that highway is opposed in direction, and every opposed lane's count is one. -/
def oneLaneEachWay : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (.atom "rel_occupies" [vSubject, .var "l"] [])
      (.existsRegion (.lit "highway") "w"
        (.and (.atom "st_on_way" [.var "l", .var "w"] [])
          (.and (.cmp (countOf "l") .eq oneLane)
            (.and (.existsRegion (.lit "lane") "ol" (opposedOn "l" "ol" "w"))
                  (.forallRegion (.lit "lane") "ol2"
                    (.implies (opposedOn "l" "ol2" "w") (.cmp (countOf "ol2") .eq oneLane))))))))

/-- The right-hand road edge `e` of the highway `w`: a road edge lying on it, to the subject's right. -/
def rightEdgeOf (e w : String) : Formula :=
  .and (.atom "st_on_way" [.var e, .var w] [])
       (.cmp (offsetOf e) .lt zeroMetres)

/-- u7: on the highway the subject occupies, the centre line's and the right road edge's lateral
    offsets, in magnitude, sum to at least the subject's width plus the free passage width. -/
def widthPermits : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "rel_occupies" [vSubject, .var "w"] [])
      (.existsRegion (.lit "centre_line") "c"
        (.and (.atom "st_on_way" [.var "c", .var "w"] [])
          (.existsRegion (.lit "road_edge") "e"
            (.and (rightEdgeOf "e" "w")
                  (.cmp (.add (.abs (offsetOf "c")) (.abs (offsetOf "e"))) .ge
                        (.add widthOf pFreePassageWidth)))))))

/-- Applicability: u1/u2 (moving motor vehicle), u3 (so slow as to impede, over the move-over
    window), u4 (traffic immediately behind), u6 (one lane each direction), u7 (width permits). -/
def applicability : Formula :=
  .and impeding (.and oneLaneEachWay widthPermits)

/-- Obligation (u8): the right side of the subject is within the pull-over gap of the right road
    edge of the highway it occupies: |offset| − width/2 ≤ gap, written without a halving literal as
    |offset| + |offset| ≤ width + gap + gap. -/
def obligation : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "rel_occupies" [vSubject, .var "w"] [])
      (.existsRegion (.lit "road_edge") "e"
        (.and (rightEdgeOf "e" "w")
              (.cmp (.add (.abs (offsetOf "e")) (.abs (offsetOf "e"))) .le
                    (.add widthOf (.add pPulloverEdgeGap pPulloverEdgeGap))))))

def rule : Rule :=
  { id := "NRS_484B_627_1a"
    laws := ["NRS-484B-627-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "so slow as to impede the forward movement of traffic"
          concepts := ["dev.governs", "dev.speed_limit_sign", "kin.speed", "rel.ahead_behind_in_lane", "rel.occupies", "rel.surface_gap", "st.travel_region"]
          params := ["p.impeding_speed_margin", "p.rear_signal_reach", "p.left_lane_move_over_time", "p.halt_speed_tolerance"]
          convention := "Slow-moving-vehicle practice: the subject impedes the traffic behind it where, at every observation of the window of p.left_lane_move_over_time behind (the time a driver needs to check, signal and move over once a faster vehicle closes), it moves (speed above p.halt_speed_tolerance) at a speed more than p.impeding_speed_margin below the value of a maximum speed limit sign governing a travel region it occupies, a traffic road user is behind it in the same lane within p.rear_signal_reach, and no road user is ahead of it in the same lane within p.rear_signal_reach, so the subject is not itself held back."
          surrogate := false }
      , { standard := "the width of the paved portion permits"
          concepts := ["kin.extent", "prim.region_lateral_offset", "st.centre_line", "st.road_edge"]
          params := ["p.free_passage_width"]
          convention := "Lateral clearance of a passing vehicle: the paved half of the roadway, from the centre line to the right road edge (the sum of the magnitudes of their lateral offsets from the subject), is at least the subject's width plus p.free_passage_width, so that with the subject at the right edge a following vehicle has room to pass beside it."
          surrogate := false } ]
    residues := ["NRS 484B.630 has no node in the library, so its turnout duty cannot be composed; the rule does not judge compliance with it."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_627_1a
