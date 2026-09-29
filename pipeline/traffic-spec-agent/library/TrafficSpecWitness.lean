/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := []
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := []
def allConceptScenarios : List Scenario := []
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Run every witness against the registered rules and concepts with a reading; the failures, by name. -/
def failures (ρ : Reading) : List String :=
  (allScenarios ++ allConceptScenarios).filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some e
end TrafficSpecWitness
