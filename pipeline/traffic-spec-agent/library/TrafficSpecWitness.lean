/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
namespace TrafficSpecWitness
open TrafficSpec
/-- A witness held as the gate holds it: Core's `Scenario.run`, and a `blind` witness Core refuses
    admitted only where its mask is the cause: unknown for masked atoms and windows truncated at the
    trace start, and decided on the same trace with nothing masked. -/
def witnessRun (rules : List TrafficSpec.Rule) (sc : TrafficSpec.Scenario) (cs : List TrafficSpec.Concept) :
    Except String TrafficSpec.Verdict :=
  match sc.run rules cs with
  | .ok v => .ok v
  | .error e =>
    if sc.name != "blind" || !sc.boundary.isEmpty || sc.manifest.absentIds.isEmpty then .error e
    else match ({ sc with boundary := "the masked observations" } : TrafficSpec.Scenario).run rules cs with
      | .error _ => .error e
      | .ok v =>
        let full : TrafficSpec.Scenario := { sc with manifest := TrafficSpec.Build.manifest [] sc.manifest.reidGap }
        let decides := fun (x : TrafficSpec.Verdict) =>
          match ({ full with expected := x } : TrafficSpec.Scenario).run rules cs with
          | .ok _ => true
          | .error _ => false
        if decides .compliant || decides .violated then .ok v
        else .error s!"{e}; with nothing masked the same trace is unknown too, so the mask does not explain the history it lacks"
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
    match witnessRun witnessRules ({ sc with reading := ρ } : Scenario) allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
