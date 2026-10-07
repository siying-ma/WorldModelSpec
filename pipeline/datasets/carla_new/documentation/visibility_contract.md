# Moving-ego visibility and TrafficSpec sight distance

The agreed visibility criterion for this pipeline is **at least one of the nine
sampled points on the actual ego body being visible**: its bounding-box centre
and eight corners. Distances are measured along incoming driving-lane routes,
not as Euclidean ray lengths or distances from a planned turn site.

For the 500 ft test, TrafficSpec's existing regional `sight_distance` scalar is
sufficient after a defined aggregation. A richer Core schema is not required for
this test. Individual approaches, body rays, brackets and censoring remain in
supplementary evidence for review. They are not discarded or confused with the
scalar's legal meaning. This replaces the earlier proposal that a Core extension
was necessarily required.

## Ownership

- `third_party/carla_scene_graphs/carla_sgg/law_evidence.py` measures visibility
  during capture/replay, from actual per-frame ego geometry.
- `scenario_pipeline/traffic_spec_adapter/visibility.py` computes the scalar and
  selects the regions to receive it; `adapter.py` applies this for every frame.
- TrafficSpec Core already decodes `sight_distance` in metres and exposes
  `st_sight_distance(scene, region)`. Its source is unchanged.
- Independently formalized laws must query an ego-associated region during the
  actual manoeuvre. No visibility-law query was present in the inspected law
  artifacts, so end-to-end law compatibility has not been established merely by
  checking the Core accessor and decoder.

## Capture procedure

`actor_visibility` now emits `actual_actor_body_raycast_v2`. At the actual ego's
projected road station, it inventories every driving lane on that road and
walks upstream along each lane's `previous(distance)` route. The virtual
observer is 1.4 m above that route's waypoint by default. The ego and all nine
body targets are recomputed every frame, including throughout a U-turn.

Each approach records:

- Nine collision rays at 152.4 m (500 ft), and `any_sample_clear_at_probe`.
- `any_body_sight_horizon`: scan for the first distance at which **all nine
  rays are blocked**, then refine the clear/blocked bracket.
- `centre_sight_horizon`: a separate centre-only diagnostic. It never supplies
  the agreed scalar.

Defaults are a 230 m maximum search, 10 m coarse scan and 0.25 m refinement
width. Search starts by checking distance zero. Bracket refinement with a missing
route yields unknown; it does not fabricate a boundary. Coarse blocked rays are
retained with their blocker evidence.

An illustrative fragment (not a measured pilot frame):

```json
{
  "visibility_criterion": "any_of_nine_body_samples",
  "distance_convention": "incoming driving-lane waypoint arc length to actor projected station",
  "required_lane_ids": [-1, 1],
  "horizon_tolerance_m": 0.25,
  "approaches": [
    {
      "lane_id": -1,
      "any_sample_clear_at_probe": true,
      "any_body_sight_horizon": {
        "distance_m": 160.0625,
        "bracket_m": [160.0, 160.125],
        "bound": "first_sampled_occlusion"
      }
    },
    {
      "lane_id": 1,
      "any_sample_clear_at_probe": true,
      "any_body_sight_horizon": {"distance_m": 230.0, "bound": "at_least"}
    }
  ]
}
```

## Deterministic scalar and attachment

The adapter verifies that every required lane appears exactly once and has a
usable any-body horizon. It takes the minimum of the **clear-side bracket
endpoints**, not the uncertain midpoints. In the example above the scalar is
160 m. A censored `at_least` distance contributes a lower bound, never an
asserted physical cutoff. A censored search shorter than 152.4 m cannot answer
this threshold test and leaves the scalar unknown.

Missing/ambiguous routes, missing any-body measurements, incomplete coverage,
a bracket straddling 152.4 m, or a false/missing 500 ft probe contradicting a
horizon above the threshold leave the scalar absent. Invalid/nonfinite numeric
measurements fail conversion. Unknown does not become a violation or a pass.

The scalar is written to **lane and roadway regions intersecting the actual
recorded ego footprint in that scene**. It is not written to distant regions,
obstructions or the full map. Region records are copied per frame, preventing a
value from leaking into subsequent scenes. The measurement is explicitly
subject-relative and time-varying, not an immutable road property. During a turn,
several intersected lane/roadway regions can receive the same scalar.

