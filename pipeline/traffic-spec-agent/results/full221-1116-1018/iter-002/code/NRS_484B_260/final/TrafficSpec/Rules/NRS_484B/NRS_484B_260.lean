/-
  NRS_484B_260 — NRS-484B-260

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): about to enter or cross a highway
    s3 (condition): from a private way
    s4 (obligation): shall yield
    s5 (standard): the right-of-way
    s6 (condition): to all vehicles approaching on such highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.roadway', 'st.on_way', 'st.highway', 'kin.speed'], derived []
    s3: atoms ['st.driveway_or_alley_entrance', 'st.alley', 'rel.occupies'], derived []
    s4: atoms ['kin.speed', 'rel.contact'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.travel_region', 'st.on_way', 'st.highway', 'rel.bearing', 'kin.speed'], derived []

  How each is written:
    s1: the binder class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s2/s3: the applicability: the subject moving (kin_speed > p.halt_speed_tolerance), overlapping no
      `alley` region, and some `highway` h, `roadway` r with `st_on_way r h`, and
      `driveway_or_alley_entrance` e such that the subject overlaps r and e and `since` (overlap of e)
      (overlap of e and not of r): it came onto the entrance from off the roadway.
    s6: v ranges over every road user other than the subject (`same` excludes it), of the vehicle
      aggregate, moving, overlapping some `travel_region` t with `st_on_way t h`, and with the subject
      ahead of it (`rel_bearing v subject ahead`, the positive longitudinal component).
    s4/s5: no `rel_contact`, and not (`prim_closest_approach_within` over p.conflict_horizon and
      `prim_closest_approach_distance` below p.conflict_centre_clearance).
    The obligation re-binds the applicability's whole selection (h, r, e) with `forallRegion` and the
    same `selection` formula, as the record says "for every selection".
  No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_260

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vH : Arg := .var "h"
def vR : Arg := .var "r"
def vE : Arg := .var "e"
def vA : Arg := .var "a"
def vV : Arg := .var "v"
def vT : Arg := .var "t"

def vehicleAgg : Arg := .lit "DEF-NRS-484A-320::vehicle"

def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- A road user moving: kin.speed above the halt tolerance (s2, s4, s6). -/
def moving (x : Arg) : Formula := .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle (s1). -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, vehicleAgg] []

/-- The selection of h (highway), r (roadway on h) and e (entrance) at this observation (s2, s3):
    the subject overlaps r and e, and its overlap with e has held since an observation at which it
    overlapped e and not r. Written once and used in both formulas, so the obligation re-binds the
    applicability's whole selection. -/
def selection : Formula :=
  .and (.atom "st_on_way" [vR, vH] [])
    (.and (occ vSubject vR)
      (.and (occ vSubject vE)
        (.since (occ vSubject vE) (.and (occ vSubject vE) (.not (occ vSubject vR))))))

/-- s3: the subject overlaps no alley (an alley is a highway, not a private way). -/
def noAlley : Formula := .not (.existsRegion (.lit "alley") "a" (occ vSubject vA))

/-- Applicability: s2 (trigger): about to enter or cross a highway; s3 (condition): from a private way. -/
def applicability : Formula :=
  .and (moving vSubject)
    (.and noAlley
      (.existsRegion (.lit "highway") "h"
        (.existsRegion (.lit "roadway") "r"
          (.existsRegion (.lit "driveway_or_alley_entrance") "e" selection))))

/-- s6: v is another vehicle, moving, on a travel region lying on h, with the subject ahead of it. -/
def approaching : Formula :=
  .and (.not (.same vV vSubject))
    (.and (.atom "ru_aggregate" [vV, vehicleAgg] [])
      (.and (moving vV)
        (.and (.existsRegion (.lit "travel_region") "t"
                (.and (occ vV vT) (.atom "st_on_way" [vT, vH] [])))
          (.atom "rel_bearing" [vV, vSubject, .lit "ahead"] []))))

/-- s4/s5: no contact, and no closest approach within the horizon below the clearance. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vV] []))
    (.not (.and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
                (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon])
                      .lt pConflictCentreClearance)))

/-- Obligation: s4 (obligation): shall yield; s5 (standard): the right-of-way; s6: to all vehicles
    approaching on such highway — for every selection (h, r, e), every approaching vehicle. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.forallRegion (.lit "roadway") "r"
      (.forallRegion (.lit "driveway_or_alley_entrance") "e"
        (.implies selection
          (.forallUser "v" (.implies approaching yields)))))

def rule : Rule :=
  { id := "NRS_484B_260"
    laws := ["NRS-484B-260"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: under constant velocities (direction and speed of both), the two centres reach their closest approach within the time-to-collision threshold at a centre distance below the collision clearance; such a pair is in danger of a crash unless the subject grants precedence"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_260
