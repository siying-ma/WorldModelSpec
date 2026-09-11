"""EX-SIGNAL-001 — entering an intersection against a steady red signal.

Targets `Rules/Signal/R0004_red_light_entry.lean`.

The compliant and violating runs differ in exactly one Traffic Manager call,
`ignore_lights_percentage`, which is CARLA's own switch for signal obedience.
Everything else — town, seed, spawn point, background traffic — is identical, so
a difference in the two `monitor` reports can only come from the behaviour under
test.

**The signal is pinned rather than caught by luck.** A run whose ego happens to
arrive on green exercises nothing, and the previous version of this scenario had
no way to tell that had happened. `driving.pin_light` holds the light the ego is
approaching at red (and its whole junction group with it), so the situation is
guaranteed to arise. The compliant ego then waits, and the light is released to
green once it has been stopped for a second, which is the lawful counterpart:
stop, wait, proceed.
"""

from __future__ import annotations

import carla

from .. import driving
from ..scenario import RunContext, Scenario, register

# Metres of plain road before the stop line. Long enough that the ego is
# demonstrably outside the intersection while facing the red, which is the
# situation R0004's antecedent tests, and short enough that the approach, the
# stop and the crossing all fit inside `max_capture_frames`.
APPROACH_M = 28.0
DWELL_BEFORE_GREEN_FRAMES = 20
# Keep recording for this long after the ego has cleared the junction, so the
# frames after the event are in the trace and the formula is not evaluated
# against a boundary. `◯` is strong-next and atoms read false past the end of a
# trace, so a capture that stops on the entry frame cannot show the entry.
TAIL_FRAMES = 40


@register
class RedLight(Scenario):
    name = "red_light"
    description = "ego meets a red signal at a junction and stops, or drives through"
    target_laws = ("EX-SIGNAL-001",)
    town = "Town03"
    duration = 12.0
    n_background = 6

    def __init__(self) -> None:
        self.light: carla.TrafficLight | None = None
        self.stopped_frames = 0
        self.released = False
        self.entered_at: int | None = None
        self.cleared_at: int | None = None

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        approach = driving.approach_to_traffic_light(ctx.world, APPROACH_M)
        if approach is None:
            raise RuntimeError(
                f"no clean signalized approach found in {ctx.carla_map.name}")
        transform, light = approach
        self.light = light
        return transform

    def configure(self, ctx: RunContext) -> None:
        self.stopped_frames = 0
        self.released = False
        self.entered_at = None
        self.cleared_at = None
        if self.light is not None:
            # Pinned before the first captured frame, so the situation cannot
            # depend on catching the phase at the right moment.
            driving.pin_light(self.light, carla.TrafficLightState.Red)
            ctx.frozen_lights.append(self.light)
            ctx.notes["pinned_light_id"] = int(self.light.id)
        ctx.tm.ignore_lights_percentage(ctx.ego, 100.0 if ctx.violating else 0.0)
        # Keep speed well under the limit in both modes: the only intended
        # offence is the signal one, not an incidental speeding violation.
        ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 25.0)
        ctx.notes["ignore_lights_percentage"] = 100.0 if ctx.violating else 0.0

    def on_tick(self, ctx: RunContext) -> None:
        if self.light is None:
            return

        self._track_junction(ctx)

        if ctx.violating or self.released:
            return

        # Compliant run: once the ego has held a full stop at the red, let it go.
        if ctx.ego.get_velocity().length() < 0.15:
            self.stopped_frames += 1
            if self.stopped_frames >= DWELL_BEFORE_GREEN_FRAMES:
                self.light.set_state(carla.TrafficLightState.Green)
                self.released = True
                ctx.notes["released_to_green_at_frame"] = ctx.frame
        else:
            self.stopped_frames = 0

    def _track_junction(self, ctx: RunContext) -> None:
        """Stop the capture once the crossing is over and its tail is recorded."""
        waypoint = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                              project_to_road=True,
                                              lane_type=carla.LaneType.Driving)
        if waypoint is None:
            return
        if waypoint.is_junction:
            if self.entered_at is None:
                self.entered_at = ctx.frame
                ctx.notes["entered_junction_at_frame"] = ctx.frame
            return
        if self.entered_at is not None and self.cleared_at is None:
            self.cleared_at = ctx.frame
            ctx.notes["cleared_junction_at_frame"] = ctx.frame
        if self.cleared_at is not None and ctx.frame - self.cleared_at >= TAIL_FRAMES:
            ctx.finished = True
