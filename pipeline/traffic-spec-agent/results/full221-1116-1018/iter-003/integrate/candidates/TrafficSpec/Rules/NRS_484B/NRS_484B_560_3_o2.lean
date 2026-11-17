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
    s3: the binder class, `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s2: some region c of kind railway_crossing with the ground distance from the subject's body
        (`st_region_geometry_distance`) at most p.railroad_crossing_approach_reach.
    s1: some travel region r the subject occupies (`rel_occupies`) is governed (`dev_governs`) by a
        device requiring a halt: a railway signal or gate with lights flashing or gate lowering or
        down; a stop sign; a traffic signal showing circular_red; a human direction of role
        police_officer or railroad_flagger with indication stop.
    s8: the exception, negated in the applicability: some highway h the subject occupies has four
        lanes l1..l4 lying on it (`st_on_way`), pairwise distinct (`not (same …)`). No count
        operator ranges over regions, so the lane count is the term `lanesOnWayUpToFour`: four
        (the text's literal, `.count`) where four pairwise distinct lanes lie on h, zero
        otherwise. The exception holds where that count is at least four.
    s7: for every crossing c selected as in s2 (the applicability's whole selection of c, written
        again), no road user v other than the subject, of DEF-NRS-484A-285::traffic, occupying a
        lane, with its body within p.railroad_crossing_approach_reach of c, has the subject's
        heading (`rel_same_direction` with p.side_by_side_same_direction_cos) and a positive
        longitudinal overlap with the subject.

  No choice beyond the record's own readings was made; `narrowings` is empty.

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

/-- Conjunction of a list of formulas. -/
def allOf : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (allOf rest)

/-- Disjunction of a list of formulas. -/
def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

/-- A road user's body within the approach reach of crossing `c` (s2). -/
def nearCrossing (x c : String) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [.var x, .var c]) .le pRailroadCrossingApproachReach

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: the subject is at a railroad crossing. -/
def atCrossing : Formula :=
  .existsRegion (.lit "railway_crossing") "c" (nearCrossing "subject" "c")

/-- s1: a device governing travel region `r` requires a halt of its traffic. -/
def haltRequiredAt (r : String) : Formula :=
  anyOf
    [ .existsDevice (.lit "railway_signal_or_gate") "dRail"
        (.and (.atom "dev_governs" [.var "dRail", .var r] [])
          (anyOf
            [ .atom "dev_railway_signal_or_gate_lights" [.var "dRail", .lit "flashing"] []
            , .atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "lowering"] []
            , .atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "down"] [] ]))
    , .existsDevice (.lit "stop_sign") "dStop"
        (.atom "dev_governs" [.var "dStop", .var r] [])
    , .existsDevice (.lit "traffic_signal") "dSignal"
        (.and (.atom "dev_governs" [.var "dSignal", .var r] [])
          (.atom "dev_traffic_signal_shows" [.var "dSignal", .lit "circular_red"] []))
    , .existsDevice (.lit "human_direction") "dHuman"
        (allOf
          [ .atom "dev_governs" [.var "dHuman", .var r] []
          , anyOf
              [ .atom "dev_human_direction_role" [.var "dHuman", .lit "police_officer"] []
              , .atom "dev_human_direction_role" [.var "dHuman", .lit "railroad_flagger"] [] ]
          , .atom "dev_human_direction_indication" [.var "dHuman", .lit "stop"] [] ]) ]

/-- s1: stopping is required of a travel region the subject occupies. -/
def stoppingRequired : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] []) (haltRequiredAt "r"))

/-- Lane `l` lies on highway `h`. -/
def onWay (l : String) : Formula := .atom "st_on_way" [.var l, .var "h"] []

def distinct (a b : String) : Formula := .not (.same (.var a) (.var b))

/-- s8: the text's figure, four lanes. -/
def fourLanes : Term := .lit (Q.ofInt 4) .count
def zeroCount : Term := .lit Q.zero .count

/-- Four pairwise distinct lanes lie on highway `h`. -/
def fourDistinctLanesOn : Formula :=
  .existsRegion (.lit "lane") "l1"
    (.and (onWay "l1")
      (.existsRegion (.lit "lane") "l2"
        (allOf
          [ onWay "l2", distinct "l1" "l2"
          , .existsRegion (.lit "lane") "l3"
              (allOf
                [ onWay "l3", distinct "l1" "l3", distinct "l2" "l3"
                , .existsRegion (.lit "lane") "l4"
                    (allOf
                      [ onWay "l4", distinct "l1" "l4", distinct "l2" "l4"
                      , distinct "l3" "l4" ]) ]) ])))

/-- The number of lanes on `h`, counted as far as the threshold needs: four where four pairwise
    distinct lanes lie on it, zero otherwise. -/
def lanesOnWayUpToFour : Term := .cond fourDistinctLanesOn fourLanes zeroCount

/-- s8: the highway the subject occupies is marked for four or more lanes. -/
def fourLaneHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.cmp lanesOnWayUpToFour .ge fourLanes))

/-- Applicability: s1 (trigger): When stopping is required; s2 (condition): at a railroad crossing; s8 (exception): unless the highway is marked for four or more lanes of traffic. -/
def applicability : Formula :=
  allOf [atCrossing, stoppingRequired, .not fourLaneHighway]

/-- s7: road user `v` forms a second lane of traffic beside the subject at crossing `c`. -/
def secondLineAt (c : String) : Formula :=
  allOf
    [ .not (.same (.var "v") vSubject)
    , .atom "ru_aggregate" [.var "v", .lit "DEF-NRS-484A-285::traffic"] []
    , .existsRegion (.lit "lane") "lv" (.atom "rel_occupies" [.var "v", .var "lv"] [])
    , nearCrossing "v" c
    , .atom "rel_same_direction" [vSubject, .var "v"] [pSideBySideSameDirectionCos]
    , .cmp (.measure "rel_longitudinal_overlap" [vSubject, .var "v"]) .gt zeroMetres ]

/-- Obligation: s7 (obligation): shall not form two lanes of traffic -/
def obligation : Formula :=
  .forallRegion (.lit "railway_crossing") "c"
    (.implies (nearCrossing "subject" "c")
      (.not (.existsUser "v" (secondLineAt "c"))))

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
