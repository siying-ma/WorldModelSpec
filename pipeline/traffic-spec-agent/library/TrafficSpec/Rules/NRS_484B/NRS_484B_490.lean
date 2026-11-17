/-
  NRS_484B_490 — NRS-484B-490

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (trigger): When official traffic-control devices are erected prohibiting parking upon a narrow highway,
    d2 (subject): a person
    d3 (obligation): shall not park a vehicle
    d4 (condition): upon any such highway.

  Elements (span → atoms, derived):
    d1: atoms ['dev.zone_sign', 'dev.governs', 'st.travel_region', 'rel.occupies', 'prim.conditions_hold'], derived []
    d2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.parked']
    d4: atoms ['rel.occupies', 'st.travel_region'], derived []

  How each span is written:
    d2 — the binder class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    d1 + d4 — the applicability: some travel region r (`existsRegion "travel_region"`, which covers
      the kinds refining it) that the subject occupies (`rel_occupies subject r`), and some zone sign
      d (`existsDevice "zone_sign"`) of kind narrow_highway (`dev_zone_sign_kind d narrow_highway`)
      that governs r (`dev_governs d r`) and whose legend conditions hold for the subject now
      (`prim_conditions_hold d subject`). The sign is tied to the subject through r (governs) and
      through the conditions primitive; r is tied to the subject by occupancy.
    d3 — the obligation: the subject is not parked,
      `not (drv_motion_parked subject [p.halt_speed_tolerance, p.parking_min_duration])`.
      The vehicle class of d3 is the binder class already stated for d2.

  No choice beyond the record's: the record's narrowings (the d3 duration reading, the d1 status
  reading and the d2 agency reading) are the plan's and are not restated.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_490

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

def vR : Arg := .var "r"
def vD : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d1: a narrow_highway zone sign governing region r, its legend conditions holding for the subject. -/
def narrowHighwaySignGoverns : Formula :=
  .existsDevice (.lit "zone_sign") "d"
    (.and (.atom "dev_zone_sign_kind" [vD, .lit "narrow_highway"] [])
      (.and (.atom "dev_governs" [vD, vR] [])
        (.derived "prim_conditions_hold" [vD, vSubject] [])))

/-- Applicability: d1 (trigger): When official traffic-control devices are erected prohibiting parking upon a narrow highway,; d4 (condition): upon any such highway. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] []) narrowHighwaySignGoverns)

/-- Obligation: d3 (obligation): shall not park a vehicle -/
def obligation : Formula :=
  .not (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration])

def rule : Rule :=
  { id := "NRS_484B_490"
    laws := ["NRS-484B-490"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_490
