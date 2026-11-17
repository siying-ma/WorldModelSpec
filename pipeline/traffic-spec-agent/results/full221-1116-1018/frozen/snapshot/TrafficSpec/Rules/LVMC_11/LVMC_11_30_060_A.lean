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
    f1: binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    f2: `crossedRoadway r`: rel_occupies(subject, r) ∧ (rel_occupies(subject, r) since
        moves-across-an-occupied-carrier), the carrier being some lane k (existsRegion "lane",
        rel_occupies(subject, k) ∧ drv_motion_moving_across_carrier(subject, k)) or r itself
        (rel_occupies(subject, r) ∧ drv_motion_moving_across_carrier(subject, r)), with
        speed_tol p.halt_speed_tolerance and cos_max p.crossing_motion_cos. The roadway is bound by
        existsRegion "roadway" r (st.roadway). Core's `since` is strong: before any recorded
        movement across, the unrecorded past leaves it unknown, as the record states.
    f3: ¬ existsRegion "crosswalk" c, rel_occupies(subject, c) — at the judged observation.
    f8: ¬ existsDevice "regulatory_sign" d, dev_regulatory_sign_code(d, pedestrians_prohibited) ∧
        dev_governs(d, r), inside the roadway's selection (the record's observable reading).
    f6/f4/f5: the obligation re-selects every roadway r with the whole selection `crossedRoadway r`
        (same definition as the applicability's), and for every road user v with
        ru_aggregate(v, DEF-NRS-484A-320::vehicle) ∧ rel_occupies(v, r): ¬ rel_contact(subject, v)
        ∧ ¬ (kin_speed(subject) > p.halt_speed_tolerance ∧ prim_closest_approach_within(subject, v;
        p.conflict_horizon) ∧ prim_closest_approach_distance(subject, v; p.conflict_horizon) <
        p.conflict_centre_clearance).
  No choice beyond the record's own narrowings was needed; `narrowings` is empty.

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
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- f2: the subject moves across carrier `c` (drv.motion.moving_across_carrier). -/
def movesAcross (c : String) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var c] [pHaltSpeedTolerance, pCrossingMotionCos]

/-- f2: the subject moves across a carrier it occupies: some lane `k` it occupies, or roadway `r`
    itself (which it occupies). -/
def movesAcrossOccupiedCarrier (r : String) : Formula :=
  .or
    (.existsRegion (.lit "lane") "k"
      (.and (.atom "rel_occupies" [vSubject, .var "k"] []) (movesAcross "k")))
    (.and (.atom "rel_occupies" [vSubject, .var r] []) (movesAcross r))

/-- f8: a pedestrians_prohibited regulatory sign governs roadway `r`. -/
def pedestriansProhibitedOn (r : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit "pedestrians_prohibited"] [])
          (.atom "dev_governs" [.var "d", .var r] []))

/-- The whole selection of the roadway `r` crossed (f2, f8): the subject occupies `r`, has occupied
    it at every observation since (strong past since) one at which it moved across a carrier it
    occupies, and no pedestrians_prohibited sign governs `r`. Written once, used in both formulas. -/
def crossedRoadway (r : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] [])
    (.and (.since (.atom "rel_occupies" [vSubject, .var r] []) (movesAcrossOccupiedCarrier r))
          (.not (pedestriansProhibitedOn r)))

/-- Applicability: f2 (trigger): crossing a roadway; f3 (condition): at any point other than within a marked crosswalk or within an unmarked crosswalk at an intersection; f6 (condition): to all vehicles upon the roadway; f8 (exception): when pedestrians are prohibited from crossing at certain designated places -/
def applicability : Formula :=
  .and (.existsRegion (.lit "roadway") "r" (crossedRoadway "r"))
    (.not (.existsRegion (.lit "crosswalk") "c" (.atom "rel_occupies" [vSubject, .var "c"] [])))

/-- f5: the danger of a crash with `v`: the centres approach within the horizon to a centre
    distance below the clearance. -/
def conflictWith (v : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var v] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var v] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- Obligation: f4 (obligation): shall yield; f5 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "r"
    (.implies (crossedRoadway "r")
      (.forallUser "v"
        (.implies
          (.and (.atom "ru_aggregate" [.var "v", .lit "DEF-NRS-484A-320::vehicle"] [])
                (.atom "rel_occupies" [.var "v", .var "r"] []))
          (.and (.not (.atom "rel_contact" [vSubject, .var "v"] []))
                (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
                            (conflictWith "v")))))))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_060_A
