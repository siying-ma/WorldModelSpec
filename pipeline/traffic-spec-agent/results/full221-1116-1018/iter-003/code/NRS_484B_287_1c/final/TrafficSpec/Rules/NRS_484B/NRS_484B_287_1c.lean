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

  How each span is written:
    v1  `.not (.ruleApplies "LVMC_11_30_140_B_o1" [subject↦subject])` and the same for `_o2`,
        conjoined into the applicability.
    v4  the binder class `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
    v2  some travel region `c` the subject occupies (`rel_occupies`) is recorded as entering an
        intersection `i1` (`st_lane_enters(c, i1)`, `i1` bound over kind `intersection`), and some
        intersection `i2` that is not `i1` (`.not (.same i1 i2)`) is reached either (a) through a
        second travel region `c2` the subject also occupies with `st_lane_enters(c2, i2)`, or (b)
        where `c` is a lane (a `lane` quantifier variable `cl` that is `same` as `c`) through a lane
        `l2` with `st_lane_enters(l2, i2)` that leads into `cl` (`st_lane_connectivity(l2, cl)`),
        directly or through one lane `l3` between (`st_lane_connectivity(l2, l3)` and
        `st_lane_connectivity(l3, cl)`). The subject is not at either intersection: it occupies
        neither `i1` nor `i2`, nor a crosswalk `k` recorded as marking the entrance of a travel
        region `cc` it occupies (`st_entrance_of(k, cc)`).
    v3  for each of `i1` and `i2`: some `traffic_signal` device `d` with
        `dev_traffic_signal_uncovered(d)`, not `dev_traffic_signal_shows(d, "dark")`, not
        `dev_inoperative(d)`, that governs the intersection itself (`dev_governs(d, i)`) or governs a
        travel region `g` recorded as entering it (`dev_governs(d, g)` and `st_lane_enters(g, i)`).
        `g` ranges over travel regions other than intersections (`.not` of an `intersection`
        quantifier variable `same` as `g`): by the st.lane_enters contract a carrier recorded as
        entering is a lane, roadway, one-way roadway, shoulder or bicycle lane or path, never an
        intersection, whose entry record is therefore always absent; the exclusion keeps that
        absent record from leaving the device condition unknown. It restates the atom's contract
        and removes no member the record's words admit.
        The device's kind and its uncovered/state attributes are the `dev.traffic_signal` atom.
    v5  `drv_motion_moving_across_carrier(subject, c)` with p.halt_speed_tolerance and
        p.crossing_motion_cos, on the same carrier `c` the v2 selection binds (inside its scope).
    v6  obligation: some crosswalk `k` the subject occupies has `st_crosswalk_marked(k)`.

  No choice beyond the record's: no narrowing of my own.

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

def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []
def enters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def leadsInto (a b : String) : Formula := .atom "st_lane_connectivity" [.var a, .var b] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- v3: intersection `i` has a traffic signal in operation that governs it, or governs a travel
    region recorded as entering it. -/
def controlled (i : String) : Formula :=
  .existsDevice (.lit "traffic_signal") ("d_" ++ i)
    (.and (.atom "dev_traffic_signal_uncovered" [.var ("d_" ++ i)] [])
    (.and (.not (.atom "dev_traffic_signal_shows" [.var ("d_" ++ i), .lit "dark"] []))
    (.and (.not (.atom "dev_inoperative" [.var ("d_" ++ i)] []))
      (.or (.atom "dev_governs" [.var ("d_" ++ i), .var i] [])
           (.existsRegion (.lit "travel_region") ("g_" ++ i)
              (.and (.not (.existsRegion (.lit "intersection") ("j_" ++ i)
                             (.same (.var ("j_" ++ i)) (.var ("g_" ++ i)))))
              (.and (.atom "dev_governs" [.var ("d_" ++ i), .var ("g_" ++ i)] [])
                    (enters ("g_" ++ i) i))))))))

/-- v2 (a): a second carrier the subject occupies enters `i2`. -/
def secondCarrier : Formula :=
  .existsRegion (.lit "travel_region") "c2" (.and (occ "c2") (enters "c2" "i2"))

/-- v2 (b): `c` is a lane, and a lane entering `i2` leads into it, directly or through one lane. -/
def connectedLane : Formula :=
  .existsRegion (.lit "lane") "cl"
    (.and (.same (.var "cl") (.var "c"))
      (.existsRegion (.lit "lane") "l2"
        (.and (enters "l2" "i2")
          (.or (leadsInto "l2" "cl")
               (.existsRegion (.lit "lane") "l3"
                  (.and (leadsInto "l2" "l3") (leadsInto "l3" "cl")))))))

/-- v2: not at an intersection: no crosswalk recorded as marking the entrance of a carrier the
    subject occupies is occupied by it. -/
def atEntranceCrosswalk : Formula :=
  .existsRegion (.lit "travel_region") "cc"
    (.and (occ "cc")
      (.existsRegion (.lit "crosswalk") "kx"
        (.and (.atom "st_entrance_of" [.var "kx", .var "cc"] []) (occ "kx"))))

/-- v2, v3, v5: between adjacent controlled intersections, moving across the carrier. -/
def betweenAndCrossing : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occ "c")
    (.and (.derived "drv_motion_moving_across_carrier" [vSubject, .var "c"]
            [pHaltSpeedTolerance, pCrossingMotionCos])
      (.existsRegion (.lit "intersection") "i1"
        (.and (enters "c" "i1")
        (.and (controlled "i1")
        (.and (.not (occ "i1"))
          (.existsRegion (.lit "intersection") "i2"
            (.and (.not (.same (.var "i1") (.var "i2")))
            (.and (controlled "i2")
            (.and (.not (occ "i2"))
              (.or secondCarrier connectedLane)))))))))))

/-- Applicability: v2 (condition): Between adjacent intersections; v3 (condition): at which official traffic-control devices are in operation; v6 (exception): except in a marked crosswalk. -/
def applicability : Formula :=
  .and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
  (.and (.not atEntranceCrosswalk)
        betweenAndCrossing))

/-- Obligation: v5 (obligation): shall not cross at any place; v6: except in a marked crosswalk. -/
def obligation : Formula :=
  .existsRegion (.lit "crosswalk") "k"
    (.and (occ "k") (.atom "st_crosswalk_marked" [.var "k"] []))

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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_287_1c
