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
    e1: binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    e2: `.asm "asm.business_or_residence_district"`.
    e3 (emerging only): a region d of kind `driveway_or_alley_entrance` or of kind `alley` (two
        region quantifiers, one per kind the record names) that the subject occupies now and has
        occupied at every observation since one at which it occupied d and not r:
        `occ(subject, d) ∧ since (occ(subject, d)) (occ(subject, d) ∧ ¬ occ(subject, r))`.
    e11: a region r of kind `roadway` that the subject occupies now.
    e14: every road user o, not the subject, that is a vehicle (`ru_aggregate`) and occupies the
        same r; 'approaching' is `prim_closest_approach_within` over the conflict horizon.
    e12/e13: not (subject speed > p.halt_speed_tolerance ∧ closest approach within the horizon ∧
        closest-approach centre distance < p.conflict_centre_clearance), and not rel_contact.
    The obligation restates the applicability's whole selection of r (roadway occupied by the
    subject from which it is emerging off a driveway-or-alley-entrance or alley region) and
    requires the duty at every such r.

  No choice beyond the record's own was needed: no narrowing of this session's.

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

def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- `x` occupies region `r`. -/
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- e3: the subject is emerging from region `d` onto region `r`: it occupies `d` now and has
    occupied it at every observation since one at which it occupied `d` and not `r`. -/
def emergingFrom (d r : String) : Formula :=
  .and (occ "subject" d)
    (.since (occ "subject" d) (.and (occ "subject" d) (.not (occ "subject" r))))

/-- e3 + e11: the subject occupies roadway region `r` and is emerging onto it from a
    driveway-or-alley-entrance region or an alley region. -/
def emergingOnto (r : String) : Formula :=
  .and (occ "subject" r)
    (.or (.existsRegion (.lit "driveway_or_alley_entrance") "d1" (emergingFrom "d1" r))
         (.existsRegion (.lit "alley") "d2" (emergingFrom "d2" r)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, vehicleAggregate] []

/-- Applicability: e2 (condition): within a business or residence district; e3 (condition): emerging or entering an alley, driveway or building; e11 (trigger): upon entering the roadway; e14 (condition): to all vehicles approaching on said roadway -/
def applicability : Formula :=
  .and (.asm "asm.business_or_residence_district")
    (.existsRegion (.lit "roadway") "r" (emergingOnto "r"))

/-- e12/e13: the subject does not proceed in preference to `o`: it is not moving above the halt
    tolerance while the constant-velocity closest approach of centres falls below the centre
    clearance within the horizon, and it does not touch `o`. -/
def yieldsTo (o : String) : Formula :=
  .and
    (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
      (.and (.derived "prim_closest_approach_within" [vSubject, .var o] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var o] [pConflictHorizon])
          .lt pConflictCentreClearance))))
    (.not (.atom "rel_contact" [vSubject, .var o] []))

/-- Obligation: e12 (obligation): shall yield; e13 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "r"
    (.implies (emergingOnto "r")
      (.forallUser "o"
        (.implies
          (.and (.not (.same (.var "o") vSubject))
            (.and (.atom "ru_aggregate" [.var "o", vehicleAggregate] []) (occ "o" "r")))
          (yieldsTo "o"))))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_20_060_o3
