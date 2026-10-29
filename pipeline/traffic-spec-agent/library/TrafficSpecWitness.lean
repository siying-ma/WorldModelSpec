/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.LVMC_11.LVMC_11_16_060
import TrafficSpecWitness.NRS_484B.NRS_484B_220_1
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1e
import TrafficSpecWitness.NRS_484B.NRS_484B_620_2
import TrafficSpecWitness.Concepts.motion.proceeds_through_region
import TrafficSpecWitness.Concepts.motion.standstill
import TrafficSpecWitness.Concepts.motion.travels_against_region_direction
import TrafficSpecWitness.Concepts.motion.turn_left
import TrafficSpecWitness.Concepts.motion.turn_right
import TrafficSpecWitness.Concepts.position.approaching_region
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.LVMC_11_16_060.scenarios ++
  TrafficSpecWitness.NRS_484B_220_1.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1e.scenarios ++
  TrafficSpecWitness.NRS_484B_620_2.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.motion.proceeds_through_region.instances ++
  TrafficSpecWitness.Concepts.motion.standstill.instances ++
  TrafficSpecWitness.Concepts.motion.travels_against_region_direction.instances ++
  TrafficSpecWitness.Concepts.motion.turn_left.instances ++
  TrafficSpecWitness.Concepts.motion.turn_right.instances ++
  TrafficSpecWitness.Concepts.position.approaching_region.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.motion.proceeds_through_region.scenarios ++
  TrafficSpecWitness.Concepts.motion.standstill.scenarios ++
  TrafficSpecWitness.Concepts.motion.travels_against_region_direction.scenarios ++
  TrafficSpecWitness.Concepts.motion.turn_left.scenarios ++
  TrafficSpecWitness.Concepts.motion.turn_right.scenarios ++
  TrafficSpecWitness.Concepts.position.approaching_region.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("LVMC_11_16_060", TrafficSpecWitness.LVMC_11_16_060.scenarios),
  ("NRS_484B_220_1", TrafficSpecWitness.NRS_484B_220_1.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("NRS_484B_600_1e", TrafficSpecWitness.NRS_484B_600_1e.scenarios),
  ("NRS_484B_620_2", TrafficSpecWitness.NRS_484B_620_2.scenarios),
  ("drv.motion.proceeds_through_region", TrafficSpecWitness.Concepts.motion.proceeds_through_region.scenarios),
  ("drv.motion.standstill", TrafficSpecWitness.Concepts.motion.standstill.scenarios),
  ("drv.motion.travels_against_region_direction", TrafficSpecWitness.Concepts.motion.travels_against_region_direction.scenarios),
  ("drv.motion.turn_left", TrafficSpecWitness.Concepts.motion.turn_left.scenarios),
  ("drv.motion.turn_right", TrafficSpecWitness.Concepts.motion.turn_right.scenarios),
  ("drv.position.approaching_region", TrafficSpecWitness.Concepts.position.approaching_region.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
