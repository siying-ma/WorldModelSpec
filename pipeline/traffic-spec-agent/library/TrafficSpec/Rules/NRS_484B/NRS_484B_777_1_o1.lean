/-
  NRS_484B_777_1_o1 — NRS-484B-777-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every person operating a bicycle, an electric bicycle or an electric scooter
    s2 (condition): upon a roadway shall, except:
    s3 (exception): (a) When traveling at a lawful rate of speed
    s4 (standard): commensurate with the speed of
    s4b (exception): any nearby traffic;
    s5 (exception): (b) When preparing to turn left;
    s6 (boilerplate): or
    s7 (standard): (c) When doing so would not be safe,
    s8 (obligation): ride as near to the right side of the roadway
    s9 (standard): as practicable,
    s10 (sibling): exercising due care
    s11 (sibling): when passing a standing vehicle or one proceeding in the same direction.
    s12 (standard): For purposes of paragraph (c) of subsection 1, the conditions under which it is not safe to operate a bicycle, an electric bicycle or an electric scooter as near to the right side of the roadway as practicable include, without limitation:
    s13 (condition): (a) When fixed or moving objects, parked or moving vehicles, bicycles, pedestrians, animals or surface hazards impede access to the right side of the roadway.
    s14 (standard): (b) When a lane is too narrow for a bicycle and a vehicle to travel safely side by side within the lane.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s2: atoms ['rel.occupies', 'st.roadway', 'st.on_way', 'st.highway', 'st.intersection', 'st.driveway_or_alley_entrance'], derived []
    s4b: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.surface_gap'], derived []
    s8: atoms ['prim.region_lateral_offset', 'kin.extent', 'st.road_edge', 'st.on_way', 'st.highway', 'st.region_geometry', 'rel.occupies', 'st.roadway'], derived []
    s13: atoms ['st.obstruction', 'st.region_geometry', 'prim.region_lateral_offset', 'prim.region_offset_along', 'st.lane_direction', 'rel.bearing', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  Compositions (span → node, as, map):
    s3: NRS_484B_785_1a as compliance map {'subject': 'subject'}

  How each is written:
    s1: the binder class, the three ru_aggregate atoms joined by `or`.
    s2: `existsRegion roadway r (rel_occupies subject r)`.
    s3/s4/s4b (exception (a)): kin_speed of the subject above p.halt_speed_tolerance, `.rule
      NRS_484B_785_1a` (compliance), and for every road user o other than the subject of the traffic
      aggregate with rel_surface_gap (distance) to the subject ≤ p.nearby_traffic_reach, o's speed ≤
      the subject's speed + p.commensurate_speed_margin (vacuous where none is nearby).
    s5 (exception (b)): a roadway r the subject occupies, a highway h with st_on_way r h, and an
      intersection or driveway/alley entrance t with st_on_way t h at which the declaration current
      at the judged observation states int.left_turn for the subject.
    s7/s12/s13/s14 (exception (c)): an obstruction o with prim_region_offset_along (subject, o, r)
      in [0, p.right_side_impede_reach] for a roadway r the subject occupies (r the carrier whose
      st.lane_direction is read) and prim_region_lateral_offset ≤ 0; or a road user u ≠ subject of
      the vehicle, bicycle or pedestrian aggregate with rel_surface_gap ≤ the reach, rel_bearing
      longitudinal ("x") > 0 and lateral ("y") ≤ 0; or a lane the subject occupies with st_lane_width
      < p.shared_lane_min_width.
    s8/s9 (obligation): for a roadway r the subject occupies, a highway h it lies on and a road edge
      e lying on h with prim_region_lateral_offset < 0, 2·|offset| − width (kin_extent "width")
      ≤ 2·p.bicycle_keep_right_gap (the body gap ≤ the gap, written doubled so that no literal 2
      enters); `definedWhen` such a right-hand edge exists, so the verdict is unknown, never
      violated, where none does or its offset is unobserved. st.region_geometry is the outline
      both primitives read.
  No choice beyond the record's own readings was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_777_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBicycleKeepRightGap : Term := .param "p.bicycle_keep_right_gap"
def pCommensurateSpeedMargin : Term := .param "p.commensurate_speed_margin"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pNearbyTrafficReach : Term := .param "p.nearby_traffic_reach"
def pRightSideImpedeReach : Term := .param "p.right_side_impede_reach"
def pSharedLaneMinWidth : Term := .param "p.shared_lane_min_width"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of road user `x` in an admitted aggregate (the claim's id). -/
def agg (x : String) (id : String) : Formula := .atom "ru_aggregate" [.var x, .lit id] []

/-- s1: the class of `subject`, the three admitted aggregates. -/
def clsSubject : Formula :=
  .or (agg "subject" "DEF-NRS-484A-025::bicycle")
    (.or (agg "subject" "DEF-NRS-484B-017::electric_bicycle")
         (agg "subject" "DEF-NRS-484B-018::electric_scooter"))

/-- s2: the subject's footprint overlaps a roadway. -/
def upon (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

def onRoadway : Formula := .existsRegion (.lit "roadway") "r" (upon "r")

/-- s4b: `o` is nearby traffic of the subject: of the traffic aggregate, not the subject, its body
    gap to the subject within the nearby reach. -/
def nearbyTraffic (o : String) : Formula :=
  .and (.not (.same (.var o) vSubject))
    (.and (agg o "DEF-NRS-484A-285::traffic")
      (.cmp (.measure "rel_surface_gap" [vSubject, .var o]) .le pNearbyTrafficReach))

/-- s3/s4/s4b, exception (a): traveling, at a lawful speed (NRS_484B_785_1a complied with),
    commensurate with every nearby traffic road user's speed. -/
def excTravelingWithTraffic : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.rule "NRS_484B_785_1a" [("subject", "subject")])
      (.forallUser "o"
        (.implies (nearbyTraffic "o")
          (.cmp (.measure "kin_speed" [.var "o"]) .le
            (.add (.measure "kin_speed" [vSubject]) pCommensurateSpeedMargin)))))

/-- s5 at a place `t` of a kind: `t` lies on the highway `h`, and the source declares the subject's
    left turn at it. -/
def leftTurnAt (kind : String) (h : String) : Formula :=
  .existsRegion (.lit kind) "t"
    (.and (.atom "st_on_way" [.var "t", .var h] [])
      (.intent "int.left_turn" vSubject (.var "t")))

/-- s5, exception (b): preparing to turn left at an intersection or a driveway/alley entrance lying
    on a highway on which a roadway the subject occupies lies. -/
def excPreparingLeftTurn : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (upon "r")
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [.var "r", .var "h"] [])
          (.or (leftTurnAt "intersection" "h") (leftTurnAt "driveway_or_alley_entrance" "h")))))

