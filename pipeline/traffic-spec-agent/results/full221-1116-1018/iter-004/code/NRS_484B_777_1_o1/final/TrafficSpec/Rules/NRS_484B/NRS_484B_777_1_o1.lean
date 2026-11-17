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
    s2: atoms ['rel.occupies', 'st.roadway', 'st.intersection', 'st.driveway_or_alley_entrance'], derived []
    s4b: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.surface_gap'], derived []
    s8: atoms ['prim.region_lateral_offset', 'kin.extent', 'st.road_edge', 'st.on_way', 'st.highway', 'st.region_geometry', 'rel.occupies', 'st.roadway'], derived []
    s13: atoms ['st.obstruction', 'st.region_geometry', 'prim.region_lateral_offset', 'prim.region_offset_along', 'st.lane_direction', 'rel.bearing', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  Compositions (span → node, as, map):
    s3: NRS_484B_785_1a as compliance map {'subject': 'subject'}

  How each is written:
    s1: the class is the disjunction of the three ru_aggregate atoms on the subject.
    s2: some roadway r the subject occupies (rel_occupies); applicability = on a roadway and none of
        exceptions (a), (b), (c) holds, as the record's applicability states.
    s3/s4/s4b: speed > p.halt_speed_tolerance, `.rule NRS_484B_785_1a` (compliance), and for every
        road user u of the traffic aggregate other than the subject with rel_surface_gap (distance)
        ≤ p.nearby_traffic_reach: speed(u) ≤ speed(subject) + p.commensurate_speed_margin.
    s5: some intersection or driveway/alley entrance at which the declaration current at the
        observation states int.left_turn for the subject.
    s7/s12/s13/s14: some obstruction o with 0 ≤ prim_region_offset_along(subject, o, r) ≤
        p.right_side_impede_reach for a roadway r the subject occupies and
        prim_region_lateral_offset(subject, o) ≤ 0; or some other road user of the vehicle, bicycle
        or pedestrian aggregate with surface gap ≤ p.right_side_impede_reach and bearing x > 0,
        y ≤ 0 (x longitudinal, y lateral in the subject's frame); or a lane the subject occupies
        with st_lane_width < p.shared_lane_min_width.
    s8/s9: for a roadway r the subject occupies, some road edge e on a highway h that r lies on
        (st_on_way both), with lateral offset < 0, and −offset − width/2 ≤ p.bicycle_keep_right_gap,
        written doubled (−2·offset − width ≤ 2·gap) since no literal two may enter; wrapped in
        definedWhen over the existence of such a right edge, so a scene without one, or without the
        offset, is unknown.
  No narrowing was chosen beyond the record's.

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

/-- Quantifier variables. -/
def vR : Arg := .var "r"          -- a roadway the subject occupies
def vU : Arg := .var "u"          -- a road user of the traffic aggregate (s4b)
def vV : Arg := .var "v"          -- a road user impeding access on the right (s13)
def vI : Arg := .var "i"          -- an intersection (s5)
def vD : Arg := .var "d"          -- a driveway or alley entrance (s5)
def vO : Arg := .var "o"          -- an obstruction (s13)
def vL : Arg := .var "l"          -- a lane the subject occupies (s14)
def vE : Arg := .var "e"          -- a road edge (s8)
def vH : Arg := .var "h"          -- a highway (s8)

/-- Membership of road user `x` in the admitted aggregate `id`. -/
def agg (x : Arg) (id : String) : Formula := .atom "ru_aggregate" [x, .lit id] []

def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula :=
  .or (agg vSubject "DEF-NRS-484A-025::bicycle")
    (.or (agg vSubject "DEF-NRS-484B-017::electric_bicycle")
      (agg vSubject "DEF-NRS-484B-018::electric_scooter"))

def subjectSpeed : Term := .measure "kin_speed" [vSubject]

/-- s2: the subject's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (occupies vSubject vR)

/-- s3, s4, s4b: exception (a). Traveling (speed above the source's resolution), lawful
    (NRS_484B_785_1a complied with), and commensurate: every other road user of the traffic
    aggregate whose body gap to the subject is within the nearby reach is no faster than the
    subject's speed plus the margin (vacuous where none is nearby). -/
def excLawfulCommensurate : Formula :=
  .and (.cmp subjectSpeed .gt pHaltSpeedTolerance)
    (.and (.rule "NRS_484B_785_1a" [("subject", "subject")])
      (.forallUser "u"
        (.implies
          (.and (agg vU "DEF-NRS-484A-285::traffic")
            (.and (.not (.same vU vSubject))
              (.cmp (.measure "rel_surface_gap" [vSubject, vU]) .le pNearbyTrafficReach)))
          (.cmp (.measure "kin_speed" [vU]) .le (.add subjectSpeed pCommensurateSpeedMargin)))))

/-- s5: exception (b), a declared left turn at an intersection or a driveway/alley entrance. -/
def excLeftTurn : Formula :=
  .or (.existsRegion (.lit "intersection") "i" (.intent "int.left_turn" vSubject vI))
    (.existsRegion (.lit "driveway_or_alley_entrance") "d" (.intent "int.left_turn" vSubject vD))

/-- s13 (objects): an obstruction ahead within the reach along the designated direction of a
    roadway the subject occupies, at or to the right of the subject. -/
def impedingObstruction : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (occupies vSubject vR)
      (.existsRegion (.lit "obstruction") "o"
        (.and (.cmp (.quantity "prim_region_offset_along" [vSubject, vO, vR] []) .ge zeroMetres)
          (.and (.cmp (.quantity "prim_region_offset_along" [vSubject, vO, vR] []) .le pRightSideImpedeReach)
            (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vO] []) .le zeroMetres)))))

