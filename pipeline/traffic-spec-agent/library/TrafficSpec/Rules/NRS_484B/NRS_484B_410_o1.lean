/-
  NRS_484B_410_o1 — NRS-484B-410

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A person,
    s2 (exception): except when stopping, standing or parking where no parking is permitted,
    s3 (obligation): shall not start a vehicle which is stopped, standing or parked on a highway
    s4 (sibling): nor enter upon a highway
    s5 (standard): unless and until such movement can be made with safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.curb_zone', 'dev.regulatory_sign', 'dev.governs', 'st.travel_region', 'prim.conditions_hold'], derived ['drv.motion.complete_halt']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.highway'], derived ['drv.motion.complete_halt']

  How each is written:
    s1: the binder's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: `halted` is drv.motion.complete_halt(subject; p.halt_speed_tolerance). `heldOnHighway` is,
        at one observation, halted ∧ some st.highway region the subject occupies ∧ ¬ the s2
        exception. The start is the observation at which the subject is not halted and
        `heldOnHighway` held at the previous one: `¬halted ∧ rises (¬heldOnHighway)` — the rise of
        the negation is true exactly where it is true now and was false (heldOnHighway true) at the
        previous observation; with ¬halted now this is the record's start. The highway occupancy
        and the exception are thereby read at the previous observation, as the record states.
    s2: a place where no parking is permitted is (a) an st.curb_zone the subject occupies whose
        kind is no_parking, no_stopping or fire_lane, or whose curb colour is red, or (b) an
        st.travel_region the subject occupies governed by a dev.regulatory_sign of code
        no_parking, no_standing or no_stopping whose conditions hold for the subject
        (prim.conditions_hold). The halt half of the exception is the halt `heldOnHighway`
        already requires.
    s5: the obligation: every road user `other` of the scene is the subject (`same`) or does not
        both approach the subject within p.conflict_horizon (prim.closest_approach_within) and come
        within p.conflict_centre_clearance at the closest approach
        (prim.closest_approach_distance ≤ p.conflict_centre_clearance).
    s4: a sibling the node does not carry.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_410_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2/s3: the subject is at rest (every halt: stopping, standing or parking). -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3: the subject occupies a highway region. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "hwy" (.atom "rel_occupies" [vSubject, .var "hwy"] [])

/-- s2 (a): a curb zone the subject occupies, of kind no_parking, no_stopping or fire_lane, or painted red. -/
def inNoParkingCurb : Formula :=
  .existsRegion (.lit "curb_zone") "zone"
    (.and (.atom "rel_occupies" [vSubject, .var "zone"] [])
      (.or
        (.or (.atom "st_curb_zone_kind" [.var "zone", .lit "no_parking"] [])
          (.or (.atom "st_curb_zone_kind" [.var "zone", .lit "no_stopping"] [])
            (.atom "st_curb_zone_kind" [.var "zone", .lit "fire_lane"] [])))
        (.atom "st_curb_zone_colour" [.var "zone", .lit "red"] [])))

/-- s2 (b): a travel region the subject occupies, governed by a no-parking, no-standing or
    no-stopping regulatory sign whose conditions hold for the subject. -/
def inSignedNoParking : Formula :=
  .existsRegion (.lit "travel_region") "tr"
    (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
      (.existsDevice (.lit "regulatory_sign") "sgn"
        (.and (.atom "dev_governs" [.var "sgn", .var "tr"] [])
          (.and
            (.or (.atom "dev_regulatory_sign_code" [.var "sgn", .lit "no_parking"] [])
              (.or (.atom "dev_regulatory_sign_code" [.var "sgn", .lit "no_standing"] [])
                (.atom "dev_regulatory_sign_code" [.var "sgn", .lit "no_stopping"] [])))
            (.derived "prim_conditions_hold" [.var "sgn", vSubject] [])))))

/-- s2: the subject is where no parking is permitted. -/
def noParkingPlace : Formula := .or inNoParkingCurb inSignedNoParking

/-- s3 with the s2 exception: halted on a highway, not where no parking is permitted. -/
def heldOnHighway : Formula := .and halted (.and onHighway (.not noParkingPlace))

/-- Applicability: s3 (the start of a vehicle stopped, standing or parked on a highway) at the
    observation the subject is no longer halted, having been held on a highway at the previous one;
    s2 (exception): except when stopping, standing or parking where no parking is permitted. -/
def applicability : Formula := .and (.not halted) (.rises (.not heldOnHighway))

/-- s5: road user `other` is predicted to come within the conflict clearance of the subject within the horizon. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var "other"] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "other"] [pConflictHorizon])
      .le pConflictCentreClearance)

/-- Obligation: s3 (obligation): shall not start a vehicle which is stopped, standing or parked on a highway; s5 (standard): unless and until such movement can be made with safety. -/
def obligation : Formula :=
  .forallUser "other" (.or (.same vSubject (.var "other")) (.not conflict))

def rule : Rule :=
  { id := "NRS_484B_410_o1"
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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_410_o1
