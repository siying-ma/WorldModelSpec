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

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_180_C_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    c1: the subject's class is the disjunction of the three admitted aggregates (ru_aggregate with
        the aggregate id). "upon a sidewalk": some region of kind `sidewalk` (st.sidewalk) that the
        subject occupies (rel_occupies). "riding": the record's observable reading — the subject
        is not at rest, `not drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
    c4: "any pedestrian" is the obligation's universal over the scene's road users `p`, other than
        the subject (`same`), that are members of DEF-NRS-484A-165::pedestrian. A scene with no
        pedestrian satisfies the universal vacuously (the record's "compliant").
    c2 + c3: for each such pedestrian, no contact (rel_contact) and no conflict: not
        (prim_closest_approach_within(subject, p; p.conflict_horizon) and
         prim_closest_approach_distance(subject, p; p.conflict_horizon) < p.conflict_centre_clearance).
        kin.speed is read through drv_motion_complete_halt (its body reads kin.speed).
  No choice beyond the record's own narrowings was made; `narrowings` stays empty.
-/

def vPed : Arg := .var "p"

def aggr (who : Arg) (id : String) : Formula := .atom "ru_aggregate" [who, .lit id] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (aggr vSubject "DEF-NRS-484A-025::bicycle")
    (.or (aggr vSubject "DEF-LVMC-11-02-082::electric_bicycle")
         (aggr vSubject "DEF-LVMC-11-02-083::electric_scooter"))

/-- c1: upon a sidewalk. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- c1: riding — the device is not at rest. -/
def riding : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- Applicability: c1 (trigger): Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk; c4 (condition): to any pedestrian -/
def applicability : Formula := .and onSidewalk riding

/-- c3: the pedestrian approaches so as to give rise to the danger of a crash. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vPed] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vPed] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- Obligation: c2 (obligation): such person shall yield; c3 (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "p"
    (.implies (.and (.not (.same vPed vSubject)) (aggr vPed "DEF-NRS-484A-165::pedestrian"))
      (.and (.not (.atom "rel_contact" [vSubject, vPed] []))
            (.not conflict)))

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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_180_C_o1
