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
    subject class: the disjunction of the three admitted aggregates, by id (`ru_aggregate`); an
      electric scooter's membership stays as the run's reading leaves it (unknown).
    c1 'upon a sidewalk': some region of kind `sidewalk` that the subject occupies (`rel_occupies`).
    c1 'riding': not `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` (reads kin.speed);
      the node's own observable reading.
    c4 'to any pedestrian': every road user other than the subject (`same`) that is a member of
      DEF-NRS-484A-165::pedestrian — written in the obligation as the record places it.
    c2/c3 'shall yield the right-of-way': for each such pedestrian, no `rel_contact` with the
      subject, and not (`prim_closest_approach_within(subject, ped; p.conflict_horizon)` and
      `prim_closest_approach_distance(subject, ped; p.conflict_horizon)` < p.conflict_centre_clearance).
      A scene with no pedestrian is compliant (the universal holds vacuously).
  No reading of mine beyond the record's: no narrowings declared.

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

/-- Membership of an admitted aggregate, by its id. -/
def inAggregate (x : Arg) (id : String) : Formula := .atom "ru_aggregate" [x, .lit id] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (inAggregate vSubject "DEF-NRS-484A-025::bicycle")
    (.or (inAggregate vSubject "DEF-LVMC-11-02-082::electric_bicycle")
      (inAggregate vSubject "DEF-LVMC-11-02-083::electric_scooter"))

/-- c1 'upon a sidewalk': the subject occupies some st.sidewalk region. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "sw" (.atom "rel_occupies" [vSubject, .var "sw"] [])

/-- c1 'riding': the device is not at rest (drv.motion.complete_halt, read through kin.speed). -/
def riding : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- Applicability: c1 (trigger): Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk; c4 (condition): to any pedestrian -/
def applicability : Formula := .and onSidewalk riding

/-- c3: the pedestrian's centre comes, under constant velocities, within the conflict clearance of
    the subject's centre within the conflict horizon. -/
def inConflict (p : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, p] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, p] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- Obligation: c2 (obligation): such person shall yield; c3 (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "ped"
    (.implies
      (.and (.not (.same (.var "ped") vSubject)) (inAggregate (.var "ped") "DEF-NRS-484A-165::pedestrian"))
      (.and (.not (.atom "rel_contact" [vSubject, .var "ped"] []))
        (.not (inConflict (.var "ped")))))

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
