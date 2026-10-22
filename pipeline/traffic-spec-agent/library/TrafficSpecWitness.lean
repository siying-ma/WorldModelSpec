/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484B.NRS_484B_307_6a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign
import TrafficSpecWitness.Concepts.control.intersection_controlled
import TrafficSpecWitness.Concepts.interaction.following
import TrafficSpecWitness.Concepts.interaction.from_different_ways
import TrafficSpecWitness.Concepts.lane.lane_change
import TrafficSpecWitness.Concepts.lane.marked_lane_departure
import TrafficSpecWitness.Concepts.lane.travel_with_designated_direction
import TrafficSpecWitness.Concepts.motion.backing
import TrafficSpecWitness.Concepts.motion.halted
import TrafficSpecWitness.Concepts.motion.left_turn
import TrafficSpecWitness.Concepts.motion.u_turn
import TrafficSpecWitness.Concepts.road.on_curve
import TrafficSpecWitness.Concepts.road.on_divided_highway
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484B_307_6a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1e.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign.instances ++
  TrafficSpecWitness.Concepts.control.intersection_controlled.instances ++
  TrafficSpecWitness.Concepts.interaction.following.instances ++
  TrafficSpecWitness.Concepts.interaction.from_different_ways.instances ++
  TrafficSpecWitness.Concepts.lane.lane_change.instances ++
  TrafficSpecWitness.Concepts.lane.marked_lane_departure.instances ++
  TrafficSpecWitness.Concepts.lane.travel_with_designated_direction.instances ++
  TrafficSpecWitness.Concepts.motion.backing.instances ++
  TrafficSpecWitness.Concepts.motion.halted.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances ++
  TrafficSpecWitness.Concepts.road.on_curve.instances ++
  TrafficSpecWitness.Concepts.road.on_divided_highway.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign.scenarios ++
  TrafficSpecWitness.Concepts.control.intersection_controlled.scenarios ++
  TrafficSpecWitness.Concepts.interaction.following.scenarios ++
  TrafficSpecWitness.Concepts.interaction.from_different_ways.scenarios ++
  TrafficSpecWitness.Concepts.lane.lane_change.scenarios ++
  TrafficSpecWitness.Concepts.lane.marked_lane_departure.scenarios ++
  TrafficSpecWitness.Concepts.lane.travel_with_designated_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.backing.scenarios ++
  TrafficSpecWitness.Concepts.motion.halted.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios ++
  TrafficSpecWitness.Concepts.road.on_curve.scenarios ++
  TrafficSpecWitness.Concepts.road.on_divided_highway.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Run every witness against the registered rules and concepts with a reading; the failures, by name. -/
def failures (ρ : Reading) : List String :=
  (allScenarios ++ allConceptScenarios).filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some e
end TrafficSpecWitness
