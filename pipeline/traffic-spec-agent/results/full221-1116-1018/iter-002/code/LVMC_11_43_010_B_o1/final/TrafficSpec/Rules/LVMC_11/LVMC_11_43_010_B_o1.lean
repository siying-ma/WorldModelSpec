/-
  LVMC_11_43_010_B_o1 — LVMC-11-43-010-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (boilerplate): The following regulations pertain to
    b2 (subject): the operation of vehicles
    b3 (condition): within a roundabout
    b4 (subject): The operator of a vehicle
    b5 (trigger): entering a roundabout
    b6 (obligation): shall yield
    b7 (standard): the right-of-way
    b8 (condition): to vehicles already in the roundabout
    b9 (sibling): and wait
    b10 (sibling): for a gap
    b11 (sibling): in traffic
    b12 (sibling): before entering

  Elements (span → atoms, derived):
    b2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b3: atoms ['rel.occupies', 'st.roundabout'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b5: atoms ['rel.occupies', 'st.roundabout'], derived []
    b6: atoms ['kin.speed', 'rel.contact'], derived []
    b8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roundabout'], derived []

  Writing:
    b2/b4: ru_aggregate(subject, "DEF-NRS-484A-320::vehicle") as the binder's class.
    b3/b5: applicability = some roundabout region r with rises(rel_occupies(subject, r)):
           occupied here, not at the observation before.
    b8:    in the obligation, for every road user v ≠ subject with ru_aggregate(v, vehicle) and
           rel_occupies(v, r) here and not newly (¬rises), i.e. also at the observation before.
           r is re-selected in the obligation exactly as in the applicability (every roundabout
           the subject enters here).
    b6/b7: ¬rel_contact(subject, v) ∧ ¬(prim_closest_approach_within(subject, v; h) ∧
           prim_closest_approach_distance(subject, v; h) < clearance).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_B_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate of b2/b4/b8. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Membership of a road user in DEF-NRS-484A-320::vehicle. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, aggVehicle] []

/-- rel.occupies(x, r). -/
def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- b5: the subject enters r — it occupies r here and not at the observation before. -/
def enters (r : Arg) : Formula := .rises (occ vSubject r)

/-- b8: v is already in r — it occupies r here and at the observation before (here, occupying
    and not newly occupying). -/
def alreadyIn (v r : Arg) : Formula := .and (occ v r) (.not (.rises (occ v r)))

/-- b7: the right-of-way standard — v approaches the subject's centre within the conflict
    clearance within the conflict horizon (traffic-conflict technique). -/
def inConflict (v : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, v] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, v] [pConflictHorizon]) .lt
             pConflictCentreClearance)

/-- b6: yielding to v — no contact and no conflict with it. -/
def yieldsTo (v : Arg) : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, v] [])) (.not (inConflict v))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: b3 (condition): within a roundabout; b5 (trigger): entering a roundabout -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" (enters (.var "r"))

/-- Obligation: b6 (obligation): shall yield; b7 (standard): the right-of-way; b8 (condition):
    to vehicles already in the roundabout. The region r is re-selected exactly as in the
    applicability (a roundabout the subject enters here), and the duty holds at every such r. -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies (enters (.var "r"))
      (.forallUser "v"
        (.implies
          (.and (.not (.same (.var "v") vSubject))
            (.and (isVehicle (.var "v")) (alreadyIn (.var "v") (.var "r"))))
          (yieldsTo (.var "v")))))

def rule : Rule :=
  { id := "LVMC_11_43_010_B_o1"
    laws := ["LVMC-11-43-010-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: preference over another approaching 'under such circumstances of direction, speed and proximity as to give rise to the danger of a crash' (DEF-NRS-484A-210)"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a circulating vehicle whose centre comes, under constant velocities, within the conflict clearance of the entering vehicle's centre within the conflict horizon is approaching so as to give rise to the danger of a crash"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_B_o1
