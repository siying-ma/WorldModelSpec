/-
  NRS_484B_263_o1 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): about to enter or exit a controlled-access highway
    s3 (obligation): shall yield the right-of-way
    s4 (condition): to all vehicles approaching on the highway
    s5 (standard): whose proximity constitutes an immediate hazard
    s6 (sibling): and shall continue to yield the right-of-way
    s7 (sibling): to that traffic
    s8 (sibling): until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.controlled_access', 'rel.occupies'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region']
    s3: atoms ['rel.occupies'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'kin.speed'], derived ['drv.motion.moving']

  How each span is written:
    s1: the binder class, ru_aggregate x "DEF-NRS-484A-320::vehicle".
    s2: some region a of kind controlled_access that x enters (drv_motion_entering_region x a) or
        leaves (drv_motion_leaving_region x a) at this observation; both concepts read rel.occupies.
    s3: the yield is judged at that entry or exit (the record's own narrowing): the obligation
        restates the selection — every controlled_access region a that x enters or leaves here —
        and requires that no hazard vehicle of s4/s5 exists on it.
    s4: y ranges over the scene's road users other than x (not same y x), is in the aggregate,
        occupies a (rel_occupies y a) and is moving (drv_motion_moving y with p.speed_resolution).
    s5: the operationalization: prim_closest_approach_within x y with horizon
        p.immediate_hazard_gap, and prim_closest_approach_distance x y with the same horizon below
        p.conflict_clearance.
    s6-s8: siblings, not this node's.
  No choice beyond the record's was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1, s4: membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def isVehicle (v : Arg) : Formula :=
  .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: x enters or leaves the controlled-access region `a` at this observation. -/
def entersOrExits (a : Arg) : Formula :=
  .or (.derived "drv_motion_entering_region" [vX, a] [])
      (.derived "drv_motion_leaving_region" [vX, a] [])

/-- s4, s5: y, a vehicle other than x on the controlled-access region `a`, moving, and predicted
    (constant velocities) to come within p.conflict_clearance of x within p.immediate_hazard_gap. -/
def hazardOn (a : Arg) : Formula :=
  let vY : Arg := .var "y"
  .and (.not (.same vY vX))
    (.and (isVehicle vY)
      (.and (.atom "rel_occupies" [vY, a] [])
        (.and (.derived "drv_motion_moving" [vY] [pSpeedResolution])
          (.and (.derived "prim_closest_approach_within" [vX, vY] [pImmediateHazardGap])
            (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pImmediateHazardGap])
              .lt pConflictClearance)))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := isVehicle vX

/-- Applicability: s2 (trigger): about to enter or exit a controlled-access highway; s4 (condition): to all vehicles approaching on the highway -/
def applicability : Formula :=
  .existsRegion (.lit "controlled_access") "a" (entersOrExits (.var "a"))

/-- Obligation: s3 (obligation): shall yield the right-of-way; s5 (standard): whose proximity constitutes an immediate hazard.
    At every controlled-access region x enters or leaves here (the applicability's selection,
    restated), no approaching vehicle on it is an immediate hazard. -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "a"
    (.implies (entersOrExits (.var "a"))
      (.not (.existsUser "y" (hazardOn (.var "a")))))

def rule : Rule :=
  { id := "NRS_484B_263_o1"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proximity that constitutes an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.immediate_hazard_gap", "p.conflict_clearance"]
          convention := "Surrogate safety conflict (FHWA SSAM; critical gap as the horizon): y's centre is predicted, under constant velocities, to come within p.conflict_clearance of x's within p.immediate_hazard_gap. The primitives alone are not a stand-in for contact or the danger of a crash; the bound is the standard's."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o1
