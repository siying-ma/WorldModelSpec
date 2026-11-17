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

  How each is written:
    f1: the binder class `ru_aggregate subject DEF-NRS-484A-165::pedestrian`.
    f2: some roadway r (existsRegion roadway) the subject occupies (rel_occupies), and the subject
        moves across a carrier it occupies: either some lane k (existsRegion lane) it occupies
        with drv_motion_moving_across_carrier(subject, k), or the roadway r itself with
        drv_motion_moving_across_carrier(subject, r); speed_tol p.halt_speed_tolerance,
        cos_max p.crossing_motion_cos. `crossesRoadway r` is that selection of r.
    f3: no crosswalk c (existsRegion crosswalk; the kind carries the marked and the unmarked
        crosswalk at an intersection alike) is occupied by the subject.
    f8: inside the roadway quantifier of the applicability: no regulatory sign d (existsDevice
        regulatory_sign) with code pedestrians_prohibited (dev_regulatory_sign_code) governs r
        (dev_governs d r).
    f6: in the obligation, every roadway r re-bound with the record's selection (the subject
        occupies r and crosses it, `crossesRoadway r`), and every road user v that is a member of
        DEF-NRS-484A-320::vehicle and occupies r (rel_occupies v r).
    f4/f5: for each such v: not rel_contact(subject, v), and not (kin_speed(subject) above
        p.halt_speed_tolerance while prim_closest_approach_within(subject, v, p.conflict_horizon)
        and prim_closest_approach_distance(subject, v, p.conflict_horizon) below
        p.conflict_centre_clearance). The distance is read only under the `within` conjunct,
        where the primitive is defined.
    f7: residue (the node's).

  Choices the text left open: none beyond the record's own narrowings; the obligation's
  re-selection of r is the record's ("the roadway the subject occupies and crosses").

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

def aggPedestrian : Arg := .lit "DEF-NRS-484A-165::pedestrian"
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- `x` occupies region `r`. -/
def occupies (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- The subject moves across carrier `k` (f2's derived concept). -/
def movingAcross (k : String) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var k] [pHaltSpeedTolerance, pCrossingMotionCos]

/-- f2's selection of roadway `r`: the subject occupies it and moves across a carrier it occupies,
    a lane or the roadway itself. -/
def crossesRoadway (r : String) : Formula :=
  .and (occupies "subject" r)
    (.or (.existsRegion (.lit "lane") "k" (.and (occupies "subject" "k") (movingAcross "k")))
         (movingAcross r))

/-- f8: a pedestrians_prohibited regulatory sign governs roadway `r`. -/
def prohibitionGoverns (r : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "pedestrians_prohibited"] [])
          (.atom "dev_governs" [.var "d", .var r] []))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggPedestrian] []

/-- f3: the subject occupies no crosswalk. -/
def outsideCrosswalk : Formula :=
  .not (.existsRegion (.lit "crosswalk") "c" (occupies "subject" "c"))

/-- Applicability: f2 (trigger): crossing a roadway; f3 (condition): at any point other than within a marked crosswalk or within an unmarked crosswalk at an intersection; f6 (condition): to all vehicles upon the roadway; f8 (exception): when pedestrians are prohibited from crossing at certain designated places -/
def applicability : Formula :=
  .and
    (.existsRegion (.lit "roadway") "r"
      (.and (crossesRoadway "r") (.not (prohibitionGoverns "r"))))
    outsideCrosswalk

/-- f5: a danger of a crash between the subject and `v`: centres approaching within the horizon
    to a centre distance below the clearance. -/
def conflictWith (v : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var v] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var v] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- f4: the subject yields to `v`: no contact, and not moving into a projected conflict. -/
def yieldsTo (v : String) : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, .var v] []))
       (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
                   (conflictWith v)))

/-- Obligation: f4 (obligation): shall yield; f5 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "r"
    (.implies (crossesRoadway "r")
      (.forallUser "v"
        (.implies (.and (.atom "ru_aggregate" [.var "v", aggVehicle] []) (occupies "v" "r"))
                  (yieldsTo "v"))))

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
