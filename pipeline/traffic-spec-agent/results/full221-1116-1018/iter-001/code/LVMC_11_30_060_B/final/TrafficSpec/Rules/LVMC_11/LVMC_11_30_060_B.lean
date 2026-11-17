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

  How each span is written:
    g1: ru_aggregate(subject, DEF-NRS-484A-165::pedestrian) as the binder class.
    g2: some roadway r (existsRegion roadway) the subject occupies (rel_occupies), and the subject
        moves across a carrier it occupies: some lane k it occupies (existsRegion lane, rel_occupies)
        or r itself (drv_motion_moving_across_carrier, speed_tol p.halt_speed_tolerance, cos_max
        p.crossing_motion_cos).
    g8: no regulatory_sign d (existsDevice regulatory_sign) of code pedestrians_prohibited
        (dev_regulatory_sign_code) governs r (dev_governs); part of r's selection.
    g3: some pedestrian_grade_separation g with st_region_geometry_distance(subject, g) at most
        p.grade_separation_reach.
    g6: in the obligation, for every road user v that is a DEF-NRS-484A-320::vehicle and occupies a
        roadway r selected exactly as in the applicability (`roadwayCrossed`, re-bound in full).
    g4/g5: not rel_contact(subject, v), and not (kin_speed(subject) > p.halt_speed_tolerance and
        prim_closest_approach_within(subject, v; p.conflict_horizon) and the
        prim_closest_approach_distance below p.conflict_centre_clearance).
  Choices the record left open: none beyond the record's own narrowings (the lane k of g2 is any
  lane the subject occupies, as the record states, not tied to r).

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

/-- g2: the subject moves across carrier `k` (drv.motion.moving_across_carrier). -/
def movesAcross (k : String) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var k] [pHaltSpeedTolerance, pCrossingMotionCos]

/-- g8: some regulatory sign of code pedestrians_prohibited governs roadway `r`. -/
def crossingProhibited (r : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "pedestrians_prohibited"] [])
          (.atom "dev_governs" [.var "d", .var r] []))

/-- The selection of the roadway `r` crossed (g2 with the g8 exception on it): the subject occupies
    `r` and moves across a carrier it occupies (a lane, or `r` itself), and no pedestrians_prohibited
    sign governs `r`. Written once and used in both formulas, so the obligation's `r` is the
    applicability's. -/
def roadwayCrossed (r : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
    (.and (.or (.existsRegion (.lit "lane") "k"
                  (.and (.atom "rel_occupies" [vSubject, .var "k"] []) (movesAcross "k")))
               (movesAcross r))
          (.not (crossingProhibited r)))

/-- g3: some pedestrian tunnel or overpass lies within the reach of the subject's body. -/
def atGradeSeparation : Formula :=
  .existsRegion (.lit "pedestrian_grade_separation") "g"
    (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "g"]) .le pGradeSeparationReach)

/-- Applicability: g2 (trigger): crossing a roadway; g3 (condition): at a point where a pedestrian tunnel or overhead pedestrian crossing has been provided; g6 (condition): to all vehicles upon the roadway; g8 (exception): when pedestrians are prohibited from crossing at certain designated places -/
def applicability : Formula :=
  .and (.existsRegion (.lit "roadway") "r" (roadwayCrossed "r")) atGradeSeparation

/-- g5: the danger of a crash between the subject and `v` (prim.closest_approach_within,
    prim.closest_approach_distance). -/
def conflictWith (v : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var v] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var v] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- Obligation: g4 (obligation): shall yield; g5 (standard): the right-of-way; g6: to every
    vehicle on the roadway crossed (re-bound with its whole selection). -/
def obligation : Formula :=
  .forallUser "v"
    (.implies
      (.and (.atom "ru_aggregate" [.var "v", .lit "DEF-NRS-484A-320::vehicle"] [])
            (.existsRegion (.lit "roadway") "r"
              (.and (roadwayCrossed "r") (.atom "rel_occupies" [.var "v", .var "r"] []))))
      (.and (.not (.atom "rel_contact" [vSubject, .var "v"] []))
            (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
                        (conflictWith "v")))))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_060_B
