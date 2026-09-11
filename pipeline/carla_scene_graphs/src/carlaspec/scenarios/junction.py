"""EX-JUNCTION-001 — yielding to a vehicle already inside an intersection.

Targets `Rules/Junction/R0006_yield_in_occupied_junction.lean`.

The situation needs two vehicles and a shared junction at the same moment, which
random background traffic supplies only by luck. Here it is arranged: a cross
vehicle is spawned on the intersecting approach and **held on the handbrake until
the ego is close**, then released so it is inside the junction as the ego
arrives. The earlier version spawned it 22 m back and let it go immediately,
which the docstring described as "timed" but was not: nothing coupled the two
vehicles, and in the recorded capture the cross vehicle crossed and left while
the ego was still 28 m away.

The mode changes only what the ego does about it. Violating:
`ignore_vehicles_percentage` at 100, so the ego crosses the boundary while the
cross vehicle is still inside.

**The compliant half is scripted, for the same reason `stop_sign`'s dwell is.**
`ignore_vehicles_percentage(ego, 0)` is not enough: the Traffic Manager's
collision avoidance looks along the ego's own lane, and a vehicle stopped
*across* a 25 m junction on a different approach is not in it. Left to the
Traffic Manager the compliant ego drove into the occupied junction at frame 71
exactly as the violating one did, and both halves labelled `violated`. The ego
is therefore held on the brake while the junction ahead of it is occupied, and
released when it clears — and, as with the stop-sign dwell, the verdict is still
read back out of `oracle.jsonl` rather than asserted from the fact that the
script ran.

**The signal is pinned green, in both modes.** With it left to cycle, the
compliant ego met a red that outlasted the whole capture: it stopped 27.9 m short
at frame 55 and never moved again, so `frames_in_junction` was 0, EX-JUNCTION-001
came out `not_applicable`, and the capture failed. Retrying with `--seed` cannot
fix that — the seed drives the Traffic Manager and the background spawns, not the
signal phase — so all three attempts failed identically. Holding the approach
green removes the signal from the experiment altogether, which is what a capture
about *yielding to a vehicle* wants: the only reason to stop is the other car.

The label is decided from the transition the oracle observes — the frame the
ego's waypoint first reports the junction, with another vehicle's waypoint
already reporting it — not from the fact that the switches were set.
"""

from __future__ import annotations

import carla

from .. import driving
from ..geometry import plane_distance, unit_forward
from ..scenario import RunContext, Scenario, register

# How far back from its own stop line the cross vehicle waits before it is
# released. Short, because it has to reach the junction before the ego does.
CROSS_START_OFFSET_M = 10.0
# Release it once the ego is this close to the junction's centre. Generous: the
# cross vehicle must arrive first, and it starts from rest.
CROSS_RELEASE_EGO_DISTANCE_M = 40.0
# Once inside, keep going this many frames before stopping, so it comes to rest
# well within the junction and across the ego's path rather than on its own stop
# line. Junction 1221 in Town03 is around 25 m across.
CROSS_ENTER_FRAMES = 20
# ...then sit there this long. This is what makes the capture repeatable rather
# than a race: with both vehicles moving, whether the junction is occupied at
# the moment the ego crosses the boundary depends on two independent approach
# lengths and two acceleration curves. Measured on the Town03 approach this
# scenario picks, the ego reaches the junction 31 frames before a cross vehicle
# released at the same moment — it cannot win that race by tuning. Stopping the
# cross vehicle inside the box removes the race: the junction is *definitely*
# occupied when the ego arrives, which is the antecedent R0006 needs.
CROSS_BLOCK_FRAMES = 40
# Released again afterwards, so the compliant ego has something to wait *for*
# and then follows it through; a permanent blocker would leave the compliant
# capture with the ego never entering and EX-JUNCTION-001 `not_applicable`.
CROSS_SPEED_PERCENT = 20.0
JUNCTION_LOOKAHEAD_M = 45.0
PIN_RADIUS_M = 70.0


