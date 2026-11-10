/-
  NRS_484B_440_1_o3 — NRS-484B-440-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (trigger): Upon any highway
    e2 (condition): outside of a business or residence district
    e3 (sibling): no person shall stop, park or leave standing
    e4 (subject): any vehicle,
    e5 (condition): whether attended or unattended,
    e6 (condition): upon the paved or main-traveled part of the highway
    e7 (sibling): when it is practicable to stop, park or so leave such vehicle off such part of the highway,
    e8 (sibling): but in every event an unobstructed width of the highway opposite a standing vehicle shall be left
    e9 (sibling): for the free passage of other vehicles
    e10 (obligation): and a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    e11 (exception): This section shall not apply to the driver of any vehicle which is disabled
    e12 (exception): while on the paved or main-traveled portion of a highway
    e13 (exception): in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position.

  Elements (span → atoms, derived):
    e1: atoms ['rel.occupies', 'st.highway'], derived []
    e4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e6: atoms ['rel.occupies', 'st.roadway', 'st.on_way'], derived []
    e10: atoms ['st.sight_distance'], derived ['drv.motion.stopped']
    e12: atoms ['rel.occupies', 'st.roadway'], derived []

  Literals the text states (each written through its Units constructor):
    e10: 200 ft — 200 feet

  How each span is written:
    e4: binder class, ru_aggregate x "DEF-NRS-484A-320::vehicle".
    e1 + e6: some highway h and some roadway rw with x occupying both and st_on_way(rw, h).
    e2: not asm.business_or_residence_district.
    e5: residue (both cases, no condition).
    e10: x halted (drv_motion_stopped, tol p.motion_speed_tolerance) is applicability;
      the obligation re-selects every (h, rw) pair of the e1/e6 selection and requires
      st_sight_distance(rw) ≥ 200 ft.
    e11–e13: exception, not (asm.vehicle_disabled ∧ x occupies some roadway (e12)
      ∧ asm.disabled_vehicle_immovable).

  Choice the text left open (declared as a narrowing on e10): "x's place" is the roadway region
  x occupies, and its recorded sight distance is the one read; where x occupies several roadways
  of the selection, each must meet the figure.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_440_1_o3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- e10: the law's literal, 200 feet. -/
def clearViewDistance : Term := .lit (Units.feet 200) .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e1 + e6: x occupies the highway `h` and the roadway `rw` lying on it. -/
def onRoadwayOfHighway (h rw : String) : Formula :=
  .and (.atom "rel_occupies" [vX, .var h] [])
    (.and (.atom "rel_occupies" [vX, .var rw] [])
      (.atom "st_on_way" [.var rw, .var h] []))

/-- e1 (trigger) + e6 (condition): some highway and a roadway on it, both occupied by x. -/
def upon : Formula :=
  .existsRegion (.lit "highway") "h"
    (.existsRegion (.lit "roadway") "rw" (onRoadwayOfHighway "h" "rw"))

/-- e10's "such stopped vehicles": x halted, through drv.motion.stopped. -/
def halted : Formula := .derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance]

/-- e11–e13 (exception): x disabled, on a roadway, and its vehicle immovable. -/
def disabledException : Formula :=
  .and (.asm "asm.vehicle_disabled")
    (.and (.existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] []))
      (.asm "asm.disabled_vehicle_immovable"))

/-- Applicability: e1 (trigger): Upon any highway; e2 (condition): outside of a business or residence district; e5 (condition): whether attended or unattended,; e6 (condition): upon the paved or main-traveled part of the highway; e11 (exception): This section shall not apply to the driver of any vehicle which is disabled; e12 (exception): while on the paved or main-traveled portion of a highway; e13 (exception): in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position. -/
def applicability : Formula :=
  .and upon
    (.and (.not (.asm "asm.business_or_residence_district"))
      (.and halted (.not disabledException)))

/-- Obligation: e10 (obligation): and a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    At every roadway x stands on (selected again as in the applicability), the sight distance the
    source records for it is at least 200 ft. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.forallRegion (.lit "roadway") "rw"
      (.implies (onRoadwayOfHighway "h" "rw")
        (.cmp (.measure "st_sight_distance" [.var "rw"]) .ge clearViewDistance)))

def rule : Rule :=
  { id := "NRS_484B_440_1_o3"
    laws := ["NRS-484B-440-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district", "asm.vehicle_disabled", "asm.disabled_vehicle_immovable"]
    intentions := []
    operationalizations := []
    residues := ["Attended or unattended, the duty is the same: the words name both cases and exclude neither."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "e10"
          why := "x's place is read as each roadway x occupies on the highway it occupies (the e1/e6 selection repeated): the sight distance the source records for that roadway region must be at least 200 ft, for every such roadway."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_440_1_o3
