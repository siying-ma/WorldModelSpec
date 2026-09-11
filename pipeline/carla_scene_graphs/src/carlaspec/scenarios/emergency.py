"""EX-EMERGENCY-001 — yielding to an approaching emergency vehicle.

Two scenarios, one per rule.

`emergency_pull_right` targets
`Rules/Emergency/R0012_pull_right_for_emergency.lean`: with an emergency vehicle
within 25 m, the ego must be at the right-hand edge of the roadway.

`emergency_junction` targets
`Rules/Emergency/R0013_clear_junction_for_emergency.lean`: with one within 25 m,
the ego must not sit inside an intersection.

**The blueprint choice is not cosmetic.** `carla_sgg` emits a proximity edge only
for the base classes in `DEFAULT_PROXIMITY_RELATIONS`, and CARLA's ambulance
(`vehicle.ford.ambulance`) is a **van**, which is not among them. An ambulance
could park on the ego's bumper and no distance-based rule would ever ground. Both
scenarios therefore use `vehicle.dodge.charger_police`, whose base class is
`car`. The oracle records `proximity_edge_possible` per actor, so if this is ever
changed to a van the label file says so in its own note rather than the rules
quietly reporting compliance.

The statute names neither a distance nor a duration, so the labeler borrows
R0012/R0013's own constants for this law. That is stated in the label file: these
captures test whether the rules fire on the right situation, not whether 25 m and
one second were the right numbers.

**What the compliant counterpart of `emergency_junction` actually is.** The
police car is spawned behind the ego in its own lane and cannot overtake, so it
stays within 25 m for most of the capture and the clause is engaged throughout.
There is therefore no run in which the ego is inside the junction with the
emergency vehicle far away — and there should not be. The lawful behaviour under
R0013 is not *avoiding* the intersection, it is *crossing and getting out of it*,
which is exactly what the compliant ego does: it is inside junction 103 for over
a hundred frames and never once stops. The labeler gates its clearance run on the
ego failing to make progress (`EMERGENCY_BLOCKING_MPS`) for this reason; scored
on presence alone, every lawful traverse of a large intersection convicts.
"""

from __future__ import annotations

import carla

from .. import compat, driving
from ..scenario import RunContext, Scenario, register

EMERGENCY_BLUEPRINT = "vehicle.dodge.charger_police"
POLICE_START_BEHIND_M = 30.0
JUNCTION_HOLD_FRAMES = 60          # 3 s, over R0013's 2 s clearance window
# How far ahead to look for the signal governing the approach, so it can be held
# green. The ego starts 25-45 m short of the junction and the lights sit on it.
PIN_RADIUS_M = 70.0


def _rightmost(waypoint: carla.Waypoint) -> bool:
    right = waypoint.get_right_lane()
    return not (right is not None
                and right.lane_type == carla.LaneType.Driving
                and right.lane_id * waypoint.lane_id > 0)


def _spawn_police_behind(ctx: RunContext) -> carla.Vehicle:
    ego_wp = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                        project_to_road=True,
                                        lane_type=carla.LaneType.Driving)
    behind = ego_wp.previous(POLICE_START_BEHIND_M) if ego_wp else []
    if not behind:
        raise RuntimeError("no lane behind the ego to place the emergency vehicle")

    blueprint = ctx.world.get_blueprint_library().find(EMERGENCY_BLUEPRINT)
    transform = behind[0].transform
    transform.location.z += 0.3
    police = ctx.spawn(blueprint, transform)
    if police is None:
        raise RuntimeError("could not spawn the emergency vehicle")
    police.set_autopilot(True, ctx.tm.get_port())
    ctx.tm.auto_lane_change(police, False)
    ctx.tm.ignore_lights_percentage(police, 100.0)
    ctx.tm.ignore_vehicles_percentage(police, 60.0)
    ctx.tm.update_vehicle_lights(police, True)
    # Faster than the ego, so it closes to within the 25 m the rules read.
    ctx.tm.vehicle_percentage_speed_difference(police, -35.0)
    ctx.notes["emergency_id"] = int(police.id)
    ctx.notes["emergency_blueprint"] = EMERGENCY_BLUEPRINT
    return police


