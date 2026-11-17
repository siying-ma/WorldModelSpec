/-
  LVMC_11_52_136 — LVMC-11-52-136

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): No person shall park
    s2 (subject): a vehicle
    s3 (condition): in an access aisle.

  Elements (span → atoms, derived):
    s1: atoms [], derived ['drv.motion.parked']
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.parking_space', 'rel.occupies'], derived []

  How each is written:
    s2: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: a region of kind `parking_space` (st.parking_space) whose designation attribute is
        `access_aisle` (st_parking_space_designation) and which the subject's footprint overlaps
        (rel_occupies subject r). The applicability asks that some such region exists.
    s1: for every parking-space region the applicability selects (the whole selection restated:
        kind parking_space, designation access_aisle, occupied by the subject), the subject is not
        parked: `drv_motion_parked subject` with speed_tol p.halt_speed_tolerance and
        min_duration p.parking_min_duration, as the record's obligation states.

  No choice beyond the record's: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_136

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- The region variable of the access aisle. -/
def vAisle : Arg := .var "aisle"

/-- s3: region `aisle` (a parking space) is designated access_aisle and the subject occupies it. -/
def inAccessAisle : Formula :=
  .and (.atom "st_parking_space_designation" [vAisle, .lit "access_aisle"] [])
       (.atom "rel_occupies" [vSubject, vAisle] [])

/-- s1: the subject is parked. -/
def parked : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s3 (condition): in an access aisle. -/
def applicability : Formula :=
  .existsRegion (.lit "parking_space") "aisle" inAccessAisle

/-- Obligation: s1 (obligation): No person shall park — in every access aisle the subject occupies. -/
def obligation : Formula :=
  .forallRegion (.lit "parking_space") "aisle" (.implies inAccessAisle (.not parked))

def rule : Rule :=
  { id := "LVMC_11_52_136"
    laws := ["LVMC-11-52-136"]
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

end TrafficSpec.Rules.LVMC_11_52_136
