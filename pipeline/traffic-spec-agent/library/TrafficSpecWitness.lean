/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_307_6a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign
import TrafficSpecWitness.Concepts.control.intersection_controlled
import TrafficSpecWitness.Concepts.interaction.following_in_lane
import TrafficSpecWitness.Concepts.interaction.following_on_way
import TrafficSpecWitness.Concepts.interaction.from_different_ways
import TrafficSpecWitness.Concepts.lane.lane_change
import TrafficSpecWitness.Concepts.lane.marked_lane_departure
import TrafficSpecWitness.Concepts.lane.travel_with_designated_direction
import TrafficSpecWitness.Concepts.motion.at_rest
import TrafficSpecWitness.Concepts.motion.backing
import TrafficSpecWitness.Concepts.motion.left_turn
import TrafficSpecWitness.Concepts.motion.u_turn
import TrafficSpecWitness.Concepts.road.on_divided_highway
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484B_250_4_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_307_6a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1e.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign.instances ++
  TrafficSpecWitness.Concepts.control.intersection_controlled.instances ++
  TrafficSpecWitness.Concepts.interaction.following_in_lane.instances ++
  TrafficSpecWitness.Concepts.interaction.following_on_way.instances ++
  TrafficSpecWitness.Concepts.interaction.from_different_ways.instances ++
  TrafficSpecWitness.Concepts.lane.lane_change.instances ++
  TrafficSpecWitness.Concepts.lane.marked_lane_departure.instances ++
  TrafficSpecWitness.Concepts.lane.travel_with_designated_direction.instances ++
  TrafficSpecWitness.Concepts.motion.at_rest.instances ++
  TrafficSpecWitness.Concepts.motion.backing.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances ++
  TrafficSpecWitness.Concepts.road.on_divided_highway.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign.scenarios ++
  TrafficSpecWitness.Concepts.control.intersection_controlled.scenarios ++
  TrafficSpecWitness.Concepts.interaction.following_in_lane.scenarios ++
  TrafficSpecWitness.Concepts.interaction.following_on_way.scenarios ++
  TrafficSpecWitness.Concepts.interaction.from_different_ways.scenarios ++
  TrafficSpecWitness.Concepts.lane.lane_change.scenarios ++
  TrafficSpecWitness.Concepts.lane.marked_lane_departure.scenarios ++
  TrafficSpecWitness.Concepts.lane.travel_with_designated_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.at_rest.scenarios ++
  TrafficSpecWitness.Concepts.motion.backing.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios ++
  TrafficSpecWitness.Concepts.road.on_divided_highway.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("NRS_484B_250_4_o1", TrafficSpecWitness.NRS_484B_250_4_o1.scenarios),
  ("NRS_484B_250_4_o2", TrafficSpecWitness.NRS_484B_250_4_o2.scenarios),
  ("NRS_484B_307_6a", TrafficSpecWitness.NRS_484B_307_6a.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios),
  ("drv.control.approach_without_stop_or_yield_sign", TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign.scenarios),
  ("drv.control.intersection_controlled", TrafficSpecWitness.Concepts.control.intersection_controlled.scenarios),
  ("drv.interaction.following_in_lane", TrafficSpecWitness.Concepts.interaction.following_in_lane.scenarios),
  ("drv.interaction.following_on_way", TrafficSpecWitness.Concepts.interaction.following_on_way.scenarios),
  ("drv.interaction.from_different_ways", TrafficSpecWitness.Concepts.interaction.from_different_ways.scenarios),
  ("drv.lane.lane_change", TrafficSpecWitness.Concepts.lane.lane_change.scenarios),
  ("drv.lane.marked_lane_departure", TrafficSpecWitness.Concepts.lane.marked_lane_departure.scenarios),
  ("drv.lane.travel_with_designated_direction", TrafficSpecWitness.Concepts.lane.travel_with_designated_direction.scenarios),
  ("drv.motion.at_rest", TrafficSpecWitness.Concepts.motion.at_rest.scenarios),
  ("drv.motion.backing", TrafficSpecWitness.Concepts.motion.backing.scenarios),
  ("drv.motion.left_turn", TrafficSpecWitness.Concepts.motion.left_turn.scenarios),
  ("drv.motion.u_turn", TrafficSpecWitness.Concepts.motion.u_turn.scenarios),
  ("drv.road.on_divided_highway", TrafficSpecWitness.Concepts.road.on_divided_highway.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