@register
class EmergencyPullRight(Scenario):
    name = "emergency_pull_right"
    description = "ego is at the kerb as a police car closes, or blocks an inner lane"
    target_laws = ("EX-EMERGENCY-001",)
    town = "Town05"
    duration = 12.0
    n_background = 4

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        want_inner = ctx.violating
        for spawn in spawn_points:
            waypoint = ctx.carla_map.get_waypoint(spawn.location,
                                                  project_to_road=True,
                                                  lane_type=carla.LaneType.Driving)
            if waypoint is None or waypoint.is_junction:
                continue
            if _rightmost(waypoint) == want_inner:
                continue
            if not waypoint.previous(POLICE_START_BEHIND_M + 5.0):
                continue
            path = driving.waypoints_ahead(ctx.carla_map, spawn, 100.0)
            if len(path) < 45:
                continue
            if want_inner and sum(1 for wp in path if not _rightmost(wp)) < 40:
                continue
            return spawn
        raise RuntimeError(
            f"no spawn point in {ctx.carla_map.name} gives a sustained "
            f"{'inner' if want_inner else 'kerbside'} lane with room behind for "
            "the emergency vehicle; try --town Town04.")

    def configure(self, ctx: RunContext) -> None:
        ctx.tm.auto_lane_change(ctx.ego, False)
        ctx.tm.random_left_lanechange_percentage(ctx.ego, 0.0)
        ctx.tm.random_right_lanechange_percentage(ctx.ego, 0.0)
        compat.keep_right_rule_percentage(
            ctx.tm, ctx.ego, 0.0 if ctx.violating else 100.0)
        ctx.tm.ignore_lights_percentage(ctx.ego, 100.0)
        ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 30.0)
        _spawn_police_behind(ctx)


@register
class EmergencyJunction(Scenario):
    name = "emergency_junction"
    description = "ego clears the intersection for a police car, or sits in it"
    target_laws = ("EX-EMERGENCY-001",)
    town = "Town03"
    duration = 12.0
    n_background = 3

    def __init__(self) -> None:
        self.held = 0
        self.holding = False
        self.done = False
        self.light: carla.TrafficLight | None = None

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        spawn = driving.spawn_reaching_junction(ctx.world, spawn_points,
                                                lookahead=45.0,
                                                min_distance=25.0)
        if spawn is None:
            # Returning None means "runner, pick for me", which would start the
            # ego anywhere and produce a capture that never reaches a junction.
            raise RuntimeError(
                f"no spawn point in {ctx.carla_map.name} reaches a junction "
                f"between 25 m and 45 m ahead; try --town Town04 or Town05.")
        return spawn

    def configure(self, ctx: RunContext) -> None:
        self.held = 0
        self.holding = False
        self.done = False
        self.light = None
        ctx.tm.auto_lane_change(ctx.ego, False)
        # Obey the signal, and hold it green so obeying it costs nothing. The
        # previous `ignore_lights_percentage(ego, 100)` made *both* counterparts
        # red-light runners: the compliant capture entered junction 103 at frame
        # 86 against a red after 86 frames facing it, so it carried an
        # EX-SIGNAL-001 violation it was never meant to test and no disagreement
        # on it could be attributed to any one rule.
        ctx.tm.ignore_lights_percentage(ctx.ego, 0.0)
        ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 30.0)
        self._pin_green(ctx)
        _spawn_police_behind(ctx)
        ctx.notes["junction_hold_frames"] = (
            JUNCTION_HOLD_FRAMES if ctx.violating else 0)

    def _pin_green(self, ctx: RunContext) -> None:
        if self.light is not None:
            return
        light = driving.pin_light_ahead(ctx.world, ctx.ego,
                                        carla.TrafficLightState.Green,
                                        PIN_RADIUS_M, ctx.carla_map)
        if light is not None:
            self.light = light
            ctx.frozen_lights.append(light)
            ctx.notes["pinned_light_green"] = int(light.id)

    def on_tick(self, ctx: RunContext) -> None:
        """Violating: stall inside the intersection while the police car closes.

        Compliant: nothing to do — the ego drives through and out, which is
        exactly the lawful behaviour the clause asks for.
        """
        # The ego may start outside every light's radius; keep trying as it
        # closes, so the approach is green before it arrives rather than after.
        self._pin_green(ctx)

        if not ctx.violating or self.done:
            return

        waypoint = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                              project_to_road=True,
                                              lane_type=carla.LaneType.Driving)
        if waypoint is None:
            return

        if self.holding:
            ctx.ego.apply_control(
                carla.VehicleControl(throttle=0.0, brake=1.0, hand_brake=True))
            self.held += 1
            if self.held >= JUNCTION_HOLD_FRAMES:
                self.holding = False
                self.done = True
                ctx.ego.apply_control(carla.VehicleControl(hand_brake=False))
                ctx.ego.set_autopilot(True, ctx.tm.get_port())
                ctx.notes["junction_hold_released_at_frame"] = ctx.frame
            return

        if waypoint.is_junction:
            ctx.ego.set_autopilot(False, ctx.tm.get_port())
            self.holding = True
            ctx.notes["junction_hold_started_at_frame"] = ctx.frame
