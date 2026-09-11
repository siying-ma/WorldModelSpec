"""EX-STOP-001 — a complete stop of at least one second at a stop sign.

Targets `Rules/Stop/R0005_stop_sign_dwell.lean`.

The violating run is a Traffic Manager switch (`ignore_signs_percentage`), but
the compliant run cannot be: the Traffic Manager slows for a stop sign without
promising to sit at rest for a full second, and the clause is entirely about that
second. The ego is therefore held on the brake by hand for `DWELL_FRAMES` once it
reaches the sign, and released afterwards. That is scripted behaviour, not the
Traffic Manager's, and the oracle measures the dwell that actually resulted
rather than assuming the script worked.

Stop signs are map furniture. `Town01`, `Town02` and `Town07` have plenty;
`Town03` has very few, so the default here is not `Town03`.
"""

from __future__ import annotations

import carla

from .. import driving
from ..scenario import RunContext, Scenario, register

DWELL_FRAMES = 30            # 1.5 s at 20 Hz, comfortably over the 1 s minimum
SIGN_TRIGGER_M = 6.0         # start the hand-held stop this far from the sign


@register
class StopSign(Scenario):
    name = "stop_sign"
    description = "ego halts fully at a stop sign, or rolls through it"
    target_laws = ("EX-STOP-001",)
    town = "Town01"
    duration = 12.0
    n_background = 4

    def __init__(self) -> None:
        self.dwelled = 0
        self.holding = False
        self.done = False

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        # 45 m rather than the 80 m default: the ego runs at 75% of a 30 km/h
        # limit, so 80 m is 13 s of approach and the dwell would fall outside a
        # 240-frame capture entirely.
        spawn = driving.spawn_reaching_junction(ctx.world, spawn_points,
                                                require_stop_sign=True,
                                                lookahead=45.0)
        if spawn is None:
            raise RuntimeError(
                f"no spawn point in {ctx.carla_map.name} leads to a junction with "
                "a stop sign posted for the approach lane. Try --town Town02 or "
                "--town Town07.")
        return spawn

    def configure(self, ctx: RunContext) -> None:
        self.dwelled = 0
        self.holding = False
        self.done = False
        ctx.tm.ignore_signs_percentage(ctx.ego, 100.0 if ctx.violating else 0.0)
        ctx.tm.auto_lane_change(ctx.ego, False)
        ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 25.0)
        ctx.notes["ignore_signs_percentage"] = 100.0 if ctx.violating else 0.0
        ctx.notes["scripted_dwell_frames"] = 0 if ctx.violating else DWELL_FRAMES

    def on_tick(self, ctx: RunContext) -> None:
        if ctx.violating or self.done:
            return

        waypoint = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                              project_to_road=True,
                                              lane_type=carla.LaneType.Driving)
        if waypoint is None:
            return

        if self.holding:
            ctx.ego.apply_control(
                carla.VehicleControl(throttle=0.0, brake=1.0, hand_brake=True))
            if ctx.ego.get_velocity().length() < 0.1:
                self.dwelled += 1
            if self.dwelled >= DWELL_FRAMES:
                self.holding = False
                self.done = True
                ctx.ego.apply_control(carla.VehicleControl(hand_brake=False))
                ctx.ego.set_autopilot(True, ctx.tm.get_port())
                ctx.notes["dwell_released_at_frame"] = ctx.frame
                ctx.notes["measured_dwell_frames"] = self.dwelled
            return

        if waypoint.is_junction:
            # Already in the junction without ever having held; nothing left to
            # script. The oracle will record whatever dwell actually happened.
            self.done = True
            return

        distance = None
        try:
            landmarks = waypoint.get_landmarks_of_type(SIGN_TRIGGER_M, "206")
            if landmarks:
                distance = min(float(lm.distance) for lm in landmarks)
        except RuntimeError:
            return
        if distance is not None:
            # Take manual control: autopilot would fight the brake.
            ctx.ego.set_autopilot(False, ctx.tm.get_port())
            self.holding = True
            ctx.notes["dwell_started_at_frame"] = ctx.frame
