/-
  NRS_484B_497 — NRS-484B-497

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a laned roadway is restricted to one direction,
    s2 (obligation): a person shall not stand or park a vehicle
    s3 (condition): upon the left-hand side of such one-way roadway
    s4 (exception): unless official traffic-control devices are erected permitting such standing or parking.

  Elements (span → atoms, derived):
    s1: atoms ['st.one_way_roadway', 'st.lane', 'st.on_way', 'st.highway'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.parked']
    s3: atoms ['rel.occupies', 'st.one_way_roadway', 'st.road_edge', 'prim.region_lateral_offset', 'kin.heading', 'st.lane_direction', 'st.on_way', 'st.highway'], derived []
    s4: atoms ['rel.occupies', 'st.parking_space', 'dev.regulatory_sign', 'dev.zone_sign', 'dev.governs', 'prim.conditions_hold', 'st.travel_region'], derived []

  How each span is written:
    s1: `selection` — a region r of kind one_way_roadway lying on (st_on_way) a highway h on which
        some region of kind lane also lies; the applicability is ∃ r h of that selection.
    s3: the subject occupies r (rel_occupies, in `selection`); `onLeftSide`: some road edge e on h
        whose |prim_region_lateral_offset| is no larger than every road edge's on h, and whose
        offset times (kin_heading · st_lane_direction of r) is strictly positive — positive offset
        with a positive dot product, negative with a negative one, as the record states.
    s2: drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration); the subject's
        class is ru_aggregate DEF-NRS-484A-320::vehicle.
    s4: `noPermit` — no parking_space the subject occupies; no regulatory_sign of code
        angle_parking and no zone_sign of kind parking_restricted whose conditions hold for the
        subject (prim_conditions_hold) and which governs (dev_governs) a travel_region the subject
        occupies.
    The obligation re-selects r with the whole of `selection` for every r and h, and forbids
    parked ∧ left-hand side ∧ no permitting device. No reading beyond the record's was chosen.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_497

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1 + s3 ("upon ... such one-way roadway"): the one-way roadway `r` the subject occupies lies on
    the highway `h`, on which some lane also lies ("laned"). -/
def selection (r h : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
    (.and (.atom "st_on_way" [.var r, .var h] [])
      (.existsRegion (.lit "lane") "l" (.atom "st_on_way" [.var "l", .var h] [])))

/-- Applicability: s1, s3 — the subject occupies a one-way roadway lying on a highway on which a lane lies. -/
def applicability : Formula :=
  .existsRegion (.lit "one_way_roadway") "r"
    (.existsRegion (.lit "highway") "h" (selection "r" "h"))

/-- s2: standing or parking — drv.motion.parked over p.standing_min_duration. -/
def parked : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]

/-- The signed lateral offset of road edge `e` from the subject (left of its heading positive). -/
def offset (e : String) : Term := .quantity "prim_region_lateral_offset" [vSubject, .var e] []

/-- Dot product of the subject's heading with r's designated direction. -/
def headingDotDirection (r : String) : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [.var r, .lit "x"]))
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [.var r, .lit "y"]))

/-- s3: the left-hand side of r — among the road edges lying on h, the one nearest the subject
    (smallest absolute lateral offset) lies left of r's direction: its offset and the heading·direction
    dot product have the same strict sign (their product is positive). -/
def onLeftSide (r h : String) : Formula :=
  .existsRegion (.lit "road_edge") "e"
    (.and (.atom "st_on_way" [.var "e", .var h] [])
      (.and (.forallRegion (.lit "road_edge") "e2"
              (.implies (.atom "st_on_way" [.var "e2", .var h] [])
                (.cmp (.abs (offset "e")) .le (.abs (offset "e2")))))
        (.cmp (.mul (offset "e") (headingDotDirection r)) .gt zeroMetres)))

/-- s4: no device permits standing or parking there — no marked bay the subject occupies, no
    angle-parking regulatory sign and no parking-restricted zone sign whose conditions hold for the
    subject governing a travel region the subject occupies. -/
def governsOccupied (d : String) : Formula :=
  .existsRegion (.lit "travel_region") "g"
    (.and (.atom "dev_governs" [.var d, .var "g"] []) (.atom "rel_occupies" [vSubject, .var "g"] []))

def noPermit : Formula :=
  .and (.not (.existsRegion (.lit "parking_space") "p" (.atom "rel_occupies" [vSubject, .var "p"] [])))
    (.and
      (.not (.existsDevice (.lit "regulatory_sign") "d"
        (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "angle_parking"] [])
          (.and (.derived "prim_conditions_hold" [.var "d", vSubject] []) (governsOccupied "d")))))
      (.not (.existsDevice (.lit "zone_sign") "z"
        (.and (.atom "dev_zone_sign_kind" [.var "z", .lit "parking_restricted"] [])
          (.and (.derived "prim_conditions_hold" [.var "z", vSubject] []) (governsOccupied "z"))))))

/-- Obligation: for every one-way roadway the subject occupies, selected again as in the
    applicability, not (parked ∧ on its left-hand side ∧ no permitting device). -/
def obligation : Formula :=
  .forallRegion (.lit "one_way_roadway") "r"
    (.forallRegion (.lit "highway") "h"
      (.implies (selection "r" "h")
        (.not (.and parked (.and (onLeftSide "r" "h") noPermit)))))

def rule : Rule :=
  { id := "NRS_484B_497"
    laws := ["NRS-484B-497"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_497
