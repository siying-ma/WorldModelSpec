/-
  NRS_484B_203_1_o2 — NRS-484B-203-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    h1 (subject): Drivers of vehicles proceeding in opposite directions
    h2 (sibling): shall pass each other keeping to the right,
    h3 (boilerplate): and
    h4 (condition): upon highways having width for not more than one line of traffic in each direction,
    h5 (obligation): each driver shall give to the other at least one-half of the paved portion of the highway
    h6 (standard): as nearly as possible.

  Elements (span → atoms, derived):
    h1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.oncoming'], derived ['drv.motion.complete_halt']
    h4: atoms ['rel.occupies', 'st.highway', 'st.lane', 'st.lane_adjacency'], derived []
    h5: atoms ['st.centre_line', 'st.on_way', 'prim.region_lateral_offset', 'kin.extent', 'prim.closest_approach_within', 'rel.longitudinal_overlap'], derived []

  Literals the text states (each written through its Units constructor):
    h4: 1 count — one

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    h1: the subject's class is ru_aggregate(subject, DEF-NRS-484A-320::vehicle); 'proceeding' is
        ¬drv_motion_complete_halt(subject, p.halt_speed_tolerance) in the applicability; 'the other'
        is any road user `other` that is the same aggregate and rel_oncoming(subject, other,
        p.oncoming_heading_cos) (which also excludes the subject itself: its own heading is not opposed).
    h4: some highway `way` and some lane `lane` the subject occupies (rel_occupies), the lane's
        st_lane_adjacency_count at most the text's "one" (a count literal).
    h5: for every road user `other` and every highway `way` both occupy, `other` being a vehicle,
        oncoming and meeting the subject (prim_closest_approach_within(subject, other,
        p.meeting_horizon), or rel_longitudinal_overlap > 0), and for every centre line `line` lying on
        `way` (st_on_way): the line's lateral offset from the subject (prim_region_lateral_offset,
        left positive) is at least half the subject's full width (kin_extent "width") less
        p.lateral_position_tolerance — written doubled, 2·offset ≥ width − 2·tol, so no figure enters.
    h6: alternatively, some road edge lies within p.lateral_position_tolerance of the subject's body
        (st_region_geometry_distance) and on its right (prim_region_lateral_offset < 0).
  Choices the record left open: the lane of h4 is sought among the lanes the subject occupies while
  it occupies a highway (nested under the highway quantifier, with no st_on_way tie between them, as
  the record states none); the road edge of h6 is any road edge, not tied to the way, as the record
  states. No narrowing beyond the record's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_203_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pLateralPositionTolerance : Term := .param "p.lateral_position_tolerance"
def pMeetingHorizon : Term := .param "p.meeting_horizon"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- h4: the text's figure "one" (line of traffic in each direction), a count. -/
def oneLine : Term := .lit (Units.ratio 1 1) .count

def vOther : Arg := .var "other"
def vWay : Arg := .var "way"
def vLane : Arg := .var "lane"
def vLine : Arg := .var "line"
def vEdge : Arg := .var "edge"

/-- h1: membership of DEF-NRS-484A-320::vehicle. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- h1 'proceeding': the subject is not at rest. -/
def proceeding : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- h4: the subject occupies a highway, and a lane whose count of lanes in its direction is at most one. -/
def narrowHighway : Formula :=
  .existsRegion (.lit "highway") "way"
    (.and (.atom "rel_occupies" [vSubject, vWay] [])
      (.existsRegion (.lit "lane") "lane"
        (.and (.atom "rel_occupies" [vSubject, vLane] [])
          (.cmp (.measure "st_lane_adjacency_count" [vLane]) .le oneLine))))

/-- Applicability: h1 (proceeding) and h4 (condition): upon highways having width for not more than one line of traffic in each direction, -/
def applicability : Formula := .and proceeding narrowHighway

/-- h1/h5 'the other': another vehicle on the subject's highway, oncoming, and meeting the subject:
    closing on it within the meeting horizon, or alongside (projections share length). -/
def meetsOther : Formula :=
  .and (.not (.same vOther vSubject))
    (.and (isVehicle vOther)
      (.and (.atom "rel_occupies" [vSubject, vWay] [])
        (.and (.atom "rel_occupies" [vOther, vWay] [])
          (.and (.atom "rel_oncoming" [vSubject, vOther] [pOncomingHeadingCos])
            (.or (.derived "prim_closest_approach_within" [vSubject, vOther] [pMeetingHorizon])
              (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vOther]) .gt zeroMetres))))))

/-- Signed lateral offset (left positive) of the centre line from the subject. -/
def lineOffset : Term := .quantity "prim_region_lateral_offset" [vSubject, vLine] []

/-- Full width of the subject's body. -/
def subjectWidth : Term := .measure "kin_extent" [vSubject, .lit "width"]

/-- h5 with h6: the body stays on the subject's half, within the tolerance: offset ≥ width/2 − tol,
    written doubled (2·offset ≥ width − 2·tol) so that no figure enters. -/
def keepsHalf : Formula :=
  .cmp (.add lineOffset lineOffset) .ge
    (.sub (.sub subjectWidth pLateralPositionTolerance) pLateralPositionTolerance)

/-- h6: no more room — the body is within the tolerance of a road edge lying on its right. -/
def atRightEdge : Formula :=
  .existsRegion (.lit "road_edge") "edge"
    (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, vEdge]) .le pLateralPositionTolerance)
      (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vEdge] []) .lt zeroMetres))

/-- Obligation: h5 (obligation): each driver shall give to the other at least one-half of the paved portion of the highway; h6 (standard): as nearly as possible. -/
def obligation : Formula :=
  .forallUser "other"
    (.forallRegion (.lit "highway") "way"
      (.implies meetsOther
        (.forallRegion (.lit "centre_line") "line"
          (.implies (.atom "st_on_way" [vLine, vWay] [])
            (.or keepsHalf atRightEdge)))))

def rule : Rule :=
  { id := "NRS_484B_203_1_o2"
    laws := ["NRS-484B-203-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "as nearly as possible"
          concepts := ["prim.region_lateral_offset", "st.region_geometry", "st.road_edge"]
          params := ["p.lateral_position_tolerance"]
          convention := "The subject gives the other half of the paved portion as nearly as possible where its body crosses the centre line by no more than a lateral positioning tolerance p.lateral_position_tolerance, or where its body is already within that tolerance of the road edge on its right (st.road_edge, ground distance through st.region_geometry, on the right per prim.region_lateral_offset), so that no more room is available to it."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_203_1_o2
