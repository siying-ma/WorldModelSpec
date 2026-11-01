/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484A.NRS_484A_450_2
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.Concepts.interaction.caravan
import TrafficSpecWitness.Concepts.interaction.following
import TrafficSpecWitness.Concepts.interaction.overtaking
import TrafficSpecWitness.Concepts.lane.begins_departure_from_region
import TrafficSpecWitness.Concepts.motion.backing
import TrafficSpecWitness.Concepts.motion.decelerating
import TrafficSpecWitness.Concepts.motion.proceeds_through_region
import TrafficSpecWitness.Concepts.motion.standstill
import TrafficSpecWitness.Concepts.motion.travels_against_region_direction
import TrafficSpecWitness.Concepts.motion.travels_with_region_direction
import TrafficSpecWitness.Concepts.motion.turn_left
import TrafficSpecWitness.Concepts.motion.turn_right
import TrafficSpecWitness.Concepts.motion.turning_right_within_region
import TrafficSpecWitness.Concepts.motion.u_turn
import TrafficSpecWitness.Concepts.road.undivided_opposed_directions
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484A_450_2.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1e.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.caravan.instances ++
  TrafficSpecWitness.Concepts.interaction.following.instances ++
  TrafficSpecWitness.Concepts.interaction.overtaking.instances ++
  TrafficSpecWitness.Concepts.lane.begins_departure_from_region.instances ++
  TrafficSpecWitness.Concepts.motion.backing.instances ++
  TrafficSpecWitness.Concepts.motion.decelerating.instances ++
  TrafficSpecWitness.Concepts.motion.proceeds_through_region.instances ++
  TrafficSpecWitness.Concepts.motion.standstill.instances ++
  TrafficSpecWitness.Concepts.motion.travels_against_region_direction.instances ++
  TrafficSpecWitness.Concepts.motion.travels_with_region_direction.instances ++
  TrafficSpecWitness.Concepts.motion.turn_left.instances ++
  TrafficSpecWitness.Concepts.motion.turn_right.instances ++
  TrafficSpecWitness.Concepts.motion.turning_right_within_region.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances ++
  TrafficSpecWitness.Concepts.road.undivided_opposed_directions.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.caravan.scenarios ++
  TrafficSpecWitness.Concepts.interaction.following.scenarios ++
  TrafficSpecWitness.Concepts.interaction.overtaking.scenarios ++
  TrafficSpecWitness.Concepts.lane.begins_departure_from_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.backing.scenarios ++
  TrafficSpecWitness.Concepts.motion.decelerating.scenarios ++
  TrafficSpecWitness.Concepts.motion.proceeds_through_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.standstill.scenarios ++
  TrafficSpecWitness.Concepts.motion.travels_against_region_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.travels_with_region_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.turn_left.scenarios ++
  TrafficSpecWitness.Concepts.motion.turn_right.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning_right_within_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios ++
  TrafficSpecWitness.Concepts.road.undivided_opposed_directions.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("NRS_484A_450_2", TrafficSpecWitness.NRS_484A_450_2.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios),
  ("drv.interaction.caravan", TrafficSpecWitness.Concepts.interaction.caravan.scenarios),
  ("drv.interaction.following", TrafficSpecWitness.Concepts.interaction.following.scenarios),
  ("drv.interaction.overtaking", TrafficSpecWitness.Concepts.interaction.overtaking.scenarios),
  ("drv.lane.begins_departure_from_region", TrafficSpecWitness.Concepts.lane.begins_departure_from_region.scenarios),
  ("drv.motion.backing", TrafficSpecWitness.Concepts.motion.backing.scenarios),
  ("drv.motion.decelerating", TrafficSpecWitness.Concepts.motion.decelerating.scenarios),
  ("drv.motion.proceeds_through_region", TrafficSpecWitness.Concepts.motion.proceeds_through_region.scenarios),
  ("drv.motion.standstill", TrafficSpecWitness.Concepts.motion.standstill.scenarios),
  ("drv.motion.travels_against_region_direction", TrafficSpecWitness.Concepts.motion.travels_against_region_direction.scenarios),
  ("drv.motion.travels_with_region_direction", TrafficSpecWitness.Concepts.motion.travels_with_region_direction.scenarios),
  ("drv.motion.turn_left", TrafficSpecWitness.Concepts.motion.turn_left.scenarios),
  ("drv.motion.turn_right", TrafficSpecWitness.Concepts.motion.turn_right.scenarios),
  ("drv.motion.turning_right_within_region", TrafficSpecWitness.Concepts.motion.turning_right_within_region.scenarios),
  ("drv.motion.u_turn", TrafficSpecWitness.Concepts.motion.u_turn.scenarios),
  ("drv.road.undivided_opposed_directions", TrafficSpecWitness.Concepts.road.undivided_opposed_directions.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
