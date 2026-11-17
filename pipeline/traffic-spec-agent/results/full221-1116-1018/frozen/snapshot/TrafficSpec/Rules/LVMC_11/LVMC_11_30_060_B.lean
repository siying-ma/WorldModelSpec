/-
  LVMC_11_30_060_B — LVMC-11-30-060-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (subject): Any pedestrian
    g2 (trigger): crossing a roadway
    g3 (condition): at a point where a pedestrian tunnel or overhead pedestrian crossing has been provided
    g4 (obligation): shall yield
    g5 (standard): the right-of-way
    g6 (condition): to all vehicles upon the roadway
    g7 (reference): The foregoing rules in this Section shall have no application under the conditions stated in Section 11.30.070
    g8 (exception): when pedestrians are prohibited from crossing at certain designated places

  Elements (span → atoms, derived):
    g1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    g2: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived ['drv.motion.moving_across_carrier']
    g3: atoms ['st.pedestrian_grade_separation', 'st.region_geometry'], derived []
    g4: atoms ['kin.speed', 'rel.contact'], derived []
    g6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roadway'], derived []
    g8: atoms ['dev.regulatory_sign', 'dev.governs'], derived []

  How each is written:
    g1: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    g2: some roadway r the subject occupies (`existsRegion "roadway"`, `rel_occupies`) such that the
        subject moves across a carrier it occupies: the roadway r itself, or some lane k it occupies
        (`existsRegion "lane"`, `rel_occupies`), each by `drv_motion_moving_across_carrier` with
        speed_tol p.halt_speed_tolerance and cos_max p.crossing_motion_cos.
    g8: that roadway r is governed (`dev_governs`) by no regulatory sign (`existsDevice
        "regulatory_sign"`) of code pedestrians_prohibited (`dev_regulatory_sign_code`); part of r's
        selection.
    g3: some pedestrian grade separation g (`existsRegion "pedestrian_grade_separation"`) whose
        ground distance to the subject's body (`st_region_geometry_distance`) is at most
        p.grade_separation_reach.
    g6: in the obligation, every road user v that is a vehicle (`ru_aggregate v
        "DEF-NRS-484A-320::vehicle"`) and occupies some roadway r selected exactly as in the
        applicability (occupied and crossed by the subject, governed by no pedestrians_prohibited
        sign).
    g4/g5: for each such v, the subject is not in contact with v (`rel_contact`), and not
        (the subject moving, `kin_speed` > p.halt_speed_tolerance, while
        `prim_closest_approach_within subject v` [p.conflict_horizon] and
        `prim_closest_approach_distance subject v` [p.conflict_horizon] < p.conflict_centre_clearance).

  Choices: none beyond the record; "all vehicles upon the roadway" is any vehicle on any roadway the
  selection admits (the subject normally occupies one).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_060_B

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pGradeSeparationReach : Term := .param "p.grade_separation_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The subject moves across carrier `k`. -/
def movingAcross (k : String) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var k]
    [pHaltSpeedTolerance, pCrossingMotionCos]

/-- g2 + g8: roadway `r` is occupied by the subject, crossed by it (the roadway itself or a lane
    it occupies), and governed by no pedestrians_prohibited regulatory sign. -/
def roadwaySelected (r : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
    (.and
      (.or (movingAcross r)
        (.existsRegion (.lit "lane") "k"
          (.and (.atom "rel_occupies" [vSubject, .var "k"] []) (movingAcross "k"))))
      (.not (.existsDevice (.lit "regulatory_sign") "d"
        (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "pedestrians_prohibited"] [])
              (.atom "dev_governs" [.var "d", .var r] [])))))

/-- g3: a pedestrian tunnel or overpass within reach of the subject's body. -/
def nearGradeSeparation : Formula :=
  .existsRegion (.lit "pedestrian_grade_separation") "g"
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "g"]) .le pGradeSeparationReach)

/-- Applicability: g2 (trigger): crossing a roadway; g3 (condition): at a point where a pedestrian tunnel or overhead pedestrian crossing has been provided; g6 (condition): to all vehicles upon the roadway; g8 (exception): when pedestrians are prohibited from crossing at certain designated places -/
def applicability : Formula :=
  .and (.existsRegion (.lit "roadway") "r" (roadwaySelected "r")) nearGradeSeparation

/-- g4/g5 towards vehicle `v`. -/
def yieldsTo (v : String) : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var v] []))
    (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
      (.and (.derived "prim_closest_approach_within" [vSubject, .var v] [pConflictHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var v] [pConflictHorizon])
          .lt pConflictCentreClearance))))

/-- Obligation: g4 (obligation): shall yield; g5 (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "v"
    (.implies
      (.and (.atom "ru_aggregate" [.var "v", .lit "DEF-NRS-484A-320::vehicle"] [])
        (.existsRegion (.lit "roadway") "r"
          (.and (roadwaySelected "r") (.atom "rel_occupies" [.var "v", .var "r"] []))))
      (yieldsTo "v"))

def rule : Rule :=
  { id := "LVMC_11_30_060_B"
    laws := ["LVMC-11-30-060-B"]
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
          convention := "traffic-conflict technique: the defined right-of-way arises between road users 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash'; that danger is read as the two centres approaching under constant velocities within p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance)."
          surrogate := false } ]
    residues := ["Section 11.30.070 is no node of this run's library, neither accepted nor planned, so no rule can be composed; the condition under which it suspends this section is stated in this text's own words, 'when pedestrians are prohibited from crossing at certain designated places', carried by g8. Conditions of 11.30.070 those words do not state are not read; reported to the operator."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_060_B
