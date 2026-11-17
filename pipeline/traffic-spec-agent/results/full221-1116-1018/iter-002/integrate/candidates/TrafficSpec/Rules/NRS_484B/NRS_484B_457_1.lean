/-
  NRS_484B_457_1 — NRS-484B-457-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except as otherwise provided in this section [(2) and (3) appended below],
    s2 (subject): every vehicle
    s3 (trigger): stopped or parked
    s4 (trigger): upon a highway
    s5 (condition): where there are adjacent curbs
    s6 (obligation): must be stopped or parked with the right-hand wheels of the vehicle parallel to and within 18 inches of the right-hand curb.
    s7 (exception): Local authorities may by ordinance permit parking
    s8 (exception): of vehicles with the left-hand wheels adjacent to and within 18 inches of the left-hand curb of a one-way highway.
    s9 (exception): Local authorities may by ordinance permit angle parking on any highway, except that angle parking must not be permitted on any highway constructed and maintained by the Department of Transportation under the authority granted by chapter 408 of NRS unless the Department has determined that the highway is of sufficient width to permit angle parking without interfering with the free movement of traffic.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['dev.governs', 'dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.railway_signal_or_gate', 'dev.human_direction', 'st.travel_region', 'rel.occupies', 'rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.occupies', 'st.highway'], derived []
    s5: atoms ['st.lane', 'st.lane_marking', 'st.on_way', 'st.highway'], derived []
    s6: atoms ['kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region', 'st.road_edge', 'st.on_way', 'st.region_geometry', 'prim.region_lateral_offset'], derived []
    s8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.one_way_roadway', 'kin.heading', 'st.lane_direction', 'st.road_edge', 'st.on_way', 'st.region_geometry', 'prim.region_lateral_offset'], derived []
    s9: atoms ['dev.regulatory_sign', 'dev.governs', 'st.travel_region', 'rel.occupies', 'st.parking_space', 'prim.conditions_hold', 'st.highway'], derived []

  Literals the text states (each written through its Units constructor):
    s6: 18 in — 18 inches
    s8: 18 in — 18 inches

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s2: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: `drv_motion_complete_halt subject [p.halt_speed_tolerance]`, conjoined with the absence of a
        halt in the stream of traffic: no travel region the subject occupies is governed by a device
        of kind traffic_signal, stop_sign, yield_sign, railway_signal_or_gate or human_direction (one
        device quantifier per kind, each `dev_governs d r`), and no road user o of the aggregate
        DEF-NRS-484A-285::traffic is ahead of the subject in its lane (`rel_ahead_behind_in_lane o
        subject`, "o ahead of subject") with a body gap (`rel_surface_gap subject o`, the distance
        form) at or below p.queue_halt_gap. The subject itself is never ahead of itself, so no
        exclusion of it is written.
    s4: a highway region h (`existsRegion highway`) the subject occupies (`rel_occupies`).
    s5: some lane l lying on h (`st_on_way l h`) with a side marked type curb: the marking atom in its
        side/type form, left or right (colour unconstrained, as the words state none).
    s6: (obligation, limb 1) a travel region r the subject occupies lying on h, the dot product of
        the subject's heading and r's designated direction (component-wise products of `kin_heading`
        and `st_lane_direction`) at or above p.parked_heading_cos, and a road edge e lying on h with
        `prim_region_lateral_offset subject e` below zero and `st_region_geometry_distance subject e`
        at most 18 inches (`Units.inches 18`).
    s7/s8: (limb 2) `asm.left_curb_parking_permitted`, a one-way roadway r the subject occupies lying
        on h, the same parallelism bound, and a road edge e on h with the offset above zero and the
        same distance bound.
    s9: (limb 3) a travel region the subject occupies governed by a regulatory sign of code
        angle_parking whose conditions hold for the subject (`prim_conditions_hold d subject`), or a
        parking space the subject occupies whose angle stands clear of zero by more than
        p.parking_space_angle_resolution (written on the angle's magnitude, as the element states
        "clear of zero"; a mapped angle is never read with a sign that would hide an angled bay).
    The obligation re-selects h with the applicability's whole selection (occupied highway on which
    a lane has a curb-marked side) before its three limbs (rule 3c).
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_457_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkedHeadingCos : Term := .param "p.parked_heading_cos"
def pParkingSpaceAngleResolution : Term := .param "p.parking_space_angle_resolution"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- 18 inches, the text's figure (s6, s8). -/
def eighteenInches : Term := .lit (Units.inches 18) .metre

def vH : Arg := .var "h"
def vL : Arg := .var "l"
def vR : Arg := .var "r"
def vE : Arg := .var "e"
def vD : Arg := .var "d"
def vO : Arg := .var "o"
def vP : Arg := .var "p"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3: at rest. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3: a device of kind `k` governs travel region `r`. -/
def governedBy (k : String) : Formula :=
  .existsDevice (.lit k) "d" (.atom "dev_governs" [vD, vR] [])

