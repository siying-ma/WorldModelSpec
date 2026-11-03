/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.Concepts.interaction.behind_in_lane
import TrafficSpecWitness.Concepts.interaction.travels_in_succession_with
import TrafficSpecWitness.Concepts.lane.enters_region
import TrafficSpecWitness.Concepts.lane.exits_region
import TrafficSpecWitness.Concepts.lane.travels_with_region_direction
import TrafficSpecWitness.Concepts.motion.direction_reversal
import TrafficSpecWitness.Concepts.motion.in_motion
import TrafficSpecWitness.Concepts.motion.leftward_course_change
import TrafficSpecWitness.Concepts.motion.rearward_motion
import TrafficSpecWitness.Concepts.motion.rightward_course_change
import TrafficSpecWitness.Concepts.motion.standstill
import TrafficSpecWitness.Concepts.road.barrier_separated_way
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484B_600_1e.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.behind_in_lane.instances ++
  TrafficSpecWitness.Concepts.interaction.travels_in_succession_with.instances ++
  TrafficSpecWitness.Concepts.lane.enters_region.instances ++
  TrafficSpecWitness.Concepts.lane.exits_region.instances ++
  TrafficSpecWitness.Concepts.lane.travels_with_region_direction.instances ++
  TrafficSpecWitness.Concepts.motion.direction_reversal.instances ++
  TrafficSpecWitness.Concepts.motion.in_motion.instances ++
  TrafficSpecWitness.Concepts.motion.leftward_course_change.instances ++
  TrafficSpecWitness.Concepts.motion.rearward_motion.instances ++
  TrafficSpecWitness.Concepts.motion.rightward_course_change.instances ++
  TrafficSpecWitness.Concepts.motion.standstill.instances ++
  TrafficSpecWitness.Concepts.road.barrier_separated_way.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.behind_in_lane.scenarios ++
  TrafficSpecWitness.Concepts.interaction.travels_in_succession_with.scenarios ++
  TrafficSpecWitness.Concepts.lane.enters_region.scenarios ++
  TrafficSpecWitness.Concepts.lane.exits_region.scenarios ++
  TrafficSpecWitness.Concepts.lane.travels_with_region_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.direction_reversal.scenarios ++
  TrafficSpecWitness.Concepts.motion.in_motion.scenarios ++
  TrafficSpecWitness.Concepts.motion.leftward_course_change.scenarios ++
  TrafficSpecWitness.Concepts.motion.rearward_motion.scenarios ++
  TrafficSpecWitness.Concepts.motion.rightward_course_change.scenarios ++
  TrafficSpecWitness.Concepts.motion.standstill.scenarios ++
  TrafficSpecWitness.Concepts.road.barrier_separated_way.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios),
  ("drv.interaction.behind_in_lane", TrafficSpecWitness.Concepts.interaction.behind_in_lane.scenarios),
  ("drv.interaction.travels_in_succession_with", TrafficSpecWitness.Concepts.interaction.travels_in_succession_with.scenarios),
  ("drv.lane.enters_region", TrafficSpecWitness.Concepts.lane.enters_region.scenarios),
  ("drv.lane.exits_region", TrafficSpecWitness.Concepts.lane.exits_region.scenarios),
  ("drv.lane.travels_with_region_direction", TrafficSpecWitness.Concepts.lane.travels_with_region_direction.scenarios),
  ("drv.motion.direction_reversal", TrafficSpecWitness.Concepts.motion.direction_reversal.scenarios),
  ("drv.motion.in_motion", TrafficSpecWitness.Concepts.motion.in_motion.scenarios),
  ("drv.motion.leftward_course_change", TrafficSpecWitness.Concepts.motion.leftward_course_change.scenarios),
  ("drv.motion.rearward_motion", TrafficSpecWitness.Concepts.motion.rearward_motion.scenarios),
  ("drv.motion.rightward_course_change", TrafficSpecWitness.Concepts.motion.rightward_course_change.scenarios),
  ("drv.motion.standstill", TrafficSpecWitness.Concepts.motion.standstill.scenarios),
  ("drv.road.barrier_separated_way", TrafficSpecWitness.Concepts.road.barrier_separated_way.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
