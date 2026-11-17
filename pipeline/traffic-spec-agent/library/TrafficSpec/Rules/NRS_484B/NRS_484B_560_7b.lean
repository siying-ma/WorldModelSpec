/-
  NRS_484B_560_7b — NRS-484B-560-7b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (subject): It is unlawful for the driver of any vehicle:
    b2 (obligation): To fail to obey an official traffic-control device or the directions of a police officer
    b3 (condition): at a railroad crossing.

  Elements (span → atoms, derived):
    b1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b2: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.human_direction', 'rel.occupies', 'st.travel_region', 'st.region_geometry', 'prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.rail_vehicle'], derived ['drv.motion.complete_halt']
    b3: atoms ['rel.occupies', 'st.railway_crossing'], derived []

  How each span is written:
    b1: `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    b3: the entry into a railroad crossing c: `rises (rel_occupies subject c)` for some region of kind
        `railway_crossing` (applicability). The obligation re-selects the same crossing by the same
        whole selection (every railway crossing c whose occupancy by the subject rises here).
    b2: at that entry, for every region r of kind `travel_region` the subject occupies, and every device
        d of each claimed kind that governs r (`dev_governs d r`):
        (i)   railway_signal_or_gate: lights not `flashing`, gate not `lowering`/`down`/`raising`;
        (ii)  traffic_signal: does not show `circular_red`;
        (iii) human_direction with role `police_officer`: indication not `stop`;
        (iv)  yield_sign: no road user q that is `ru_rail_vehicle` has
              `prim_closest_approach_within(subject, q)` over p.conflict_horizon with
              `prim_closest_approach_distance(subject, q)` at most p.conflict_centre_clearance;
        (v)   stop_sign: the subject halted before this entry. The search back from the entry is
              `χ := since (¬occ(c) ∧ dist(c) ≤ reach) H` with
              `H := complete_halt(subject; p.halt_speed_tolerance) ∧ ¬occ(c) ∧ dist(c) ≤ reach`,
              dist = `st_region_geometry_distance(subject, c)`, reach = p.railroad_crossing_approach_reach.
              χ holds at an observation when a halt within the reach and off the crossing is found at it
              or before it with every observation since off the crossing and within the reach; an
              observation farther than the reach (the approach start) or one on the crossing (the
              previous entry and its stay) ends the search. The search runs back from the observation
              before the entry: at the entry χ is false (the subject overlaps c), so χ at the previous
              observation is `rises (¬χ)` at the entry. A trace that starts within the reach with no
              halt leaves χ unknown (`since` truncated), as does an unobserved distance read.
    Where no device governs an occupied travel region, every device quantifier is vacuous: complied.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_560_7b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pRailroadCrossingApproachReach : Term := .param "p.railroad_crossing_approach_reach"

def zeroMetres : Term := .lit Q.zero .metre

def vC : Arg := .var "c"
def vR : Arg := .var "r"
def vD : Arg := .var "d"
def vQ : Arg := .var "q"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject's footprint overlaps crossing `c` (rel.occupies). -/
def occCrossing : Formula := .atom "rel_occupies" [vSubject, vC] []

/-- The subject enters crossing `c` at this observation. -/
def entersCrossing : Formula := .rises occCrossing

/-- Applicability: b3 (condition): at a railroad crossing. -/
def applicability : Formula := .existsRegion (.lit "railway_crossing") "c" entersCrossing

/-- The subject's body is within the approach reach of crossing `c` (st.region_geometry). -/
def withinReach : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vSubject, vC]) .le pRailroadCrossingApproachReach

/-- An observation on the approach: off the crossing, within the reach. -/
def onApproach : Formula := .and (.not occCrossing) withinReach

/-- A halt that counts: at rest, off the crossing, within the reach. -/
def haltOnApproach : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]) onApproach

/-- The halt found searching back to the approach start or the previous stay on the crossing. -/
def haltFound : Formula := .since onApproach haltOnApproach

/-- (v) at the entry: the search, from the observation before it, finds the halt. -/
def stopObeyed : Formula := .rises (.not haltFound)

def governed : Formula := .atom "dev_governs" [vD, vR] []

/-- (i) railway lights and gate. -/
def railwayObeyed : Formula :=
  .forallDevice (.lit "railway_signal_or_gate") "d"
    (.implies governed
      (.and (.not (.atom "dev_railway_signal_or_gate_lights" [vD, .lit "flashing"] []))
        (.not (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "lowering"] [])
          (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "down"] [])
            (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "raising"] []))))))

/-- (ii) a traffic signal's circular red. -/
def signalObeyed : Formula :=
  .forallDevice (.lit "traffic_signal") "d"
    (.implies governed (.not (.atom "dev_traffic_signal_shows" [vD, .lit "circular_red"] [])))

/-- (iii) a police officer's stop. -/
def officerObeyed : Formula :=
  .forallDevice (.lit "human_direction") "d"
    (.implies (.and governed (.atom "dev_human_direction_role" [vD, .lit "police_officer"] []))
      (.not (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])))

/-- (iv) a yield sign: no rail vehicle in conflict. -/
def yieldObeyed : Formula :=
  .forallDevice (.lit "yield_sign") "d"
    (.implies governed
      (.forallUser "q"
        (.implies (.atom "ru_rail_vehicle" [vQ] [])
          (.not (.and (.derived "prim_closest_approach_within" [vSubject, vQ] [pConflictHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vQ] [pConflictHorizon])
              .le pConflictCentreClearance))))))

/-- (v) a stop sign: halted before the entry. -/
def stopSignObeyed : Formula :=
  .forallDevice (.lit "stop_sign") "d" (.implies governed stopObeyed)

/-- Obligation: b2 (obligation): To fail to obey an official traffic-control device or the directions of a police officer -/
def obligation : Formula :=
  .forallRegion (.lit "railway_crossing") "c"
    (.implies entersCrossing
      (.forallRegion (.lit "travel_region") "r"
        (.implies (.atom "rel_occupies" [vSubject, vR] [])
          (.and railwayObeyed
            (.and signalObeyed
              (.and officerObeyed
                (.and yieldObeyed stopSignObeyed)))))))

def rule : Rule :=
  { id := "NRS_484B_560_7b"
    laws := ["NRS-484B-560-7b"]
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

end TrafficSpec.Rules.NRS_484B_560_7b
