/-
  NRS_484B_257_2_o2 — NRS-484B-257-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    g2 (subject): The driver of a vehicle
    g3 (sibling): shall stop in obedience to a stop sign or yield in compliance with a yield sign, in compliance with the manner prescribed in subsection 1 [NRS-484B-257-1], prior to entering an intersection
    g4 (trigger): if a stop sign or a yield sign is erected at one or more entrances thereto
    g5 (condition): although not a part of a through highway
    g6 (standard): and shall proceed cautiously,
    g7 (obligation): yielding to vehicles not so obligated to stop or yield
    g8 (condition): and which are within the intersection
    g9 (standard): or approaching so closely as to constitute an immediate hazard
    g10 (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    g1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'st.intersection', 'rel.occupies'], derived []
    g2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g4: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []
    g7: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region'], derived []
    g8: atoms ['rel.occupies', 'st.intersection'], derived []
    g10: atoms ['rel.occupies', 'st.intersection', 'kin.speed'], derived ['drv.lane.enters_region']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN (this session's record)

  The junction is one region, selected once by `.existsRegion "intersection" "i"` and re-selected
  in the obligation with the same whole selection (`signedApproach` and `movingInIntersection`), so
  the duty speaks of the junction the applicability found and of no other.

  g2 — the binder's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; the driver is read
  through the vehicle, as the record's narrowing (agency) directs.

  g4 (trigger) — `signedApproach`: a travel region `c` the subject occupies (`rel_occupies`) whose
  entrance end is the selected junction (`st_lane_enters c i`), with a stop sign or a yield sign
  recorded as governing it (`dev_governs` under a quantifier over each sign kind). `c` is required
  not to be the junction itself (`.not (.same c i)`): the junction is a travel region too, an
  approach carrier is never the junction it enters (st.lane_enters: "a carrier enters one
  intersection at most"), and the words single out the entrances to it.

  g5 — residue: no condition, declared by the node.

  g10 (condition) — `movingInIntersection`: the subject enters the junction at this observation
  (`drv.lane.enters_region` on the junction) or its footprint overlaps the junction
  (`rel_occupies`) while its speed (`kin.speed`) is above the motion tolerance. The entry
  observation and the overlap-in-motion observations together are the stretch of time the words
  describe; the entry event is kept as its own limb so that the crossing is read from its first
  observation, where a body that has just broken the boundary may still be below the motion
  tolerance.

  g1 (exception) — `controlledByOfficerOrSignal`, negated in the applicability: the subject is
  traffic (`ru_aggregate` on DEF-NRS-484A-285::traffic) with its anchor at the junction
  (`rel_occupies`), and either a person directing traffic (a quantifier over `dev.human_direction`)
  governs that junction (`dev_governs`) with the role police_officer and an indication given (the
  disjunction over every value the attribute takes, so a device whose indication is unobserved
  leaves the exception unknown rather than false), or a traffic-control signal (a quantifier over
  `dev.traffic_signal`) governs that junction.

  g8/g9 (the vehicles the duty is owed to) — `withinOrApproaching`: the other vehicle's footprint
  overlaps the junction (`rel_occupies`), or it is approaching that junction
  (`drv.position.approaching_intersection`) and the distance from its body to the junction region
  (`st.region_geometry`) is at most its speed (`kin.speed`) times the arrival time — the
  operationalization of g9, a bound that moves with the approaching vehicle's own speed and
  distance.

  g7 (obligation) — `notObligatedAt`: the carrier through which that vehicle approaches the
  junction (a travel region it occupies whose entrance end is that junction, again never the
  junction itself) has no stop sign and no yield sign recorded as governing it, the record's
  reading of "not so obligated to stop or yield". The duty itself is `noPredictedConflict`: under
  the velocities observed at the instant the two centres either do not approach within the conflict
  horizon (`prim.closest_approach_within`) or are no closer than the minimum clearance at their
  closest approach (`prim.closest_approach_distance`).

  g6 (standard) — the subject's speed (`kin.speed`) is at or below the cautious-entry speed, over
  the instants the applicability selects (the entry into the junction and the crossing of it).

  Declared reading: the existence of such a vehicle is written into the applicability (narrowing on
  g7 below), so that a crossing with no unobligated vehicle within or approaching the junction, and
  one where the only such vehicle is itself sign-obligated, are not engaged rather than complied
  with — the verdicts the node's `idle` and `branch_2` scenarios state.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_2_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The variables the formulas quantify. -/
def vIntersection : Arg := .var "i"
def vCarrier : Arg := .var "c"
def vOther : Arg := .var "v"
def vOtherCarrier : Arg := .var "w"
def vDevice : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCautiousEntrySpeedMax : Term := .param "p.cautious_entry_speed_max"
def pImmediateHazardArrivalTime : Term := .param "p.immediate_hazard_arrival_time"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

-- Leaves, written once each.

/-- Membership of the vehicle aggregate of DEF-NRS-484A-320. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
/-- Membership of the traffic aggregate of DEF-NRS-484A-285. -/
def isTraffic (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-285::traffic"] []
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []
/-- The carrier's entrance end is that intersection. -/
def entersAt (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []
def speedOf (x : Arg) : Term := .measure "kin_speed" [x]
/-- The distance from the road user's body to the region. -/
def distanceTo (x r : Arg) : Term := .measure "st_region_geometry_distance" [x, r]

/-- A sign of the given kind is recorded as governing the carrier. -/
def signGoverns (kind : String) (c : Arg) : Formula :=
  .existsDevice (.lit kind) "d" (governs vDevice c)

/-- An indication is given by the person directing traffic: every value the attribute takes. -/
def indicationGiven (d : Arg) : Formula :=
  let ind (k : String) : Formula := .atom "dev_human_direction_indication" [d, .lit k] []
  .or (ind "stop")
    (.or (ind "proceed")
      (.or (ind "slow")
        (.or (ind "turn(left)")
          (.or (ind "turn(right)")
            (.or (ind "turn(straight)") (ind "turn(u_turn)"))))))

/-- g4: a stop sign or a yield sign governs the carrier through which the subject approaches `i`. -/
def signedApproach (i : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (.not (.same vCarrier i))
      (.and (occupies vSubject vCarrier)
        (.and (entersAt vCarrier i)
          (.or (signGoverns "stop_sign" vCarrier) (signGoverns "yield_sign" vCarrier)))))

/-- g10: the subject is moving across or within `i`. -/
def movingInIntersection (i : Arg) : Formula :=
  .or (.derived "drv_lane_enters_region" [vSubject, i] [])
    (.and (occupies vSubject i) (.cmp (speedOf vSubject) .gt pMotionSpeedTolerance))

/-- g1: traffic at `i` is being controlled by a police officer or a traffic-control signal. -/
def controlledByOfficerOrSignal (i : Arg) : Formula :=
  .and (isTraffic vSubject)
    (.and (occupies vSubject i)
      (.or
        (.existsDevice (.lit "human_direction") "d"
          (.and (governs vDevice i)
            (.and (.atom "dev_human_direction_role" [vDevice, .lit "police_officer"] [])
              (indicationGiven vDevice))))
        (.existsDevice (.lit "traffic_signal") "d" (governs vDevice i))))

/-- g8 and g9: the other vehicle is within `i`, or approaching it so closely as to constitute an
    immediate hazard (the gap-acceptance bound of the operationalization). -/
def withinOrApproaching (i : Arg) : Formula :=
  .or (occupies vOther i)
    (.and (.derived "drv_position_approaching_intersection" [vOther, i] [])
      (.cmp (distanceTo vOther i) .le (.mul (speedOf vOther) pImmediateHazardArrivalTime)))

/-- g7: no stop sign and no yield sign governs the carrier through which the other vehicle
    approaches `i`. -/
def notObligatedAt (i : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "w"
    (.and (.not (.same vOtherCarrier i))
      (.and (occupies vOther vOtherCarrier)
        (.and (entersAt vOtherCarrier i)
          (.and (.not (signGoverns "stop_sign" vOtherCarrier))
            (.not (signGoverns "yield_sign" vOtherCarrier))))))

/-- A vehicle other than the subject that is within or approaching `i` and is not itself obligated
    by a stop sign or a yield sign to stop or yield there. -/
def unobligatedClaimant (i : Arg) : Formula :=
  .and (isVehicle vOther)
    (.and (.not (.same vOther vSubject))
      (.and (withinOrApproaching i) (notObligatedAt i)))

/-- g7: the subject brings about no predicted conflict with that vehicle. -/
def noPredictedConflict : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [vSubject, vOther] [pYieldConflictHorizon]))
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pYieldConflictHorizon])
      .ge pYieldMinClearance)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: g1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; g4 (trigger): if a stop sign or a yield sign is erected at one or more entrances thereto; g5 (condition): although not a part of a through highway; g8 (condition): and which are within the intersection; g10 (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (signedApproach vIntersection)
      (.and (movingInIntersection vIntersection)
        (.and (.existsUser "v" (unobligatedClaimant vIntersection))
          (.not (controlledByOfficerOrSignal vIntersection)))))

