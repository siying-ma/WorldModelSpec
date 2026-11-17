/-
  LVMC_11_40_180_C_o1 — LVMC-11-40-180-C

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk
    c2 (obligation): such person shall yield
    c3 (standard): the right-of-way
    c4 (condition): to any pedestrian
    c5 (sibling): and shall give audible signal
    c6 (sibling): before overtaking and passing
    c7 (sibling): such pedestrian

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle', 'ru.aggregate=DEF-LVMC-11-02-083::electric_scooter', 'rel.occupies', 'st.sidewalk'], derived ['drv.motion.complete_halt']
    c2: atoms ['kin.speed', 'rel.contact'], derived []
    c4: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each is written:
    c1  The subject's class is the disjunction of the three admitted aggregates (ru_aggregate with
        each aggregate id, never expanded). "upon a sidewalk": some region of kind `sidewalk`
        (st.sidewalk, through the quantifier's kind) that the subject occupies (rel_occupies,
        which anchors the region to the subject). "riding": the record's observable reading,
        the subject is not at rest — `not drv_motion_complete_halt(subject; p.halt_speed_tolerance)`
        (the concept reads kin.speed).
    c4  "any pedestrian": every road user p of the scene other than the subject (`same` excludes
        the subject) that is a member of DEF-NRS-484A-165::pedestrian; a scene with no
        pedestrian makes the universal true (compliant), as the record states.
    c2/c3  For each such p: no contact (rel_contact(subject, p)), and not (closest approach of the
        centres within p.conflict_horizon and the centre distance at it below
        p.conflict_centre_clearance) — the record's operationalization verbatim. The
        undefined distance (no approach within the horizon) is guarded by the conjunction with
        `prim_closest_approach_within`, which is then false.
    c5–c7 are siblings: not this node.

  Choices the record left open: none beyond the record's own narrowings (c1 observable reading,
  c2 reading), which are on the record and not restated here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_180_C_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The pedestrian quantified over in the obligation. -/
def vPed : Arg := .var "ped"

/-- The sidewalk region quantified over in the applicability. -/
def vSidewalk : Arg := .var "sw"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of an admitted aggregate. -/
def member (x : Arg) (aggId : String) : Formula :=
  .atom "ru_aggregate" [x, .lit aggId] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (member vSubject "DEF-NRS-484A-025::bicycle")
    (.or (member vSubject "DEF-LVMC-11-02-082::electric_bicycle")
         (member vSubject "DEF-LVMC-11-02-083::electric_scooter"))

/-- c1: the subject occupies a sidewalk. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "sw" (.atom "rel_occupies" [vSubject, vSidewalk] [])

/-- c1 ("riding", the record's observable reading): the subject is not at rest. -/
def riding : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- Applicability: c1 (trigger): Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk; c4 (condition): to any pedestrian -/
def applicability : Formula := .and onSidewalk riding

/-- c3: the pedestrian approaches so as to give rise to the danger of a crash. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vPed] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vPed] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- c2/c3: the subject yields to `ped`: no collision and no conflict. -/
def yieldsTo : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vPed] [])) (.not conflict)

/-- Obligation: c2 (obligation): such person shall yield; c3 (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "ped"
    (.implies (.and (.not (.same vPed vSubject)) (member vPed "DEF-NRS-484A-165::pedestrian"))
              yieldsTo)

def rule : Rule :=
  { id := "LVMC_11_40_180_C_o1"
    laws := ["LVMC-11-40-180-C"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: preference over another approaching 'under such circumstances of direction, speed and proximity as to give rise to the danger of a crash' (DEF-NRS-484A-210)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: a pedestrian whose centre comes, under constant velocities, within the conflict clearance of the moving subject's centre within the conflict horizon is approaching so as to give rise to the danger of a crash"
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_180_C_o1
