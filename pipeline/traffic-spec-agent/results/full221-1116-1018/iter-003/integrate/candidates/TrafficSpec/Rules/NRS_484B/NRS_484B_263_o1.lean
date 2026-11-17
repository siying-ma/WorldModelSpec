/-
  NRS_484B_263_o1 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): The driver of a vehicle
    a2 (trigger): about to enter or exit a controlled-access highway
    a3 (obligation): shall yield the right-of-way
    a4 (condition): to all vehicles approaching on the highway
    a5 (standard): whose proximity constitutes an immediate hazard
    a6 (sibling): and shall continue to yield the right-of-way to that traffic
    a7 (sibling): until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a2: atoms ['rel.occupies', 'st.controlled_access', 'kin.speed'], derived []
    a3: atoms ['kin.speed', 'rel.contact'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'rel.bearing', 'kin.speed'], derived []

  How each is written:
    a1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    a2: the subject moves (`kin_speed subject > p.halt_speed_tolerance`) and some region `c` of kind
        `controlled_access` (st.controlled_access, read as the quantifier's kind) is entered
        (`rises (rel_occupies subject c)`) or exited (`rises (not (rel_occupies subject c))`) at
        this observation.
    a3/a4/a5: the obligation re-binds every such `c` with the same selection (the entry-or-exit
        rise), and for every other road user `v` that is of the vehicle aggregate, moves
        (`kin_speed v > p.halt_speed_tolerance`), occupies the same `c`, and has the subject ahead
        of it (`rel_bearing v subject "ahead"`, the positive longitudinal component), requires no
        contact (`rel_contact subject v`) and no closest-approach conflict
        (`prim_closest_approach_within subject v p.conflict_horizon` together with
        `prim_closest_approach_distance subject v p.conflict_horizon < p.conflict_centre_clearance`).
    a6/a7: siblings, not this node's.

  No choice beyond the record's was made: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- A road user `x` is of the vehicle aggregate. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, vehicleAggregate] []

/-- A road user `x` moves: its speed above the halt tolerance. -/
def moving (x : Arg) : Formula := .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- `x`'s footprint overlaps region `c`. -/
def occ (x : Arg) (c : Arg) : Formula := .atom "rel_occupies" [x, c] []

/-- The subject enters (overlap rises) or exits (non-overlap rises) region `c` at this observation. -/
def entryOrExit (c : Arg) : Formula :=
  .or (.rises (occ vSubject c)) (.rises (.not (occ vSubject c)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: a2 (trigger): about to enter or exit a controlled-access highway; a4 (condition): to all vehicles approaching on the highway -/
def applicability : Formula :=
  .and (moving vSubject)
    (.existsRegion (.lit "controlled_access") "c" (entryOrExit (.var "c")))

/-- a4: `v` is another vehicle, moving, on region `c`, with the subject ahead of it. -/
def approachingOn (v c : Arg) : Formula :=
  .and (.not (.same v vSubject))
    (.and (isVehicle v)
      (.and (moving v)
        (.and (occ v c)
          (.atom "rel_bearing" [v, vSubject, .lit "ahead"] []))))

/-- a3/a5: no contact, and no closest-approach conflict within the horizon below the clearance. -/
def yields (v : Arg) : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, v] []))
    (.not (.and (.derived "prim_closest_approach_within" [vSubject, v] [pConflictHorizon])
               (.cmp (.quantity "prim_closest_approach_distance" [vSubject, v] [pConflictHorizon])
                  .lt pConflictCentreClearance)))

/-- Obligation: a3 (obligation): shall yield the right-of-way; a5 (standard): whose proximity constitutes an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "c"
    (.implies (entryOrExit (.var "c"))
      (.forallUser "v"
        (.implies (approachingOn (.var "v") (.var "c")) (yields (.var "v")))))

def rule : Rule :=
  { id := "NRS_484B_263_o1"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proximity that constitutes an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: under constant velocities the two centres reach their closest approach within the time-to-collision threshold at a centre distance below the collision clearance; a vehicle so placed is an immediate hazard"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o1