/-- s13 (road users): a vehicle, bicycle or pedestrian other than the subject within the reach,
    ahead and at or to the right of the subject. -/
def impedingUser : Formula :=
  .existsUser "v"
    (.and (.not (.same vV vSubject))
      (.and (.or (agg vV "DEF-NRS-484A-320::vehicle")
              (.or (agg vV "DEF-NRS-484A-025::bicycle") (agg vV "DEF-NRS-484A-165::pedestrian")))
        (.and (.cmp (.measure "rel_surface_gap" [vSubject, vV]) .le pRightSideImpedeReach)
          (.and (.cmp (.measure "rel_bearing" [vSubject, vV, .lit "x"]) .gt zeroMetres)
            (.cmp (.measure "rel_bearing" [vSubject, vV, .lit "y"]) .le zeroMetres)))))

/-- s14: the subject occupies a lane narrower than the shared-lane width. -/
def narrowLane : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (occupies vSubject vL)
      (.cmp (.measure "st_lane_width" [vL]) .lt pSharedLaneMinWidth))

/-- s7, s12, s13, s14: exception (c), not safe. -/
def excNotSafe : Formula :=
  .or impedingObstruction (.or impedingUser narrowLane)

/-- Applicability: s2 (condition): upon a roadway shall, except:; s3 (exception): (a) When traveling at a lawful rate of speed; s4b (exception): any nearby traffic;; s5 (exception): (b) When preparing to turn left;; s13 (condition): (a) When fixed or moving objects, parked or moving vehicles, bicycles, pedestrians, animals or surface hazards impede access to the right side of the roadway. -/
def applicability : Formula :=
  .and onRoadway
    (.and (.not excLawfulCommensurate)
      (.and (.not excLeftTurn) (.not excNotSafe)))

/-- s8: the edge's signed lateral offset from the subject. -/
def edgeOffset : Term := .quantity "prim_region_lateral_offset" [vSubject, vE] []

/-- s8: road edge `e` lies on a highway that roadway `r` lies on, and is on the subject's right. -/
def rightEdgeOfRoadway : Formula :=
  .and (.existsRegion (.lit "highway") "h"
          (.and (.atom "st_on_way" [vR, vH] []) (.atom "st_on_way" [vE, vH] [])))
    (.cmp edgeOffset .lt zeroMetres)

/-- s9: the body gap to the edge (|offset| less half the subject's width) at most the keep-right
    gap; stated doubled, |offset|·2 − width ≤ gap·2, so that no literal enters the rule. -/
def nearEdge : Formula :=
  .cmp (.sub (.add (.neg edgeOffset) (.neg edgeOffset)) (.measure "kin_extent" [vSubject, .lit "width"]))
    .le (.add pBicycleKeepRightGap pBicycleKeepRightGap)

/-- Obligation: s4 (standard): commensurate with the speed of; s7 (standard): (c) When doing so would not be safe,; s8 (obligation): ride as near to the right side of the roadway; s9 (standard): as practicable,; s12 (standard): For purposes of paragraph (c) of subsection 1, the conditions under which it is not safe to operate a bicycle, an electric bicycle or an electric scooter as near to the right side of the roadway as practicable include, without limitation:; s14 (standard): (b) When a lane is too narrow for a bicycle and a vehicle to travel safely side by side within the lane. -/
def obligation : Formula :=
  .definedWhen
    (.existsRegion (.lit "roadway") "r"
      (.and (occupies vSubject vR) (.existsRegion (.lit "road_edge") "e" rightEdgeOfRoadway)))
    (.existsRegion (.lit "roadway") "r"
      (.and (occupies vSubject vR)
        (.existsRegion (.lit "road_edge") "e" (.and rightEdgeOfRoadway nearEdge))))

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
