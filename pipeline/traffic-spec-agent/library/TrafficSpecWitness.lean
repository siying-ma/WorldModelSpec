/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.LVMC_11.LVMC_11_38_030
import TrafficSpecWitness.LVMC_11.LVMC_11_43_010_A
import TrafficSpecWitness.NRS_484B.NRS_484B_113_2
import TrafficSpecWitness.NRS_484B.NRS_484B_127_3
import TrafficSpecWitness.NRS_484B.NRS_484B_210_3
import TrafficSpecWitness.NRS_484B.NRS_484B_223_4a
import TrafficSpecWitness.NRS_484B.NRS_484B_223_4b
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_270_3_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_270_7b
import TrafficSpecWitness.NRS_484B.NRS_484B_297_6_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_297_6_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o4
import TrafficSpecWitness.NRS_484B.NRS_484B_363_3
import TrafficSpecWitness.NRS_484B.NRS_484B_400_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_400_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_413_2
import TrafficSpecWitness.NRS_484B.NRS_484B_440_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_440_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_440_1_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_450_1c
import TrafficSpecWitness.NRS_484B.NRS_484B_560_7a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.Concepts.interaction.overtaking
import TrafficSpecWitness.Concepts.interaction.passing_on_right
import TrafficSpecWitness.Concepts.lane.facing_against_direction
import TrafficSpecWitness.Concepts.lane.heading_offset_from_direction
import TrafficSpecWitness.Concepts.motion.backing
import TrafficSpecWitness.Concepts.motion.clockwise_about_region
import TrafficSpecWitness.Concepts.motion.left_turn
import TrafficSpecWitness.Concepts.motion.left_turn_through_region
import TrafficSpecWitness.Concepts.motion.moving
import TrafficSpecWitness.Concepts.motion.right_turn_through_region
import TrafficSpecWitness.Concepts.motion.stopped
import TrafficSpecWitness.Concepts.motion.stopping_distance
import TrafficSpecWitness.Concepts.motion.straight_through_region
import TrafficSpecWitness.Concepts.motion.turning
import TrafficSpecWitness.Concepts.motion.turning_left
import TrafficSpecWitness.Concepts.motion.u_turn
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.LVMC_11_38_030.scenarios ++
  TrafficSpecWitness.LVMC_11_43_010_A.scenarios ++
  TrafficSpecWitness.NRS_484B_113_2.scenarios ++
  TrafficSpecWitness.NRS_484B_127_3.scenarios ++
  TrafficSpecWitness.NRS_484B_210_3.scenarios ++
  TrafficSpecWitness.NRS_484B_223_4a.scenarios ++
  TrafficSpecWitness.NRS_484B_223_4b.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_270_3_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_270_7b.scenarios ++
  TrafficSpecWitness.NRS_484B_297_6_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_297_6_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o4.scenarios ++
  TrafficSpecWitness.NRS_484B_363_3.scenarios ++
  TrafficSpecWitness.NRS_484B_400_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_400_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_413_2.scenarios ++
  TrafficSpecWitness.NRS_484B_440_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_440_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_440_1_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_450_1c.scenarios ++
  TrafficSpecWitness.NRS_484B_560_7a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.overtaking.instances ++
  TrafficSpecWitness.Concepts.interaction.passing_on_right.instances ++
  TrafficSpecWitness.Concepts.lane.facing_against_direction.instances ++
  TrafficSpecWitness.Concepts.lane.heading_offset_from_direction.instances ++
  TrafficSpecWitness.Concepts.motion.backing.instances ++
  TrafficSpecWitness.Concepts.motion.clockwise_about_region.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn_through_region.instances ++
  TrafficSpecWitness.Concepts.motion.moving.instances ++
  TrafficSpecWitness.Concepts.motion.right_turn_through_region.instances ++
  TrafficSpecWitness.Concepts.motion.stopped.instances ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.instances ++
  TrafficSpecWitness.Concepts.motion.straight_through_region.instances ++
  TrafficSpecWitness.Concepts.motion.turning.instances ++
  TrafficSpecWitness.Concepts.motion.turning_left.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.overtaking.scenarios ++
  TrafficSpecWitness.Concepts.interaction.passing_on_right.scenarios ++
  TrafficSpecWitness.Concepts.lane.facing_against_direction.scenarios ++
  TrafficSpecWitness.Concepts.lane.heading_offset_from_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.backing.scenarios ++
  TrafficSpecWitness.Concepts.motion.clockwise_about_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn_through_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.moving.scenarios ++
  TrafficSpecWitness.Concepts.motion.right_turn_through_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.stopped.scenarios ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios ++
  TrafficSpecWitness.Concepts.motion.straight_through_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning_left.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("LVMC_11_38_030", TrafficSpecWitness.LVMC_11_38_030.scenarios),
  ("LVMC_11_43_010_A", TrafficSpecWitness.LVMC_11_43_010_A.scenarios),
  ("NRS_484B_113_2", TrafficSpecWitness.NRS_484B_113_2.scenarios),
  ("NRS_484B_127_3", TrafficSpecWitness.NRS_484B_127_3.scenarios),
  ("NRS_484B_210_3", TrafficSpecWitness.NRS_484B_210_3.scenarios),
  ("NRS_484B_223_4a", TrafficSpecWitness.NRS_484B_223_4a.scenarios),
  ("NRS_484B_223_4b", TrafficSpecWitness.NRS_484B_223_4b.scenarios),
  ("NRS_484B_227_1_o1", TrafficSpecWitness.NRS_484B_227_1_o1.scenarios),
  ("NRS_484B_227_1_o2", TrafficSpecWitness.NRS_484B_227_1_o2.scenarios),
  ("NRS_484B_227_1_o3", TrafficSpecWitness.NRS_484B_227_1_o3.scenarios),
  ("NRS_484B_250_4_o1", TrafficSpecWitness.NRS_484B_250_4_o1.scenarios),
  ("NRS_484B_250_4_o2", TrafficSpecWitness.NRS_484B_250_4_o2.scenarios),
  ("NRS_484B_253_o1", TrafficSpecWitness.NRS_484B_253_o1.scenarios),
  ("NRS_484B_253_o2", TrafficSpecWitness.NRS_484B_253_o2.scenarios),
  ("NRS_484B_257_1_o1", TrafficSpecWitness.NRS_484B_257_1_o1.scenarios),
  ("NRS_484B_257_1_o2", TrafficSpecWitness.NRS_484B_257_1_o2.scenarios),
  ("NRS_484B_270_3_o2", TrafficSpecWitness.NRS_484B_270_3_o2.scenarios),
  ("NRS_484B_270_7b", TrafficSpecWitness.NRS_484B_270_7b.scenarios),
  ("NRS_484B_297_6_o1", TrafficSpecWitness.NRS_484B_297_6_o1.scenarios),
  ("NRS_484B_297_6_o2", TrafficSpecWitness.NRS_484B_297_6_o2.scenarios),
  ("NRS_484B_307_9b_o1", TrafficSpecWitness.NRS_484B_307_9b_o1.scenarios),
  ("NRS_484B_307_9b_o3", TrafficSpecWitness.NRS_484B_307_9b_o3.scenarios),
  ("NRS_484B_307_9b_o4", TrafficSpecWitness.NRS_484B_307_9b_o4.scenarios),
  ("NRS_484B_363_3", TrafficSpecWitness.NRS_484B_363_3.scenarios),
  ("NRS_484B_400_1_o1", TrafficSpecWitness.NRS_484B_400_1_o1.scenarios),
  ("NRS_484B_400_1_o2", TrafficSpecWitness.NRS_484B_400_1_o2.scenarios),
  ("NRS_484B_413_2", TrafficSpecWitness.NRS_484B_413_2.scenarios),
  ("NRS_484B_440_1_o1", TrafficSpecWitness.NRS_484B_440_1_o1.scenarios),
  ("NRS_484B_440_1_o2", TrafficSpecWitness.NRS_484B_440_1_o2.scenarios),
  ("NRS_484B_440_1_o3", TrafficSpecWitness.NRS_484B_440_1_o3.scenarios),
  ("NRS_484B_450_1c", TrafficSpecWitness.NRS_484B_450_1c.scenarios),
  ("NRS_484B_560_7a", TrafficSpecWitness.NRS_484B_560_7a.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("drv.interaction.overtaking", TrafficSpecWitness.Concepts.interaction.overtaking.scenarios),
  ("drv.interaction.passing_on_right", TrafficSpecWitness.Concepts.interaction.passing_on_right.scenarios),
  ("drv.lane.facing_against_direction", TrafficSpecWitness.Concepts.lane.facing_against_direction.scenarios),
  ("drv.lane.heading_offset_from_direction", TrafficSpecWitness.Concepts.lane.heading_offset_from_direction.scenarios),
  ("drv.motion.backing", TrafficSpecWitness.Concepts.motion.backing.scenarios),
  ("drv.motion.clockwise_about_region", TrafficSpecWitness.Concepts.motion.clockwise_about_region.scenarios),
  ("drv.motion.left_turn", TrafficSpecWitness.Concepts.motion.left_turn.scenarios),
  ("drv.motion.left_turn_through_region", TrafficSpecWitness.Concepts.motion.left_turn_through_region.scenarios),
  ("drv.motion.moving", TrafficSpecWitness.Concepts.motion.moving.scenarios),
  ("drv.motion.right_turn_through_region", TrafficSpecWitness.Concepts.motion.right_turn_through_region.scenarios),
  ("drv.motion.stopped", TrafficSpecWitness.Concepts.motion.stopped.scenarios),
  ("drv.motion.stopping_distance", TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios),
  ("drv.motion.straight_through_region", TrafficSpecWitness.Concepts.motion.straight_through_region.scenarios),
  ("drv.motion.turning", TrafficSpecWitness.Concepts.motion.turning.scenarios),
  ("drv.motion.turning_left", TrafficSpecWitness.Concepts.motion.turning_left.scenarios),
  ("drv.motion.u_turn", TrafficSpecWitness.Concepts.motion.u_turn.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
