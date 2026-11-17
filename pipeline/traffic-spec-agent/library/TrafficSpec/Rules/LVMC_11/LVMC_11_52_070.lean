/-
  LVMC_11_52_070 — LVMC-11-52-070

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (condition): The City Traffic Engineer shall determine upon what streets angle parking shall be permitted,
    t2 (condition): and shall provide signage or other markings to indicate where such parking is permitted.
    t3 (condition): Where angle parking is permitted,
    t4 (obligation): no person shall stand or park a vehicle unless the front of the vehicle is pointed toward the direction of lawful traffic movement.

  Elements (span → atoms, derived):
    t1: atoms ['dev.regulatory_sign', 'dev.governs', 'st.parking_space', 'rel.occupies', 'st.travel_region'], derived []
    t2: atoms ['dev.regulatory_sign', 'dev.governs', 'st.parking_space', 'rel.occupies', 'st.travel_region'], derived []
    t3: atoms ['dev.regulatory_sign', 'dev.governs', 'st.parking_space', 'rel.occupies', 'st.travel_region'], derived []
    t4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.heading', 'st.lane_direction', 'rel.occupies', 'st.travel_region', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.parked']

  How each span is written.
    subject: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, the admitted aggregate claimed whole.
    t1–t3 (the angle-parking place, read through its signage or markings, as the record's
      observable readings state): `angleParkingPlace r` — the subject occupies the travel region r
      (`existsRegion travel_region`, `rel_occupies`), and either some regulatory sign
      (`existsDevice regulatory_sign`) of code `angle_parking` (`dev_regulatory_sign_code`, the
      sign's code attribute) governs r (`dev_governs`), or the subject also occupies some parking
      space (`existsRegion parking_space`, `rel_occupies`) whose angle (`st_parking_space_angle`,
      the space's angle attribute) in absolute value exceeds p.parking_space_angle_resolution.
      The applicability is: some travel region r satisfies `angleParkingPlace r`.
    t4: `drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration)` implies that,
      for every travel region r satisfying the same whole selection `angleParkingPlace r` (rewritten
      in the obligation, 3c), the subject's heading (`kin_heading`, x and y) dotted with r's
      designated direction (`st_lane_direction`, x and y) is positive. "lawful traffic movement" —
      the traffic (DEF-NRS-484A-285::traffic, claimed whole) whose designated direction is read —
      is written as the subject's membership of that aggregate beside the direction test: the
      vehicle stands among the traffic whose lawful direction it must face. A vehicle is always
      traffic under the run's classification, so this conjunct never strengthens or weakens the
      duty; it carries the claimed word. A subject not parked complies (the implication).
      A region with no direction or an unobserved heading leaves the comparison unknown.

  No choice beyond the record's: the record states the selection, the quantifier (every selected
  region), the comparison (positive dot product) and the standing window; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_070

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingSpaceAngleResolution : Term := .param "p.parking_space_angle_resolution"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- t1/t2 "signage": a regulatory sign of code angle_parking governing the travel region `r`. -/
def angleParkingSign (r : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "angle_parking"] [])
          (.atom "dev_governs" [.var "d", .var r] []))

/-- t1/t2 "other markings": a parking space the subject occupies whose angle stands clear of zero. -/
def angledBayOccupied : Formula :=
  .existsRegion (.lit "parking_space") "s"
    (.and (.atom "rel_occupies" [vSubject, .var "s"] [])
          (.cmp (.abs (.measure "st_parking_space_angle" [.var "s"])) .gt pParkingSpaceAngleResolution))

/-- t3 "Where angle parking is permitted": the travel region `r` the subject occupies, indicated
    by the sign or the angled bay. -/
def angleParkingPlace (r : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
       (.or (angleParkingSign r) angledBayOccupied)

/-- Applicability: t1 (condition): The City Traffic Engineer shall determine upon what streets angle parking shall be permitted,; t2 (condition): and shall provide signage or other markings to indicate where such parking is permitted.; t3 (condition): Where angle parking is permitted, -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "r" (angleParkingPlace "r")

/-- "the front of the vehicle is pointed toward the direction of lawful traffic movement" on `r`:
    heading · designated direction > 0. -/
def frontTowardTraffic (r : String) : Formula :=
  .cmp (.add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [.var r, .lit "x"]))
             (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [.var r, .lit "y"])))
       .gt zeroRatio

/-- Obligation: t4 (obligation): no person shall stand or park a vehicle unless the front of the vehicle is pointed toward the direction of lawful traffic movement. -/
def obligation : Formula :=
  .implies (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration])
    (.and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
          (.forallRegion (.lit "travel_region") "r"
            (.implies (angleParkingPlace "r") (frontTowardTraffic "r"))))

def rule : Rule :=
  { id := "LVMC_11_52_070"
    laws := ["LVMC-11-52-070"]
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

end TrafficSpec.Rules.LVMC_11_52_070