/-- s13, an object: an obstruction ahead of the subject within the impede reach along the designated
    direction of a roadway it occupies, at or to the right of its line. -/
def obstructionOnRight : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (upon "r")
      (.existsRegion (.lit "obstruction") "o"
        (.and (.cmp (.quantity "prim_region_offset_along" [vSubject, .var "o", .var "r"] []) .ge zeroMetres)
          (.and (.cmp (.quantity "prim_region_offset_along" [vSubject, .var "o", .var "r"] []) .le pRightSideImpedeReach)
            (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "o"] []) .le zeroMetres)))))

/-- s13, a road user: of the vehicle, bicycle or pedestrian aggregate, not the subject, its body gap
    within the impede reach, ahead and at or to the right of the subject. -/
def userOnRight : Formula :=
  .existsUser "u"
    (.and (.not (.same (.var "u") vSubject))
      (.and (.or (agg "u" "DEF-NRS-484A-320::vehicle")
              (.or (agg "u" "DEF-NRS-484A-025::bicycle") (agg "u" "DEF-NRS-484A-165::pedestrian")))
        (.and (.cmp (.measure "rel_surface_gap" [vSubject, .var "u"]) .le pRightSideImpedeReach)
          (.and (.cmp (.measure "rel_bearing" [vSubject, .var "u", .lit "x"]) .gt zeroMetres)
            (.cmp (.measure "rel_bearing" [vSubject, .var "u", .lit "y"]) .le zeroMetres)))))

/-- s14: the subject occupies a lane narrower than the shared-lane width. -/
def narrowLane : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (upon "l") (.cmp (.measure "st_lane_width" [.var "l"]) .lt pSharedLaneMinWidth))

/-- s7/s12, exception (c): not safe, through s13 and s14. -/
def excNotSafe : Formula := .or obstructionOnRight (.or userOnRight narrowLane)

/-- Applicability: upon a roadway (s2), and none of exceptions (a), (b), (c) holds. -/
def applicability : Formula :=
  .and onRoadway
    (.and (.not excTravelingWithTraffic)
      (.and (.not excPreparingLeftTurn) (.not excNotSafe)))

/-- s8: the lateral offset of the road edge `e` from the subject. -/
def edgeOffset (e : String) : Term := .quantity "prim_region_lateral_offset" [vSubject, .var e] []

