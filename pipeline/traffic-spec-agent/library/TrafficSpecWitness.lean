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
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := []
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
