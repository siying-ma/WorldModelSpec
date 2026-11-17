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

  How each is written.
    b2/b4: the binder class `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    b3/b5: a region `r` of kind `roundabout` (st.roundabout, the quantifier's kind) that the subject
      enters: `rises (rel_occupies subject r)` — occupies r here and not at the observation before.
      Applicability: some such r.
    b8: a road user `v` of the scene that is a DEF-NRS-484A-320::vehicle and occupies r at the
      entry and at the observation before. "At the observation before" is written
      `occ(v,r) ∧ ¬ rises(occ(v,r))`, which, where occ(v,r) holds now, is exactly occ(v,r) at the
      previous observation. "Other than the subject" needs no conjunct of its own: the subject does
      not occupy r at the observation before its entry, so it never satisfies b8's selection.
    b6/b7: for each such v, the subject is not in contact with v (rel_contact), and it is not the
      case that prim_closest_approach_within(subject, v; p.conflict_horizon) holds with
      prim_closest_approach_distance(subject, v; p.conflict_horizon) < p.conflict_centre_clearance.
      Where the centres do not approach within the horizon, the conjunction is decided false by
      its first operand (the distance is then undefined).
    The obligation repeats the applicability's whole selection of r (kind roundabout, entered by
    the subject here) and states the duty at every r so selected.
    kin.speed (claimed on b6) is read by no formula: the node's obligation statement states the
    yield through rel.contact and the closest-approach primitives alone (which read kin.position
    and kin.velocity), and no reading of b6 that the obligation allows uses the speed.

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

/-- DEF-NRS-484A-320::vehicle membership of the road user bound to `x`. -/
def isVehicle (x : String) : Formula :=
  .atom "ru_aggregate" [.var x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- rel.occupies(x, r). -/
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- b5: the subject enters region r here: occupies it here and not at the observation before. -/
def entersR : Formula := .rises (occ "subject" "r")

/-- b8: v occupies r here and at the observation before. -/
def alreadyIn : Formula := .and (occ "v" "r") (.not (.rises (occ "v" "r")))

/-- b7: the right-of-way conflict, as the operationalization bounds it. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var "v"] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "v"] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- b6: yields to v — no contact and no conflict. -/
def yieldsTo : Formula := .and (.not (.atom "rel_contact" [vSubject, .var "v"] [])) (.not conflict)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle "subject"

/-- Applicability: b3 (condition): within a roundabout; b5 (trigger): entering a roundabout; b8 (condition): to vehicles already in the roundabout -/
def applicability : Formula := .existsRegion (.lit "roundabout") "r" entersR

/-- Obligation: b6 (obligation): shall yield; b7 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies entersR
      (.forallUser "v" (.implies (.and (isVehicle "v") alreadyIn) yieldsTo)))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_B_o1
