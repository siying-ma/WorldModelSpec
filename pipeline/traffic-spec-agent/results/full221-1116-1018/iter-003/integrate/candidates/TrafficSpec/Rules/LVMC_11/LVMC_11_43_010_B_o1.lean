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
    b6: atoms ['rel.contact'], derived []
    b8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roundabout'], derived []

  How each is written:
    b2, b4: the subject's class, `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (the record's
      observable reading of 'the operator' is the plan's, not restated).
    b3, b5: `existsRegion roundabout r (rises (rel_occupies subject r))` — the subject occupies a
      roundabout region at the judged observation and did not at the one before (the record's
      applicability, verbatim).
    b8: in the obligation, as the record places it ("an entry with no such vehicle is compliant"):
      every road user v other than the subject (`same`), of the aggregate, occupying r at the entry
      and at the observation before. "At the observation before" is written as
      `rel_occupies v r ∧ ¬ rises (rel_occupies v r)`: occupied now and not newly occupied, which is
      exactly occupied at the previous observation. The region r is the record's whole selection
      again (every roundabout region the subject enters at this observation), quantified for every
      such region as the record states.
    b6: `¬ rel_contact subject v`.
    b7: `¬ (prim_closest_approach_within subject v h ∧ prim_closest_approach_distance subject v h
      < p.conflict_centre_clearance)`, h = p.conflict_horizon, as the operationalization states.

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

def vRegion : Arg := .var "r"
def vOther : Arg := .var "v"

/-- Membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- b5: the subject enters region r here (occupies it now, not at the observation before). -/
def entersR : Formula := .rises (.atom "rel_occupies" [vSubject, vRegion] [])

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: b3 (condition): within a roundabout; b5 (trigger): entering a roundabout -/
def applicability : Formula := .existsRegion (.lit "roundabout") "r" entersR

/-- b8: v is another vehicle already in r: it occupies r at the entry and at the observation before. -/
def alreadyIn : Formula :=
  .and (.not (.same vOther vSubject))
    (.and (isVehicle vOther)
      (.and (.atom "rel_occupies" [vOther, vRegion] [])
        (.not (.rises (.atom "rel_occupies" [vOther, vRegion] [])))))

/-- b6 + b7: no contact with v, and no conflict (closest approach within the horizon and below the
    clearance). -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vOther] []))
    (.not (.and (.derived "prim_closest_approach_within" [vSubject, vOther] [pConflictHorizon])
               (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pConflictHorizon])
                  .lt pConflictCentreClearance)))

/-- Obligation: b6 (obligation): shall yield; b7 (standard): the right-of-way; b8 (condition): to
    vehicles already in the roundabout -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies entersR (.forallUser "v" (.implies alreadyIn yields)))

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
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_B_o1
