/-
  NRS_484B_440_1_o2 — NRS-484B-440-1

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
    e8 (obligation): but in every event an unobstructed width of the highway opposite a standing vehicle shall be left
    e9 (standard): for the free passage of other vehicles
    e10 (sibling): and a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    e11 (exception): This section shall not apply to the driver of any vehicle which is disabled
    e12 (exception): while on the paved or main-traveled portion of a highway
    e13 (exception): in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position.

  Elements (span → atoms, derived):
    e1: atoms ['rel.occupies', 'st.highway'], derived []
    e4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e6: atoms ['rel.occupies', 'st.roadway', 'st.on_way'], derived []
    e8: atoms ['st.lane', 'st.on_way', 'rel.occupies', 'rel.longitudinal_overlap'], derived ['drv.motion.stopped']
    e12: atoms ['rel.occupies', 'st.roadway'], derived []

  How each is written:
    e4: the class of x, ru_aggregate with the aggregate id DEF-NRS-484A-320::vehicle.
    e1, e6: x occupies a highway h and a roadway rw with st_on_way(rw, h); this selection is
      written once (`onPavedPartOf`) and opens both the applicability and the obligation, so the
      lane of the obligation lies on the same highway.
    e2: not asm.business_or_residence_district.
    e5: residue (attended or unattended alike); nothing is read.
    e8: x halted (drv.motion.stopped at p.motion_speed_tolerance) in the applicability; in the
      obligation some lane l with st_on_way(l, h), not occupied by x, which no road user that is
      halted occupies with a longitudinal overlap with x not negative. x itself never counts, as it
      does not occupy l, so no `same` is needed.
    e9: st_lane_width(l) ≥ p.free_passage_width (the node's operationalization).
    e11–e13: the exception asm.vehicle_disabled ∧ x occupies a roadway ∧ asm.disabled_vehicle_immovable,
      negated in the applicability.
  No choice beyond the record's own narrowing was made, so `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_440_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFreePassageWidth : Term := .param "p.free_passage_width"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e8: a road user halted (the standing of DEF-NRS-484A-250), at the speed resolution. -/
def stopped (who : Arg) : Formula := .derived "drv_motion_stopped" [who] [pMotionSpeedTolerance]

/-- e1, e6: x occupies a highway `h` and a roadway lying on it; the same selection opens the
    applicability and the obligation, so both speak of the same highway. -/
def onPavedPartOf (h : String) (body : Formula) : Formula :=
  .existsRegion (.lit "highway") h
    (.and (.atom "rel_occupies" [vX, .var h] [])
      (.and (.existsRegion (.lit "roadway") "rw"
               (.and (.atom "st_on_way" [.var "rw", .var h] [])
                     (.atom "rel_occupies" [vX, .var "rw"] [])))
            body))

/-- e11–e13: x disabled, on the roadway, and immovable from where it stands. -/
def disabledException : Formula :=
  .and (.asm "asm.vehicle_disabled")
    (.and (.existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] []))
          (.asm "asm.disabled_vehicle_immovable"))

/-- Applicability: e1 (trigger): Upon any highway; e2 (condition): outside of a business or residence district; e5 (condition): whether attended or unattended,; e6 (condition): upon the paved or main-traveled part of the highway; e11 (exception): This section shall not apply to the driver of any vehicle which is disabled; e12 (exception): while on the paved or main-traveled portion of a highway; e13 (exception): in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position. -/
def applicability : Formula :=
  .and (onPavedPartOf "h" .tt)
    (.and (.not (.asm "asm.business_or_residence_district"))
      (.and (stopped vX)
            (.not disabledException)))

/-- e8: no other halted road user occupies lane `l` alongside x (overlap along x's heading not negative). -/
def unobstructedAlongside (l : String) : Formula :=
  .forallUser "y"
    (.not (.and (stopped (.var "y"))
            (.and (.atom "rel_occupies" [.var "y", .var l] [])
                  (.cmp (.measure "rel_longitudinal_overlap" [vX, .var "y"]) .ge zeroMetres))))

/-- Obligation: e8 (obligation): but in every event an unobstructed width of the highway opposite a standing vehicle shall be left; e9 (standard): for the free passage of other vehicles -/
def obligation : Formula :=
  onPavedPartOf "h"
    (.existsRegion (.lit "lane") "l"
      (.and (.atom "st_on_way" [.var "l", .var "h"] [])
        (.and (.not (.atom "rel_occupies" [vX, .var "l"] []))
          (.and (.cmp (.measure "st_lane_width" [.var "l"]) .ge pFreePassageWidth)
                (unobstructedAlongside "l")))))

def rule : Rule :=
  { id := "NRS_484B_440_1_o2"
    laws := ["NRS-484B-440-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district", "asm.vehicle_disabled", "asm.disabled_vehicle_immovable"]
    intentions := []
    operationalizations :=
      [ { standard := "free passage of other vehicles"
          concepts := ["st.lane_width"]
          params := ["p.free_passage_width"]
          convention := "Free passage of other vehicles is read through the width of the lane left opposite the standing vehicle: st.lane_width ('width of a lane at a point') at least the width a design vehicle needs to pass, so the measured width enters the bound."
          surrogate := false } ]
    residues := ["Attended or unattended, the duty is the same: the words name both cases and exclude neither."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_440_1_o2
