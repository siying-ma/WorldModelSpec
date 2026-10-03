/-
  TrafficSpec.Index — generated registry of formalized rules and concepts (harness index_sync);
  do not edit.
-/
import TrafficSpec.Core
import TrafficSpec.Concepts.interaction.precedence_granted
import TrafficSpec.Concepts.motion.complete_cessation
import TrafficSpec.Concepts.motion.left_turn
namespace TrafficSpec
/-- Every registered rule, in file order. -/
def allRules : List Rule := []
/-- Every registered concept, in file order. -/
def allConcepts : List Concept := [
  TrafficSpec.Concepts.interaction.precedence_granted.concept,
  TrafficSpec.Concepts.motion.complete_cessation.concept,
  TrafficSpec.Concepts.motion.left_turn.concept
]
end TrafficSpec
