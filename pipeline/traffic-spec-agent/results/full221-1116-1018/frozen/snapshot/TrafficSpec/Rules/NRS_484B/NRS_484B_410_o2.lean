/-
  NRS_484B_410_o2 — NRS-484B-410

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A person,
    s2 (exception): except when stopping, standing or parking where no parking is permitted,
    s3 (sibling): shall not start a vehicle which is stopped, standing or parked on a highway
    s4 (obligation): nor enter upon a highway
    s5 (standard): unless and until such movement can be made with safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.curb_zone', 'dev.regulatory_sign', 'dev.governs', 'st.travel_region', 'prim.conditions_hold'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.occupies', 'st.highway'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_410_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.

  s1: the binder `subject` is a member of the admitted aggregate DEF-NRS-484A-320::vehicle
      (`ru_aggregate` with the aggregate id as its literal).

  s4: "enter upon a highway" — `onHighway`: the subject's footprint overlaps (`rel_occupies`) some
      region of kind `highway`. The entry is the observation at which `onHighway` holds and did not
      hold at the previous observation: `.rises onHighway`.

  s2: "stopping, standing or parking where no parking is permitted" — `haltedWhereNoParking`: the
      subject is at rest (`drv_motion_complete_halt`, tolerance p.halt_speed_tolerance) and its
      footprint overlaps either
        (a) a `curb_zone` whose kind is no_parking, no_stopping or fire_lane, or whose painted
            colour is red; or
        (b) a `travel_region` governed (`dev_governs`) by a `regulatory_sign` of code no_parking,
            no_standing or no_stopping whose conditions hold for the subject (`prim_conditions_hold`).
      The record reads the exception at the observation before the entry. The language has no
      "previous observation" operator; `rises` is "here and not at the previous observation", so
      `.rises (.or onHighway haltedWhereNoParking)`, conjoined with `.rises onHighway` (which makes
      `onHighway` true here, hence the disjunction true here), is exactly: at the previous
      observation the subject neither occupied a highway nor was halted where no parking is
      permitted. The applicability is therefore: entry, and the exception not holding at the
      observation before it — the record's applicability, with no choice of my own.

  s5: "such movement can be made with safety" — the node's operationalization: for every road user
      `other` of the scene other than the subject (`same` excludes the subject),
      not (prim_closest_approach_within(subject, other; p.conflict_horizon) and
           prim_closest_approach_distance(subject, other; p.conflict_horizon) ≤ p.conflict_centre_clearance).
      Where the centres do not approach within the horizon the distance is undefined; the
      conjunction is then decided false by its first operand.

  No narrowing of my own: every reading above is the record's.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4: the subject's footprint overlaps some highway region. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "hw" (.atom "rel_occupies" [vSubject, .var "hw"] [])

/-- s2 (a): the subject occupies a curb zone marked no parking, no stopping or fire lane, or painted red. -/
def inNoParkingCurbZone : Formula :=
  .existsRegion (.lit "curb_zone") "cz"
    (.and (.atom "rel_occupies" [vSubject, .var "cz"] [])
      (.or (.atom "st_curb_zone_kind" [.var "cz", .lit "no_parking"] [])
        (.or (.atom "st_curb_zone_kind" [.var "cz", .lit "no_stopping"] [])
          (.or (.atom "st_curb_zone_kind" [.var "cz", .lit "fire_lane"] [])
            (.atom "st_curb_zone_colour" [.var "cz", .lit "red"] [])))))

/-- s2 (b): the subject occupies a travel region governed by a no-parking, no-standing or
    no-stopping regulatory sign whose conditions hold for it now. -/
def inSignedNoParkingRegion : Formula :=
  .existsRegion (.lit "travel_region") "tr"
    (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
      (.existsDevice (.lit "regulatory_sign") "rs"
        (.and (.atom "dev_governs" [.var "rs", .var "tr"] [])
          (.and
            (.or (.atom "dev_regulatory_sign_code" [.var "rs", .lit "no_parking"] [])
              (.or (.atom "dev_regulatory_sign_code" [.var "rs", .lit "no_standing"] [])
                (.atom "dev_regulatory_sign_code" [.var "rs", .lit "no_stopping"] [])))
            (.derived "prim_conditions_hold" [.var "rs", vSubject] [])))))

/-- s2: the subject stopping, standing or parking where no parking is permitted. -/
def haltedWhereNoParking : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])
    (.or inNoParkingCurbZone inSignedNoParkingRegion)

/-- Applicability: s4 the entry upon a highway, and s2 the exception not holding at the
    observation before it (see the header for why the second `rises` says exactly that). -/
def applicability : Formula :=
  .and (.rises onHighway) (.rises (.or onHighway haltedWhereNoParking))

/-- Obligation: s5 — no other road user's centre is predicted to come within the conflict centre
    clearance of the subject's within the conflict horizon. -/
def obligation : Formula :=
  .forallUser "other"
    (.or (.same (.var "other") vSubject)
      (.not (.and (.derived "prim_closest_approach_within" [vSubject, .var "other"] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "other"] [pConflictHorizon])
          .le pConflictCentreClearance))))

def rule : Rule :=
  { id := "NRS_484B_410_o2"
    laws := ["NRS-484B-410"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "such movement can be made with safety"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a movement is made with safety where, at its onset, no other road user's centre is predicted under constant velocities to come within the conflict centre clearance of the subject's centre within the time-to-collision horizon"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_410_o2
