/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484A.NRS_484A_450_2
import TrafficSpecWitness.NRS_484B.NRS_484B_113_2
import TrafficSpecWitness.NRS_484B.NRS_484B_127_2
import TrafficSpecWitness.NRS_484B.NRS_484B_220_1
import TrafficSpecWitness.NRS_484B.NRS_484B_223_1b
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_250_1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_2
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_257_2_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_2_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_307_6a
import TrafficSpecWitness.NRS_484B.NRS_484B_400_2a
import TrafficSpecWitness.NRS_484B.NRS_484B_400_2b
import TrafficSpecWitness.NRS_484B.NRS_484B_407
import TrafficSpecWitness.NRS_484B.NRS_484B_413_2
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1c
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.Concepts.interaction.following_vehicle_ahead
import TrafficSpecWitness.Concepts.interaction.passing_vehicle_ahead
import TrafficSpecWitness.Concepts.interaction.travelling_in_procession
import TrafficSpecWitness.Concepts.lane.enters_region
import TrafficSpecWitness.Concepts.lane.exits_region
import TrafficSpecWitness.Concepts.lane.travels_with_region_direction
import TrafficSpecWitness.Concepts.motion.direction_reversal
import TrafficSpecWitness.Concepts.motion.halted
import TrafficSpecWitness.Concepts.motion.leftward_course_change
import TrafficSpecWitness.Concepts.motion.rearward_motion
import TrafficSpecWitness.Concepts.motion.rightward_course_change
import TrafficSpecWitness.Concepts.motion.turning
import TrafficSpecWitness.Concepts.position.approaching_intersection
import TrafficSpecWitness.Concepts.road.opposed_approach_directions
import TrafficSpecWitness.Concepts.road.two_directional_way
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484A_450_2.scenarios ++
  TrafficSpecWitness.NRS_484B_113_2.scenarios ++
  TrafficSpecWitness.NRS_484B_127_2.scenarios ++
  TrafficSpecWitness.NRS_484B_220_1.scenarios ++
  TrafficSpecWitness.NRS_484B_223_1b.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_250_1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_2.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_257_2_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_2_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_307_6a.scenarios ++
  TrafficSpecWitness.NRS_484B_400_2a.scenarios ++
  TrafficSpecWitness.NRS_484B_400_2b.scenarios ++
  TrafficSpecWitness.NRS_484B_407.scenarios ++
  TrafficSpecWitness.NRS_484B_413_2.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1c.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1e.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.following_vehicle_ahead.instances ++
  TrafficSpecWitness.Concepts.interaction.passing_vehicle_ahead.instances ++
  TrafficSpecWitness.Concepts.interaction.travelling_in_procession.instances ++
  TrafficSpecWitness.Concepts.lane.enters_region.instances ++
  TrafficSpecWitness.Concepts.lane.exits_region.instances ++
  TrafficSpecWitness.Concepts.lane.travels_with_region_direction.instances ++
  TrafficSpecWitness.Concepts.motion.direction_reversal.instances ++
  TrafficSpecWitness.Concepts.motion.halted.instances ++
  TrafficSpecWitness.Concepts.motion.leftward_course_change.instances ++
  TrafficSpecWitness.Concepts.motion.rearward_motion.instances ++
  TrafficSpecWitness.Concepts.motion.rightward_course_change.instances ++
  TrafficSpecWitness.Concepts.motion.turning.instances ++
  TrafficSpecWitness.Concepts.position.approaching_intersection.instances ++
  TrafficSpecWitness.Concepts.road.opposed_approach_directions.instances ++
  TrafficSpecWitness.Concepts.road.two_directional_way.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.following_vehicle_ahead.scenarios ++
  TrafficSpecWitness.Concepts.interaction.passing_vehicle_ahead.scenarios ++
  TrafficSpecWitness.Concepts.interaction.travelling_in_procession.scenarios ++
  TrafficSpecWitness.Concepts.lane.enters_region.scenarios ++
  TrafficSpecWitness.Concepts.lane.exits_region.scenarios ++
  TrafficSpecWitness.Concepts.lane.travels_with_region_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.direction_reversal.scenarios ++
  TrafficSpecWitness.Concepts.motion.halted.scenarios ++
  TrafficSpecWitness.Concepts.motion.leftward_course_change.scenarios ++
  TrafficSpecWitness.Concepts.motion.rearward_motion.scenarios ++
  TrafficSpecWitness.Concepts.motion.rightward_course_change.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning.scenarios ++
  TrafficSpecWitness.Concepts.position.approaching_intersection.scenarios ++
  TrafficSpecWitness.Concepts.road.opposed_approach_directions.scenarios ++
  TrafficSpecWitness.Concepts.road.two_directional_way.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("NRS_484A_450_2", TrafficSpecWitness.NRS_484A_450_2.scenarios),
  ("NRS_484B_113_2", TrafficSpecWitness.NRS_484B_113_2.scenarios),
  ("NRS_484B_127_2", TrafficSpecWitness.NRS_484B_127_2.scenarios),
  ("NRS_484B_220_1", TrafficSpecWitness.NRS_484B_220_1.scenarios),
  ("NRS_484B_223_1b", TrafficSpecWitness.NRS_484B_223_1b.scenarios),
  ("NRS_484B_227_1_o1", TrafficSpecWitness.NRS_484B_227_1_o1.scenarios),
  ("NRS_484B_227_1_o2", TrafficSpecWitness.NRS_484B_227_1_o2.scenarios),
  ("NRS_484B_250_1", TrafficSpecWitness.NRS_484B_250_1.scenarios),
  ("NRS_484B_250_2", TrafficSpecWitness.NRS_484B_250_2.scenarios),
  ("NRS_484B_250_4_o1", TrafficSpecWitness.NRS_484B_250_4_o1.scenarios),
  ("NRS_484B_250_4_o2", TrafficSpecWitness.NRS_484B_250_4_o2.scenarios),
  ("NRS_484B_253_o1", TrafficSpecWitness.NRS_484B_253_o1.scenarios),
  ("NRS_484B_253_o2", TrafficSpecWitness.NRS_484B_253_o2.scenarios),
  ("NRS_484B_257_1_o1", TrafficSpecWitness.NRS_484B_257_1_o1.scenarios),
  ("NRS_484B_257_1_o2", TrafficSpecWitness.NRS_484B_257_1_o2.scenarios),
  ("NRS_484B_257_2_o1", TrafficSpecWitness.NRS_484B_257_2_o1.scenarios),
  ("NRS_484B_257_2_o2", TrafficSpecWitness.NRS_484B_257_2_o2.scenarios),
  ("NRS_484B_307_6a", TrafficSpecWitness.NRS_484B_307_6a.scenarios),
  ("NRS_484B_400_2a", TrafficSpecWitness.NRS_484B_400_2a.scenarios),
  ("NRS_484B_400_2b", TrafficSpecWitness.NRS_484B_400_2b.scenarios),
  ("NRS_484B_407", TrafficSpecWitness.NRS_484B_407.scenarios),
  ("NRS_484B_413_2", TrafficSpecWitness.NRS_484B_413_2.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("NRS_484B_600_1c", TrafficSpecWitness.NRS_484B_600_1c.scenarios),
  ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios),
  ("drv.interaction.following_vehicle_ahead", TrafficSpecWitness.Concepts.interaction.following_vehicle_ahead.scenarios),
  ("drv.interaction.passing_vehicle_ahead", TrafficSpecWitness.Concepts.interaction.passing_vehicle_ahead.scenarios),
  ("drv.interaction.travelling_in_procession", TrafficSpecWitness.Concepts.interaction.travelling_in_procession.scenarios),
  ("drv.lane.enters_region", TrafficSpecWitness.Concepts.lane.enters_region.scenarios),
  ("drv.lane.exits_region", TrafficSpecWitness.Concepts.lane.exits_region.scenarios),
  ("drv.lane.travels_with_region_direction", TrafficSpecWitness.Concepts.lane.travels_with_region_direction.scenarios),
  ("drv.motion.direction_reversal", TrafficSpecWitness.Concepts.motion.direction_reversal.scenarios),
  ("drv.motion.halted", TrafficSpecWitness.Concepts.motion.halted.scenarios),
  ("drv.motion.leftward_course_change", TrafficSpecWitness.Concepts.motion.leftward_course_change.scenarios),
  ("drv.motion.rearward_motion", TrafficSpecWitness.Concepts.motion.rearward_motion.scenarios),
  ("drv.motion.rightward_course_change", TrafficSpecWitness.Concepts.motion.rightward_course_change.scenarios),
  ("drv.motion.turning", TrafficSpecWitness.Concepts.motion.turning.scenarios),
  ("drv.position.approaching_intersection", TrafficSpecWitness.Concepts.position.approaching_intersection.scenarios),
  ("drv.road.opposed_approach_directions", TrafficSpecWitness.Concepts.road.opposed_approach_directions.scenarios),
  ("drv.road.two_directional_way", TrafficSpecWitness.Concepts.road.two_directional_way.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
