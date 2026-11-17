/-
  NRS_486_351_1 — NRS-486-351-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): A person,
    s2 (exception): except a police officer in the performance of his or her duty,
    s3 (subject): shall not drive a motorcycle or moped
    s4 (obligation): between moving or stationary vehicles occupying adjacent traffic lanes.

  Elements (span → atoms, derived):
    s2: atoms ['ru.emergency_vehicle', 'sig.warning_lamp'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-486-041::motorcycle', 'ru.aggregate=DEF-NRS-486-038::moped'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane', 'st.lane_adjacency', 'rel.bearing', 'rel.longitudinal_overlap'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_486_351_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s3: the subject's class is `ru_aggregate subject DEF-NRS-486-041::motorcycle` or
        `ru_aggregate subject DEF-NRS-486-038::moped` (the admitted aggregates, by id).
    s2: the exception is a police vehicle (`ru_emergency_vehicle` and `ru_emergency_vehicle_kind`
        police) displaying a warning lamp (`sig_warning_lamp`) in mode flashing or rotating; the
        record names no colour, so every colour of `LampColour` is admitted (one atom per colour and
        mode, disjoined: one leaf of the atom's enumeration). The applicability is its negation.
    s4: no two road users v1, v2, each other than the subject (`not (same v subject)`) and of
        DEF-NRS-484A-320::vehicle, and no two distinct lanes L1, L2 (`existsRegion lane`, `not (same
        L1 L2)`) with v1 occupying L1, v2 occupying L2 (`rel_occupies`), L1 and L2 adjacent (L2 is
        L1's left or right neighbour by `st_lane_adjacency`, or the subject occupies both), v1 on the
        subject's left and v2 on its right (`rel_bearing … left/right`), and the longitudinal overlap
        of the subject with each at or above zero (`rel_longitudinal_overlap ≥ 0`).
  No choice beyond the record's: "L1's neighbour per st.lane_adjacency" is read on either side, as
  the record states it without a side.
-/

def vV1 : Arg := .var "v1"
def vV2 : Arg := .var "v2"
def vL1 : Arg := .var "l1"
def vL2 : Arg := .var "l2"

/-- Class of `subject`: ru.aggregate=DEF-NRS-486-041::motorcycle, ru.aggregate=DEF-NRS-486-038::moped -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-486-041::motorcycle"] [])
      (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-486-038::moped"] [])

/-- A warning lamp lit in mode flashing or rotating, of any colour. -/
def warningLampFlashingOrRotating : Formula :=
  let one (c m : String) : Formula := .atom "sig_warning_lamp" [vSubject, .lit c, .lit m] []
  let colour (c : String) : Formula := .or (one c "flashing") (one c "rotating")
  .or (colour "red") (.or (colour "blue") (.or (colour "amber") (colour "white")))

/-- s2: a police vehicle displaying its warning lamps, read as an officer in the performance of duty. -/
def policeOnDuty : Formula :=
  .and (.atom "ru_emergency_vehicle" [vSubject] [])
    (.and (.atom "ru_emergency_vehicle_kind" [vSubject, .lit "police"] [])
      warningLampFlashingOrRotating)

/-- Applicability: s2 (exception): except a police officer in the performance of his or her duty, -/
def applicability : Formula := .not policeOnDuty

/-- A road user other than the subject, of DEF-NRS-484A-320::vehicle. -/
def otherVehicle (v : Arg) : Formula :=
  .and (.not (.same v vSubject)) (.atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- L1 and L2 adjacent: neighbours per st.lane_adjacency, or both overlapped by the subject. -/
def adjacentLanes : Formula :=
  .or (.or (.atom "st_lane_adjacency" [vL1, .lit "left", vL2] [])
           (.atom "st_lane_adjacency" [vL1, .lit "right", vL2] []))
      (.and (.atom "rel_occupies" [vSubject, vL1] []) (.atom "rel_occupies" [vSubject, vL2] []))

/-- The subject side by side with `v` (longitudinal overlap at or above zero). -/
def sideBySide (v : Arg) : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vSubject, v]) .ge zeroMetres

/-- The subject between v1 (in L1, on its left) and v2 (in L2, on its right). -/
def between : Formula :=
  .and (otherVehicle vV1)
    (.and (otherVehicle vV2)
      (.and (.not (.same vL1 vL2))
        (.and (.atom "rel_occupies" [vV1, vL1] [])
          (.and (.atom "rel_occupies" [vV2, vL2] [])
            (.and adjacentLanes
              (.and (.atom "rel_bearing" [vSubject, vV1, .lit "left"] [])
                (.and (.atom "rel_bearing" [vSubject, vV2, .lit "right"] [])
                  (.and (sideBySide vV1) (sideBySide vV2)))))))))

/-- Obligation: s4 (obligation): between moving or stationary vehicles occupying adjacent traffic lanes. -/
def obligation : Formula :=
  .not (.existsUser "v1" (.existsUser "v2"
    (.existsRegion (.lit "lane") "l1" (.existsRegion (.lit "lane") "l2" between))))

def rule : Rule :=
  { id := "NRS_486_351_1"
    laws := ["NRS-486-351-1"]
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

end TrafficSpec.Rules.NRS_486_351_1
