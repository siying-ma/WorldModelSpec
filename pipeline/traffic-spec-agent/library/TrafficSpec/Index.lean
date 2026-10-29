/-
  TrafficSpec.Index — generated registry of formalized rules and concepts (harness index_sync);
  do not edit.
-/
import TrafficSpec.Core
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_060
import TrafficSpec.Rules.NRS_484B.NRS_484B_220_1
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Rules.NRS_484B.NRS_484B_620_2
import TrafficSpec.Concepts.motion.proceeds_through_region
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Concepts.motion.travels_against_region_direction
import TrafficSpec.Concepts.motion.turn_left
import TrafficSpec.Concepts.motion.turn_right
import TrafficSpec.Concepts.position.approaching_region
namespace TrafficSpec
/-- Every registered rule, in file order. -/
def allRules : List Rule := [
  TrafficSpec.Rules.LVMC_11_16_060.rule,
  TrafficSpec.Rules.NRS_484B_220_1.rule,
  TrafficSpec.Rules.NRS_484B_600_1a.rule,
  TrafficSpec.Rules.NRS_484B_600_1e.rule,
  TrafficSpec.Rules.NRS_484B_620_2.rule
]
/-- Every registered concept, in file order. -/
def allConcepts : List Concept := [
  TrafficSpec.Concepts.motion.proceeds_through_region.concept,
  TrafficSpec.Concepts.motion.standstill.concept,
  TrafficSpec.Concepts.motion.travels_against_region_direction.concept,
  TrafficSpec.Concepts.motion.turn_left.concept,
  TrafficSpec.Concepts.motion.turn_right.concept,
  TrafficSpec.Concepts.position.approaching_region.concept
]
end TrafficSpec