`adapter_report.json` documents the method and counts frames with/without a
scalar and reasons for missing values. Each supplementary record adds
`visibility_mapping` with `value_m`, `attached_regions` and `reason`, while
retaining the complete original evidence and telemetry records.

The manifest declares `st.sight_distance` as an estimate only when at least one
exported frame contains a value; otherwise it is `absent`. Coverage counts and
missing reasons distinguish partial coverage from complete measurement. `rel.visible` remains
absent: these virtual observers are not recorded vehicle tracks. Decoder
acceptance does not demonstrate that an independently produced law selects the
correct region or evaluates the correct manoeuvre interval.

## Historical recordings before capture repair

The five C353238 captures were recorded with centre-only horizons. They have
any-body visibility at 500 ft but **no any-body horizon**. The adapter deliberately
leaves their scalar absent and reports `any-body horizons not captured`. It does
not relabel their centre distances or interpolate an any-body horizon from one
probe. Existing artifacts are not overwritten by a source-code update.

To populate a minimum distance scalar, repeat scene-graph capture from the saved
CARLA recordings using the updated capture function, then run `adapt-trace` into
a new output directory and validate it. A live simulator is needed for the ray
measurements, but the original driving execution need not be rerun. Preserve
old captures and failed attempts as evidence.

## Limits of the measurement

- Any of nine points is the declared sampling criterion, not a claim of human
  recognizability or continuous whole-body visibility.
- The coarse scan may miss narrow occlusions or nonmonotone visibility between
  samples. Refinement does not eliminate this limitation.
- Every driving lane of the current road is considered; ambiguous junction
  branches are unknown, not silently selected. Other roads feeding a junction
  require a separately established approach inventory.
- Virtual eye height, collision meshes and endpoint filtering affect results.
- A lower-bound scalar supports the documented 500 ft comparison, not arbitrary
  exact-distance queries, equality tests or thresholds beyond the search limit.
- The manoeuvre interval and legal evaluation remain downstream responsibilities.

## Validation

`tests/test_visibility.py` tests any-body rather than centre-only visibility,
clear/blocked brackets, censoring, missing routes and lanes, inconsistent probes,
threshold uncertainty, invalid numbers and per-frame attachment without mutation
of static map regions. Existing adapter tests also remain applicable.

Use the full Core decoder on generated JSON. A representative measured-v2 fixture
can validate format and structure IDs; it is a software test, not a replacement
for recording actual simulator rays. No legal verdict is produced here.

## Separate barrier-footprint issue

A footprint proven disjoint from the ego footprint cannot be colliding with it at
that instant. Full geometry for every distant object is unnecessary solely for
collision testing. Graph absence, however, is not a spatial exclusion certificate:
actors may be cropped or filtered, and the ROI is a forward rectangle rather
than a 50 m circle.

M024's recorded barrier origin comes within about 47.40 m of the ego origin;
that is not a footprint gap. Its missing boundary is a capture/coverage issue.
The current adapter's global occupancy-unknown response to that boundary is too
coarse. This visibility implementation does not change occupancy semantics or
claim to fix that separate issue. Preserve geometry only where law-relevant
occupancy, hazard distance or visibility requires it, or retain a justified
spatial-exclusion record.

## Road extent during construction

Before recording a case that requires visibility throughout its route, check that
each required incoming lane supports the observer search at every planned subject
station. The default horizon search is 230 m and the statutory probe is 152.4 m;
route endpoints are not occluders. Extend authored road geometry before driving
when full coverage is intended. Do not change a saved execution's map during
replay and present the measurements as belonging to the original world. A clear
500-ft probe does not supply an uncensored horizon beyond the map endpoint.

Required visibility must be available throughout a delivered example, not merely
in a subset of frames. If the map is too short, extend its approaches and create a
new recorded construction; retain the old recording as history. Publication of the
replacement requires full per-frame required-measurement coverage. The horizon
scan includes the explicit probe distance so its refined bracket cannot ambiguously
cross that distance without a direct ray measurement there.
