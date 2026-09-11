"""The capture runner: everything every scenario needs, written once.

Produces exactly the layout `traffic-spec-agent`'s `carla/adapter.py` and
`scripts.run_spec monitor` consume, plus the ground truth that makes the label
file meaningful:

    <database>/<capture>/
        rsv/{0..N}.pkl        process_to_junction_rsv frames
        rsv/{0..N}.png        scene-graph renders (--save-viz)
        ego_logs.json         per-frame ego control/state, 1:1 with rsv/
        camera/{00000..}.png  RGB stills, for human spot-checking the labels
        oracle.jsonl          per-frame CARLA-server ground truth
        labels.json           per-law verdicts derived from oracle.jsonl
        simulation.json       what was configured, and what actually happened

This module replaces the boilerplate that used to sit in `src/red_light.py`:
connecting, synchronous mode, spawning, the SGG loop, the camera queue drain and
teardown. The red-light specifics live in `scenarios/red_light.py`.
"""

from __future__ import annotations

import json
import random
import shutil
import traceback
from pathlib import Path
from queue import Empty, Queue
from typing import Optional

from . import compat, paths

paths.ensure_agents_importable()
paths.ensure_repo_importable()
for _shim in compat.apply_all():
    print(f"[compat] {_shim}")

import carla                                                   # noqa: E402

from carla_sgg.sgg import SGG, IgnoreWaypointPickler           # noqa: E402
from carla_sgg.sgg_abstractor import process_to_junction_rsv   # noqa: E402
from carla_sgg.utils import plot_graph                         # noqa: E402

from . import driving                                          # noqa: E402
from .labeler import (                                         # noqa: E402
    COMPLIANT,
    VIOLATED,
    build_label_file,
    engaged_laws,
    write_label_file,
)
from .oracle import OracleRecorder, summarize                  # noqa: E402
from .scenario import RunContext, Scenario                     # noqa: E402


class CaptureError(RuntimeError):
    """Raised when a capture completes but does not exercise what it claims."""


def build_ego_record(ego: carla.Vehicle) -> dict:
    """One `ego_logs.json` record, in the shape `carla/adapter.py` reads
    (`state.velocity.value`, `control.throttle`, ...)."""
    control = ego.get_control()
    velocity = ego.get_velocity()
    acceleration = ego.get_acceleration()
    angular_velocity = ego.get_angular_velocity()
    transform = ego.get_transform()
    return {
        "control": {
            "throttle": control.throttle,
            "steer": control.steer,
            "brake": control.brake,
            "hand_brake": control.hand_brake,
            "reverse": control.reverse,
            "manual_gear_shift": control.manual_gear_shift,
            "gear": control.gear,
        },
        "state": {
            "velocity": {"value": velocity.length(), "x": velocity.x,
                         "y": velocity.y, "z": velocity.z},
            "acceleration": {"value": acceleration.length(), "x": acceleration.x,
                             "y": acceleration.y, "z": acceleration.z},
            "angular_velocity": {"value": angular_velocity.length(),
                                 "x": angular_velocity.x, "y": angular_velocity.y,
                                 "z": angular_velocity.z},
            "transform": {
                "x": transform.location.x, "y": transform.location.y,
                "z": transform.location.z, "pitch": transform.rotation.pitch,
                "yaw": transform.rotation.yaw, "roll": transform.rotation.roll,
            },
        },
    }


def prepare_endpoint(destination: Path, name: str, overwrite: bool) -> Path:
    """Pick the capture directory, and make sure it holds only this run.

    Overwriting must **clear** the frame directories, not just write into them.
    `carla/adapter.py` globs `rsv/*.pkl` and pairs frame *i* with ego-log record
    *i*, so a shorter re-run left behind the tail of a longer earlier one: a
    240-frame capture in a directory still holding 500 stale frames converted as
    a 500-frame trace, splicing two different runs together and silently
    dropping ego dynamics past record 239.
    """
    endpoint = destination / name
    if endpoint.exists() and not overwrite:
        index = 2
        candidate = destination / f"{name}_{index}"
        while candidate.exists():
            index += 1
            candidate = destination / f"{name}_{index}"
        print(f"\033[93mWARNING: {endpoint} exists, writing to {candidate}\033[0m")
        endpoint = candidate
    elif endpoint.exists():
        for sub in ("rsv", "camera"):
            if (endpoint / sub).is_dir():
                shutil.rmtree(endpoint / sub)
        for stale in ("oracle.jsonl", "labels.json", "ego_logs.json",
                      "simulation.json"):
            (endpoint / stale).unlink(missing_ok=True)
    (endpoint / "rsv").mkdir(parents=True, exist_ok=True)
    (endpoint / "camera").mkdir(parents=True, exist_ok=True)
    return endpoint


