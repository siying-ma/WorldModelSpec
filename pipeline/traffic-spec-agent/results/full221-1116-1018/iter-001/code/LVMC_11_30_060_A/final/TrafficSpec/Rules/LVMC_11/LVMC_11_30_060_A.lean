/-
  LVMC_11_30_060_A — LVMC-11-30-060-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (subject): Every pedestrian
    f2 (trigger): crossing a roadway
    f3 (condition): at any point other than within a marked crosswalk or within an unmarked crosswalk at an intersection
    f4 (obligation): shall yield
    f5 (standard): the right-of-way
    f6 (condition): to all vehicles upon the roadway
    f7 (reference): The foregoing rules in this Section shall have no application under the conditions stated in Section 11.30.070
    f8 (exception): when pedestrians are prohibited from crossing at certain designated places

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    f2: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived ['drv.motion.moving_across_carrier']
    f3: atoms ['rel.occupies', 'st.crosswalk'], derived []
    f4: atoms ['kin.speed', 'rel.contact'], derived []
    f6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roadway'], derived []
    f8: atoms ['dev.regulatory_sign', 'dev.governs'], derived []

  How each span is written:
    f1: the binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    f2: `crossingRoadway r` — the subject occupies roadway r (existsRegion roadway, rel_occupies)
        and moves across a carrier it occupies: either r itself, or a lane k it occupies
        (existsRegion lane, rel_occupies), each by drv.motion.moving_across_carrier with
        p.halt_speed_tolerance and p.crossing_motion_cos — the record's "a lane, st.lane, or the
        roadway".
    f3: no crosswalk (existsRegion crosswalk, which carries both the marked and the unmarked
        crosswalk at an intersection) is occupied by the subject.
    f8: no regulatory sign of code pedestrians_prohibited governs the roadway r selected by f2;
        it sits inside f2's roadway quantifier so it speaks of that same roadway.
    f6: in the obligation, every road user v that is a member of DEF-NRS-484A-320::vehicle and
        occupies a roadway r re-bound with f2's whole selection (`crossingRoadway r`).
    f4/f5: for each such v — not in contact (rel_contact), and not (the subject moving above
        p.halt_speed_tolerance while prim.closest_approach_within over p.conflict_horizon holds and
        prim.closest_approach_distance over p.conflict_horizon is below p.conflict_centre_clearance).

  Choices the record left open: none beyond the above; no narrowing of my own is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_060_A

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The subject moves across carrier `k` (drv.motion.moving_across_carrier). -/
def movingAcross (k : String) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var k] [pHaltSpeedTolerance, pCrossingMotionCos]

/-- f2: the subject occupies roadway `r` and moves across a carrier it occupies — the roadway
    itself, or a lane it occupies. -/
def crossingRoadway (r : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
    (.or (movingAcross r)
      (.existsRegion (.lit "lane") "k"
        (.and (.atom "rel_occupies" [vSubject, .var "k"] []) (movingAcross "k"))))

/-- f3: the subject occupies no crosswalk (marked, or unmarked at an intersection). -/
def outsideCrosswalk : Formula :=
  .not (.existsRegion (.lit "crosswalk") "c" (.atom "rel_occupies" [vSubject, .var "c"] []))

/-- f8: no pedestrians_prohibited regulatory sign governs roadway `r`. -/
def notProhibited (r : String) : Formula :=
  .not (.existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "pedestrians_prohibited"] [])
      (.atom "dev_governs" [.var "d", .var r] [])))

/-- Applicability: f2 (trigger): crossing a roadway; f3 (condition): at any point other than within a marked crosswalk or within an unmarked crosswalk at an intersection; f6 (condition): to all vehicles upon the roadway; f8 (exception): when pedestrians are prohibited from crossing at certain designated places -/
def applicability : Formula :=
  .and (.existsRegion (.lit "roadway") "r" (.and (crossingRoadway "r") (notProhibited "r")))
    outsideCrosswalk

/-- f5: the danger of a crash between the subject and `v`, by the closest approach of centres. -/
def conflict (v : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var v] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var v] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- Obligation: f4 (obligation): shall yield; f5 (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "v"
    (.implies
      (.and (.atom "ru_aggregate" [.var "v", .lit "DEF-NRS-484A-320::vehicle"] [])
        (.existsRegion (.lit "roadway") "r"
          (.and (crossingRoadway "r") (.atom "rel_occupies" [.var "v", .var "r"] []))))
      (.and (.not (.atom "rel_contact" [vSubject, .var "v"] []))
        (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
          (conflict "v")))))

def rule : Rule :=
  { id := "LVMC_11_30_060_A"
    laws := ["LVMC-11-30-060-A"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: precedence owed where direction, speed and proximity give rise to the danger of a crash"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: the defined right-of-way arises between road users 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash'; that danger is read, from the two road users' directions, speeds and positions, as their centres approaching under constant velocities within p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance)."
          surrogate := false } ]
    residues := ["Section 11.30.070 is no node of this run's library, neither accepted nor planned, so no rule can be composed; the condition under which it suspends this section is stated in this text's own words, 'when pedestrians are prohibited from crossing at certain designated places', carried by f8. Conditions of 11.30.070 those words do not state are not read; reported to the operator."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_060_A
