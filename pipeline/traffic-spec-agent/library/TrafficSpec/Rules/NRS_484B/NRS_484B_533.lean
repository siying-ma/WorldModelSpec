/-
  NRS_484B_533 — NRS-484B-533

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (condition): shall not be permitted to stand
    s3 (condition): unattended
    s4 (condition): upon any perceptible grade
    s5 (obligation): without stopping the engine and effectively setting the brake thereon and turning the front wheels to the curb or side of the highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.complete_halt']
    s3: atoms ['ru.occupant_count'], derived []
    s4: atoms ['st.grade', 'rel.occupies', 'st.highway'], derived []
    s5: atoms ['kin.engine_running', 'kin.parking_brake', 'kin.steer_angle', 'prim.region_lateral_offset', 'st.road_edge', 'st.on_way', 'st.highway'], derived []

  How each span is written:
    s1: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s2: `drv_motion_complete_halt subject` with p.halt_speed_tolerance.
    s3: `ru_occupant_count subject = 0`.
    s4: some highway h (kind `highway`) the subject occupies (`rel_occupies`) whose grade
        (`st_grade h`, the slope of the way at the subject's place) exceeds p.grade_resolution in
        magnitude.
    s5: engine not running (`not kin_engine_running`), parking brake set (`kin_parking_brake`), and,
        for every highway h selected again as in s4 (occupied, grade beyond the resolution), some
        road edge e lying on h (`st_on_way e h`) whose absolute lateral offset
        (`prim_region_lateral_offset subject e`) is no larger than that of any road edge lying on h,
        with the steering angle beyond p.steer_angle_resolution on the side of that offset:
        offset > 0 and steer > res, or offset < 0 and steer < -res (both left-positive).

  Choices the record left open:
    - h in the obligation: every highway selected as in the applicability carries the wheel duty
      (the record's "with h selected again as there"); engine and brake do not depend on h and are
      written outside the quantifier.
    - Equally nearest road edges on opposite sides: wheels turned toward either comply (declared as
      a narrowing on s5). An edge with offset zero (reference point inside the edge region) gives no
      side, so no steering complies with it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_533

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pGradeResolution : Term := .param "p.grade_resolution"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pSteerAngleResolution : Term := .param "p.steer_angle_resolution"

def zeroMetres : Term := .lit Q.zero .metre
def zeroCount : Term := .lit Q.zero .count

def vH : Arg := .var "h"
def vE : Arg := .var "e"
def vE2 : Arg := .var "e2"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4's selection of the highway h: occupied by the subject, its grade beyond the resolution. -/
def onPerceptibleGrade : Formula :=
  .and (.atom "rel_occupies" [vSubject, vH] [])
       (.cmp (.abs (.measure "st_grade" [vH])) .gt pGradeResolution)

/-- s2: standing (halted). -/
def standing : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3: unattended, no person in or on the vehicle. -/
def unattended : Formula := .cmp (.measure "ru_occupant_count" [vSubject]) .eq zeroCount

/-- Applicability: s2 (condition): shall not be permitted to stand; s3 (condition): unattended; s4 (condition): upon any perceptible grade -/
def applicability : Formula :=
  .and standing
    (.and unattended
      (.existsRegion (.lit "highway") "h" onPerceptibleGrade))

def offsetOf (r : Arg) : Term := .quantity "prim_region_lateral_offset" [vSubject, r] []
def steer : Term := .measure "kin_steer_angle" [vSubject]

/-- e is a road edge of h nearest the subject: no road edge lying on h is nearer. -/
def nearestEdgeOfH : Formula :=
  .and (.atom "st_on_way" [vE, vH] [])
    (.forallRegion (.lit "road_edge") "e2"
      (.implies (.atom "st_on_way" [vE2, vH] [])
        (.cmp (.abs (offsetOf vE)) .le (.abs (offsetOf vE2)))))

/-- The front wheels turned beyond the resolution toward the side of e (left positive). -/
def wheelsTowardE : Formula :=
  .or (.and (.cmp (offsetOf vE) .gt zeroMetres) (.cmp steer .gt pSteerAngleResolution))
      (.and (.cmp (offsetOf vE) .lt zeroMetres) (.cmp steer .lt (.neg pSteerAngleResolution)))

def wheelsToCurb : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies onPerceptibleGrade
      (.existsRegion (.lit "road_edge") "e" (.and nearestEdgeOfH wheelsTowardE)))

/-- Obligation: s5 (obligation): without stopping the engine and effectively setting the brake thereon and turning the front wheels to the curb or side of the highway. -/
def obligation : Formula :=
  .and (.not (.atom "kin_engine_running" [vSubject] []))
    (.and (.atom "kin_parking_brake" [vSubject] [])
      wheelsToCurb)

def rule : Rule :=
  { id := "NRS_484B_533"
    laws := ["NRS-484B-533"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "Where two road edges lying on the highway are equally nearest the vehicle, front wheels turned beyond the resolution toward the side of either comply."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_533