@register
class JunctionYield(Scenario):
    name = "junction_yield"
    description = "ego waits for an occupied intersection to clear, or drives in"
    target_laws = ("EX-JUNCTION-001",)
    town = "Town03"
    duration = 12.0
    n_background = 4

    def __init__(self) -> None:
        self.cross: carla.Vehicle | None = None
        self.junction: carla.Junction | None = None
        self.light: carla.TrafficLight | None = None
        # held -> running -> entering -> blocking -> leaving
        self.phase = "held"
        self.counter = 0
        self.ego_held = False
        self.ego_released = False

    def choose_ego_spawn(self, ctx: RunContext, spawn_points):
        spawn = driving.spawn_reaching_junction(
            ctx.world, spawn_points,
            lookahead=JUNCTION_LOOKAHEAD_M, min_distance=20.0)
        if spawn is None:
            # Returning None means "runner, pick for me", and the runner would
            # then start the ego at a random spawn point with no junction ahead
            # — a capture that fails much later for a reason that looks
            # unrelated to the missing geometry.
            raise RuntimeError(
                f"no spawn point in {ctx.carla_map.name} reaches a junction "
                f"between 20 m and {JUNCTION_LOOKAHEAD_M:.0f} m ahead; try "
                f"--town Town04 or Town05.")
        return spawn

    def _cross_spawn(self, ctx: RunContext) -> carla.Transform | None:
        """A start point on a *crossing* approach to the same junction.

        Entries are ranked by how close to perpendicular they are to the ego's
        heading. Taking the first entry on a different road, as this used to,
        can pick the opposing approach — a vehicle coming head-on through the
        junction rather than across it, which is a different clause.
        """
        junction = driving.junction_ahead_of(ctx.carla_map, ctx.ego,
                                             JUNCTION_LOOKAHEAD_M)
        if junction is None:
            return None
        self.junction = junction
        ego_wp = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                            project_to_road=True,
                                            lane_type=carla.LaneType.Driving)
        ego_fx, ego_fy = unit_forward(ctx.ego.get_transform())

        candidates = []
        for entry, _exit in junction.get_waypoints(carla.LaneType.Driving):
            if ego_wp is not None and entry.road_id == ego_wp.road_id:
                continue
            back = entry.previous(CROSS_START_OFFSET_M)
            if not back:
                continue
            ex, ey = unit_forward(entry.transform)
            # 0 when the approach is exactly perpendicular to the ego's.
            candidates.append((abs(ex * ego_fx + ey * ego_fy), back[0]))
        if not candidates:
            return None

        candidates.sort(key=lambda pair: pair[0])
        transform = candidates[0][1].transform
        transform.location.z += 0.3
        return transform

    def configure(self, ctx: RunContext) -> None:
        self.cross = None
        self.light = None
        self.phase = "held"
        self.counter = 0
        self.ego_held = False
        self.ego_released = False

        transform = self._cross_spawn(ctx)
        if transform is None:
            raise RuntimeError("could not find a cross approach to the junction "
                               "ahead of the ego")

        blueprint = ctx.world.get_blueprint_library().find("vehicle.audi.etron")
        cross = ctx.spawn(blueprint, transform)
        if cross is None:
            raise RuntimeError("could not spawn the cross-traffic vehicle")
        # Held at rest until the ego is close; `on_tick` releases it. Autopilot
        # is switched on at release, because the Traffic Manager would drive it
        # away immediately otherwise.
        cross.set_autopilot(False, ctx.tm.get_port())
        cross.apply_control(
            carla.VehicleControl(throttle=0.0, brake=1.0, hand_brake=True))
        ctx.tm.auto_lane_change(cross, False)
        # The cross vehicle must be *in* the junction, so it does not stop for
        # the signal; it is not the vehicle under test.
        ctx.tm.ignore_lights_percentage(cross, 100.0)
        ctx.tm.vehicle_percentage_speed_difference(cross, CROSS_SPEED_PERCENT)
        ctx.tm.update_vehicle_lights(cross, True)
        self.cross = cross
        ctx.notes["cross_id"] = int(cross.id)
        ctx.notes["cross_start_offset_m"] = CROSS_START_OFFSET_M

        ctx.tm.auto_lane_change(ctx.ego, False)
        ctx.tm.vehicle_percentage_speed_difference(ctx.ego, 25.0)
        # Green in both modes, so the only thing that can stop the ego is the
        # cross vehicle — which is the whole point of the capture. Obeying the
        # signal then costs nothing and keeps EX-SIGNAL-001 out of the capture.
        ctx.tm.ignore_lights_percentage(ctx.ego, 0.0)
        self._pin_green(ctx)
        if ctx.violating:
            ctx.tm.ignore_vehicles_percentage(ctx.ego, 100.0)
        else:
            ctx.tm.ignore_vehicles_percentage(ctx.ego, 0.0)
        ctx.notes["ignore_vehicles_percentage"] = 100.0 if ctx.violating else 0.0

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

    def _hold(self) -> None:
        # A single apply_control persists, but re-asserting it each tick costs
        # nothing and survives anything else touching the vehicle.
        self.cross.apply_control(
            carla.VehicleControl(throttle=0.0, brake=1.0, hand_brake=True))

    def _drive(self, ctx: RunContext) -> None:
        self.cross.apply_control(carla.VehicleControl(hand_brake=False))
        self.cross.set_autopilot(True, ctx.tm.get_port())

    def _junction_occupied(self, ctx: RunContext) -> bool:
        """Is any vehicle other than the ego inside the junction ahead?

        Asked of the map rather than of the scenario's own bookkeeping, so
        background traffic counts too: the ego must yield to whatever is
        actually in the box, which is also what the labeler reads.
        """
        if self.junction is None:
            return False
        for actor in ctx.world.get_actors().filter("vehicle.*"):
            if ctx.ego is not None and actor.id == ctx.ego.id:
                continue
            waypoint = ctx.carla_map.get_waypoint(
                actor.get_location(), project_to_road=True,
                lane_type=carla.LaneType.Driving)
            if (waypoint is not None and waypoint.is_junction
                    and int(waypoint.junction_id) == int(self.junction.id)):
                return True
        return False

    def _drive_ego_compliantly(self, ctx: RunContext) -> None:
        """Hold short of the line while the junction is spoken for, then go.

        The hold begins when the cross vehicle is *released* rather than when
        the junction is first observed occupied. Waiting for observation left
        only 13 frames of braking from 4.5 m/s — about half what the ego needs
        to stop — so it crossed the boundary anyway and the compliant run
        labelled `violated`. A driver yields to the vehicle that is arriving,
        not only to the one that has already arrived.

        `hand_brake=True` matters: it is what `stop_sign` and the violating half
        of `emergency_junction` both use, and a plain `brake=1.0` did not hold
        this vehicle against the Traffic Manager.
        """
        if self.ego_released:
            return

        ego_wp = ctx.carla_map.get_waypoint(ctx.ego.get_location(),
                                            project_to_road=True,
                                            lane_type=carla.LaneType.Driving)
        if ego_wp is not None and ego_wp.is_junction:
            # Already inside; there is nothing left to yield to, and braking
            # here would stop the ego in the box — a different offence.
            return

        committed = self.phase in ("running", "entering", "blocking")
        if committed or self._junction_occupied(ctx):
            if not self.ego_held:
                # Autopilot would fight the brake.
                ctx.ego.set_autopilot(False, ctx.tm.get_port())
                self.ego_held = True
                ctx.notes.setdefault("ego_yield_started_at_frame", ctx.frame)
            ctx.ego.apply_control(carla.VehicleControl(
                throttle=0.0, brake=1.0, hand_brake=True))
        elif self.ego_held:
            ctx.ego.apply_control(carla.VehicleControl(hand_brake=False))
            ctx.ego.set_autopilot(True, ctx.tm.get_port())
            self.ego_held = False
            # Latched: the junction is clear and the ego goes. Re-holding later
            # would flap the autopilot on and off for background traffic.
            self.ego_released = True
            ctx.notes["ego_yield_released_at_frame"] = ctx.frame

    def on_tick(self, ctx: RunContext) -> None:
        """Walk the cross vehicle through: wait, enter, block, leave."""
        self._pin_green(ctx)
        if not ctx.violating:
            self._drive_ego_compliantly(ctx)

        if (self.cross is None or not self.cross.is_alive
                or self.junction is None or self.phase == "leaving"):
            return

        if self.phase == "held":
            distance = plane_distance(ctx.ego.get_location(),
                                      self.junction.bounding_box.location)
            if distance > CROSS_RELEASE_EGO_DISTANCE_M:
                self._hold()
                return
            self._drive(ctx)
            self.phase = "running"
            ctx.notes["cross_released_at_frame"] = ctx.frame
            ctx.notes["cross_released_at_ego_distance_m"] = distance
            return

        if self.phase == "running":
            waypoint = ctx.carla_map.get_waypoint(
                self.cross.get_location(), project_to_road=True,
                lane_type=carla.LaneType.Driving)
            if waypoint is not None and waypoint.is_junction:
                self.phase = "entering"
                self.counter = 0
                ctx.notes["cross_entered_junction_at_frame"] = ctx.frame
            return

        if self.phase == "entering":
            self.counter += 1
            if self.counter >= CROSS_ENTER_FRAMES:
                # Take manual control: autopilot would drive it straight out.
                self.cross.set_autopilot(False, ctx.tm.get_port())
                self._hold()
                self.phase = "blocking"
                self.counter = 0
                ctx.notes["cross_blocking_from_frame"] = ctx.frame
            return

        if self.phase == "blocking":
            self._hold()
            self.counter += 1
            if self.counter >= CROSS_BLOCK_FRAMES:
                self._drive(ctx)
                self.phase = "leaving"
                ctx.notes["cross_released_from_junction_at_frame"] = ctx.frame
