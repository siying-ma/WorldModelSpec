/-
  LVMC_11_52_300 — LVMC-11-52-300

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except for a motor vehicle,
    s2 (obligation): no person shall park
    s3 (subject): any vehicle
    s4 (condition): on any street
    s5 (condition): for a period of time longer than thirty minutes
    s6 (condition): between the hours of one a.m. and six a.m. of any day.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s2: atoms [], derived ['drv.motion.parked']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.highway'], derived []
    s5: atoms ['kin.time'], derived ['drv.motion.parked']
    s6: atoms ['env.civil_time'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 30 min — thirty minutes
    s6: 60 count — one a.m.
    s6: 360 count — six a.m.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s3: binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1: applicability conjunct `not (ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle")`.
    s4: `existsRegion highway street (rel_occupies subject street)` — the kind `highway` carries
        st.highway, rel.occupies anchors the region to the subject.
    s6: `env_civil_time minute_of_day ≥ 60 ∧ < 360` (count literals, no conversion).
    s2 + s5: obligation `not (holdsFor time 30 min subject (parked ∧ street ∧ hours))`, the
        window measured in kin.time; drv.motion.parked with p.halt_speed_tolerance and
        p.parking_min_duration. The street and the hours are restated inside the window, since
        the applicability's region and hours are not in scope there (one selection, rewritten whole).
  No choice beyond the record: no narrowing of mine.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_300

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- s5: "thirty minutes", the length of the period of parking looked back over. -/
def thirtyMinutes : Term := .lit (Units.minutes 30) .second
/-- s6: "one a.m." and "six a.m." as the civil minute of the day (a count). -/
def oneAm : Term := .lit (Units.ratio 60 1) .count
def sixAm : Term := .lit (Units.ratio 360 1) .count

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the subject is not a motor vehicle. -/
def motorVehicle : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s4: the subject's footprint overlaps a street (a highway region, its entire width). -/
def onStreet : Formula :=
  .existsRegion (.lit "highway") "street" (.atom "rel_occupies" [vSubject, .var "street"] [])

/-- s6: the civil minute of the day is at or after one a.m. and before six a.m. -/
def minuteOfDay : Term := .measure "env_civil_time" [.lit "minute_of_day"]
def withinHours : Formula :=
  .and (.cmp minuteOfDay .ge oneAm) (.cmp minuteOfDay .lt sixAm)

/-- s2: parked (drv.motion.parked with the halt tolerance and the parking minimum duration). -/
def parked : Formula := .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- Applicability: s1 (exception): Except for a motor vehicle,; s4 (condition): on any street; s5 (condition): for a period of time longer than thirty minutes; s6 (condition): between the hours of one a.m. and six a.m. of any day. -/
def applicability : Formula := .and (.not motorVehicle) (.and onStreet withinHours)

/-- Obligation: s2 (obligation): no person shall park; s5: not, at every observation of the
    thirty minutes behind (kin.time), parked on a street within the hours. -/
def obligation : Formula :=
  .not (.holdsFor .time thirtyMinutes "subject" (.and parked (.and onStreet withinHours)))

def rule : Rule :=
  { id := "LVMC_11_52_300"
    laws := ["LVMC-11-52-300"]
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

end TrafficSpec.Rules.LVMC_11_52_300
