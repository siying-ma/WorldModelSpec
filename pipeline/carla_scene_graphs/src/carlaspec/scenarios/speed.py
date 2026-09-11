"""EX-SPEED-001 (max speed) and EX-SPEED-002 (speed within a junction).

Targets `Rules/Speed/R0001_max_speed.lean` and
`Rules/Speed/R0002_junction_speed.lean`.

Two scenarios, because the two clauses need different geography: the plain speed
limit wants a long stretch with nothing to stop for, and the junction limit wants
a junction the ego is guaranteed to cross.

`TrafficManager.set_desired_speed` is documented in km/h. If that is ever wrong,
this scenario does not silently produce a useless capture: the oracle records the
measured speed, the labeler compares it against the statutory 50 km/h, and the
runner fails the capture when the target law comes out `not_applicable` or the
verdict does not match the mode.
"""

from __future__ import annotations

import carla

from .. import compat, driving
from ..scenario import RunContext, Scenario, register

CRUISE_KPH = 35.0
SPEEDING_KPH = 80.0
JUNCTION_SLOW_KPH = 18.0
JUNCTION_FAST_KPH = 55.0
PIN_DISTANCE_M = 45.0


@register
class MaxSpeed(Scenario):
    name = "max_speed"
    description = "ego cruises under the 50 km/h limit, or well over it"
    target_laws = ("EX-SPEED-001",)
    town = "Town03"
    duration = 12.0
    n_background = 4

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        """Prefer a start with no junction for 100 m, so the run is about speed
        and not about what the ego meets at an intersection."""
        best = None
        for spawn in spawn_points:
            path = driving.waypoints_ahead(ctx.carla_map, spawn, 100.0)
            if len(path) < 45 or any(wp.is_junction for wp in path):
                continue
            best = spawn
            break
        return best

    def configure(self, ctx: RunContext) -> None:
        target = SPEEDING_KPH if ctx.violating else CRUISE_KPH
        ctx.tm.set_desired_speed(ctx.ego, target)
        ctx.tm.auto_lane_change(ctx.ego, False)
        # Stay in the rightmost lane so a keep-right violation does not ride
        # along with the speeding one.
        compat.keep_right_rule_percentage(ctx.tm, ctx.ego, 100.0)
        ctx.tm.ignore_lights_percentage(ctx.ego, 0.0)
        ctx.notes["desired_speed_kph"] = target


@register
class JunctionSpeed(Scenario):
    name = "junction_speed"
    description = "ego crosses an intersection slowly, or at speed"
    target_laws = ("EX-SPEED-002",)
    town = "Town03"
    duration = 12.0
    n_background = 4

    def __init__(self) -> None:
        self.light: carla.TrafficLight | None = None

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        # 45 m rather than the 80 m default: at the 18 km/h the compliant run
        # is set to, 80 m of approach is 16 s and the junction would fall
        # outside a 240-frame capture.
        spawn = driving.spawn_reaching_junction(ctx.world, spawn_points,
                                                lookahead=45.0)
        if spawn is None:
            raise RuntimeError(
                f"no spawn point in {ctx.carla_map.name} reaches a junction "
                f"within 45 m; try --town Town04 or Town05.")
        return spawn

    def configure(self, ctx: RunContext) -> None:
        self.light = None
        target = JUNCTION_FAST_KPH if ctx.violating else JUNCTION_SLOW_KPH
        ctx.tm.set_desired_speed(ctx.ego, target)
        ctx.tm.auto_lane_change(ctx.ego, False)
        # Do not let a red light stop the ego before it reaches the junction:
        # this capture is about speed inside the intersection, and a signal
        # violation riding along would muddy the comparison.
        ctx.tm.ignore_vehicles_percentage(ctx.ego, 50.0 if ctx.violating else 0.0)
        ctx.notes["desired_speed_kph"] = target

    def on_tick(self, ctx: RunContext) -> None:
        """Hold the approach signal green in both modes, so the only difference
        between the runs is how fast the ego crosses."""
        if self.light is not None:
            return
        candidate = driving.pin_light_ahead(ctx.world, ctx.ego,
                                            carla.TrafficLightState.Green,
                                            PIN_DISTANCE_M, ctx.carla_map)
        if candidate is not None:
            ctx.frozen_lights.append(candidate)
            self.light = candidate
            ctx.notes["pinned_light_green"] = int(candidate.id)
