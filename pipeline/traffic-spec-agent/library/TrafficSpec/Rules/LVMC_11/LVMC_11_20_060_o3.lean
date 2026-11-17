/-
  LVMC_11_20_060_o3 — LVMC-11-20-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): The driver of a vehicle
    e2 (condition): within a business or residence district
    e3 (condition): emerging or entering an alley, driveway or building
    e4 (sibling): shall stop such vehicle immediately prior to
    e5 (sibling): driving onto a sidewalk or onto the sidewalk area extending across any alleyway or driveway
    e6 (sibling): yielding
    e7 (sibling): the right-of-way
    e8 (sibling): to any pedestrian
    e9 (sibling): as may be necessary to avoid collision
    e10 (boilerplate): and
    e11 (trigger): upon entering the roadway
    e12 (obligation): shall yield
    e13 (standard): the right-of-way
    e14 (condition): to all vehicles approaching on said roadway

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e3: atoms ['st.driveway_or_alley_entrance', 'st.alley', 'rel.occupies'], derived []
    e11: atoms ['st.roadway', 'rel.occupies'], derived []
    e12: atoms ['kin.speed', 'rel.contact'], derived []
    e14: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roadway', 'prim.closest_approach_within'], derived []

  How each is written:
    e1: binder class ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    e2: the declared assumption asm.business_or_residence_district.
    e3 + e11: for some roadway region r: rel_occupies(subject, r), and for some region d of kind
      driveway_or_alley_entrance or of kind alley: rel_occupies(subject, d) holding at every
      observation since one at which rel_occupies(subject, d) and not rel_occupies(subject, r)
      (`since`). The obligation re-selects r (and d) with the same formula (`emergingOnto`) and
      states the duty for every such r.
    e14: every road user o, not the subject, with ru_aggregate(o, vehicle) and rel_occupies(o, r).
    e12/e13: not (kin_speed(subject) > p.halt_speed_tolerance and prim_closest_approach_within
      (subject, o; p.conflict_horizon) and prim_closest_approach_distance(subject, o;
      p.conflict_horizon) < p.conflict_centre_clearance), and not rel_contact(subject, o).
  No choice beyond the record's own narrowings was made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_20_060_o3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate `vehicle` (DEF-NRS-484A-320). -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

def vR : Arg := .var "r"
def vD : Arg := .var "d"
def vO : Arg := .var "o"

def occupies (x y : Arg) : Formula := .atom "rel_occupies" [x, y] []

/-- e3 (emerging) for one region `d` of the driveway/alley kinds and the roadway `r`: the subject
    occupies `d` now and has at every observation since one at which it occupied `d` and not `r`. -/
def emergingFrom : Formula :=
  .and (occupies vSubject vD)
    (.since (occupies vSubject vD)
      (.and (occupies vSubject vD) (.not (occupies vSubject vR))))

/-- e3 + e11: the subject's footprint overlaps the roadway `r` (entering it) while it is emerging
    from a driveway-or-alley-entrance region or an alley region `d`. -/
def emergingOnto : Formula :=
  .and (occupies vSubject vR)
    (.or (.existsRegion (.lit "driveway_or_alley_entrance") "d" emergingFrom)
         (.existsRegion (.lit "alley") "d" emergingFrom))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- Applicability: e2 (condition): within a business or residence district; e3 (condition): emerging or entering an alley, driveway or building; e11 (trigger): upon entering the roadway; e14 (condition): to all vehicles approaching on said roadway -/
def applicability : Formula :=
  .and (.asm "asm.business_or_residence_district")
    (.existsRegion (.lit "roadway") "r" emergingOnto)

/-- e14: `o` is a vehicle, other than the subject, on the same roadway `r`. -/
def vehicleOnSaidRoadway : Formula :=
  .and (.not (.same vO vSubject))
    (.and (.atom "ru_aggregate" [vO, aggVehicle] [])
      (occupies vO vR))

/-- e13 (standard, operationalized): the subject proceeds (speed above the resolution) while the
    constant-velocity closest approach of the centres within the horizon falls below the clearance. -/
def proceedsIntoConflict : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.derived "prim_closest_approach_within" [vSubject, vO] [pConflictHorizon])
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vO] [pConflictHorizon])
        .lt pConflictCentreClearance))

/-- Obligation: e12 (obligation): shall yield; e13 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "r"
    (.implies emergingOnto
      (.forallUser "o"
        (.implies vehicleOnSaidRoadway
          (.and (.not proceedsIntoConflict)
                (.not (.atom "rel_contact" [vSubject, vO] []))))))

def rule : Rule :=
  { id := "LVMC_11_20_060_o3"
    laws := ["LVMC-11-20-060"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district"]
    intentions := []
    operationalizations :=
      [ { standard := "right-of-way: DEF-NRS-484A-210 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: danger of a crash where the constant-velocity closest approach of centres is below a centre clearance within a time-to-collision horizon; a road user at or below the speed resolution has granted precedence"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_20_060_o3
