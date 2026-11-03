import TrafficSpec.Core
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Rules.NRS_484A.NRS_484A_450_2
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Concepts.motion.backing
import TrafficSpec.Concepts.motion.travels_against_region_direction
import TrafficSpec.Concepts.interaction.following
import TrafficSpec.Concepts.motion.turn_left
import TrafficSpec.Concepts.motion.turn_right
import TrafficSpec.Concepts.motion.proceeds_through_region
import TrafficSpec.Concepts.road.undivided_opposed_directions
import TrafficSpec.Concepts.motion.turning_right_within_region
import TrafficSpec.Concepts.motion.decelerating
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Concepts.lane.begins_departure_from_region
import TrafficSpec.Concepts.interaction.caravan
import TrafficSpec.Concepts.motion.travels_with_region_direction
import TrafficSpec.Concepts.interaction.overtaking
namespace TrafficSpec
def allRules : List Rule := [
  TrafficSpec.Rules.NRS_484B_600_1e.rule,
  TrafficSpec.Rules.NRS_484B_600_1a.rule,
  TrafficSpec.Rules.NRS_484A_450_2.rule
]
def allConcepts : List Concept := [
  TrafficSpec.Concepts.motion.standstill.concept,
  TrafficSpec.Concepts.motion.backing.concept,
  TrafficSpec.Concepts.motion.travels_against_region_direction.concept,
  TrafficSpec.Concepts.interaction.following.concept,
  TrafficSpec.Concepts.motion.turn_left.concept,
  TrafficSpec.Concepts.motion.turn_right.concept,
  TrafficSpec.Concepts.motion.proceeds_through_region.concept,
  TrafficSpec.Concepts.road.undivided_opposed_directions.concept,
  TrafficSpec.Concepts.motion.turning_right_within_region.concept,
  TrafficSpec.Concepts.motion.decelerating.concept,
  TrafficSpec.Concepts.motion.u_turn.concept,
  TrafficSpec.Concepts.lane.begins_departure_from_region.concept,
  TrafficSpec.Concepts.interaction.caravan.concept,
  TrafficSpec.Concepts.motion.travels_with_region_direction.concept,
  TrafficSpec.Concepts.interaction.overtaking.concept
]
end TrafficSpec
