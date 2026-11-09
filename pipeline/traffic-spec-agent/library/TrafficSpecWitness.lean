/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484A.NRS_484A_450_2
import TrafficSpecWitness.NRS_484B.NRS_484B_113_2
import TrafficSpecWitness.NRS_484B.NRS_484B_127_1
import TrafficSpecWitness.NRS_484B.NRS_484B_127_2
import TrafficSpecWitness.NRS_484B.NRS_484B_127_3
import TrafficSpecWitness.NRS_484B.NRS_484B_220_1
import TrafficSpecWitness.NRS_484B.NRS_484B_223_1b
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_257_2_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_307_6a
import TrafficSpecWitness.NRS_484B.NRS_484B_400_2a
import TrafficSpecWitness.NRS_484B.NRS_484B_400_2b
import TrafficSpecWitness.NRS_484B.NRS_484B_407
import TrafficSpecWitness.NRS_484B.NRS_484B_413_2
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1c
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.Concepts.interaction.following
import TrafficSpecWitness.Concepts.interaction.overtaking
import TrafficSpecWitness.Concepts.interaction.vehicle_file
import TrafficSpecWitness.Concepts.lane.lane_change
import TrafficSpecWitness.Concepts.motion.left_turn
import TrafficSpecWitness.Concepts.motion.region_entry
import TrafficSpecWitness.Concepts.motion.region_exit
import TrafficSpecWitness.Concepts.motion.reverse_travel
import TrafficSpecWitness.Concepts.motion.standstill
import TrafficSpecWitness.Concepts.motion.turning
import TrafficSpecWitness.Concepts.motion.u_turn
import TrafficSpecWitness.Concepts.position.direction_component
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484A_450_2.scenarios ++
  TrafficSpecWitness.NRS_484B_113_2.scenarios ++
  TrafficSpecWitness.NRS_484B_127_1.scenarios ++
  TrafficSpecWitness.NRS_484B_127_2.scenarios ++
  TrafficSpecWitness.NRS_484B_127_3.scenarios ++
  TrafficSpecWitness.NRS_484B_220_1.scenarios ++
  TrafficSpecWitness.NRS_484B_223_1b.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o2.scenarios ++
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
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.following.instances ++
  TrafficSpecWitness.Concepts.interaction.overtaking.instances ++
  TrafficSpecWitness.Concepts.interaction.vehicle_file.instances ++
  TrafficSpecWitness.Concepts.lane.lane_change.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn.instances ++
  TrafficSpecWitness.Concepts.motion.region_entry.instances ++
  TrafficSpecWitness.Concepts.motion.region_exit.instances ++
  TrafficSpecWitness.Concepts.motion.reverse_travel.instances ++
  TrafficSpecWitness.Concepts.motion.standstill.instances ++
  TrafficSpecWitness.Concepts.motion.turning.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances ++
  TrafficSpecWitness.Concepts.position.direction_component.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.following.scenarios ++
  TrafficSpecWitness.Concepts.interaction.overtaking.scenarios ++
  TrafficSpecWitness.Concepts.interaction.vehicle_file.scenarios ++
  TrafficSpecWitness.Concepts.lane.lane_change.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn.scenarios ++
  TrafficSpecWitness.Concepts.motion.region_entry.scenarios ++
  TrafficSpecWitness.Concepts.motion.region_exit.scenarios ++
  TrafficSpecWitness.Concepts.motion.reverse_travel.scenarios ++
  TrafficSpecWitness.Concepts.motion.standstill.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios ++
  TrafficSpecWitness.Concepts.position.direction_component.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("NRS_484A_450_2", TrafficSpecWitness.NRS_484A_450_2.scenarios),
  ("NRS_484B_113_2", TrafficSpecWitness.NRS_484B_113_2.scenarios),
  ("NRS_484B_127_1", TrafficSpecWitness.NRS_484B_127_1.scenarios),
  ("NRS_484B_127_2", TrafficSpecWitness.NRS_484B_127_2.scenarios),
  ("NRS_484B_127_3", TrafficSpecWitness.NRS_484B_127_3.scenarios),
  ("NRS_484B_220_1", TrafficSpecWitness.NRS_484B_220_1.scenarios),
  ("NRS_484B_223_1b", TrafficSpecWitness.NRS_484B_223_1b.scenarios),
  ("NRS_484B_227_1_o1", TrafficSpecWitness.NRS_484B_227_1_o1.scenarios),
  ("NRS_484B_227_1_o2", TrafficSpecWitness.NRS_484B_227_1_o2.scenarios),
  ("NRS_484B_250_4_o1", TrafficSpecWitness.NRS_484B_250_4_o1.scenarios),
  ("NRS_484B_250_4_o2", TrafficSpecWitness.NRS_484B_250_4_o2.scenarios),
  ("NRS_484B_253_o1", TrafficSpecWitness.NRS_484B_253_o1.scenarios),
  ("NRS_484B_253_o2", TrafficSpecWitness.NRS_484B_253_o2.scenarios),
  ("NRS_484B_257_1_o1", TrafficSpecWitness.NRS_484B_257_1_o1.scenarios),
  ("NRS_484B_257_1_o2", TrafficSpecWitness.NRS_484B_257_1_o2.scenarios),
  ("NRS_484B_257_2_o2", TrafficSpecWitness.NRS_484B_257_2_o2.scenarios),
  ("NRS_484B_307_6a", TrafficSpecWitness.NRS_484B_307_6a.scenarios),
  ("NRS_484B_400_2a", TrafficSpecWitness.NRS_484B_400_2a.scenarios),
  ("NRS_484B_400_2b", TrafficSpecWitness.NRS_484B_400_2b.scenarios),
  ("NRS_484B_407", TrafficSpecWitness.NRS_484B_407.scenarios),
  ("NRS_484B_413_2", TrafficSpecWitness.NRS_484B_413_2.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("NRS_484B_600_1c", TrafficSpecWitness.NRS_484B_600_1c.scenarios),
  ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios),
  ("drv.interaction.following", TrafficSpecWitness.Concepts.interaction.following.scenarios),
  ("drv.interaction.overtaking", TrafficSpecWitness.Concepts.interaction.overtaking.scenarios),
  ("drv.interaction.vehicle_file", TrafficSpecWitness.Concepts.interaction.vehicle_file.scenarios),
  ("drv.lane.lane_change", TrafficSpecWitness.Concepts.lane.lane_change.scenarios),
  ("drv.motion.left_turn", TrafficSpecWitness.Concepts.motion.left_turn.scenarios),
  ("drv.motion.region_entry", TrafficSpecWitness.Concepts.motion.region_entry.scenarios),
  ("drv.motion.region_exit", TrafficSpecWitness.Concepts.motion.region_exit.scenarios),
  ("drv.motion.reverse_travel", TrafficSpecWitness.Concepts.motion.reverse_travel.scenarios),
  ("drv.motion.standstill", TrafficSpecWitness.Concepts.motion.standstill.scenarios),
  ("drv.motion.turning", TrafficSpecWitness.Concepts.motion.turning.scenarios),
  ("drv.motion.u_turn", TrafficSpecWitness.Concepts.motion.u_turn.scenarios),
  ("drv.position.direction_component", TrafficSpecWitness.Concepts.position.direction_component.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
