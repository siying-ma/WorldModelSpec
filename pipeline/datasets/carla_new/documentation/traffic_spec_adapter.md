# Raw capture to TrafficSpec

`pipeline.py adapt-trace` writes runtime JSON, not Lean source. The full
TrafficSpec decoder turns `trace.json` into `TrafficSpec.Trace`. The adapter
imports no laws or law templates and does not choose judgment-call thresholds.
It does not use the previous SceneFlowSpec exporter or abstract-only captures.

Run with Python 3.8+ and NetworkX/Shapely installed; the existing CARLA Python
environment has these dependencies. No CARLA installation or server is needed
by the offline graph loader. Pickles must be trusted repository captures.

```bash
../envs/carla-py38/bin/python pipeline.py adapt-trace \
  --capture ../runs/scenario_pipeline/legacy/C353238/scene_graphs/M010 \
  --original-run ../runs/scenario_pipeline/legacy/C353238/recordings/corrected/M010-20260930T225704705418Z \
  --library ../repo_prep/nevada_sydney/pipeline/traffic-spec-agent/library \
  --output ../runs/scenario_pipeline/adapters/my-export/M010 \
  --validator ../runs/scenario_pipeline/adapters/traffic-spec-v1/decoder-v2/.lake/build/bin/adapterCheck
```

Use a new output directory. The command does not open the pipeline job database,
connect to CARLA, alter sources, or select/re-run simulations. The source recording
is explicit because historical capture manifests can contain relocated paths.
Its map and telemetry hashes must match the capture's manifest.

## Output and provenance

- `trace.json`: the exact World/Decode schema; one scene per captured frame.
- `manifest.json`: every full-ontology atom, with this acquisition version's
  capability. Unobserved values remain missing; observed false stays false.
- `supplementary_evidence.jsonl`: complete original evidence and telemetry records,
  joined to each World timestamp, plus the path/hash of the immutable raw graph.
  This retains visibility directions, body rays, bounds, obstruction observations,
  control targets, physical failure indicators and native attributes without
  assigning them an incorrect World meaning. Raw graph references retain all
  attributes, including those without a JSON representation.
- `adapter_report.json`: input hashes, conversion methods, limitations and decoder
  status. Decoder logs are added when `--validator` is supplied.

An atom is not supported merely because its data was retained in the supplementary
file. The monitor reads only trace/manifest. This is explicitly distinct from
information preservation and decoder compatibility.

CARLA body positions, vector y components and headings are reflected into the
right-handed World frame. Source OpenDRIVE geometry is **already right-handed**
and is not reflected again. Units are SI; timestamps come from original simulation
observation times, in integer milliseconds; numeric output has at most six decimals.
Body position is the recorded box centre, not an assumed zero-offset actor origin.

Original recorded speed takes precedence over replay kinematics. Replay velocity
zeros and requested speed are never lifted into observed speed. The adapter does
not reconstruct velocity direction from speed and heading. Subject yaw rate is an
estimate from unwrapped measured headings, central differences internally and
one-sided differences at endpoints. Sampling gaps and large unresolved angle jumps
leave it unknown. Path length uses trapezoidal speed integration and remains unknown
after a sampling gap. The manifest uses `subject` for these quantities because this
capture path has original velocity telemetry only for the subject; the report
records their estimation methods.

## Geometry, participants and signals

Full lanes have stable (road, section, lane) identities. Their polygons are sampled
from the supplied OpenDRIVE at up to 2 m intervals. Local roadway patches carry
constant reference curvature; curve values are not copied to straight sections.
The reference curve is not the ego trajectory or lane-offset curve. Unsupported
OpenDRIVE geometry fails rather than producing a fictitious empty map. A winding
lane has no single direction vector in World: that field remains unknown. Grade is
emitted only where supported; varying grade remains in the source evidence.

Spawned traffic cones/barriers become obstruction regions. When static-prop capture
is enabled, the generator retains their actual transforms and bounding boxes even
outside its local crop or occlusion filter. This records geometry, not a claim of
ego visibility. Recorder creation events alone establish existence and position;
they never provide an invented footprint.

Occupancy is computed from measured convex footprints against sampled map/prop
polygons. Missing boundaries remain explicit in `structures_without_observed_boundary`;
Core's per-user observation mask remains unknown when region coverage is incomplete.
The report's `required_measurements_complete` checks requested visibility coverage
and occupancy boundaries. Decoder success checks formatting and references only.
Sight-distance manifest availability is derived from the exported frames: an entirely
missing scalar is `absent`, not an estimated measurement. Older exports remain
immutable and must be regenerated from repaired captures.

Road users keep their source actor IDs. Recorded blueprint identity supports
classification; uncertain subclasses remain in `unobserved_classes`. Measured
lamp flags are mapped without inferring lamps from brake/throttle/steering commands.
The decoder has no turn-indicator `off` value, so observed off is retained as
supplementary evidence and the corresponding scalar remains unknown.

Traffic signal/stop actors and recognized stop/yield/speed landmarks are mapped.
Only actual `controlsTrafficOf` edges establish governance; `mayAffect` does not.
Dynamic signal indications are emitted only when observed in that frame, never
carried forward from a previous observation. Unsupported legends/units remain in
the raw evidence. Incomplete map/device coverage is reported; an empty device or
crosswalk domain must not be interpreted as verified legal absence. Core also
cannot distinguish an unobserved device governance list from an empty one;
observed edges are retained, but missing ones do not establish legal absence. Core's
quantification over listed entities cannot fix this coverage gap in the adapter.

## Subject-relative sight distance

The agreed seeing criterion is **any of the nine sampled ego-body points**.
Capture measures an any-body horizon for every inventoried driving lane on the
current road. The adapter takes the minimum clear-side bound and attaches it to
lane/roadway regions intersecting the actual ego footprint at that timestamp.
It uses the existing `sight_distance` field in metres; Core is unchanged.

See [the complete measurement and mapping contract](visibility_lean_interface/README.md)
for censoring, uncertainty, approach coverage and attachment. Rays remain in
supplementary evidence. `rel.visible` stays absent because the incoming observers
are virtual, not recorded road-user tracks.

Older C353238 captures have only centre horizons and any-body probes at 500 ft;
they cannot supply the agreed any-body scalar. Recapture scene graphs from the
saved CARLA recordings before exporting a new populated trace. Never substitute
a centre horizon, fixed calibration value or controller target. Per-frame unknown
reasons and mapping IDs appear in the adapter report/supplement. The software
checks the Core interface; it does not assert independently formalized laws use
the correct region or manoeuvre interval.

## Decode validation

`traffic_spec_adapter.validate.build_validator(library, workspace, lake)` copies
only Core source into a new artifact workspace and overlays the full-split files.
It builds a small Lean executable using the actual `Decode.trace` and
`Decode.manifest`, without changing `splits/ACTIVE` or the source library. The
executable checks full manifest coverage, typed decoding, subject IDs and occupancy
and device references. It exits 2 on failure and 0 on success.

`--validator` runs this executable and records its result. Without it, the report
explicitly says `not_run`. The five pilot exports use the built validator. Its
success is type/contract validation, not comparison with autoformalized laws or a
compliance verdict. Independently formalized-law compatibility checks are excluded
from this implementation.
