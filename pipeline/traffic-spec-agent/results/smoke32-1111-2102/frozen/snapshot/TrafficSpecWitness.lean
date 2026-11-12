/-
  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing
  that runs the library imports this.
-/
import TrafficSpec
import TrafficSpec.Core.Evidence.Builders
import TrafficSpecWitness.NRS_484B.NRS_484B_113_3
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_227_1_o3
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_250_4_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_253_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o1
import TrafficSpecWitness.NRS_484B.NRS_484B_257_1_o2
import TrafficSpecWitness.NRS_484B.NRS_484B_280_1a
import TrafficSpecWitness.NRS_484B.NRS_484B_600_1a
import TrafficSpecWitness.Concepts.motion.at_rest
import TrafficSpecWitness.Concepts.motion.backing
import TrafficSpecWitness.Concepts.motion.decelerating
import TrafficSpecWitness.Concepts.motion.heading_change_since_entry
import TrafficSpecWitness.Concepts.motion.left_turn
import TrafficSpecWitness.Concepts.motion.left_turn_from_onset
import TrafficSpecWitness.Concepts.motion.stopping_distance
import TrafficSpecWitness.Concepts.motion.turning_left
import TrafficSpecWitness.Concepts.motion.turning_right
import TrafficSpecWitness.Concepts.motion.u_turn
import TrafficSpecWitness.Concepts.position.behind
import TrafficSpecWitness.Concepts.position.near_region
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
def allScenarios : List Scenario := TrafficSpecWitness.NRS_484B_113_3.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_227_1_o3.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_250_4_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_253_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o1.scenarios ++
  TrafficSpecWitness.NRS_484B_257_1_o2.scenarios ++
  TrafficSpecWitness.NRS_484B_280_1a.scenarios ++
  TrafficSpecWitness.NRS_484B_600_1a.scenarios
/-- Every registered concept instance and its scenarios, in file order. -/
def allInstances : List Concept.Instance := TrafficSpecWitness.Concepts.motion.at_rest.instances ++
  TrafficSpecWitness.Concepts.motion.backing.instances ++
  TrafficSpecWitness.Concepts.motion.decelerating.instances ++
  TrafficSpecWitness.Concepts.motion.heading_change_since_entry.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn.instances ++
  TrafficSpecWitness.Concepts.motion.left_turn_from_onset.instances ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.instances ++
  TrafficSpecWitness.Concepts.motion.turning_left.instances ++
  TrafficSpecWitness.Concepts.motion.turning_right.instances ++
  TrafficSpecWitness.Concepts.motion.u_turn.instances ++
  TrafficSpecWitness.Concepts.position.behind.instances ++
  TrafficSpecWitness.Concepts.position.near_region.instances
def allConceptScenarios : List Scenario := TrafficSpecWitness.Concepts.motion.at_rest.scenarios ++
  TrafficSpecWitness.Concepts.motion.backing.scenarios ++
  TrafficSpecWitness.Concepts.motion.decelerating.scenarios ++
  TrafficSpecWitness.Concepts.motion.heading_change_since_entry.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn.scenarios ++
  TrafficSpecWitness.Concepts.motion.left_turn_from_onset.scenarios ++
  TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning_left.scenarios ++
  TrafficSpecWitness.Concepts.motion.turning_right.scenarios ++
  TrafficSpecWitness.Concepts.motion.u_turn.scenarios ++
  TrafficSpecWitness.Concepts.position.behind.scenarios ++
  TrafficSpecWitness.Concepts.position.near_region.scenarios
/-- The rules every witness runs against: the registered rules and the concept instances. -/
def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)
/-- Every registered witness list, under the id of the node or concept that owns it. -/
def taggedScenarios : List (String × List Scenario) := [
  ("NRS_484B_113_3", TrafficSpecWitness.NRS_484B_113_3.scenarios),
  ("NRS_484B_227_1_o1", TrafficSpecWitness.NRS_484B_227_1_o1.scenarios),
  ("NRS_484B_227_1_o2", TrafficSpecWitness.NRS_484B_227_1_o2.scenarios),
  ("NRS_484B_227_1_o3", TrafficSpecWitness.NRS_484B_227_1_o3.scenarios),
  ("NRS_484B_250_4_o1", TrafficSpecWitness.NRS_484B_250_4_o1.scenarios),
  ("NRS_484B_250_4_o2", TrafficSpecWitness.NRS_484B_250_4_o2.scenarios),
  ("NRS_484B_253_o1", TrafficSpecWitness.NRS_484B_253_o1.scenarios),
  ("NRS_484B_257_1_o1", TrafficSpecWitness.NRS_484B_257_1_o1.scenarios),
  ("NRS_484B_257_1_o2", TrafficSpecWitness.NRS_484B_257_1_o2.scenarios),
  ("NRS_484B_280_1a", TrafficSpecWitness.NRS_484B_280_1a.scenarios),
  ("NRS_484B_600_1a", TrafficSpecWitness.NRS_484B_600_1a.scenarios),
  ("drv.motion.at_rest", TrafficSpecWitness.Concepts.motion.at_rest.scenarios),
  ("drv.motion.backing", TrafficSpecWitness.Concepts.motion.backing.scenarios),
  ("drv.motion.decelerating", TrafficSpecWitness.Concepts.motion.decelerating.scenarios),
  ("drv.motion.heading_change_since_entry", TrafficSpecWitness.Concepts.motion.heading_change_since_entry.scenarios),
  ("drv.motion.left_turn", TrafficSpecWitness.Concepts.motion.left_turn.scenarios),
  ("drv.motion.left_turn_from_onset", TrafficSpecWitness.Concepts.motion.left_turn_from_onset.scenarios),
  ("drv.motion.stopping_distance", TrafficSpecWitness.Concepts.motion.stopping_distance.scenarios),
  ("drv.motion.turning_left", TrafficSpecWitness.Concepts.motion.turning_left.scenarios),
  ("drv.motion.turning_right", TrafficSpecWitness.Concepts.motion.turning_right.scenarios),
  ("drv.motion.u_turn", TrafficSpecWitness.Concepts.motion.u_turn.scenarios),
  ("drv.position.behind", TrafficSpecWitness.Concepts.position.behind.scenarios),
  ("drv.position.near_region", TrafficSpecWitness.Concepts.position.near_region.scenarios)
]
/-- Run every witness against the registered rules and concepts with a reading; each failure as
    `<owner id>\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/
def failures (ρ : Reading) : List String :=
  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>
    match witnessRun witnessRules ({ sc with reading := ρ } : Scenario) allConcepts with
    | .ok _ => none
    | .error e => some s!"{owner}\t{e}"
end TrafficSpecWitness
