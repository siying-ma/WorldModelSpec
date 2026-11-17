/-
  NRS_484B_560_3_o1 — NRS-484B-560-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When stopping is required
    s2 (condition): at a railroad crossing
    s3 (subject): the driver
    s4 (obligation): shall keep as far to the right of the highway
    s5 (standard): as possible
    s6 (boilerplate): and
    s7 (sibling): shall not form two lanes of traffic
    s8 (sibling): unless the highway is marked for four or more lanes of traffic.

  Elements (span → atoms, derived):
    s1: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s2: atoms ['st.railway_crossing', 'st.region_geometry'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.road_edge', 'prim.region_lateral_offset'], derived []

  How each is written:
    s3: `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)` — the binder's class.
    s1: some travel region r (quantifier over `travel_region`, which covers every kind refining it)
        that the subject occupies (`rel_occupies`) is governed (`dev_governs`) by a device requiring
        a halt at this observation: a railway signal or gate (quantifier kind) with lights flashing
        or gate lowering/down; a stop sign (quantifier kind); a traffic signal (quantifier kind)
        showing circular_red; a human direction (quantifier kind) of role police_officer or
        railroad_flagger giving stop.
    s2: some railway crossing c (quantifier kind) with the ground distance from the subject's body
        to c (`st_region_geometry_distance`) at most p.railroad_crossing_approach_reach.
    s4+s5: some highway h the subject occupies, and some road edge e lying on h (`st_on_way(e, h)`),
        with the signed lateral offset of e from the subject (`prim_region_lateral_offset`) below
        zero (on the right) and the ground distance from the body to e at most p.pullover_edge_gap.
  No choice beyond the record's own was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_560_3_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPulloverEdgeGap : Term := .param "p.pullover_edge_gap"
def pRailroadCrossingApproachReach : Term := .param "p.railroad_crossing_approach_reach"

def zeroMetres : Term := .lit Q.zero .metre

def vR : Arg := .var "r"
def vD : Arg := .var "d"
def vC : Arg := .var "c"
def vH : Arg := .var "h"
def vE : Arg := .var "e"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: a railway signal or gate governing r with lights flashing or gate lowering or down. -/
def railwayHalt : Formula :=
  .existsDevice (.lit "railway_signal_or_gate") "d"
    (.and (.atom "dev_governs" [vD, vR] [])
      (.or (.atom "dev_railway_signal_or_gate_lights" [vD, .lit "flashing"] [])
        (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "lowering"] [])
          (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "down"] []))))

/-- s1: a stop sign governing r. -/
def stopSignHalt : Formula :=
  .existsDevice (.lit "stop_sign") "d" (.atom "dev_governs" [vD, vR] [])

/-- s1: a traffic signal governing r displaying circular red. -/
def signalHalt : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_governs" [vD, vR] [])
      (.atom "dev_traffic_signal_shows" [vD, .lit "circular_red"] []))

/-- s1: a police officer or railroad flagger directing r's traffic to stop. -/
def humanHalt : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_governs" [vD, vR] [])
      (.and
        (.or (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
          (.atom "dev_human_direction_role" [vD, .lit "railroad_flagger"] []))
        (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])))

/-- s1 (trigger): stopping is required of the traffic of a travel region the subject occupies. -/
def stoppingRequired : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.or railwayHalt (.or stopSignHalt (.or signalHalt humanHalt))))

/-- s2 (condition): the subject's body is within the approach reach of a railroad crossing. -/
def atRailroadCrossing : Formula :=
  .existsRegion (.lit "railway_crossing") "c"
    (.cmp (.measure "st_region_geometry_distance" [vSubject, vC]) .le pRailroadCrossingApproachReach)

/-- Applicability: s1 (trigger): When stopping is required; s2 (condition): at a railroad crossing -/
def applicability : Formula := .and stoppingRequired atRailroadCrossing

/-- Obligation: s4 (obligation): shall keep as far to the right of the highway; s5 (standard): as possible -/
def obligation : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, vH] [])
      (.existsRegion (.lit "road_edge") "e"
        (.and (.atom "st_on_way" [vE, vH] [])
          (.and (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vE] []) .lt zeroMetres)
            (.cmp (.measure "st_region_geometry_distance" [vSubject, vE]) .le pPulloverEdgeGap)))))

def rule : Rule :=
  { id := "NRS_484B_560_3_o1"
    laws := ["NRS-484B-560-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "as far to the right of the highway as possible"
          concepts := ["prim.region_lateral_offset", "st.region_geometry", "st.road_edge"]
          params := ["p.pullover_edge_gap"]
          convention := "A vehicle kept as far right as it can be placed stands with its body within the curb clearance of a parallel-parked car plus lane-keeping variability and an edge margin of the right-hand edge of the roadway: the ground distance from its body to a road edge on its right (st.region_geometry, prim.region_lateral_offset negative) is at most p.pullover_edge_gap. A vehicle in any lane but the rightmost, or wandering left within the rightmost, is farther."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_560_3_o1