/-- s8/s9 at a selection of road edges: for a roadway the subject occupies and a highway it lies
    on, some road edge lying on that highway, on the subject's right, satisfying `φ`. -/
def rightEdge (φ : String → Formula) : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (upon "r")
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [.var "r", .var "h"] [])
          (.existsRegion (.lit "road_edge") "e"
            (.and (.atom "st_on_way" [.var "e", .var "h"] []) (φ "e"))))))

/-- s8: the edge `e` lies on the subject's right. -/
def onRight (e : String) : Formula := .cmp (edgeOffset e) .lt zeroMetres

/-- s9: the body gap to the edge (offset magnitude less half the width) at most the keep-right gap,
    stated doubled: 2·|offset| − width ≤ 2·gap. -/
def nearEnough (e : String) : Formula :=
  .cmp (.sub (.add (.neg (edgeOffset e)) (.neg (edgeOffset e))) (.measure "kin_extent" [vSubject, .lit "width"]))
    .le (.add pBicycleKeepRightGap pBicycleKeepRightGap)

/-- Obligation: ride as near the right side of the roadway as practicable; unknown where no edge
    of the roadway's highway lies on the subject's right. -/
def obligation : Formula :=
  .definedWhen (rightEdge onRight) (rightEdge fun e => .and (onRight e) (nearEnough e))

def rule : Rule :=
  { id := "NRS_484B_777_1_o1"
    laws := ["NRS-484B-777-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "a rate of speed commensurate with the speed of nearby traffic"
          concepts := ["kin.speed"]
          params := ["p.commensurate_speed_margin", "p.halt_speed_tolerance", "p.nearby_traffic_reach"]
          convention := "Traveling is the subject's speed (kin.speed) above the source's speed resolution (p.halt_speed_tolerance). The subject's speed is commensurate with the nearby traffic (s4b: traffic road users within p.nearby_traffic_reach, two seconds of headway at urban speed) where each such road user's speed exceeds the subject's by no more than p.commensurate_speed_margin, a speed differential within one traffic stream; the bound moves with both measured speeds."
          surrogate := false }
      , { standard := "when doing so would not be safe"
          concepts := ["prim.region_lateral_offset", "rel.bearing", "rel.surface_gap", "st.lane_width", "st.obstruction"]
          params := ["p.right_side_impede_reach", "p.shared_lane_min_width"]
          convention := "Not safe is read through the two conditions subsection 2 names: (a) an object, vehicle, bicycle or pedestrian on the subject's right within p.right_side_impede_reach (s13), the distance within which a rider must steer around it; (b) the lane the subject occupies narrower than p.shared_lane_min_width (s14), the wide-outside-lane width of bicycle facility guidance below which a bicycle and a motor vehicle cannot share a lane side by side."
          surrogate := false }
      , { standard := "as near to the right side of the roadway as practicable"
          concepts := ["kin.extent", "prim.region_lateral_offset", "st.road_edge"]
          params := ["p.bicycle_keep_right_gap"]
          convention := "As near as practicable is a gap between the subject's body and the roadway's right edge of at most p.bicycle_keep_right_gap: a bicyclist's shy distance from a curb or edge plus the sway of its operating space and the source's position error (AASHTO bicycle operating space)."
          surrogate := false }
      , { standard := "the conditions under which it is not safe ... include, without limitation"
          concepts := ["rel.bearing", "rel.surface_gap", "st.lane_width", "st.obstruction"]
          params := ["p.right_side_impede_reach", "p.shared_lane_min_width"]
          convention := "The catch-all 'include, without limitation' is read only through the contracts s13 and s14 read: obstructions and road users of the named aggregates on the subject's right within p.right_side_impede_reach, and a lane narrower than p.shared_lane_min_width."
          surrogate := false }
      , { standard := "a lane too narrow for a bicycle and a vehicle to travel safely side by side within the lane"
          concepts := ["rel.occupies", "st.lane", "st.lane_width"]
          params := ["p.shared_lane_min_width"]
          convention := "The lane the subject occupies (rel.occupies, st.lane) has a width (st.lane_width, 'width of a lane at a point') below p.shared_lane_min_width: 14 ft, the lane width below which bicycle facility guidance (AASHTO, MUTCD shared-lane guidance) holds that a bicycle and a motor vehicle cannot travel safely side by side within one lane; the bicycle and the vehicle are the design road users the width stands for, not road users present in the scene."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_777_1_o1
