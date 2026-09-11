"""Shared manoeuvres the scenarios build on.

These are the parts that would otherwise be copy-pasted eight times: finding a
start point whose route reaches the right kind of junction, pinning a signal to
red so a capture does not depend on catching the phase by luck, and driving a
vehicle somewhere the Traffic Manager refuses to go.
"""

from __future__ import annotations

import math
from typing import Iterable, Optional

import carla

from .geometry import plane_distance, unit_forward


# --------------------------------------------------------------------------
# Choosing where to start
# --------------------------------------------------------------------------

def waypoints_ahead(carla_map: carla.Map, transform: carla.Transform,
                    distance: float, step: float = 2.0) -> list[carla.Waypoint]:
    """Follow the lane forward from a transform, taking the first branch at each
    fork. Enough to answer "what will the ego meet if it drives straight on"."""
    wp = carla_map.get_waypoint(transform.location, project_to_road=True,
                                lane_type=carla.LaneType.Driving)
    out: list[carla.Waypoint] = []
    travelled = 0.0
    while wp is not None and travelled < distance:
        nxt = wp.next(step)
        if not nxt:
            break
        wp = nxt[0]
        out.append(wp)
        travelled += step
    return out


def spawn_reaching_junction(world: carla.World,
                            spawn_points: list[carla.Transform],
                            require_signal: bool = False,
                            require_stop_sign: bool = False,
                            lookahead: float = 80.0,
                            min_distance: float = 12.0) -> Optional[carla.Transform]:
    """A spawn point whose lane leads into a junction within `lookahead` metres.

    Optionally require that the junction is signalized, or that a stop sign is
    posted for the approach. Preferring the *nearest* qualifying junction keeps
    captures short: the ego reaches the situation under test in a few seconds
    instead of wandering until `--duration` runs out.
    """
    carla_map = world.get_map()
    lights = list(world.get_actors().filter("traffic.traffic_light"))

    best: Optional[tuple[float, carla.Transform]] = None
    for spawn in spawn_points:
        path = waypoints_ahead(carla_map, spawn, lookahead)
        junction_at: Optional[float] = None
        for index, wp in enumerate(path):
            if wp.is_junction:
                junction_at = index * 2.0
                break
        if junction_at is None or junction_at < min_distance:
            continue

        if require_stop_sign:
            first = path[0]
            try:
                marks = first.get_landmarks_of_type(junction_at + 10.0, "206")
            except RuntimeError:
                marks = []
            if not marks:
                continue

        if require_signal:
            entry = path[min(len(path) - 1, int(junction_at / 2.0))]
            near_light = any(
                plane_distance(entry.transform.location,
                               light.get_transform().location) < 25.0
                for light in lights)
            if not near_light:
                continue

        if best is None or junction_at < best[0]:
            best = (junction_at, spawn)
    return best[1] if best else None


def approach_to_traffic_light(
        world: carla.World, back_distance: float = 45.0,
        junction_within: float = 16.0,
        exclude_junctions: tuple[int, ...] = (),
) -> Optional[tuple[carla.Transform, carla.TrafficLight]]:
    """A start transform on a clean signalized approach, plus the light itself.

    Working backwards from `TrafficLight.get_stop_waypoints()` — the lane
    positions CARLA itself stops vehicles at — is far more reliable than
    scanning spawn points for a junction ahead. That scan produced a start
    inside Town03's junction 861, a junction complex tens of metres across: the
    ego's waypoint reported `is_junction` from the third second onward, so it
    never had an *outside the intersection* approach and the red-light clause
    was never engaged at all.

    The approach returned here is guaranteed to satisfy three things the clause
    needs: every waypoint from the start to the stop line is outside a junction,
    a junction begins within `junction_within` metres past the stop line, and
    the light governing it is the one returned.
    """
    carla_map = world.get_map()
    for light in world.get_actors().filter("traffic.traffic_light"):
        try:
            stops = light.get_stop_waypoints()
        except RuntimeError:
            continue
        for stop in stops:
            if stop.is_junction:
                continue

            # A junction must actually begin just past the stop line, otherwise
            # this is a signal on a straight stretch and nothing is "entered".
            junction_id = None
            cursor, travelled = stop, 0.0
            while travelled < junction_within:
                nxt = cursor.next(2.0)
                if not nxt:
                    break
                cursor = nxt[0]
                travelled += 2.0
                if cursor.is_junction:
                    junction_id = cursor.junction_id
                    break
            if junction_id is None or junction_id in exclude_junctions:
                continue

            back = stop.previous(back_distance)
            if not back:
                continue
            start = back[0]
            if start.is_junction:
                continue

            # The whole approach must be plain road: a junction part-way along
            # it puts the ego inside an intersection before the clause applies.
            cursor, travelled, clean = start, 0.0, True
            while travelled < back_distance - 2.0:
                nxt = cursor.next(2.0)
                if not nxt:
                    clean = False
                    break
                cursor = nxt[0]
                travelled += 2.0
                if cursor.is_junction:
                    clean = False
                    break
            if not clean:
                continue

            transform = start.transform
            transform.location.z += 0.3
            return transform, light
    return None


