/-
  NRS_484B_403_2 — NRS-484B-403-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): If an official traffic-control device indicates that a U-turn is prohibited,
    s2 (subject): the driver
    s3 (obligation): shall obey the directions of the device.

  Elements (span → atoms, derived):
    s1: atoms ['dev.regulatory_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'prim.conditions_hold', 'st.lane_enters', 'st.intersection', 'st.lane'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms [], derived ['drv.motion.u_turn']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_403_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.

  s2 (subject): `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)` — the admitted aggregate, never
    expanded; 'driver' is the plan's observable reading (agency).

  s3 (obligation): the act `drv_motion_u_turn(subject; window, u_turn_min, yaw_tol)` with
    p.vehicle_turn_window, p.u_turn_heading_min, p.turn_yaw_rate_tol, in the contract's order. The
    obligation is that it does not hold at the judged observation (the plan's reading of 'obey').

  Occasion (boundary "window", s1 read some_moment): the applicability is
    `.not (.holdsFor .time W subject (.not (.and U φ)))`, W = p.vehicle_turn_window, with
    U = |kin_yaw_rate(subject)| > p.turn_yaw_rate_tol (the under_way element: the heading is turning)
    and φ the s1 element below, so that U and φ hold together at one common observation of the
    window behind.

  s1 (trigger): some device of kind regulatory_sign d with code no_u_turn whose conditions hold for
    the subject there (prim_conditions_hold(d, subject)), and either
      (a) d governs (dev_governs) a travel region r (st.travel_region, its refinements included)
          the subject's footprint overlaps (rel_occupies), or
      (b) the subject's footprint overlaps an intersection i (st.intersection), and d governs a lane
          l (st.lane) that enters i (st_lane_enters(l, i)), the subject having come into i from l:
          `.since (rel_occupies subject i) (rel_occupies subject l)` — it occupied l at some
          observation and has occupied i at every observation since.
  'official' and 'driver' are the plan's observable readings; no reading of this file's own.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The act: drv.motion.u_turn of the subject, recognized at the observation judged. -/
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vSubject] [pVehicleTurnWindow, pUTurnHeadingMin, pTurnYawRateTol]

/-- The occasion's under_way element: the subject's heading is turning. -/
def underWay : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vSubject])) .gt pTurnYawRateTol

def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- s1: a no-U-turn sign, its conditions holding for the subject, directs the subject's traffic. -/
def underSign : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "no_u_turn"] [])
      (.and (.derived "prim_conditions_hold" [.var "d", vSubject] [])
        (.or
          (.existsRegion (.lit "travel_region") "r" (.and (governs "d" "r") (occ "r")))
          (.existsRegion (.lit "intersection") "i"
            (.and (occ "i")
              (.existsRegion (.lit "lane") "l"
                (.and (governs "d" "l")
                  (.and (.atom "st_lane_enters" [.var "l", .var "i"] [])
                    (.since (occ "i") (occ "l"))))))))))

/-- Applicability: s1 (trigger): If an official traffic-control device indicates that a U-turn is prohibited,
    read some_moment over the window behind while the U-turn is under way. -/
def applicability : Formula :=
  .not (.holdsFor .time pVehicleTurnWindow "subject" (.not (.and underWay underSign)))

/-- Obligation: s3 (obligation): shall obey the directions of the device — no U-turn. -/
def obligation : Formula := .not uTurn

def rule : Rule :=
  { id := "NRS_484B_403_2"
    laws := ["NRS-484B-403-2"]
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

end TrafficSpec.Rules.NRS_484B_403_2