/-- Obligation: g6 (standard): and shall proceed cautiously,; g7 (obligation): yielding to vehicles not so obligated to stop or yield; g9 (standard): or approaching so closely as to constitute an immediate hazard -/
def obligation : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (signedApproach vIntersection)
      (.and (movingInIntersection vIntersection)
        (.and (.cmp (speedOf vSubject) .le pCautiousEntrySpeedMax)
          (.forallUser "v" (.implies (unobligatedClaimant vIntersection) noPredictedConflict)))))

def rule : Rule :=
  { id := "NRS_484B_257_2_o2"
    laws := ["NRS-484B-257-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proceed cautiously"
          concepts := ["drv.lane.enters_region", "kin.speed", "rel.occupies", "st.intersection"]
          params := ["p.cautious_entry_speed_max"]
          convention := "intersection-entry speed convention: a driver proceeds cautiously across a junction it has stopped or yielded for where its speed (kin.speed) while its footprint overlaps the junction is at or below the crawl speed at which it can give way to a vehicle already there, the same bound the run uses for the cautious proceeding of NRS_484B_250_4_o2"
          surrogate := false }
      , { standard := "approaching so closely as to constitute an immediate hazard"
          concepts := ["drv.position.approaching_intersection", "kin.speed", "rel.occupies", "st.intersection", "st.lane_enters", "st.region_geometry", "st.travel_region"]
          params := ["p.immediate_hazard_arrival_time"]
          convention := "gap-acceptance convention for a vehicle entering from a stop or yield controlled approach: a vehicle approaching the junction is so close as to constitute an immediate hazard where the distance from its body to the junction region (st.region_geometry) is at most its observed speed times the arrival time, that is where it would reach the junction within the time a passenger car needs to clear it from the controlled approach; the bound moves with the approaching vehicle's own speed and its own distance"
          surrogate := false } ]
    residues := ["\"although not a part of a through highway\" adds no condition to the duty: it says the duty holds at such an entrance even where the junction is no part of a through highway, so the obligation is the same whether or not the ways at the junction have that status."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "g7"
          why := "the vehicles the duty is owed to are written into the applicability as well as the obligation: the rule is engaged only where the scene holds a vehicle, other than the subject, that is within the intersection or approaching it as an immediate hazard and has no stop sign or yield sign recorded as governing its own approach carrier. A crossing with no such vehicle, and one where the only such vehicle is itself sign-obligated, are therefore not engaged rather than complied with, which is the verdict the node's `idle` and `branch_2` scenarios state for them."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_2_o2
