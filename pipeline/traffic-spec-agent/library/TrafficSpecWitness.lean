/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.Concepts.interaction.precedence_granted
import TrafficSpecWitness.Concepts.motion.complete_cessation
import TrafficSpecWitness.Concepts.motion.left_turn
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := []
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.interaction.precedence_granted.instances ++
  TrafficSpecWitness.Concepts.motion.complete_cessation.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.interaction.precedence_granted.scenarios ++
  TrafficSpecWitness.Concepts.motion.complete_cessation.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Run every witness against the registered rules and concepts with a reading; the failures, by name. -/
def failures (ρ : Reading) : List String :=
  (allScenarios ++ allConceptScenarios).filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some e
end TrafficSpecWitness