def junction_ahead_of(carla_map: carla.Map, actor: carla.Actor,
                      lookahead: float = 60.0) -> Optional[carla.Junction]:
    path = waypoints_ahead(carla_map, actor.get_transform(), lookahead)
    for wp in path:
        if wp.is_junction:
            return wp.get_junction()
    return None


# --------------------------------------------------------------------------
# Traffic lights
# --------------------------------------------------------------------------

def light_for(world: carla.World, actor: carla.Actor) -> Optional[carla.TrafficLight]:
    """The light CARLA says governs this vehicle right now."""
    try:
        return actor.get_traffic_light()
    except RuntimeError:
        return None


def nearest_light_ahead(world: carla.World, actor: carla.Actor,
                        radius: float = 45.0) -> Optional[carla.TrafficLight]:
    """The nearest traffic light in front of the actor.

    Used before the ego is close enough for `get_traffic_light()` to answer, so a
    scenario can pin the phase early rather than discovering at the stop line
    that the light is green.
    """
    location = actor.get_location()
    fx, fy = unit_forward(actor.get_transform())
    best: Optional[tuple[float, carla.TrafficLight]] = None
    for light in world.get_actors().filter("traffic.traffic_light"):
        target = light.get_transform().location
        dx, dy = target.x - location.x, target.y - location.y
        if dx * fx + dy * fy <= 0:          # behind
            continue
        distance = math.hypot(dx, dy)
        if distance > radius:
            continue
        if best is None or distance < best[0]:
            best = (distance, light)
    return best[1] if best else None


def pin_light(light: carla.TrafficLight, state: carla.TrafficLightState) -> None:
    """Hold a light — and the rest of its junction group — in one state.

    Freezing the whole group matters: CARLA drives a junction's heads as one
    state machine, and un-frozen siblings would keep cycling and could show two
    greens at once, which is not a situation any traffic law contemplates.
    """
    for member in light.get_group_traffic_lights():
        member.set_state(carla.TrafficLightState.Red)
        member.freeze(True)
    light.set_state(state)
    light.freeze(True)


def light_governing_lane(world: carla.World, carla_map: carla.Map,
                         actor: carla.Actor,
                         lookahead: float = 60.0) -> Optional[carla.TrafficLight]:
    """The light that stops traffic in the actor's own lane.

    Indexed from `TrafficLight.get_stop_waypoints()` — the lane positions CARLA
    itself halts vehicles at — and matched against the actor's lane and the
    lanes ahead of it. This is the same index `oracle.py::_index_lights` builds,
    and for the same reason: at a junction every approach's head sits a few
    metres from every other, so *which light is nearest* is not *which light
    governs me*.

    That distinction is not academic here. `pin_light` reds a light's whole
    group before greening the one it was given, so pinning the wrong head green
    sets the ego's own head red — which is worse than leaving the phase alone.

    Costs one RPC per traffic light, so call it until it answers and then cache
    the result rather than calling it every tick.
    """
    wp = carla_map.get_waypoint(actor.get_location(), project_to_road=True,
                                lane_type=carla.LaneType.Driving)
    if wp is None:
        return None

    # The approach may span more than one road segment, so collect every
    # (road, lane) the actor will occupy between here and the stop line.
    keys = {(int(wp.road_id), int(wp.lane_id))}
    cursor, travelled = wp, 0.0
    while travelled < lookahead:
        nxt = cursor.next(2.0)
        if not nxt:
            break
        cursor = nxt[0]
        travelled += 2.0
        if cursor.is_junction:
            break
        keys.add((int(cursor.road_id), int(cursor.lane_id)))

    for light in world.get_actors().filter("traffic.traffic_light"):
        try:
            stops = light.get_stop_waypoints()
        except RuntimeError:
            continue
        for stop in stops:
            if (int(stop.road_id), int(stop.lane_id)) in keys:
                return light
    return None


