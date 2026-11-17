/-
  LVMC_11_52_340 — LVMC-11-52-340

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The City Council may designate parking spaces upon City streets or in City parking facilities for the parking of City vehicles.
    s2 (obligation): It is unlawful to park
    s3 (subject): a vehicle
    s4 (exception): other than a City vehicle
    s5 (condition): in any such space that has been duly posted or marked.

  Elements (span → atoms, derived):
    s1: atoms ['st.parking_space'], derived []
    s2: atoms [], derived ['drv.motion.parked']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['ru.official_vehicle'], derived []
    s5: atoms ['st.parking_space', 'rel.occupies'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_340

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s3: the binder class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s4: a City vehicle is an official vehicle (class atom `ru_official_vehicle`) whose kind is
        municipal (`ru_official_vehicle_kind subject municipal`); the exception negates the
        conjunction. The class conjunct keeps the exception decided (false) for a road user that
        is not an official vehicle at all, whose kind field is unobserved.
    s1/s5: "such space ... duly posted or marked" is a region of kind `parking_space` whose
        designation is municipal (`st_parking_space_designation r municipal`), anchored to the
        subject by `rel_occupies subject r`.
    s2: "park" is `drv_motion_parked subject` with p.halt_speed_tolerance and
        p.parking_min_duration.
  The obligation restates the whole selection of the space (kind, municipal designation,
  occupancy by the subject) and requires, for every such space, that the subject is not parked.
  No choice beyond the record's own narrowings was made.
-/

/-- s1/s5: region `r` is a municipal-designated parking space the subject occupies. -/
def municipalSpaceOccupied (r : String) : Formula :=
  .and (.atom "st_parking_space_designation" [.var r, .lit "municipal"] [])
       (.atom "rel_occupies" [vSubject, .var r] [])

/-- s4: the subject is a City vehicle (official vehicle of kind municipal). -/
def cityVehicle : Formula :=
  .and (.atom "ru_official_vehicle" [vSubject] [])
       (.atom "ru_official_vehicle_kind" [vSubject, .lit "municipal"] [])

/-- s2: the subject is parked. -/
def parked : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (condition): The City Council may designate parking spaces upon City streets or in City parking facilities for the parking of City vehicles.; s4 (exception): other than a City vehicle; s5 (condition): in any such space that has been duly posted or marked. -/
def applicability : Formula :=
  .and (.not cityVehicle)
       (.existsRegion (.lit "parking_space") "space" (municipalSpaceOccupied "space"))

/-- Obligation: s2 (obligation): It is unlawful to park -/
def obligation : Formula :=
  .forallRegion (.lit "parking_space") "space"
    (.implies (municipalSpaceOccupied "space") (.not parked))

def rule : Rule :=
  { id := "LVMC_11_52_340"
    laws := ["LVMC-11-52-340"]
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

end TrafficSpec.Rules.LVMC_11_52_340
