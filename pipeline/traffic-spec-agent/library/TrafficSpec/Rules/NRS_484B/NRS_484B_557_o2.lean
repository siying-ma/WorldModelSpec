/-
  NRS_484B_557_o2 — NRS-484B-557

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The Department of Transportation, and local authorities with the approval of the Department of Transportation, may designate dangerous highway grade crossings of railroads
    s2 (condition): and erect official traffic-control devices at such crossings directing a stop.
    s3 (condition): When such stop signs are erected
    s4 (subject): the driver of any vehicle
    s5 (condition): shall stop within 50 feet but not less than 15 feet from the nearest track of such a grade crossing
    s7 (obligation): and afterward may proceed only
    s8 (standard): upon exercising due care.

  Elements (span → atoms, derived):
    s1: atoms ['st.railway_crossing', 'st.on_way', 'st.highway'], derived []
    s2: atoms ['dev.stop_sign'], derived []
    s3: atoms ['dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['st.region_geometry', 'rel.occupies', 'st.railway_crossing'], derived ['drv.motion.complete_halt']
    s7: atoms ['rel.occupies', 'st.railway_crossing'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 50 ft — 50 feet
    s5: 15 ft — 15 feet

  How each is written:
    s1: `existsRegion railway_crossing x`, `existsRegion highway h`, `st_on_way x h`.
    s2/s3: `existsRegion travel_region r` with `st_on_way r h` (same highway) and
        `existsDevice stop_sign d (dev_governs d r)`; `rel_occupies subject r` at the observation
        before the entry (the approach the subject came from).
    s4: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s5: `haltInBand` = complete_halt (p.halt_speed_tolerance) ∧ ¬occupies x ∧ 15 ft ≤ ground
        distance to x ≤ 50 ft; searched back with `since`: the stretch it runs through is off the
        crossing and within 50 ft, so it ends at the last observation farther than 50 ft or at the
        previous exit; `since` is unknown where the stretch reaches the trace start.
    s7: entry = occupies x now ∧ `rises (occX ∨ ¬(occR ∧ halted))`, i.e. at the previous
        observation off x, on r, with the halt found; `since occX entry` keeps the duty from the
        entry while the subject stays on x.
    s8: operationalization: for every road user v that is a rail vehicle, not (closest approach
        within p.conflict_horizon ∧ its centre distance < p.conflict_centre_clearance); for every
        road user u other than the subject (`same` excludes the subject's own body), no rel_contact.
  No choice beyond the record's reading was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_557_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's two figures of s5. -/
def upperFigure : Term := .lit (Units.feet 50) .metre
def lowerFigure : Term := .lit (Units.feet 15) .metre

def vX : Arg := .var "x"
def vH : Arg := .var "h"
def vR : Arg := .var "r"
def vD : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s7/s5: the subject's footprint overlaps the crossing `x`. -/
def occX : Formula := .atom "rel_occupies" [vSubject, vX] []
/-- s3: the subject's footprint overlaps the approach region `r`. -/
def occR : Formula := .atom "rel_occupies" [vSubject, vR] []
/-- s5: the ground distance from the subject's body to the crossing. -/
def distX : Term := .measure "st_region_geometry_distance" [vSubject, vX]

/-- s5: halted, off the crossing, between the lower and the upper figure from it. -/
def haltInBand : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])
    (.and (.not occX)
      (.and (.cmp distX .ge lowerFigure) (.cmp distX .le upperFigure)))

/-- s5 "afterward": searched back to the last observation farther than the upper figure or to
    the previous exit from the crossing (the stretch is off the crossing and within the upper
    figure), a halt in the band was observed; unknown where the stretch reaches the trace start. -/
def haltedOnApproach : Formula :=
  .since (.and (.not occX) (.cmp distX .le upperFigure)) haltInBand

/-- s7 "proceed": entry into the crossing — on it now, and at the previous observation off it, on
    the approach region `r`, with the halt behind (`rises` of a disjunction that is true now and
    whose negation is that previous state). -/
def entry : Formula :=
  .and occX (.rises (.or occX (.not (.and occR haltedOnApproach))))

/-- Applicability: s1 crossing on a highway; s2 a stop sign; s3 governing the approach region
    on the same highway; s5 the halt in the band; s7 from the entry while the subject stays on
    the crossing. -/
def applicability : Formula :=
  .existsRegion (.lit "railway_crossing") "x"
    (.existsRegion (.lit "highway") "h"
      (.and (.atom "st_on_way" [vX, vH] [])
        (.existsRegion (.lit "travel_region") "r"
          (.and (.atom "st_on_way" [vR, vH] [])
            (.and (.existsDevice (.lit "stop_sign") "d" (.atom "dev_governs" [vD, vR] []))
              (.since occX entry))))))

/-- Obligation (s8, surrogate): no rail vehicle closes on the subject within the horizon to a
    centre distance below the clearance, and the subject touches no other road user. -/
def obligation : Formula :=
  .and
    (.forallUser "v"
      (.implies (.atom "ru_rail_vehicle" [.var "v"] [])
        (.not (.and (.derived "prim_closest_approach_within" [vSubject, .var "v"] [pConflictHorizon])
          (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "v"] [pConflictHorizon])
            .lt pConflictCentreClearance)))))
    (.forallUser "u"
      (.implies (.not (.same vSubject (.var "u")))
        (.not (.atom "rel_contact" [vSubject, .var "u"] []))))

def rule : Rule :=
  { id := "NRS_484B_557_o2"
    laws := ["NRS-484B-557"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "due care"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact", "ru.rail_vehicle"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: proceeding across the crossing with due care is read by its outcome: from the entry and while the vehicle occupies the crossing, no rail vehicle (ru.rail_vehicle) approaches it within the conflict horizon (prim.closest_approach_within with p.conflict_horizon) to a centre distance below the collision clearance (prim.closest_approach_distance below p.conflict_centre_clearance), and the vehicle's body touches no road user (rel.contact)"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_557_o2
