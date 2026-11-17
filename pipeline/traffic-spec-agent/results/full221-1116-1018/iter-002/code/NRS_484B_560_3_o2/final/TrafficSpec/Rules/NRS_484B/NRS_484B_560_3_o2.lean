/-
  NRS_484B_560_3_o2 — NRS-484B-560-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When stopping is required
    s2 (condition): at a railroad crossing
    s3 (subject): the driver
    s4 (sibling): shall keep as far to the right of the highway
    s5 (sibling): as possible
    s6 (boilerplate): and
    s7 (obligation): shall not form two lanes of traffic
    s8 (exception): unless the highway is marked for four or more lanes of traffic.

  Elements (span → atoms, derived):
    s1: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s2: atoms ['st.railway_crossing', 'st.region_geometry'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.same_direction', 'rel.longitudinal_overlap', 'rel.occupies', 'st.lane'], derived []
    s8: atoms ['st.lane', 'st.on_way', 'st.highway', 'rel.occupies'], derived []

  Literals the text states (each written through its Units constructor):
    s8: 4 count — four

  How each span is written:
    s3: `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    s1: some travel region r (quantifier over kind `travel_region`, which covers lanes and every
        kind refining it) that the subject occupies (`rel_occupies`) is governed (`dev_governs`) by
        a device requiring a halt at this observation: a railway signal or gate (quantifier kind
        `railway_signal_or_gate`) with lights `flashing` or gate `lowering`/`down`; a stop sign
        (quantifier kind `stop_sign`); a traffic signal (quantifier kind `traffic_signal`) showing
        `circular_red`; a human direction (quantifier kind `human_direction`) of role
        `police_officer` or `railroad_flagger` giving indication `stop`. The device kinds are read
        through the device quantifiers' kinds.
    s2: some railway crossing c (quantifier kind `railway_crossing`) with the ground distance from
        the subject's body (`st_region_geometry_distance`) at most p.railroad_crossing_approach_reach.
    s8: some highway h (quantifier kind `highway`) the subject occupies on which four pairwise
        distinct lanes lie (`st_on_way(l_i, h)`, `not same(l_i, l_j)`): the text's "four or more"
        is written as four distinct lane witnesses, since the language counts road users only
        (`Term.aggregate`), not regions; the figure four is the number of nested lane quantifiers.
        Negated in the applicability (the exception).
    s7: no road user v other than the subject (`not same(v, subject)`), a member of
        DEF-NRS-484A-285::traffic, occupying some lane, within p.railroad_crossing_approach_reach of
        a railway crossing c that is itself within that reach of the subject (the applicability's
        whole selection of c restated), heading the subject's way (`rel_same_direction` with
        p.side_by_side_same_direction_cos) with a positive longitudinal overlap with the subject.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_560_3_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pRailroadCrossingApproachReach : Term := .param "p.railroad_crossing_approach_reach"
def pSideBySideSameDirectionCos : Term := .param "p.side_by_side_same_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The body of road user `who` is within the approach reach of crossing `c` (st.region_geometry). -/
def withinReach (who c : String) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [.var who, .var c]) .le pRailroadCrossingApproachReach

/-- s2: the subject is at a railroad crossing. -/
def atCrossing : Formula :=
  .existsRegion (.lit "railway_crossing") "c" (withinReach "subject" "c")

/-- s1: a device governing travel region `r` requires a halt of its traffic at this observation. -/
def haltRequiredOn (r : String) : Formula :=
  let d : Arg := .var "d"
  let gov : Formula := .atom "dev_governs" [d, .var r] []
  .or
    (.existsDevice (.lit "railway_signal_or_gate") "d"
      (.and gov
        (.or (.atom "dev_railway_signal_or_gate_lights" [d, .lit "flashing"] [])
          (.or (.atom "dev_railway_signal_or_gate_gate" [d, .lit "lowering"] [])
               (.atom "dev_railway_signal_or_gate_gate" [d, .lit "down"] [])))))
    (.or
      (.existsDevice (.lit "stop_sign") "d" gov)
      (.or
        (.existsDevice (.lit "traffic_signal") "d"
          (.and gov (.atom "dev_traffic_signal_shows" [d, .lit "circular_red"] [])))
        (.existsDevice (.lit "human_direction") "d"
          (.and gov
            (.and
              (.or (.atom "dev_human_direction_role" [d, .lit "police_officer"] [])
                   (.atom "dev_human_direction_role" [d, .lit "railroad_flagger"] []))
              (.atom "dev_human_direction_indication" [d, .lit "stop"] []))))))

/-- s1: stopping is required of the subject's traffic. -/
def stoppingRequired : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] []) (haltRequiredOn "r"))

/-- Lane `l` lies on highway `h`. -/
def onWay (l : String) : Formula := .atom "st_on_way" [.var l, .var "h"] []

def distinct (a b : String) : Formula := .not (.same (.var a) (.var b))

/-- s8: the text's figure, four lanes. -/
def fourLanes : Term := .lit (Units.ratio 4 1) .count
def zeroLanes : Term := .lit Q.zero .count

/-- Lanes `l1 … l4` all lie on highway `h` and are pairwise distinct. -/
def fourDistinctOnWay : Formula :=
  .and (.and (onWay "l1") (onWay "l2"))
    (.and (.and (onWay "l3") (onWay "l4"))
      (.and (.and (distinct "l1" "l2") (distinct "l1" "l3"))
        (.and (.and (distinct "l1" "l4") (distinct "l2" "l3"))
          (.and (distinct "l2" "l4") (distinct "l3" "l4")))))

/-- s8: the highway the subject occupies is marked for four or more lanes: among the lanes of the
    scene there are lanes l1 … l4 such that the number of pairwise distinct lanes of the tuple
    lying on it (four where all four are, otherwise counted as none) is at least four. -/
def fourOrMoreLanes : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.existsRegion (.lit "lane") "l1"
        (.existsRegion (.lit "lane") "l2"
          (.existsRegion (.lit "lane") "l3"
            (.existsRegion (.lit "lane") "l4"
              (.cmp (.cond fourDistinctOnWay fourLanes zeroLanes) .ge fourLanes))))))

/-- Applicability: s1 (trigger): When stopping is required; s2 (condition): at a railroad crossing; s8 (exception): unless the highway is marked for four or more lanes of traffic. -/
def applicability : Formula :=
  .and atCrossing (.and stoppingRequired (.not fourOrMoreLanes))

/-- s7: road user `v` forms a second lane of traffic beside the subject at the crossing. -/
def formsSecondLane : Formula :=
  let v : Arg := .var "v"
  .and (.not (.same v vSubject))
    (.and (.atom "ru_aggregate" [v, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.existsRegion (.lit "lane") "l" (.atom "rel_occupies" [v, .var "l"] []))
        (.and (.existsRegion (.lit "railway_crossing") "c"
                (.and (withinReach "subject" "c") (withinReach "v" "c")))
          (.and (.atom "rel_same_direction" [vSubject, v] [pSideBySideSameDirectionCos])
            (.cmp (.measure "rel_longitudinal_overlap" [vSubject, v]) .gt zeroMetres)))))

/-- Obligation: s7 (obligation): shall not form two lanes of traffic -/
def obligation : Formula := .not (.existsUser "v" formsSecondLane)

def rule : Rule :=
  { id := "NRS_484B_560_3_o2"
    laws := ["NRS-484B-560-3"]
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

end TrafficSpec.Rules.NRS_484B_560_3_o2
