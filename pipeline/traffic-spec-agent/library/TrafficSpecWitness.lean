/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Builders
import TrafficSpecWitness.NRS_484B.NRS_484B_213_1
import TrafficSpecWitness.NRS_484B.NRS_484B_213_2a
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484B_213_1.scenarios ++
  TrafficSpecWitness.NRS_484B_213_2a.scenarios
/-- Run every witness against the registered rules with a reading; the failures, by name. -/
def failures (ρ : Reading) : List String :=
  allScenarios.filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run allRules with
    | .ok _ => none
    | .error e => some e
end TrafficSpecWitness
