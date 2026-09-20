/-
  TrafficSpecWitness — acceptance witnesses, registered separately from the rules. Empty until the
  first run; `run_spec index` regenerates the registry. Nothing that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Builders
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered scenario, in file order. -/
def allScenarios : List Scenario := []
/-- Run every witness against the registered rules; the failures, by name. -/
def failures : List String :=
  allScenarios.filterMap fun sc =>
    match sc.run allRules with
    | .ok _ => none
    | .error e => some e
end TrafficSpecWitness
