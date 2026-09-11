"""The scenario interface and its registry.

A scenario says only what makes it *that* scenario: which town, where the ego
starts, which Traffic Manager knobs differ between the compliant and the
violating run, what extra actors to spawn, and what to do on a given tick.
Everything else — synchronous mode, the SGG, writing `.pkl` frames, the ego log,
the camera, the ground-truth oracle, cleanup — belongs to `runner.CaptureRunner`
and is written once.

Each scenario declares `target_laws`, and the runner checks two things against
the labels afterwards. It **fails** if a target law came out `not_applicable`: a
capture that never reached a red light proves nothing about a red-light rule, and
silently labelling it `not_applicable` would let a library of vacuous rules score
perfectly. It also **fails** if a target law was engaged but came out the wrong
way round — a `compliant` capture whose ground truth reads `violated` is not a
lawful counterpart, and passing it downstream gets the resulting
`TRIGGER-HAPPY` billed to the Lean rule rather than to the capture.

`mode` is a claim about the footage, not a description of the switches that were
set, so both checks are made against `oracle.jsonl` and neither consults the
Traffic Manager settings the scenario chose.
"""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Optional

import carla

MODES = ("compliant", "violation")


@dataclass
class RunContext:
    """Everything a scenario hook is allowed to touch."""

    client: carla.Client
    world: carla.World
    carla_map: carla.Map
    tm: carla.TrafficManager
    mode: str
    fps: int
    rng: random.Random
    ego: Optional[carla.Vehicle] = None
    frame: int = 0
    # Actors the scenario spawned; the runner destroys these.
    spawned: list[carla.Actor] = field(default_factory=list)
    # Traffic lights the scenario froze; the runner un-freezes them.
    frozen_lights: list[carla.TrafficLight] = field(default_factory=list)
    # Free-form scenario state, copied into simulation.json.
    notes: dict = field(default_factory=dict)
    # Set by a scenario to end the capture early.
    finished: bool = False

    @property
    def violating(self) -> bool:
        return self.mode == "violation"

    def spawn(self, blueprint: carla.ActorBlueprint,
              transform: carla.Transform,
              attach_to: Optional[carla.Actor] = None) -> Optional[carla.Actor]:
        actor = self.world.try_spawn_actor(blueprint, transform, attach_to=attach_to)
        if actor is not None:
            self.spawned.append(actor)
        return actor


class Scenario:
    """Base class. Subclasses override the hooks they need."""

    #: registry key, and the default capture folder name
    name: str = "unnamed"
    #: one-line description, shown by `--list`
    description: str = ""
    #: law ids from laws/example/laws.jsonl this scenario is built to exercise
    target_laws: tuple[str, ...] = ()
    #: map to load; None keeps whatever the server has
    town: Optional[str] = "Town03"
    #: seconds of captured driving.
    #:
    #: Must satisfy `duration * fps <= max_capture_frames`, which at the
    #: reference 20 Hz means 12 seconds. The runner refuses a scenario that
    #: declares more rather than truncating it: every scenario here used to ask
    #: for 22-30 s and silently receive 12, so approaches, closing vehicles and
    #: scripted manoeuvres were all choreographed against a length that never
    #: existed. Shorten the approach instead of raising this.
    duration: float = 12.0
    #: hard cap on captured frames.
    #:
    #: `carla/adapter.py` emits the whole trace as one Lean list literal, and
    #: Lean's *code generator* — not its elaborator — gives up on it with
    #: "maximum recursion depth reached in the code generator". Measured on a
    #: Town03 signalized-junction capture (roughly 60 entities per frame): 250
    #: frames build, 350 do not. The bundled `Carla/Sample.lean` is 8 frames and
    #: `Captured.lean` is 50, so nothing upstream ever ran into this.
    #:
    #: 240 frames is 12 s at the reference 20 Hz, comfortably longer than the
    #: widest window any rule uses (R0011's 80 frames). A scenario whose
    #: situation needs longer should shorten its approach rather than raise
    #: this, or the capture will convert and then fail to build.
    max_capture_frames: int = 240
    #: ticks to settle physics and traffic before frame 0
    warmup_ticks: int = 30
    #: background autopilot vehicles the runner spawns
    n_background: int = 8

    # ------------------------------------------------------------ hooks

    def choose_ego_spawn(self, ctx: RunContext,
                         spawn_points: list[carla.Transform]) -> Optional[carla.Transform]:
        """Return the ego's start transform, or None to let the runner pick."""
        return None

    def configure(self, ctx: RunContext) -> None:
        """Called once, after the ego exists and autopilot is on. Set Traffic
        Manager knobs, spawn extra actors, force signal states."""

    def on_tick(self, ctx: RunContext) -> None:
        """Called once per captured frame, after `world.tick()`."""

    def teardown(self, ctx: RunContext) -> None:
        """Called before the runner destroys actors. Rarely needed."""

    # --------------------------------------------------------- utilities

    def capture_name(self, mode: str) -> str:
        return f"{self.name}_{mode}"


REGISTRY: dict[str, Scenario] = {}


def register(scenario_cls: type[Scenario]) -> type[Scenario]:
    instance = scenario_cls()
    if instance.name in REGISTRY:
        raise ValueError(f"duplicate scenario name: {instance.name}")
    REGISTRY[instance.name] = instance
    return scenario_cls


def get(name: str) -> Scenario:
    if name not in REGISTRY:
        known = ", ".join(sorted(REGISTRY)) or "(none registered)"
        raise KeyError(f"unknown scenario {name!r}; known scenarios: {known}")
    return REGISTRY[name]
