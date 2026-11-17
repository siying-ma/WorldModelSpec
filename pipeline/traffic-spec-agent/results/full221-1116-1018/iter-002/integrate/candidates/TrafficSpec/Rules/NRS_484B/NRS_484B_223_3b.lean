/-
  NRS_484B_223_3b — NRS-484B-223-3b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single center lane to be used only for turning by traffic moving in both directions,
    s2 (boilerplate): the following rules apply:
    s3 (subject): A vehicle
    s4 (obligation): must not travel more than 200 feet in a center turn lane
    s5 (trigger): before making a left-hand turn from the highway.

  Elements (span → atoms, derived):
    s1: atoms ['st.centre_turn_lane', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.centre_turn_lane', 'kin.path_length'], derived []
    s5: atoms ['rel.occupies', 'st.centre_turn_lane'], derived ['drv.motion.left_turn']

  Literals the text states (each written through its Units constructor):
    s4: 200 ft — 200 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s3: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1: the centre turn lane is the region quantifier over kind `centre_turn_lane`, tied to the
        subject by `rel_occupies`; "traffic" is `ru_aggregate subject "DEF-NRS-484A-285::traffic"`,
        so the subject is one of the users of the traffic the lane is provided for. The lane's
        presence ("designed to provide") is the existence of such a region.
    s5: `drv_motion_left_turn subject` with (window, turn_min, u_turn_min, yaw_tol) =
        (p.vehicle_turn_window, p.turn_heading_min, p.u_turn_heading_min, p.turn_yaw_rate_tol),
        and, for some centre turn lane c, the subject occupied c at some observation of the window
        p.vehicle_turn_window behind (`not (holdsFor … (not occupies))`) and does not occupy it now.
    s4: for every centre turn lane selected as in s5 (the whole selection is restated in the
        obligation), at the last observation of the window at which the subject occupied c
        (`atLast .time p.vehicle_turn_window`), `distanceWhile subject (occupies c)` — the path
        length (kin.path_length) over which it occupied c continuously — is ≤ 200 ft
        (`Units.feet 200`). A run that began before the recording leaves it unknown (Core).
    Choice: where several centre turn lanes satisfy the selection, the duty is read at each of them
    (forallRegion … implies); the record speaks of "that" lane, which for one turn is a single lane.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_3b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's literal: 200 feet (s4). -/
def twoHundredFeet : Term := .lit (Units.feet 200) .metre

def vLane : Arg := .var "c"

/-- s1/s4/s5: the subject's footprint overlaps the centre turn lane `c`. -/
def occupiesLane : Formula := .atom "rel_occupies" [vSubject, vLane] []

/-- s5: drv.motion.left_turn of the subject, with the node's four parameters in the concept's order
    (window, turn_min, u_turn_min, yaw_tol). -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn" [vSubject]
    [pVehicleTurnWindow, pTurnHeadingMin, pUTurnHeadingMin, pTurnYawRateTol]

/-- s5: the centre turn lane the turn is made from: the subject occupied `c` at some observation of
    the turn window behind and does not occupy it at this observation. -/
def turnedOutOf : Formula :=
  .and (.not (.holdsFor .time pVehicleTurnWindow "subject" (.not occupiesLane)))
       (.not occupiesLane)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the subject is a member of the traffic for which the centre turn lane is provided. -/
def isTraffic : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] []

/-- Applicability: s1 (condition): If a highway has been designed to provide a single center lane to be used only for turning by traffic moving in both directions,; s5 (trigger): before making a left-hand turn from the highway. -/
def applicability : Formula :=
  .and isTraffic
    (.and leftTurn
      (.existsRegion (.lit "centre_turn_lane") "c" turnedOutOf))

/-- Obligation: s4 (obligation): must not travel more than 200 feet in a center turn lane.
    For every centre turn lane selected as the applicability selects it, at the last observation
    of the turn window at which the subject occupied it, the path length over which it had occupied
    it continuously is at most 200 ft. -/
def obligation : Formula :=
  .forallRegion (.lit "centre_turn_lane") "c"
    (.implies turnedOutOf
      (.atLast .time pVehicleTurnWindow "subject" occupiesLane
        (.cmp (.distanceWhile "subject" occupiesLane) .le twoHundredFeet)))

def rule : Rule :=
  { id := "NRS_484B_223_3b"
    laws := ["NRS-484B-223-3b"]
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

end TrafficSpec.Rules.NRS_484B_223_3b