def pin_light_ahead(world: carla.World, actor: carla.Actor,
                    state: carla.TrafficLightState,
                    radius: float = 60.0,
                    carla_map: Optional[carla.Map] = None,
                    ) -> Optional[carla.TrafficLight]:
    """Hold the signal governing this actor's approach in one state.

    A scenario that is not *about* the signal still has to decide what the
    signal does, because leaving it to chance decides the capture. A default
    CARLA red phase on a four-way junction outlasts a whole 12-second capture,
    so an ego that obeys lights and meets a red simply never reaches the
    junction and the situation under test never arises — while an ego told to
    ignore lights reaches it by committing a second, untargeted offence. Pinning
    green is the third option and the only clean one.

    The lane index is tried first and `nearest_light_ahead` only as a fallback:
    picking by distance at a junction reliably gets a sibling head, and pinning
    that green reds the ego's own.

    Returns the light so the caller can add it to `ctx.frozen_lights`; the
    runner un-freezes those in `_cleanup`.
    """
    carla_map = carla_map if carla_map is not None else world.get_map()
    candidate = (light_governing_lane(world, carla_map, actor, radius)
                 or light_for(world, actor)
                 or nearest_light_ahead(world, actor, radius))
    if candidate is None:
        return None
    pin_light(candidate, state)
    return candidate


def release_lights(lights: Iterable[carla.TrafficLight]) -> None:
    for light in lights:
        try:
            for member in light.get_group_traffic_lights():
                member.freeze(False)
            light.freeze(False)
        except RuntimeError:
            pass


# --------------------------------------------------------------------------
# Driving where the Traffic Manager will not
# --------------------------------------------------------------------------

class WaypointDriver:
    """A minimal pure-pursuit controller.

    The Traffic Manager will not drive into an opposing lane, so the wrong-way
    scenario cannot use it. This follows a fixed list of waypoints with a
    proportional steering law and a target speed — crude, but a lane excursion
    only needs the vehicle to hold a heading for a few seconds.
    """

    def __init__(self, vehicle: carla.Vehicle, route: list[carla.Waypoint],
                 target_speed_mps: float = 8.0, lookahead: float = 5.0):
        self.vehicle = vehicle
        self.route = route
        self.target_speed = target_speed_mps
        self.lookahead = lookahead
        self.index = 0

    @property
    def done(self) -> bool:
        return self.index >= len(self.route)

    def step(self) -> None:
        if self.done:
            self.vehicle.apply_control(
                carla.VehicleControl(throttle=0.0, brake=1.0))
            return

        transform = self.vehicle.get_transform()
        location = transform.location

        # Advance past waypoints we have already reached.
        while (self.index < len(self.route)
               and plane_distance(location,
                                  self.route[self.index].transform.location)
               < self.lookahead):
            self.index += 1
        if self.done:
            return

        target = self.route[self.index].transform.location
        fx, fy = unit_forward(transform)
        dx, dy = target.x - location.x, target.y - location.y
        # Signed angle between the forward vector and the bearing to target.
        cross = fx * dy - fy * dx
        dot = fx * dx + fy * dy
        angle = math.atan2(cross, dot)
        steer = max(-1.0, min(1.0, angle / (math.pi / 4.0)))

        speed = self.vehicle.get_velocity().length()
        throttle = 0.6 if speed < self.target_speed else 0.0
        brake = 0.3 if speed > self.target_speed * 1.25 else 0.0
        self.vehicle.apply_control(
            carla.VehicleControl(throttle=throttle, steer=steer, brake=brake))


def opposing_route(carla_map: carla.Map, start: carla.Transform,
                   length: float = 80.0, step: float = 2.0) -> list[carla.Waypoint]:
    """A route down the lane that opposes the one at `start`.

    Built by hopping to the left neighbour of opposite sign and then walking
    *backwards* along it, which is the direction a wrong-way driver travels.
    """
    wp = carla_map.get_waypoint(start.location, project_to_road=True,
                                lane_type=carla.LaneType.Driving)
    if wp is None:
        return []
    left = wp.get_left_lane()
    if left is None or left.lane_type != carla.LaneType.Driving:
        return []
    if left.lane_id * wp.lane_id > 0:       # same direction, not the opposing one
        return []

    route: list[carla.Waypoint] = []
    cursor = left
    travelled = 0.0
    while travelled < length:
        previous = cursor.previous(step)
        if not previous:
            break
        cursor = previous[0]
        route.append(cursor)
        travelled += step
    return route
