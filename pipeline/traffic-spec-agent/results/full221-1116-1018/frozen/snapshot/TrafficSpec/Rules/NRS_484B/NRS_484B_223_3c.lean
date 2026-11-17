/-
  NRS_484B_223_3c — NRS-484B-223-3c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single center lane to be used only for turning by traffic moving in both directions,
    s2 (boilerplate): the following rules apply:
    s3 (subject): A vehicle
    s4 (obligation): must not travel more than 50 feet in a center turn lane
    s5 (trigger): after making a left-hand turn onto the highway
    s6 (condition): before merging with traffic.

  Elements (span → atoms, derived):
    s1: atoms ['st.centre_turn_lane', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.centre_turn_lane', 'kin.path_length'], derived []
    s5: atoms ['rel.occupies', 'st.highway', 'st.on_way'], derived ['drv.motion.left_turn']
    s6: atoms ['rel.occupies', 'st.centre_turn_lane', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []

  Literals the text states (each written through its Units constructor):
    s4: 50 ft — 50 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_3c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.

  s3 (subject): the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
  s1 (condition): a region `c` of kind `centre_turn_lane` (st.centre_turn_lane), quantified in the
    applicability and again in the obligation, lying on a region `h` of kind `highway`
    (st.on_way c h). The lane is "used by traffic": the subject is itself traffic,
    `ru_aggregate subject "DEF-NRS-484A-285::traffic"`, conjoined in the applicability.
  s5 (trigger): the left-hand turn is `drv_motion_left_turn subject` (window
    p.vehicle_turn_window, turn_min p.turn_heading_min, u_turn_min p.u_turn_heading_min,
    yaw_tol p.turn_yaw_rate_tol), recognized while the subject occupies c (rel_occupies subject c);
    "onto the highway" is that at some observation of the window p.vehicle_turn_window behind the
    recognition the subject occupied no part of h:
    `.not (.holdsFor .time p.vehicle_turn_window subject (rel_occupies subject h))`.
  s6 (condition): "before merging with traffic": the condition lasts while the subject has
    occupied c at every observation since that recognition: `.since (rel_occupies subject c) trig`.
    The count ends when the footprint leaves c (the record's own narrowing).
  s4 (obligation): `Term.distanceWhile subject (inLaneAfterTurn c h)` — the path length (from
    kin.path_length) over which that condition has held — is at most the literal 50 ft. The
    obligation restates the whole selection of c and h (kind, st_on_way, the condition) and
    requires the bound for every such pair.
  No reading of my own: `narrowings` is empty.
-/

/-- The record's turn onto the highway, recognized while the subject occupies `c` on way `h`. -/
def turnOntoHighway (c h : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var c] [])
    (.and (.derived "drv_motion_left_turn" [vSubject]
            [pVehicleTurnWindow, pTurnHeadingMin, pUTurnHeadingMin, pTurnYawRateTol])
          (.not (.holdsFor .time pVehicleTurnWindow "subject"
                  (.atom "rel_occupies" [vSubject, .var h] []))))

/-- The subject has occupied `c` at every observation since such a turn (s5, s6). -/
def inLaneAfterTurn (c h : String) : Formula :=
  .since (.atom "rel_occupies" [vSubject, .var c] []) (turnOntoHighway c h)

/-- `c` is a centre turn lane on highway `h` (s1). -/
def laneOnWay (c h : String) : Formula := .atom "st_on_way" [.var c, .var h] []

/-- The literal 50 feet of s4. -/
def fiftyFeet : Term := .lit (Units.feet 50) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (condition): If a highway has been designed to provide a single center lane to be used only for turning by traffic moving in both directions,; s5 (trigger): after making a left-hand turn onto the highway; s6 (condition): before merging with traffic. -/
def applicability : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.existsRegion (.lit "centre_turn_lane") "c"
      (.existsRegion (.lit "highway") "h"
        (.and (laneOnWay "c" "h") (inLaneAfterTurn "c" "h"))))

/-- Obligation: s4 (obligation): must not travel more than 50 feet in a center turn lane -/
def obligation : Formula :=
  .forallRegion (.lit "centre_turn_lane") "c"
    (.forallRegion (.lit "highway") "h"
      (.implies (.and (laneOnWay "c" "h") (inLaneAfterTurn "c" "h"))
        (.cmp (.distanceWhile "subject" (inLaneAfterTurn "c" "h")) .le fiftyFeet)))

def rule : Rule :=
  { id := "NRS_484B_223_3c"
    laws := ["NRS-484B-223-3c"]
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

end TrafficSpec.Rules.NRS_484B_223_3c
