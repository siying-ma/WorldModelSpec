"""EX-LANE-001 — driving on the right half of the roadway.

Two scenarios, one per sentence of the clause.

`keep_right` targets `Rules/Lane/R0011_keep_right_of_roadway.lean`: the ego
cruises a multi-lane carriageway either in the kerbside lane or in an inner one.
The mode is chosen by *where the ego starts*, with automatic lane changes off, so
the Traffic Manager cannot quietly correct it.

`oncoming` targets `Rules/Lane/R0008_opposing_lane_oncoming.lean`, and it is the
one scenario the Traffic Manager cannot drive: it will not enter an opposing
lane. The violating ego is therefore driven by `driving.WaypointDriver`, a small
pure-pursuit controller, down the wrong side of a two-way road while a background
car approaches. The compliant run is the same road and the same oncoming car with
the ego left on autopilot in its own lane — the lawful counterpart, not an empty
capture.
"""

from __future__ import annotations

import carla

from .. import compat, driving
from ..scenario import RunContext, Scenario, register

WRONG_WAY_SPEED_MPS = 7.0
ONCOMING_SPAWN_AHEAD_M = 55.0


def _rightmost(waypoint: carla.Waypoint) -> bool:
    right = waypoint.get_right_lane()
    return not (right is not None
                and right.lane_type == carla.LaneType.Driving
                and right.lane_id * waypoint.lane_id > 0)


@register
class KeepRight(Scenario):
    name = "keep_right"
    description = "ego cruises the kerbside lane, or sits in an inner lane"
    target_laws = ("EX-LANE-001",)
    town = "Town05"
    duration = 12.0
    n_background = 5

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        """Compliant wants a rightmost lane; violating wants one with a
        same-direction lane to its right, held for the whole capture."""
        want_inner = ctx.violating
        for spawn in spawn_points:
            waypoint = ctx.carla_map.get_waypoint(spawn.location,
                                                  project_to_road=True,
                                                  lane_type=carla.LaneType.Driving)
            if waypoint is None or waypoint.is_junction:
                continue
            if _rightmost(waypoint) == want_inner:
                continue
            path = driving.waypoints_ahead(ctx.carla_map, spawn, 120.0)
            if len(path) < 50:
                continue
            # The lane must keep its neighbour for long enough to matter: the
            # clause is about a sustained stretch, not a momentary geometry.
            if want_inner and sum(1 for wp in path if not _rightmost(wp)) < 40:
                continue
            return spawn
        raise RuntimeError(
            f"no spawn point in {ctx.carla_map.name} gives a sustained "
            f"{'inner' if want_inner else 'kerbside'} lane; try --town Town04.")

    def configure(self, ctx: RunContext) -> None:
        ctx.tm.auto_lane_change(ctx.ego, False)
        ctx.tm.random_left_lanechange_percentage(ctx.ego, 0.0)
        ctx.tm.random_right_lanechange_percentage(ctx.ego, 0.0)
        # 0% means "never voluntarily return to the slow lane", which is what
        # holds the violating ego where it was spawned.
        compat.keep_right_rule_percentage(
            ctx.tm, ctx.ego, 0.0 if ctx.violating else 100.0)
        ctx.tm.ignore_lights_percentage(ctx.ego, 100.0)
        ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 25.0)
        ctx.notes["keep_slow_lane_rule_percentage"] = (
            0.0 if ctx.violating else 100.0)


@register
class Oncoming(Scenario):
    name = "oncoming"
    description = "ego meets an oncoming car from its own lane, or from the wrong one"
    target_laws = ("EX-LANE-001",)
    town = "Town03"
    duration = 12.0
    n_background = 2

    def __init__(self) -> None:
        self.driver: driving.WaypointDriver | None = None
        self.approacher: carla.Vehicle | None = None

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        for spawn in spawn_points:
            waypoint = ctx.carla_map.get_waypoint(spawn.location,
                                                  project_to_road=True,
                                                  lane_type=carla.LaneType.Driving)
            if waypoint is None or waypoint.is_junction:
                continue
            left = waypoint.get_left_lane()
            if left is None or left.lane_type != carla.LaneType.Driving:
                continue
            if left.lane_id * waypoint.lane_id > 0:      # same direction, not opposing
                continue
            if len(driving.waypoints_ahead(ctx.carla_map, spawn, 80.0)) < 35:
                continue
            return spawn
        raise RuntimeError(
            f"no two-way road with an opposing lane found in {ctx.carla_map.name}")

    def configure(self, ctx: RunContext) -> None:
        self.driver = None
        self.approacher = None

        ego_wp = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                            project_to_road=True,
                                            lane_type=carla.LaneType.Driving)
        opposing = ego_wp.get_left_lane() if ego_wp else None
        if opposing is None:
            raise RuntimeError("the chosen spawn lost its opposing lane")

        # A car coming the other way, placed up the opposing lane so it meets the
        # ego head-on partway through the capture.
        meeting = opposing.previous(ONCOMING_SPAWN_AHEAD_M)
        if not meeting:
            raise RuntimeError("opposing lane is too short to place an approacher")
        blueprint = ctx.world.get_blueprint_library().find("vehicle.nissan.patrol")
        transform = meeting[0].transform
        transform.location.z += 0.3
        approacher = ctx.spawn(blueprint, transform)
        if approacher is None:
            raise RuntimeError("could not spawn the oncoming vehicle")
        approacher.set_autopilot(True, ctx.tm.get_port())
        ctx.tm.auto_lane_change(approacher, False)
        ctx.tm.ignore_lights_percentage(approacher, 100.0)
        ctx.tm.vehicle_percentage_speed_difference(approacher, 40.0)
        self.approacher = approacher
        ctx.notes["oncoming_id"] = int(approacher.id)

        if ctx.violating:
            # The Traffic Manager refuses to drive into an opposing lane, so the
            # ego comes off autopilot and is steered by hand down the wrong side.
            route = driving.opposing_route(ctx.carla_map,
                                           ctx.ego.get_transform(), length=80.0)
            if len(route) < 10:
                raise RuntimeError("could not build a wrong-way route")
            ctx.ego.set_autopilot(False, ctx.tm.get_port())
            # Place the ego in the opposing lane to begin with; steering across
            # the centre line under pure pursuit is unreliable.
            start = route[0].transform
            start.location.z += 0.3
            start.rotation.yaw += 180.0
            ctx.ego.set_transform(start)
            self.driver = driving.WaypointDriver(ctx.ego, route,
                                                 WRONG_WAY_SPEED_MPS)
            ctx.notes["wrong_way_route_points"] = len(route)
        else:
            ctx.tm.auto_lane_change(ctx.ego, False)
            ctx.tm.ignore_lights_percentage(ctx.ego, 100.0)
            ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 35.0)

    def on_tick(self, ctx: RunContext) -> None:
        if self.driver is not None:
            self.driver.step()
