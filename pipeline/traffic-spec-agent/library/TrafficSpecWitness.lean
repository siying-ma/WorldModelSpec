/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484B.NRS_484B_407
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.Concepts.motion.braking_distance
import TrafficSpecWitness.Concepts.motion.direction_reversal
import TrafficSpecWitness.Concepts.motion.in_motion
import TrafficSpecWitness.Concepts.motion.stopping_distance
namespace TrafficSpecWitness
open TrafficSpec
/-- Every registered node scenario, in file order. -/
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484B_407.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.motion.braking_distance.instances ++
  TrafficSpecWitness.Concepts.motion.direction_reversal.instances ++
  TrafficSpecWitness.Concepts.motion.in_motion.instances ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.motion.braking_distance.scenarios ++
  TrafficSpecWitness.Concepts.motion.direction_reversal.scenarios ++
  TrafficSpecWitness.Concepts.motion.in_motion.scenarios ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Run every witness against the registered rules and concepts with a reading; the failures, by name. -/
def failures (ρ : Reading) : List String :=
  (allScenarios ++ allConceptScenarios).filterMap fun sc =>
    match ({ sc with reading := ρ } : Scenario).run witnessRules allConcepts with
    | .ok _ => none
    | .error e => some e
end TrafficSpecWitness
