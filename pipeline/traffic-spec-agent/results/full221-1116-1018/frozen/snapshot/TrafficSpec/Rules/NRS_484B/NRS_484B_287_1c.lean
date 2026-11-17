/-
  NRS_484B_287_1c — NRS-484B-287-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    v1 (reference): Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:
    v2 (condition): Between adjacent intersections
    v3 (condition): at which official traffic-control devices are in operation
    v4 (subject): pedestrians
    v5 (obligation): shall not cross at any place
    v6 (exception): except in a marked crosswalk.

  Elements (span → atoms, derived):
    v2: atoms ['rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection', 'st.lane', 'st.lane_connectivity', 'st.crosswalk', 'st.entrance_of'], derived []
    v3: atoms ['dev.governs', 'dev.traffic_signal', 'dev.inoperative', 'st.lane_enters'], derived []
    v4: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    v5: atoms ['rel.occupies', 'st.travel_region'], derived ['drv.motion.moving_across_carrier']
    v6: atoms ['rel.occupies', 'st.crosswalk'], derived []

  Compositions (span → node, as, map):
    v1: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    v1: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_287_1c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    v4: the binder class, `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    v1: the two exceptions, `.not (.ruleApplies "LVMC_11_30_140_B_o1" …)` and the same for o2,
        subject mapped to subject.
    v2: a travel region `c` the subject occupies (`rel_occupies`) that enters an intersection `i1`
        (`st_lane_enters c i1`), and an intersection `i2`, not `i1` (`.same` negated), reached
        either through a second occupied travel region `c2` that enters `i2` (`linkOpposing`), or,
        where `c` is a lane (`st_lane c`), through a lane `l` entering `i2` that leads into `c`
        directly or through one lane `l3` between (`st_lane_connectivity`, `linkThroughLanes`).
        Not at either intersection: the subject occupies neither `i1` nor `i2`, nor a crosswalk
        recorded as marking the entrance (`st_entrance_of`) of a travel region it occupies
        (`notAtIntersection`).
    v3: for each of `i1`, `i2` a device of kind traffic_signal that is uncovered, does not show
        `dark` and is not inoperative, and that governs the intersection or governs a travel region
        entering it (`operating`). The carrier `g` of the second branch is a travel region that is
        not an intersection (`st_intersection` negated): per the st.lane_enters contract only a
        carrier (a lane, roadway, shoulder or bicycle lane or path) is ever recorded as entering an
        intersection, and the adapter never writes the record on an intersection, so this states
        no exclusion of a region that could be "recorded as entering it"; it keeps the record's
        absence on an intersection from leaving the branch unknown where `dev.governs` is not
        observed.
    v5: `drv_motion_moving_across_carrier subject c` with p.halt_speed_tolerance and
        p.crossing_motion_cos, on the same `c` the subject occupies — in the applicability, as the
        record places it.
    v6: the obligation: some crosswalk the subject occupies whose marked attribute is true.
  No choice beyond the record's words was made; no narrowing is declared.
-/

def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []
def enters (r i : String) : Formula := .atom "st_lane_enters" [.var r, .var i] []
def leadsInto (a b : String) : Formula := .atom "st_lane_connectivity" [.var a, .var b] []

/-- v4. -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- v3: a signal head in operation at intersection `i`: uncovered, not dark, not inoperative, and
    governing `i` itself or a travel region recorded as entering `i`. -/
def operating (d i g : String) : Formula :=
  .existsDevice (.lit "traffic_signal") d
    (.and (.atom "dev_traffic_signal_uncovered" [.var d] [])
      (.and (.not (.atom "dev_traffic_signal_shows" [.var d, .lit "dark"] []))
        (.and (.not (.atom "dev_inoperative" [.var d] []))
          (.or (.atom "dev_governs" [.var d, .var i] [])
               (.existsRegion (.lit "travel_region") g
                  (.and (.not (.atom "st_intersection" [.var g] []))
                    (.and (enters g i) (.atom "dev_governs" [.var d, .var g] []))))))))

/-- v2: `i2` reached through a second travel region the subject occupies that enters it. -/
def linkOpposing : Formula :=
  .existsRegion (.lit "travel_region") "c2" (.and (occ "c2") (enters "c2" "i2"))

/-- v2: `c` is a lane, and a lane entering `i2` leads into `c`, directly or through one lane. -/
def linkThroughLanes : Formula :=
  .and (.atom "st_lane" [.var "c"] [])
    (.existsRegion (.lit "lane") "l"
      (.and (enters "l" "i2")
        (.or (leadsInto "l" "c")
             (.existsRegion (.lit "lane") "l3" (.and (leadsInto "l" "l3") (leadsInto "l3" "c"))))))

/-- v2: at neither intersection, nor on a crosswalk marking the entrance of a carrier occupied. -/
def notAtIntersection : Formula :=
  .and (.not (occ "i1"))
    (.and (.not (occ "i2"))
      (.not (.existsRegion (.lit "crosswalk") "x"
        (.and (occ "x")
          (.existsRegion (.lit "travel_region") "e"
            (.and (occ "e") (.atom "st_entrance_of" [.var "x", .var "e"] [])))))))

/-- v5: crossing the carrier `c`. -/
def crossing : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var "c"] [pHaltSpeedTolerance, pCrossingMotionCos]

/-- v2, v3, v5: crossing a carrier between two adjacent signal-controlled intersections. -/
def betweenControlled : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occ "c")
      (.and crossing
        (.existsRegion (.lit "intersection") "i1"
          (.and (enters "c" "i1")
            (.and (operating "d1" "i1" "g1")
              (.existsRegion (.lit "intersection") "i2"
                (.and (.not (.same (.var "i1") (.var "i2")))
                  (.and (.or linkOpposing linkThroughLanes)
                    (.and (operating "d2" "i2" "g2") notAtIntersection)))))))))

/-- Applicability: v1 exceptions; v2, v3, v5. -/
def applicability : Formula :=
  .and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
    (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
      betweenControlled)

/-- Obligation: v6 — in a marked crosswalk. -/
def obligation : Formula :=
  .existsRegion (.lit "crosswalk") "w" (.and (occ "w") (.atom "st_crosswalk_marked" [.var "w"] []))

def rule : Rule :=
  { id := "NRS_484B_287_1c"
    laws := ["NRS-484B-287-1c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_287_1c