class CaptureRunner:
    def __init__(self, scenario: Scenario, mode: str, *, host: str = "127.0.0.1",
                 port: int = 2000, tm_port: int = 8000, fps: int = 20,
                 destination: Optional[Path] = None, name: Optional[str] = None,
                 seed: int = 42, duration: Optional[float] = None,
                 save_viz: bool = False, no_camera: bool = False,
                 overwrite: bool = False, town: Optional[str] = None):
        self.scenario = scenario
        self.mode = mode
        self.host, self.port, self.tm_port = host, port, tm_port
        self.fps = fps
        self.destination = destination or paths.DEFAULT_DATABASE
        self.name = name or scenario.capture_name(mode)
        self.seed = seed
        self.duration_overridden = duration is not None
        self.duration = duration if duration is not None else scenario.duration
        self.save_viz = save_viz
        self.no_camera = no_camera
        self.overwrite = overwrite
        self.town = town if town is not None else scenario.town

    # ------------------------------------------------------------ world

    def _connect(self) -> tuple[carla.Client, carla.World]:
        client = carla.Client(self.host, self.port)
        client.set_timeout(180.0)
        if self.town:
            current = client.get_world().get_map().name.split("/")[-1]
            if current != self.town:
                print(f"[world] loading {self.town} (was {current})")
                world = client.load_world(self.town)
            else:
                world = client.get_world()
        else:
            world = client.get_world()
        world.set_weather(carla.WeatherParameters.ClearNoon)

        settings = world.get_settings()
        settings.synchronous_mode = True
        settings.fixed_delta_seconds = 1.0 / self.fps
        world.apply_settings(settings)
        world.tick()
        return client, world

    def _spawn_background(self, ctx: RunContext,
                          ego_spawn: carla.Transform) -> list[carla.Actor]:
        count = self.scenario.n_background
        if count <= 0:
            return []
        blueprints = [bp for bp in ctx.world.get_blueprint_library().filter("vehicle.*")
                      if int(bp.get_attribute("number_of_wheels")) == 4]
        candidates = [sp for sp in ctx.carla_map.get_spawn_points()
                      if sp.location.distance(ego_spawn.location) > 8.0]
        ctx.rng.shuffle(candidates)

        spawned = []
        for spawn_point in candidates[:count]:
            actor = ctx.world.try_spawn_actor(ctx.rng.choice(blueprints), spawn_point)
            if actor is None:
                continue
            actor.set_autopilot(True, self.tm_port)
            # Background traffic obeys everything; only the ego is under test.
            ctx.tm.ignore_lights_percentage(actor, 0.0)
            ctx.tm.ignore_signs_percentage(actor, 0.0)
            ctx.tm.update_vehicle_lights(actor, True)
            spawned.append(actor)
        return spawned

    def _attach_camera(self, ctx: RunContext) -> tuple[Optional[carla.Actor],
                                                       Optional[Queue]]:
        if self.no_camera:
            return None, None
        blueprint = ctx.world.get_blueprint_library().find("sensor.camera.rgb")
        blueprint.set_attribute("image_size_x", "960")
        blueprint.set_attribute("image_size_y", "540")
        blueprint.set_attribute("fov", "100")
        camera = ctx.world.spawn_actor(
            blueprint, carla.Transform(carla.Location(x=0.7, z=1.6)),
            attach_to=ctx.ego)
        queue: Queue = Queue()
        camera.listen(queue.put)
        return camera, queue

    # -------------------------------------------------------------- run

    def run(self) -> dict:
        endpoint = prepare_endpoint(self.destination, self.name, self.overwrite)
        print(f"\033[1m> {self.scenario.name} [{self.mode}] -> {endpoint}\033[0m")

        client, world = self._connect()
        tm = client.get_trafficmanager(self.tm_port)
        tm.set_synchronous_mode(True)
        tm.set_random_device_seed(self.seed)
        tm.set_global_distance_to_leading_vehicle(2.5)

        ctx = RunContext(client=client, world=world, carla_map=world.get_map(),
                         tm=tm, mode=self.mode, fps=self.fps,
                         rng=random.Random(self.seed))

        background: list[carla.Actor] = []
        camera = camera_queue = None
        ego_records: list[dict] = []
        oracle: Optional[OracleRecorder] = None
        failure: Optional[str] = None
        interrupted = False

        try:
            spawn_points = ctx.carla_map.get_spawn_points()
            if not spawn_points:
                raise RuntimeError(f"{ctx.carla_map.name} has no spawn points")

            ego_spawn = self.scenario.choose_ego_spawn(ctx, spawn_points)
            if ego_spawn is None:
                # Documented as "let the runner pick", but a scenario that
                # searched for particular geometry and found none also returns
                # None. Substituting a random spawn point turns "this town has
                # no signalized approach" into a capture that fails 200 frames
                # later for a reason that looks unrelated, so say so here.
                print(f"\033[93mWARNING: {self.scenario.name}."
                      f"choose_ego_spawn returned None; falling back to a "
                      f"random spawn point. If the scenario needs specific "
                      f"geometry it should raise instead.\033[0m")
                ego_spawn = ctx.rng.choice(spawn_points)

            blueprint = world.get_blueprint_library().find("vehicle.tesla.model3")
            if blueprint.has_attribute("role_name"):
                blueprint.set_attribute("role_name", "hero")
            # A scenario picks its start for its geometry, not from the map's
            # spawn-point list, so the spot may be occupied or slightly sunk.
            for lift in (0.0, 0.5, 1.0):
                attempt = carla.Transform(
                    carla.Location(ego_spawn.location.x, ego_spawn.location.y,
                                   ego_spawn.location.z + lift),
                    ego_spawn.rotation)
                ctx.ego = world.try_spawn_actor(blueprint, attempt)
                if ctx.ego is not None:
                    break
            if ctx.ego is None:
                raise RuntimeError(f"could not spawn the ego at {ego_spawn}")
            world.tick()

            background = self._spawn_background(ctx, ego_spawn)
            world.tick()

            camera, camera_queue = self._attach_camera(ctx)

            # Sane defaults; a scenario overrides whatever it is about.
            ctx.ego.set_autopilot(True, self.tm_port)
            tm.ignore_lights_percentage(ctx.ego, 0.0)
            tm.ignore_signs_percentage(ctx.ego, 0.0)
            tm.ignore_vehicles_percentage(ctx.ego, 0.0)
            # CARLA leaves vehicle lights off unless something drives them, and
            # `light_brake` is the only dynamic evidence the abstraction keeps
            # about a non-ego vehicle. Without this, any rule reading a lead
            # vehicle's brake light is silently vacuous on every capture.
            tm.update_vehicle_lights(ctx.ego, True)
            # CARLA's convention is inverted from the obvious reading: a
            # positive percentage means slower than the limit.
            tm.vehicle_percentage_speed_difference(ctx.ego, 20.0)

            self.scenario.configure(ctx)

            print("[sgg] indexing the map (slow, once per process)...")
            sgg = SGG(client, ctx.ego.id)

            for _ in range(self.scenario.warmup_ticks):
                world.tick()

            oracle = OracleRecorder(world, ctx.ego, self.fps)
            n_frames = int(self.duration * self.fps)
            if n_frames > self.scenario.max_capture_frames:
                if not self.duration_overridden:
                    # A scenario that asks for more frames than it is allowed to
                    # keep was choreographed against a length it never gets: the
                    # approach, the closing vehicle and the manoeuvre were all
                    # timed for `duration` seconds and then cut to a fraction of
                    # it. Truncating silently is how that goes unnoticed.
                    raise ValueError(
                        f"{self.scenario.name} declares duration="
                        f"{self.scenario.duration}s, which is {n_frames} frames "
                        f"at {self.fps} Hz, over its own max_capture_frames="
                        f"{self.scenario.max_capture_frames}. Shorten the "
                        f"scenario's approach and lower its duration to "
                        f"{self.scenario.max_capture_frames / self.fps:.1f}s or "
                        f"less; do not rely on the runner to cut it.")
                print(f"[capture] --duration {self.duration}s is {n_frames} "
                      f"frames, over the {self.scenario.max_capture_frames}-frame "
                      f"ceiling Lean's code generator imposes; truncating")
                n_frames = self.scenario.max_capture_frames
            print(f"[capture] {n_frames} frames at {self.fps} Hz")

            for index in range(n_frames):
                world.tick()
                ctx.frame = index
                sim_frame = world.get_snapshot().frame

                self.scenario.on_tick(ctx)

                graph = sgg.generate_graph_for_frame(index)
                rsv = process_to_junction_rsv(graph)
                with open(endpoint / "rsv" / f"{index}.pkl", "wb") as fd:
                    IgnoreWaypointPickler(fd).dump(rsv)
                if self.save_viz:
                    plot_graph(rsv, str(endpoint / "rsv" / f"{index}.png"))

                ego_records.append(build_ego_record(ctx.ego))
                oracle.tick(index, sim_frame)

                if camera_queue is not None:
                    self._drain_camera(camera_queue, sim_frame, endpoint, index)

                if index % self.fps == 0:
                    speed = ctx.ego.get_velocity().length()
                    print(f"  frame {index}/{n_frames}  {speed:5.2f} m/s  "
                          f"at_light={ctx.ego.is_at_traffic_light()}", end="\r")
                if ctx.finished:
                    print(f"\n[capture] scenario ended early at frame {index}")
                    break
            print()
        except KeyboardInterrupt:
            # `except Exception` does not catch this, and without a branch here
            # the interrupt skips `_finalize` entirely: the capture directory is
            # left holding rsv/ and camera/ with no oracle.jsonl, labels.json or
            # simulation.json. `capture_bench.discover` then reports the whole
            # counterpart pair INCOMPLETE, and a re-run without --overwrite
            # writes to <name>_2 rather than replacing the stub.
            interrupted = True
            failure = "interrupted by the user before the capture finished"
            print(f"\n\033[93m[capture] {failure}; writing what was "
                  f"recorded\033[0m")
        except Exception:                                   # noqa: BLE001
            failure = traceback.format_exc()
            print(f"\033[91m{failure}\033[0m")
        finally:
            try:
                self.scenario.teardown(ctx)
            except Exception:                               # noqa: BLE001
                traceback.print_exc()
            self._cleanup(ctx, background, camera)

        result = self._finalize(endpoint, ctx, ego_records, oracle, failure)
        if interrupted:
            # Finalized, but the user asked to stop: do not let `--all` roll on
            # to the next scenario.
            raise KeyboardInterrupt
        return result

    def _drain_camera(self, queue: Queue, sim_frame: int, endpoint: Path,
                      index: int) -> None:
        """Keep the still whose sensor frame matches this tick.

        Sensor callbacks fire on another thread; in synchronous mode the image
        for `sim_frame` is guaranteed to be queued by the time `tick()` returns,
        but may land just after this line runs.
        """
        image = None
        try:
            while True:
                candidate = queue.get(True, 2.0)
                if candidate.frame >= sim_frame:
                    image = candidate
                    break
        except Empty:
            print(f"\nWARNING: camera frame for tick {sim_frame} timed out")
        if image is not None:
            image.save_to_disk(str(endpoint / "camera" / f"{index:05d}.png"))

    def _cleanup(self, ctx: RunContext, background: list[carla.Actor],
                 camera: Optional[carla.Actor]) -> None:
        print("[cleanup] releasing actors and restoring the world")
        driving.release_lights(ctx.frozen_lights)
        if camera is not None:
            try:
                camera.stop()
                camera.destroy()
            except RuntimeError:
                pass
        for actor in list(ctx.spawned) + background:
            try:
                if actor.type_id.startswith("vehicle."):
                    actor.set_autopilot(False, self.tm_port)
                actor.destroy()
            except RuntimeError:
                pass
        if ctx.ego is not None:
            try:
                ctx.ego.set_autopilot(False, self.tm_port)
                ctx.ego.destroy()
            except RuntimeError:
                pass
        try:
            settings = ctx.world.get_settings()
            settings.synchronous_mode = False
            settings.fixed_delta_seconds = None
            ctx.world.apply_settings(settings)
            ctx.tm.set_synchronous_mode(False)
        except RuntimeError:
            pass

    # --------------------------------------------------------- reporting

    def _finalize(self, endpoint: Path, ctx: RunContext, ego_records: list[dict],
                  oracle: Optional[OracleRecorder],
                  failure: Optional[str]) -> dict:
        with open(endpoint / "ego_logs.json", "w", encoding="utf-8") as fd:
            json.dump({"records": ego_records}, fd, indent=2, ensure_ascii=False)

        result: dict = {
            "capture": self.name,
            "scenario": self.scenario.name,
            "mode": self.mode,
            "endpoint": str(endpoint),
            "target_laws": list(self.scenario.target_laws),
            "frames": len(ego_records),
            "ok": failure is None,
        }

        if oracle is not None and oracle.records:
            oracle.write(endpoint / "oracle.jsonl")
            digest = summarize(oracle.records)
            label_file = build_label_file(
                oracle.records, self.name, self.fps,
                meta={"scenario": self.scenario.name, "mode": self.mode,
                      "seed": self.seed, "town": ctx.carla_map.name,
                      "notes": ctx.notes})
            write_label_file(label_file, endpoint / "labels.json")

            engaged = engaged_laws(label_file)
            missing = [law for law in self.scenario.target_laws
                       if law not in engaged]
            verdicts = {entry["law"]: entry["verdict"]
                        for entry in label_file["labels"]}

            # A capture recorded as `compliant` asserts that the footage is
            # lawful under the law it targets, and `violation` asserts the
            # opposite. Checking only that the law was *engaged* lets a run that
            # engaged it and then came out the wrong way pass as ok — which is
            # how emergency_junction_compliant scored ok:true while its own
            # ground truth said `violated`. Downstream that reaches
            # `capture_bench.pair_status` as TRIGGER-HAPPY and is billed to the
            # Lean rule rather than to the capture that provoked it.
            expected = COMPLIANT if self.mode == "compliant" else VIOLATED
            mismatched = {law: verdicts.get(law)
                          for law in self.scenario.target_laws
                          if law in engaged and verdicts.get(law) != expected}

            # Not a failure, but worth saying out loud: a counterpart capture is
            # only attributable if it is lawful in every respect except the one
            # under test. A `compliant` run that also breaks an untargeted law
            # cannot tell you which rule a later disagreement belongs to.
            incidental = sorted(law for law, verdict in verdicts.items()
                                if verdict == VIOLATED
                                and law not in self.scenario.target_laws)

            # `dict.update`, not `|=`: the client library CARLA 0.9.14 ships a
            # wheel for is cp37, and PEP 584's dict union is 3.9+. This line
            # sits in `_finalize`, so under 3.7 it raised only after the whole
            # simulation had run, discarding oracle.jsonl, labels.json and
            # simulation.json for every capture.
            result.update({
                "oracle": digest,
                "verdicts": verdicts,
                "engaged": sorted(engaged),
                "targets_not_engaged": missing,
                "targets_wrong_verdict": mismatched,
                "incidental_violations": incidental,
            })
            self._print_summary(digest, verdicts, missing, mismatched,
                                incidental, expected)
            if missing:
                result["ok"] = False
                result["error"] = (
                    f"capture did not exercise {', '.join(missing)}")
            elif mismatched:
                result["ok"] = False
                result["error"] = (
                    f"mode is {self.mode!r} but ground truth says "
                    + ", ".join(f"{law}={verdict}"
                                for law, verdict in mismatched.items())
                    + f" (expected {expected})")
        elif failure is None:
            result["ok"] = False
            result["error"] = "no frames captured"

        if failure:
            result["error"] = failure.strip().splitlines()[-1]

        # A copy, so the manifest-only keys do not leak into the dict this
        # method returns to `run_one`. See the `dict.update` note above for why
        # this is not `result | {...}`.
        manifest = dict(result)
        manifest.update({"fps": self.fps, "seed": self.seed,
                         "duration": self.duration,
                         "town": ctx.carla_map.name,
                         "scenario_notes": ctx.notes,
                         "generator": self._generator_manifest()})
        with open(endpoint / "simulation.json", "w", encoding="utf-8") as fd:
            json.dump(manifest, fd, indent=2, ensure_ascii=False)
        return result

    def _generator_manifest(self) -> dict:
        """The generator and simulator settings this capture was actually made
        with.

        `traffic-spec-agent` hard-codes several of these — the 20 Hz frame rate
        in `Core/Scene.lean::captureHz`, the proximity band metres in
        `distanceBands` — and its own `carla/schema.json` states them as facts.
        They are in truth caller-supplied defaults, and nothing in a capture
        recorded them, so a capture made at another rate or with other
        thresholds would have been read against the wrong numbers in silence.
        Recording them lets `carla/adapter.py` refuse instead.
        """
        from carla_sgg import sgg_abstractor as abstractor
        return {
            "capture_hz": self.fps,
            "fixed_delta_seconds": 1.0 / self.fps,
            "proximity_thresholds": abstractor.DEFAULT_PROXIMITY_THRESHOLDS,
            "directional_thresholds": abstractor.DEFAULT_DIRECTIONAL_THRESHOLDS,
            "proximity_relation_classes": sorted(
                {pair[1] for pair in abstractor.DEFAULT_PROXIMITY_RELATIONS}),
            "render_dist": 50.0,          # generate_graph_for_frame default
            "segment_length": 1.0,        # SGG default
            "check_occlusion": False,     # SGG default
            "parse_junction_boundaries": False,   # init_to_world default
            # Every actor dropped from the frame. The ego is always excluded
            # by generate_graph_for_frame, which is why it carries no light_*
            # attributes; this runner never excludes anything else.
            "exclude_ids": ["ego"],
            "abstraction": "process_to_junction_rsv",
        }

    def _print_summary(self, digest: dict, verdicts: dict[str, str],
                       missing: list[str],
                       mismatched: Optional[dict[str, str]] = None,
                       incidental: Optional[list[str]] = None,
                       expected: Optional[str] = None) -> None:
        print(f"\n[oracle] {digest['frames']} frames, "
              f"peak {digest['speed_kph_max']:.1f} km/h, "
              f"{digest['frames_in_junction']} in a junction, "
              f"{digest['frames_facing_red']} facing red, "
              f"{digest['frames_wrong_way']} wrong-way")
        print("[labels]")
        for law, verdict in verdicts.items():
            marker = "*" if law in self.scenario.target_laws else " "
            print(f"  {marker} {law:<20} {verdict}")
        if missing:
            print(f"\033[91m[FAIL] target law(s) not exercised: "
                  f"{', '.join(missing)}\033[0m")
            print("       re-run with a different --seed or --town; a capture "
                  "that never reaches the situation proves nothing about the rule.")
        if mismatched:
            print(f"\033[91m[FAIL] recorded as {self.mode!r}, but the ground "
                  f"truth disagrees: "
                  + ", ".join(f"{law}={verdict}"
                              for law, verdict in mismatched.items())
                  + f" (expected {expected})\033[0m")
            print("       the scenario did not produce the behaviour its mode "
                  "claims; fix the scenario, not the label.")
        if incidental:
            print(f"\033[93m[warn] this capture also violates untargeted "
                  f"law(s): {', '.join(incidental)}. A counterpart pair is only "
                  f"attributable when its two runs differ in one respect.\033[0m")
