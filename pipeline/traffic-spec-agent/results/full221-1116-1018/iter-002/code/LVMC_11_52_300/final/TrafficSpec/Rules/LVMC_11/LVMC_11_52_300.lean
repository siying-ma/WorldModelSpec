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
    s6: 1 h — one a.m.
    s6: 6 h — six a.m.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s3 → binder class: ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    s1 → applicability: not ru_aggregate(subject, DEF-NRS-484A-130::motor_vehicle).
    s4 → some region of kind highway (st.highway) the subject occupies (rel.occupies); written
         again inside the obligation's window, the same whole selection.
    s6 → env.civil_time's minute_of_day, times one minute (the field's unit, so that it reads as a
         time of day in seconds), at or after Units.hours 1 and before Units.hours 6; in the
         applicability and, at every observation of the window, in the obligation.
    s2, s5 → obligation: not holdsFor(time, Units.minutes 30, subject, parked ∧ on a street ∧
         within the hours), parked = drv.motion.parked(subject; p.halt_speed_tolerance,
         p.parking_min_duration); the time window reads kin.time.
  No choice beyond the record's was made; no narrowing is declared.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_300

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- s5: thirty minutes, the length of the continuous period. -/
def thirtyMinutes : Term := .lit (Units.minutes 30) .second
/-- s6: one a.m. and six a.m., as times of day. -/
def oneAm : Term := .lit (Units.hours 1) .second
def sixAm : Term := .lit (Units.hours 6) .second
/-- The unit of env.civil_time's `minute_of_day` field: one minute, so that the field times it is
    the time of day in seconds, comparable with the text's hours. A unit conversion, no bound. -/
def minuteUnit : Term := .lit (Units.minutes 1) .second

/-- s1: the subject is a motor vehicle (DEF-NRS-484A-130). -/
def motorVehicle : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s4: the subject's footprint overlaps a street (st.highway, the entire width between the
    boundary lines), via rel.occupies. -/
def onStreet : Formula :=
  .existsRegion (.lit "highway") "street" (.atom "rel_occupies" [vSubject, .var "street"] [])

/-- s6: the civil time of day is at or after one a.m. and before six a.m. -/
def timeOfDay : Term := .mul (.measure "env_civil_time" [.lit "minute_of_day"]) minuteUnit
def withinHours : Formula :=
  .and (.cmp timeOfDay .ge oneAm) (.cmp timeOfDay .lt sixAm)

/-- s2: the subject is parked (DEF-NRS-484A-155 through drv.motion.parked). -/
def parked : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (exception): Except for a motor vehicle,; s4 (condition): on any street; s5 (condition): for a period of time longer than thirty minutes; s6 (condition): between the hours of one a.m. and six a.m. of any day. -/
def applicability : Formula :=
  .and (.not motorVehicle) (.and onStreet withinHours)

/-- Obligation: s2 (obligation): no person shall park — s5: not, at every observation of the
    thirty-minute window behind (kin.time), parked on a street within the hours (s4, s6). -/
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
