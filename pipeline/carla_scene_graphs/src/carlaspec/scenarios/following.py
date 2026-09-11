"""EX-FOLLOW-001 — following too closely.

Targets `Rules/Following/R0003_following_distance.lean` (a sustained gap under
four metres) and `Rules/Following/R0010_prudent_gap_when_lead_brakes.lean`
(closing on a lead vehicle whose brake lights are on).

Two details make or break this capture.

**Brake lights.** R0010's antecedent includes `Pred.brakeLightOn w` on the *lead*
vehicle, and a non-ego vehicle's light booleans are the only dynamic evidence the
abstraction keeps about it. CARLA does not drive those lights on its own, so the
runner turns on `TrafficManager.update_vehicle_lights` for every vehicle. Without
it R0010 grounds and is trivially satisfied on every capture ever recorded.

**Which distance.** `carla_sgg` bins proximity from the plane-projected distance
between actor *origins*, so `Pred.withinMetres 4` means centre-to-centre under
four metres — for two ~4.7 m cars that is bodywork overlapping. The statute means
the clear space. The violating run therefore drives the bumper gap as close to
zero as the Traffic Manager will allow, and the oracle records both numbers so a
disagreement between the label and R0003 can be read off rather than guessed at.
"""

from __future__ import annotations

import carla

from .. import driving
from ..scenario import RunContext, Scenario, register

LEAD_OFFSET_M = 14.0
SAFE_GAP_M = 12.0
TAILGATE_GAP_M = 0.3

# The lead's speed setting alternates so it repeatedly decelerates, which is what
# lights its brake lamps and creates the closing-on-a-braking-lead situation.
LEAD_CRUISE_PERCENT = 30.0
LEAD_SLOW_PERCENT = 75.0
BRAKE_CYCLE_FRAMES = 40


@register
class Following(Scenario):
    name = "following"
    description = "ego holds a prudent gap behind a lead vehicle, or tailgates it"
    target_laws = ("EX-FOLLOW-001",)
    town = "Town03"
    duration = 12.0
    n_background = 3

    def __init__(self) -> None:
        self.lead: carla.Vehicle | None = None
        self.slow_phase = False

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        for spawn in spawn_points:
            path = driving.waypoints_ahead(ctx.carla_map, spawn, 90.0)
            if len(path) >= 40 and not any(wp.is_junction for wp in path[:20]):
                return spawn
        return None

    def configure(self, ctx: RunContext) -> None:
        self.lead = None
        self.slow_phase = False

        # Put the lead vehicle directly ahead in the ego's own lane; a lead in
        # another lane would leave `Pred.sameLane` false and the rule vacuous.
        ego_wp = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                            project_to_road=True,
                                            lane_type=carla.LaneType.Driving)
        ahead = ego_wp.next(LEAD_OFFSET_M) if ego_wp else []
        if not ahead:
            raise RuntimeError("no lane ahead of the ego to place a lead vehicle")

        blueprint = ctx.world.get_blueprint_library().find("vehicle.audi.tt")
        transform = ahead[0].transform
        transform.location.z += 0.3
        lead = ctx.spawn(blueprint, transform)
        if lead is None:
            raise RuntimeError("could not spawn the lead vehicle")
        lead.set_autopilot(True, ctx.tm.get_port())
        ctx.tm.update_vehicle_lights(lead, True)
        ctx.tm.auto_lane_change(lead, False)
        ctx.tm.ignore_lights_percentage(lead, 100.0)
        ctx.tm.vehicle_percentage_speed_difference(lead, LEAD_CRUISE_PERCENT)
        self.lead = lead

        ctx.tm.auto_lane_change(ctx.ego, False)
        ctx.tm.ignore_lights_percentage(ctx.ego, 100.0)
        if ctx.violating:
            ctx.tm.distance_to_leading_vehicle(ctx.ego, TAILGATE_GAP_M)
            # Faster than the lead, so the ego actually closes the gap rather
            # than merely being allowed to.
            ctx.tm.vehicle_percentage_speed_difference(ctx.ego, -10.0)
        else:
            ctx.tm.distance_to_leading_vehicle(ctx.ego, SAFE_GAP_M)
            ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 30.0)
        ctx.notes["lead_id"] = int(lead.id)
        ctx.notes["distance_to_leading_vehicle_m"] = (
            TAILGATE_GAP_M if ctx.violating else SAFE_GAP_M)

    def on_tick(self, ctx: RunContext) -> None:
        """Make the lead brake periodically, so R0010's antecedent is reachable.

        Driven through the Traffic Manager rather than `apply_control`, because
        `update_vehicle_lights` only lights the brake lamps for a vehicle the TM
        is controlling.
        """
        if self.lead is None or not self.lead.is_alive:
            return
        if ctx.frame % BRAKE_CYCLE_FRAMES:
            return
        self.slow_phase = not self.slow_phase
        ctx.tm.vehicle_percentage_speed_difference(
            self.lead, LEAD_SLOW_PERCENT if self.slow_phase else LEAD_CRUISE_PERCENT)
