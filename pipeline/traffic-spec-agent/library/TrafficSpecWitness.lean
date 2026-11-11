/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.LVMC_11.LVMC_11_38_030
import TrafficSpecWitness.LVMC_11.LVMC_11_43_010_A
import TrafficSpecWitness.NRS_484B.NRS_484B_113_2
import TrafficSpecWitness.NRS_484B.NRS_484B_210_3
import TrafficSpecWitness.NRS_484B.NRS_484B_223_4a
import TrafficSpecWitness.NRS_484B.NRS_484B_223_4b
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_250_1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_263_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_263_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_270_7b
import TrafficSpecWitness.NRS_484B.NRS_484B_297_6_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_297_6_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_307_9b_o4
import TrafficSpecWitness.NRS_484B.NRS_484B_363_3
import TrafficSpecWitness.NRS_484B.NRS_484B_400_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_400_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_413_2
import TrafficSpecWitness.NRS_484B.NRS_484B_440_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_440_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_440_1_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_560_7a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_769
import TrafficSpecWitness.Concepts.interaction.overtaking_alongside
import TrafficSpecWitness.Concepts.interaction.passing_on_right
import TrafficSpecWitness.Concepts.motion.against_carrier_direction
import TrafficSpecWitness.Concepts.motion.clockwise_about_region
import TrafficSpecWitness.Concepts.motion.entering_region
import TrafficSpecWitness.Concepts.motion.halted
import TrafficSpecWitness.Concepts.motion.heading_change_since_entry
import TrafficSpecWitness.Concepts.motion.leaving_region
import TrafficSpecWitness.Concepts.motion.moving
import TrafficSpecWitness.Concepts.motion.reversing
import TrafficSpecWitness.Concepts.motion.slowing
import TrafficSpecWitness.Concepts.motion.stopping_distance
import TrafficSpecWitness.Concepts.motion.turning_left
import TrafficSpecWitness.Concepts.motion.u_turn
import TrafficSpecWitness.Concepts.motion.veering_left
import TrafficSpecWitness.Concepts.motion.veering_right
import TrafficSpecWitness.Concepts.motion.yawing
import TrafficSpecWitness.Concepts.position.within_clearance_since_entry
import TrafficSpecWitness.Concepts.road.opposed_directions
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.LVMC_11_38_030.scenarios ++
  TrafficSpecWitness.LVMC_11_43_010_A.scenarios ++
  TrafficSpecWitness.NRS_484B_113_2.scenarios ++
  TrafficSpecWitness.NRS_484B_210_3.scenarios ++
  TrafficSpecWitness.NRS_484B_223_4a.scenarios ++
  TrafficSpecWitness.NRS_484B_223_4b.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_250_1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_263_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_263_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_270_7b.scenarios ++
  TrafficSpecWitness.NRS_484B_297_6_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_297_6_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_307_9b_o4.scenarios ++
  TrafficSpecWitness.NRS_484B_363_3.scenarios ++
  TrafficSpecWitness.NRS_484B_400_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_400_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_413_2.scenarios ++
  TrafficSpecWitness.NRS_484B_440_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_440_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_440_1_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_560_7a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_769.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.overtaking_alongside.instances ++
  TrafficSpecWitness.Concepts.interaction.passing_on_right.instances ++
  TrafficSpecWitness.Concepts.motion.against_carrier_direction.instances ++
  TrafficSpecWitness.Concepts.motion.clockwise_about_region.instances ++
  TrafficSpecWitness.Concepts.motion.entering_region.instances ++
  TrafficSpecWitness.Concepts.motion.halted.instances ++
  TrafficSpecWitness.Concepts.motion.heading_change_since_entry.instances ++
  TrafficSpecWitness.Concepts.motion.leaving_region.instances ++
  TrafficSpecWitness.Concepts.motion.moving.instances ++
  TrafficSpecWitness.Concepts.motion.reversing.instances ++
  TrafficSpecWitness.Concepts.motion.slowing.instances ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.instances ++
  TrafficSpecWitness.Concepts.motion.turning_left.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances ++
  TrafficSpecWitness.Concepts.motion.veering_left.instances ++
  TrafficSpecWitness.Concepts.motion.veering_right.instances ++
  TrafficSpecWitness.Concepts.motion.yawing.instances ++
  TrafficSpecWitness.Concepts.position.within_clearance_since_entry.instances ++
  TrafficSpecWitness.Concepts.road.opposed_directions.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.overtaking_alongside.scenarios ++
  TrafficSpecWitness.Concepts.interaction.passing_on_right.scenarios ++
  TrafficSpecWitness.Concepts.motion.against_carrier_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.clockwise_about_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.entering_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.halted.scenarios ++
  TrafficSpecWitness.Concepts.motion.heading_change_since_entry.scenarios ++
  TrafficSpecWitness.Concepts.motion.leaving_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.moving.scenarios ++
  TrafficSpecWitness.Concepts.motion.reversing.scenarios ++
  TrafficSpecWitness.Concepts.motion.slowing.scenarios ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning_left.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios ++
  TrafficSpecWitness.Concepts.motion.veering_left.scenarios ++
  TrafficSpecWitness.Concepts.motion.veering_right.scenarios ++
  TrafficSpecWitness.Concepts.motion.yawing.scenarios ++
  TrafficSpecWitness.Concepts.position.within_clearance_since_entry.scenarios ++
  TrafficSpecWitness.Concepts.road.opposed_directions.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("LVMC_11_38_030", TrafficSpecWitness.LVMC_11_38_030.scenarios),
  ("LVMC_11_43_010_A", TrafficSpecWitness.LVMC_11_43_010_A.scenarios),
  ("NRS_484B_113_2", TrafficSpecWitness.NRS_484B_113_2.scenarios),
  ("NRS_484B_210_3", TrafficSpecWitness.NRS_484B_210_3.scenarios),
  ("NRS_484B_223_4a", TrafficSpecWitness.NRS_484B_223_4a.scenarios),
  ("NRS_484B_223_4b", TrafficSpecWitness.NRS_484B_223_4b.scenarios),
  ("NRS_484B_227_1_o1", TrafficSpecWitness.NRS_484B_227_1_o1.scenarios),
  ("NRS_484B_227_1_o2", TrafficSpecWitness.NRS_484B_227_1_o2.scenarios),
  ("NRS_484B_250_1", TrafficSpecWitness.NRS_484B_250_1.scenarios),
  ("NRS_484B_250_4_o1", TrafficSpecWitness.NRS_484B_250_4_o1.scenarios),
  ("NRS_484B_250_4_o2", TrafficSpecWitness.NRS_484B_250_4_o2.scenarios),
  ("NRS_484B_253_o1", TrafficSpecWitness.NRS_484B_253_o1.scenarios),
  ("NRS_484B_253_o2", TrafficSpecWitness.NRS_484B_253_o2.scenarios),
  ("NRS_484B_257_1_o1", TrafficSpecWitness.NRS_484B_257_1_o1.scenarios),
  ("NRS_484B_257_1_o2", TrafficSpecWitness.NRS_484B_257_1_o2.scenarios),
  ("NRS_484B_263_o1", TrafficSpecWitness.NRS_484B_263_o1.scenarios),
  ("NRS_484B_263_o2", TrafficSpecWitness.NRS_484B_263_o2.scenarios),
  ("NRS_484B_270_7b", TrafficSpecWitness.NRS_484B_270_7b.scenarios),
  ("NRS_484B_297_6_o2", TrafficSpecWitness.NRS_484B_297_6_o2.scenarios),
  ("NRS_484B_297_6_o3", TrafficSpecWitness.NRS_484B_297_6_o3.scenarios),
  ("NRS_484B_307_9b_o1", TrafficSpecWitness.NRS_484B_307_9b_o1.scenarios),
  ("NRS_484B_307_9b_o2", TrafficSpecWitness.NRS_484B_307_9b_o2.scenarios),
  ("NRS_484B_307_9b_o3", TrafficSpecWitness.NRS_484B_307_9b_o3.scenarios),
  ("NRS_484B_307_9b_o4", TrafficSpecWitness.NRS_484B_307_9b_o4.scenarios),
  ("NRS_484B_363_3", TrafficSpecWitness.NRS_484B_363_3.scenarios),
  ("NRS_484B_400_1_o1", TrafficSpecWitness.NRS_484B_400_1_o1.scenarios),
  ("NRS_484B_400_1_o2", TrafficSpecWitness.NRS_484B_400_1_o2.scenarios),
  ("NRS_484B_413_2", TrafficSpecWitness.NRS_484B_413_2.scenarios),
  ("NRS_484B_440_1_o1", TrafficSpecWitness.NRS_484B_440_1_o1.scenarios),
  ("NRS_484B_440_1_o2", TrafficSpecWitness.NRS_484B_440_1_o2.scenarios),
  ("NRS_484B_440_1_o3", TrafficSpecWitness.NRS_484B_440_1_o3.scenarios),
  ("NRS_484B_560_7a", TrafficSpecWitness.NRS_484B_560_7a.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("NRS_484B_769", TrafficSpecWitness.NRS_484B_769.scenarios),
  ("drv.interaction.overtaking_alongside", TrafficSpecWitness.Concepts.interaction.overtaking_alongside.scenarios),
  ("drv.interaction.passing_on_right", TrafficSpecWitness.Concepts.interaction.passing_on_right.scenarios),
  ("drv.motion.against_carrier_direction", TrafficSpecWitness.Concepts.motion.against_carrier_direction.scenarios),
  ("drv.motion.clockwise_about_region", TrafficSpecWitness.Concepts.motion.clockwise_about_region.scenarios),
  ("drv.motion.entering_region", TrafficSpecWitness.Concepts.motion.entering_region.scenarios),
  ("drv.motion.halted", TrafficSpecWitness.Concepts.motion.halted.scenarios),
  ("drv.motion.heading_change_since_entry", TrafficSpecWitness.Concepts.motion.heading_change_since_entry.scenarios),
  ("drv.motion.leaving_region", TrafficSpecWitness.Concepts.motion.leaving_region.scenarios),
  ("drv.motion.moving", TrafficSpecWitness.Concepts.motion.moving.scenarios),
  ("drv.motion.reversing", TrafficSpecWitness.Concepts.motion.reversing.scenarios),
  ("drv.motion.slowing", TrafficSpecWitness.Concepts.motion.slowing.scenarios),
  ("drv.motion.stopping_distance", TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios),
  ("drv.motion.turning_left", TrafficSpecWitness.Concepts.motion.turning_left.scenarios),
  ("drv.motion.u_turn", TrafficSpecWitness.Concepts.motion.u_turn.scenarios),
  ("drv.motion.veering_left", TrafficSpecWitness.Concepts.motion.veering_left.scenarios),
  ("drv.motion.veering_right", TrafficSpecWitness.Concepts.motion.veering_right.scenarios),
  ("drv.motion.yawing", TrafficSpecWitness.Concepts.motion.yawing.scenarios),
  ("drv.position.within_clearance_since_entry", TrafficSpecWitness.Concepts.position.within_clearance_since_entry.scenarios),
  ("drv.road.opposed_directions", TrafficSpecWitness.Concepts.road.opposed_directions.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