/-- s3: the subject occupies a travel region governed by a traffic-control device or a person
    directing traffic. -/
def controlledHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.or (governedBy "traffic_signal")
        (.or (governedBy "stop_sign")
          (.or (governedBy "yield_sign")
            (.or (governedBy "railway_signal_or_gate")
              (governedBy "human_direction"))))))

/-- s3: a member of traffic is ahead of the subject in its lane within the queue spacing. -/
def queuedHalt : Formula :=
  .existsUser "o"
    (.and (.atom "ru_aggregate" [vO, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.atom "rel_ahead_behind_in_lane" [vO, vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, vO]) .le pQueueHaltGap)))

/-- s5: some lane lying on `h` has a side marked type curb. -/
def curbLaneOn : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (.atom "st_on_way" [vL, vH] [])
      (.or (.atom "st_lane_marking" [vL, .lit "left", .lit "curb"] [])
        (.atom "st_lane_marking" [vL, .lit "right", .lit "curb"] [])))

/-- s4 + s5: the subject occupies `h`, a highway on which a lane has a curb-marked side. -/
def curbedHighwayWith (body : Formula) : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, vH] [])
      (.and curbLaneOn body))

/-- s4 + s5 alone, for the applicability. -/
def curbedHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, vH] []) curbLaneOn)

/-- s6/s8: the subject's heading lies along `r`'s designated direction within the tolerance. -/
def parallelTo : Formula :=
  .cmp (.add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [vR, .lit "x"]))
             (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [vR, .lit "y"])))
    .ge pParkedHeadingCos

/-- s6/s8: a road edge on `h`, on the side `op` (lt: right, gt: left), within 18 inches of the body. -/
def edgeWithin (op : CmpOp) : Formula :=
  .existsRegion (.lit "road_edge") "e"
    (.and (.atom "st_on_way" [vE, vH] [])
      (.and (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vE] []) op zeroMetres)
        (.cmp (.measure "st_region_geometry_distance" [vSubject, vE]) .le eighteenInches)))

/-- s6: right-hand wheels parallel to and within 18 inches of the right-hand curb. -/
def rightCurb : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.and (.atom "st_on_way" [vR, vH] [])
        (.and parallelTo (edgeWithin .lt))))

/-- s7/s8: left-hand wheels at the left-hand curb of a one-way highway, where permitted. -/
def leftCurb : Formula :=
  .and (.asm "asm.left_curb_parking_permitted")
    (.existsRegion (.lit "one_way_roadway") "r"
      (.and (.atom "rel_occupies" [vSubject, vR] [])
        (.and (.atom "st_on_way" [vR, vH] [])
          (.and parallelTo (edgeWithin .gt)))))

/-- s9: angle parking permitted by a posted sign or a marked angled bay. -/
def angleParking : Formula :=
  .or
    (.existsRegion (.lit "travel_region") "r"
      (.and (.atom "rel_occupies" [vSubject, vR] [])
        (.existsDevice (.lit "regulatory_sign") "d"
          (.and (.atom "dev_governs" [vD, vR] [])
            (.and (.atom "dev_regulatory_sign_code" [vD, .lit "angle_parking"] [])
              (.derived "prim_conditions_hold" [vD, vSubject] []))))))
    (.existsRegion (.lit "parking_space") "p"
      (.and (.atom "rel_occupies" [vSubject, vP] [])
        (.cmp (.abs (.measure "st_parking_space_angle" [vP])) .gt pParkingSpaceAngleResolution)))

/-- Applicability: s1 (exception): Except as otherwise provided in this section [(2) and (3) appended below],; s3 (trigger): stopped or parked; s4 (trigger): upon a highway; s5 (condition): where there are adjacent curbs; s7 (exception): Local authorities may by ordinance permit parking; s8 (exception): of vehicles with the left-hand wheels adjacent to and within 18 inches of the left-hand curb of a one-way highway.; s9 (exception): Local authorities may by ordinance permit angle parking on any highway, except that angle parking must not be permitted on any highway constructed and maintained by the Department of Transportation under the authority granted by chapter 408 of NRS unless the Department has determined that the highway is of sufficient width to permit angle parking without interfering with the free movement of traffic. -/
def applicability : Formula :=
  .and halted
    (.and curbedHighway
      (.and (.not controlledHalt) (.not queuedHalt)))

/-- Obligation: s6 (obligation): must be stopped or parked with the right-hand wheels of the vehicle parallel to and within 18 inches of the right-hand curb. -/
def obligation : Formula :=
  curbedHighwayWith (.or rightCurb (.or leftCurb angleParking))

def rule : Rule :=
  { id := "NRS_484B_457_1"
    laws := ["NRS-484B-457-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.left_curb_parking_permitted"]
    intentions := []
    operationalizations := []
    residues := ["The provisions the words point to are subsections (2) and (3), which are segments s7-s9 of this same text and are carried there as the exceptions of this node; the words add nothing beyond them, so the duty is the same whether or not they are read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_457_1
