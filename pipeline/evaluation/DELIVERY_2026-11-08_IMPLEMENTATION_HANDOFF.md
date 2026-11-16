# Implementation handoff: delivery audit items 1.1–1.8 and linked items 2.1, 2.5 / 3.3, 2.6, 2.7 and 3.2

## Scope, decisions and execution status

This specifies the agreed fixes discussed in [review notes](DELIVERY_2026-11-08_REVIEW_NOTES.md), against [the delivery audit](DELIVERY_2026-11-08_AUDIT.md) and [the original refactor response](DATA_ISSUES_FOR_MAURICIO_2026-11-05_concise_response.md). Items 2.2–2.4 repeat earlier fixes; items 2.5 / 3.3, 2.6, 2.7, 3.2 and classification complaint 3.1 are included. Items 3.5–3.6 are also included; item 3.4 is deferred with existing assumptions unchanged. Items 4.3–4.5 are also included; 4.7 is reviewed with no changes planned. Item 5.1 is investigated/planned below; 5.2–5.7 are planned; 5.8 is intentional with no changes planned; 5.9 is planned. Other remaining requests are pending review.

**This handoff primarily specifies future implementation; section 4.4 records the limited shared mapping code fix already completed. Historical publication remains pending. The simulation goal remains paused. Do not allocate a GPU, run CARLA, retry scenarios, install rewritten accepted recordings, or change labels/selections merely because this document exists.** An implementation task can use this specification to produce reusable code changes, tests, staged exports and a validation report. Publication or a rerun is a separate execution step.

Default data scope for offline staging is the 189 recordings identified by delivery `demo-train-20261108T223214Z`. First resolve that delivery’s authoritative index; freeze its recording list, hashes and source paths. If that index is unavailable or does not resolve uniquely, report the block rather than substituting the current demo-test set or claiming the historical counts were verified. Reusable code must support every export path; fixtures may cover other paths without changing their accepted recordings.

Do not change original captures, actor identities, timestamps, scenario construction/controllers, accepted membership, ontology taxonomy, or unrelated atoms to make validation pass. Preserve labels and judgment flags except for the explicitly source-backed, separately logged historical classification corrections specified in section 1.8 / 2.1; never modify them merely to pass validation. Preserve originals and previous receipts. Use existing evidence-reader/hash verification; do not unpickle captured Native graphs or execute saved scenario code to establish facts. Inspect JSON/text sources and verified identities. Missing evidence is a reported unknown, not permission to invent it.

| Decision | Required behavior | Not part of this fix |
|---|---|---|
| Partial occupancy | Read source-supported listed pairs as true; use completeness only to infer false for unlisted pairs. | No complete-list claim from a partial list; no explicit negative-pair schema yet. |
| Acceleration | Use original-frame simulator telemetry consistently; export every source-supported value, independent of the labelled law. | No zero defaults, controller-derived acceleration, or newly invented finite-difference estimator. Retain previously validated estimates only with their method/source proof. |
| Road-user classes | One evidence-based classifier for all paths; resolve every evidence-supported Yes/No answer. | No new class IDs, role inference from names, or blanket removal of genuine unknowns. |
| Field coverage | Check applicability before missingness; distinguish unavailable evidence from export omissions. | No demand for car lamps/controls on pedestrians; no fake geometry or value-free “estimate” labels. |
| Structure kinds | Normalize verified kinds and ancestors; remove stale contradicted masks; clear absence uncertainty only with kind-specific completeness proof. | No global mask deletion or new certainty based only on an empty map list. |
| Steering angle | Mean same-frame measured front-left/front-right angles; single front-wheel measurement for two-wheel vehicles. Preserve both raw measurements and version the method. | No front-left-only value relabelled as a mean, no command substitution, missing-wheel fallback or silent capture failure. |

## Global implementation constraint: lean code and external migrations

**This section governs every work item and all implementation phases in this handoff.** Item-specific cleanup notes supplement it; they do not limit it to reporting, labels or geometry.

- Keep reusable production behavior, essential correctness/source checks and compact meaningful regression tests in maintained source. Consolidate fresh/saved/export paths through shared helpers and existing facilities; do not add parallel implementations or a subsystem per acceptance check.
- Keep all one-time historical migration, remapping, repair and repair-only investigation scripts outside the repository, together with repair inventories, backups and migration receipts in an external operation/archive directory. Do not commit maintenance-only modules or leave temporary scripts/tests in maintained source. Normal generated artifacts and reusable source/method provenance follow existing output contracts.
- Remove all obsolete implementations once active callers and supported consumers have migrated: superseded generators/classifiers, unused helpers and tests, dead imports/CLI hooks, abandoned schemas, old report readers, redundant validation layers and stale documentation references. Search actual callers, entry points, packaging and tests before deletion. Do not delete original evidence or historical audit records as if they were dead code; archive superseded artifacts with verified hashes.
- Retain compatibility code only for a specifically identified, still-supported input or consumer, using the smallest shared adapter possible and documenting why it remains necessary. Archive-only reproduction is not grounds to retain dead production paths. Remove compatibility branches once that requirement ends.
- Run historical comparisons, migration audits and representative performance benchmarks once at the relevant acceptance phase rather than imposing them on every future export. Essential validity checks and provenance remain; simplification must not replace missing measurements with invented values or remove necessary correctness gates.
- Completion requires a repository-wide caller/reference check within the affected implementation scope, appropriate existing tests, and a concise cleanup inventory listing reusable code retained, obsolete code/references removed, necessary compatibility retained with reasons, and external locations of one-time tooling/artifacts. No speculative framework, duplicated pipeline or one-off repair code may remain as an unexplained residual.

Apply this rule to occupancy/Core changes, telemetry, road-user classification, applicability, inventory/masks, steering, shared reports, labels and geometry, and to any later issue added to this handoff.

## Global GPU execution constraint — one integrated recapture per recording

This rule has precedence over all item-specific simulation/remeasurement instructions in this handoff, including velocity 2.6, sight, steering, operability 4.3, way membership 5.1 and future additions. **Do not rerun a recording separately for different audit items.**

1. Finish a joint offline evidence/compatibility inventory across all planned items before scheduling a recording. Distinguish obtainable simulator observations from authored context/road-grouping decisions and producer bugs. Recover supported existing evidence offline first. Settle blockers that would predictably require another execution; an unresolved required acquisition plan blocks batch start for that recording, not permission to run now and rerun later.
2. Produce one consolidated recapture roster with one acquisition profile/checklist per recording, covering the union of every required supported applicable measurement and source binding. Include required actor/frame coverage, raw velocity/acceleration, wheel readbacks, lights/device operability evidence, sight-distance approaches/rays/bounds, map/device/region identity/topology and any other approved acquisition. Use existing profile/required-observation infrastructure; keep one-time roster/repair orchestration outside the repo. Law-specific dependencies must not switch off common acquisition.
3. Upgrade and preflight the shared capture/export path for the whole profile before the batch. Verify sensors, coordinate/sign conventions, source IDs, frame/time joins, retained artifacts, method metadata and all expected downstream fields together. If sight or another probe needs additional queries/frozen-state sampling, integrate it into the same recording session and validate state/timing consistency. Do not assume all modalities are compatible or launch a second independent scenario execution to supply missing parts. Required incompatible capture modes must be resolved before the batch.
4. Execute each selected accepted incompatible scenario **once** with all profile acquisitions active together. Reuse its approved scenario/map/controller/configuration/seeds; no tuning or automatic retries. Use allocated CPUs/GPU under project m5029_g, relinquishing/renewing allocations between work as necessary. An allocation renewal does not authorize restarting a scenario already attempted. Distinct methods/readouts from that same execution retain shared recording/frame provenance; a separate replay or later execution is not silently joined as same-run evidence.
5. Apply one recording-level completeness gate covering the full profile, then normal source/physical/media/decode/label validation. Track each required acquisition's result in existing reporting. A failed/partial attempt remains incomplete and blocked for final publication; do not schedule another run under a different audit item or silently reduce the profile. Further retry requires a separate user decision. New runs do not inherit original acceptance/labels automatically.
6. Publish one final validated recording and current outputs per roster entry after external archival/hash verification of superseded evidence. Keep normal source provenance, remove obsolete implementations and parallel legacy outputs, and retain only reusable shared instrumentation/tests in source. Do not create per-issue acquisition pipelines, duplicate captures or permanent migration/orchestration modules.

Future simulations must use the finalized common profile from the outset so required observations are collected together in their initial execution. This coordination requirement does not itself resume the paused unrelated demo-test campaign or authorize unsupported measurements. Existing conditional recapture authorization applies only after the complete integrated profile is ready.

## Code map and implementation order

Paths below are starting points, not permission to edit frozen run snapshots. Resolve the active Core library through the pipeline configuration/`full_core()` and record its hash. Update maintained source variants through the repository’s existing split/build workflow; never patch `.lake` binaries or archived copies. Generated ontology files must come from their generator.

| Work | Existing entry points |
|---|---|
| Original-frame capture | [`scripts/original_observations.py`](../../../../scripts/original_observations.py): `actor_state`, device/light observations; [`scripts/pipeline_capture.py`](../../../../scripts/pipeline_capture.py): common capture integration |
| Fresh export and saved reconstruction | [`adapter.py`](../../../../scenario_pipeline/traffic_spec_adapter/adapter.py): `convert`, `reconstruct`, `repair_scene`, `live_kinematics`, `classes`, `signals`, `manifest`, `attach_original_participants` |
| Road-user normalization | [`classifications.py`](../../../../scenario_pipeline/traffic_spec_adapter/classifications.py): `project_user`, `known_classes` |
| Inventory evidence/masks | [`inventory_observations.py`](../../../../scenario_pipeline/traffic_spec_adapter/inventory_observations.py): `retained_static_inventory`, `project_static_inventory`, `STATIC_KINDS`; `adapter.py`: `preserve_inventory_unknown` |
| Geometry/transformation | [`geometry.py`](../../../../scenario_pipeline/traffic_spec_adapter/geometry.py): `retained_map`, `native_centre_lines`, `painted_map_objects`, `project_lane_segments`; reconstruction’s region additions/merges |
| Adapter coverage | [`atom_contract.py`](../../../../scenario_pipeline/traffic_spec_adapter/atom_contract.py): `observed`, `required_coverage`, source/method descriptions |
| Core behavior | [`Atoms.lean`](../traffic-spec-agent/library/TrafficSpec/Core/Vocab/Atoms.lean): `rel_occupies`, `rel_occupies_regions`, `Structure.isOfKind`, `Structure.maskApplies`; [`World.lean`](../traffic-spec-agent/library/TrafficSpec/Core/Vocab/World.lean): scene/class/kind contracts; [`Decode.lean`](../traffic-spec-agent/library/TrafficSpec/Core/Runtime/Decode.lean): field decoding |
| Consumer diagnostics/tests | [`recorded/source_check.py`](../traffic-spec-agent/recorded/source_check.py); [`Core atom tests`](../traffic-spec-agent/library/TrafficSpec/Tests/Atoms.lean), [`decode tests`](../traffic-spec-agent/library/TrafficSpec/Tests/Decode.lean), [`refinement tests`](../traffic-spec-agent/library/TrafficSpec/Tests/Refinement.lean) |

Order: (1) pin baseline and evidence, (2) implement/test Core occupancy behavior and migration gate, (3) common actor/field/kind normalization, (4) fixture tests for both fresh and saved export paths, (5) stage the selected recordings, (6) decode/query/source validation and regenerated reports. Do not run a legal monitor or resimulate as a substitute for these checks.

## Evidence rules shared by all fixes

Only source-supported facts can become known. “Verified” below has the following operational meaning.

| Evidence | Accept when | Reject / leave unknown when |
|---|---|---|
| Actor identity and attributes | Original-frame observation binds actor ID, blueprint/type and attributes to the recording. Alternatively, an actual saved spawn/recorder identity binds the actor to the executed construction and its observed frame interval. Hashes and frame/time joins match. | Only a planned spawn, case name, verdict, role-name string, nearest actor or unbound blueprint is available. Contradictory bindings are an error, not a reason to select the preferred source. |
| Motion/light readbacks | Same actor and original frame/time, finite values, declared units/frame, source hash verified; original live acquisition or already validated source-bound method. | Replay artifacts, requested commands substituted for physical results, carried-forward missing states, invalid numbers or mismatched actor/frame. |
| Positive structure kind | Verified native identity/type and source-backed mapping establish that specific structure kind. Kind evidence does not require a representable painted-area boundary. | Only its current trace label, proximity/containment, a scenario name, or a desired legal result supports it. Preserve uncertainty and report the missing proof. |
| Complete kind inventory | Existing verified receipt binds the actual map/recording, evidence hashes, scope, period, kind, count and inventory method. All instances within that scope are classified; projected positive count agrees. | Empty OpenDRIVE lists, requested configuration, cropped/local queries, unexplained objects, mismatched maps/counts or missing physical inventory evidence. |

Write per-entity decisions in `adapter_report.json` under a versioned `evidence_decisions` section, not as unrecognized fields in the Core trace. Minimum records: recording ID; source-path/SHA256 map; native frame interval; entity family/ID; atom/attribute; status (`known_true`, `known_false`, `known_value`, `unknown`, `not_applicable`); value when known; method; source references; and reason for unknown/not-applicable or a correction. `not_applicable` requires established entity-kind evidence. Compress identical decisions across a frame interval only when their supporting evidence applies throughout it. No source reference may point solely to the rewritten trace as proof of itself.

Known absence, empty lists and zero values require their own evidence; they are not missing-data defaults. Source checks must verify receipt hashes, joins and scopes, not just the presence of a receipt file. Keep unresolved facts in the report rather than creating new ontology IDs or placeholder objects.

## 1.1 — partial occupancy: exact semantics and migration

Keep the existing JSON fields. `occupies` contains only supported positive `(track, region)` pairs. `occupancy_observed` still identifies vehicles whose occupancy list is complete in that scene. Boolean all/none decoding remains as currently supported.

For a valid actor/region query, change `rel_occupies` to:

1. Pair is listed in `occupies` → `some true`.
2. Pair is unlisted and actor is in `occupancyObserved` → `some false`.
3. Otherwise → `none` (unknown).

Keep `rel_occupies_regions` a **complete-list-only** accessor: return its list only when the actor is in `occupancyObserved`; otherwise return `none`. Do not return a partial list as a complete one. Existing consumers such as lane-based relations may therefore remain unknown; this fix does not promise to decide every rule. Do not add a partial-list or explicit-negative-pair API in this minimum change.

**Migration gate:** old traces could contain unvalidated pairs that Core previously ignored. Before evaluating them with the changed Core, verify each retained positive against recorded body/region evidence. Remove unsupported pairs from the staged export, preserve them in original evidence, and leave their answers unknown unless a complete-list proof exists. Do not change Core and silently reinterpret every historical listed pair as certified true. Pin the new Core/adapter hashes and `partial-positive-v1` semantics in the export report; old delivery receipts remain associated with their original decoder.

Exporter completeness requires enough evidence to resolve each represented region’s occupancy for that actor. A retained measured surface union can suffice even without one exported polygon. If any region remains unresolved, do not declare the actor’s list complete. Do not infer occupied/not-occupied from region kind or lane names alone. Use source-bound original body vertices when available: form their ground-plane convex hull using the existing Native-to-Core coordinate conversion and test region overlap with the existing boundary-touch convention. A retained original bounding-box reconstruction may remain a disclosed estimate when its source binding and convention are verified; never silently upgrade it to exact. Ambiguous surface identity or grade-separated geometry remains unresolved. Do not switch geometry methods without recording the method and validating affected pairs.

Illustrative JSON fragments (tests must wrap these in valid scenes with users 1/2, lane 10 and stop line 20):

```json
{"occupancy_observed": [], "occupies": [[1, 10]]}
```

After the change, `(1,10)` is true, `(1,20)` is unknown, and the complete-region-list query for 1 is unknown. With `occupancy_observed: [1]`, `(1,20)` becomes false and the complete list is `[10]`—but the exporter must reject that completeness declaration if source evidence leaves region 20 unresolved.

| Test | Input / evidence | Required result |
|---|---|---|
| O1 | Supported pair `[1,10]`; actor 1 incomplete | Pair 10 true; pair 20 unknown; complete-list query unknown. |
| O2 | Same pair; complete occupancy proof for actor 1 | Pair 10 true; pair 20 false; complete list `[10]`. |
| O3 | No pairs, no completeness | All occupancy queries unknown; not false. |
| O4 | Actor 1 partial with pair 10; actor 2 complete with no pairs | Actor 1 as O1; actor 2 false for both regions and complete list `[]`. |
| O5 | Old unsupported pair, no complete proof | Drop only that staged pair with a reason; its query remains unknown. Original capture unchanged. |
| O6 | Missing stop-line extent, no alternative evidence | Reject a claimed complete list; retain supported lane overlap as true. |
| O7 | Unknown actor/region IDs in trace references | Decoder/reference validation rejects the malformed trace; do not invent referents. |
| O8 | Reconstruction/subdivision changes region identities | Recompute/remap only source-supported pairs; completeness does not survive unresolved added geometry. |

Coverage must report known-positive pair count, complete-actor count and incomplete-actor count separately. Do not change the existing full-completeness check into “one pair exists.” Source diagnostics must distinguish useful partial occupancy from complete occupancy and track this intentional semantic change.

## 1.2 — one acceleration contract across export paths

Raw source contract: original frame/time, actor ID, full world velocity, full world acceleration, body transform/forward vector, and units. Capture for every supported live vehicle/walker regardless of the labelled law. Keep full measured components and provenance. Section 2.6 defines the final dimensional contract: horizontal exported speed/velocity plus a measured vertical-velocity component accessible in Lean; the acceleration fix must use that shared capture/export path.

For direct telemetry use `accel_longitudinal = dot(acceleration_world, forward_unit)` in m/s², positive along the body’s forward direction. Require finite values and a nonzero forward vector with unit-norm error at most `1e-6`; normalize within that tolerance before projection. A zero vector or larger unit-norm error is invalid for this direct-telemetry method. This is a numerical measurement convention, not a legal threshold. Sign is relative to body heading, not direction of movement or throttle. Preserve the measurement method and coordinate convention.

Implementation requirements:

- Route fresh conversion and saved reconstruction through the same extraction/normalization logic. Fix omissions where matching original acceleration/forward evidence exists.
- Existing validated scalar longitudinal telemetry can be used with its bound method. If vector and scalar sources coexist, compare within `1e-6` m/s² for unrounded original telemetry; contradictions are errors, not silently overwritten values. If a retained source is rounded more coarsely, its documented quantization bound must be recorded and used explicitly; without that bound, report the comparison unresolved rather than inventing a tolerance.
- Missing original acceleration remains unknown unless a previously validated, source-bound estimator exists. Developing a new velocity-difference estimator is deferred; do not improvise one in this repair. Missing telemetry becomes a recapture candidate, not a zero.
- A shared future capture path can share one capability manifest. Legacy acquisition paths with genuinely different capabilities must use path-specific capability signatures/manifests, not one optimistic union. Identical capability signatures may share a manifest; per-frame unknowns remain separately reported. Estimates have explicit methods; manifest relabeling alone is not a repair.

| Test | Source input | Expected |
|---|---|---|
| A1 | Acceleration `[2,3,4]`, forward `[1,0,0]` | Longitudinal `2` m/s². |
| A2 | Velocity `[-5,0,0]`, acceleration `[1,0,0]`, forward `[1,0,0]` | Longitudinal `+1`, not a value inferred from reversing or scalar-speed change. |
| A3 | Acceleration `[1,2,3]`, unit forward `[0.6,0,0.8]` | `3` m/s² within declared floating precision. |
| A4 | Missing acceleration, valid velocity, no approved estimator | Field unknown and missing-source reason; never zero. |
| A5 | Recorded acceleration is zero | Export zero, not unknown. |
| A6 | Replay-only zeros or actor/frame mismatch | Do not treat as original live telemetry; bad joins fail validation. |
| A7 | Same evidence through fresh and saved exporters | Identical value, units, scope and method; law/cell labels do not change output. |

## 1.3 / 3.1 — road-user classes: per-class Yes/No/Unknown

Use only current ontology class IDs. A precise CARLA model remains source evidence; do not add `ru.passenger_car`, `ru.animal` or other unapproved IDs. Use verified blueprint/model/attribute mappings, not substring heuristics or the blanket rule “every `vehicle.*` is `motor_vehicle`.” In particular, obey the ontology’s separate treatment of bicycles/motorcycles/mopeds and its legal aggregate definitions.

Implement one shared classifier called from fresh conversion, participant attachment and saved reprojection. For each class, resolve a positive/negative only where the identity/attributes or another validated source establishes it. Preserve compatible existing facts; conflicting evidence fails validation. A generic passenger-car blueprint does not establish taxi service, commercial licensing or official status. Specialized physical markings/equipment and service/legal facts need the evidence demanded by that class’s contract; a role-name or intended configuration alone is insufficient.

Encoding: known positives go in a non-null `classes` list and not in `unobserved_classes`; known negatives go in neither list; unresolved classes go in `unobserved_classes`. A null `classes` list does not establish negative answers. Preserve legal category overlaps, e.g. verified bus plus motor vehicle; do not make every class mutually exclusive. Unknown pedestrian age stays unknown, but known-false pedestrian membership establishes known-false child membership.

| Test | Evidence / before | Required staged/Core result |
|---|---|---|
| C1 | Actor 24 bound to a verified Tesla passenger-car model/base type; old masks include pedestrian, child, bicycle, motorcycle, bus and truck | `motor_vehicle` true; those six excluded classes false; unresolved specialized roles remain unknown. No null class list. |
| C2 | Same C1 evidence via two scenario families/export paths | Identical class answers and exclusion policy, irrespective of law/cell/case name. |
| C3 | Verified walker, age unobserved | Pedestrian true; child unknown. Verified supported child/adult evidence changes only the justified classification. |
| C4 | Sedan without taxi evidence versus a verified taxi meeting the class contract | First retains taxicab unknown; second emits motor vehicle and taxicab true. Do not infer false just because no taxi claim was recorded. |
| C5 | Known class appears in both positive and unknown lists | Detect conflict; reconcile only with source evidence and record the correction. No silent masking of a verified positive. |
| C6 | Actor identity missing or mismatched | Keep unresolved answers/report or reject a contradictory binding. Do not map a nearby actor or planned spawn by guess. |
| C7 | Verified bicycle/motorcycle source | Follow the ontology’s classifications/exclusions; do not inherit motor_vehicle solely from CARLA’s `vehicle.*` prefix. |

Target: zero **evidence-resolvable** unknowns, not zero unknowns of every kind. Class semantics already support this; do not change `hasClass` to make unknown default to false.

## 1.4 — field applicability and coverage

Use this matrix both for exporter behavior and coverage diagnostics. The contract remains the ontology plus the source’s actual acquisition scope. `subject` capability limits the required subjects accordingly; do not claim all-actor support while only reading the ego. An unknown entity kind is a classification gap, not permission to invent applicability or value. Not-applicable statuses belong in reports, not arbitrary new Core fields.

| Fields | Applicable entities | Record/export | Must not demand or fabricate |
|---|---|---|---|
| Actor identity, `ru.*` | All road users | Supported positive/negative classifications and genuine unknowns, per section 1.3 | Specialized roles/licensing without evidence |
| `kin.time`, position, heading, extent, velocity, speed, longitudinal acceleration; supported yaw rate/path length | All source-supported road users, including pedestrians | Scene time plus joined motion/body records; validated derived methods disclosed | Vehicle controls are not motion; missing measurements are not zero |
| `kin.throttle`, service/parking brake, steer angle; conditionally gear/engine_running | Applicable instrumented vehicles | Actual readbacks with their supported scope; representative wheel angle per section 1.6, not steering command | No car-control requirement for pedestrians; no engine/gear inference from movement or reverse flag |
| `sig.turn_indicator`, hazard, brake/position/reverse lamp, headlamp | Vehicles with applicable equipment and validated acquisition, including supported cycles/motorcycles | Original-frame lamp states, including measured off/false | No car lamps/headlamps on ordinary pedestrians; not every bicycle has every lamp; no light inference from brakes/turns |
| Hand signals, horn/siren, special lamps, doors | Only the actor/equipment/source covered by each atom’s contract | Validated gesture/audio/equipment observations | Unsupported acquisition is not no_signal/false; do not demand every `sig.*` on every actor |
| Lane width, local designated direction, adjacency/ordinal/count, per-side markings, connectivity | Lanes/subtypes and other direction-bearing carriers as specified by ontology | Supported local map attributes, curve pieces and explicit topology | No designated direction on a centre turn lane; no terminal `[]` without proof; unknown marking is not known “none” |
| Roadway curvature/grade and separately measured sight | Roadway/subtypes and sight-specific scopes | Supported measured attributes and declared estimation conventions | Not generic attributes for stop lines/sidewalks; geometry alone does not prove sight |
| Region position/boundary | Represented regions where that component is observed/representable | Source-grounded positions and valid area boundaries; richer geometry retained in evidence | No invented paint width or arbitrary hulls; centre-line estimated strips follow section 2.5 / 3.3 and verified painted-stop-line fallback follows 5.3. Missing boundary does not mean unknown kind |
| Device position/governance and kind attributes | Actual installed devices of the relevant kind | Signal indications; speed-sign rate/kind; regulatory-sign code/conditions; supported associations | No regulatory conditions on every stop/speed sign; no carried-forward missing indication; absent governance is not `[]`; dark alone is not proof of inoperability |
| `env.*` | Scene | Supported weather/calendar/context measurements or declared estimates | No repeated per-user environment; no invented date, ice or fog-distance value |

Special handling:

- If measured lamp flags are present and off, emit off/false. If source flags are missing for an applicable vehicle, report unknown. If the actor is a verified pedestrian, car-lamp fields are not required. Do not force the same rule onto unsupported special signals such as hand gestures.
- A known unmarked lane side uses the ontology’s explicit no-marking convention only when source completeness supports it; missing data remains unknown. A known terminal lane may have `leads_to: []`; unknown topology may not.
- Region geometry can have a known position and unknown area boundary. Preserve that distinction. Do not alter line/paint conventions pending the separate geometry review.
- `estimate` requires a real exported estimate, method and limitations. It is not a label to hide an empty field. A genuinely unknown value remains reported unknown, even when the source can measure that atom in other frames.

| Test | Input | Expected |
|---|---|---|
| F1 | Verified pedestrian, valid motion, no vehicle lamps | No missing car-lamp/headlamp/control finding; retain motion and class checks. |
| F2 | Applicable vehicle, observed lamp flags all off | Export six supported lamp/indicator values as off/false, not omit the block. |
| F3 | Applicable vehicle with missing original lamp readback | Unknown with source reason; do not fill off or copy another frame. |
| F4 | `classes: null` despite C1 identity evidence | Classification gap must be repaired under section 1.3, not excused as non-applicable. |
| F5 | Stop-line reference coordinates/extent, width unmeasured | Apply 5.3: verified paint/reference supports an estimated 0.35 m strip; otherwise retain the gap/block. Never infer paint or fabricate an alternative stopping reference. |
| F6 | Verified lane width or known unmarked side | Export supported width/no-marking; another family receives the same treatment. |
| F7 | Missing colour on an observed mark, or uncertain connectivity | Preserve the affected unknown, not a guessed colour or `[]`. |
| F8 | Subject-only control acquisition | Require those fields on the subject only; manifest does not claim all-actor control coverage. |

The 1.4 audit example `ae1b4c888fbd…` currently has pedestrians 35–42 without `sig` blocks and motor vehicles with the six exported lamp fields. This does not by itself demonstrate a missing vehicle-light value. Historical delivery bytes and applicability must be checked before accepting/rejecting aggregate audit counts.

## 1.5 — structure masks: deterministic correction and proof limits

Do not change Core’s kind hierarchy or make all labels automatically trustworthy. Normalize against `StructureKind.refines` from the pinned Core, not a separate hard-coded inheritance table.

For an evidence-verified positive kind K, remove only masks M that contradict that known fact: M is K or an ancestor of K and would make the verified K/ancestor query unknown. Preserve unrelated unresolved masks and all supported subtype distinctions. A plain roadway does not establish one-way status. Apply normalization after every transformation that can add/copy masks, and run it again at final export.

Before/after fragment (assume original evidence verifies region 4’s kind):

```json
{"id":4,"kind":"one_way_roadway","unobserved_kinds":["roadway","crosswalk"]}
```

```json
{"id":4,"kind":"one_way_roadway","unobserved_kinds":["crosswalk"]}
```

Roadway and one-way queries must be true. Do not globally delete `crosswalk` here: its actual effect follows Core’s hierarchy and its separate evidence. An absent boundary stays absent. If the positive kind is unverified, leave the uncertainty and report it; correcting an unsupported label requires evidence, not merely preference for the positive label. Validation rejects an exported conflict **between verified evidence and its query result**, not every deliberate uncertainty mask on an unverified label.

### Kind-specific inventory gates

The existing `STATIC_KINDS` list excludes roadway, centre_line and obstruction. Merely adding strings to it is not a fix. Implement the following checks before any new absence clearance:

| Kind | Evidence permitting correction | Mandatory blocked/unknown cases |
|---|---|---|
| Roadway | Native map/surface identity and source classification bind the specific projected region; verified one-way designation establishes its roadway ancestor. A complete roadway inventory additionally enumerates all source roadway surfaces in its stated scope. | Ambiguous native identity, map mismatch, or unknown surface classification. Missing boundary alone does not invalidate an independently verified kind. |
| Centre line | Complete lane topology/directions, lane offsets and source geometry establish the divider between opposing traffic; retain measured paint separately. A complete scope with no opposing directions and no qualifying divider may establish zero count. | Missing/cropped lane inventory, ambiguous directions, or “there is no painted line” alone. A two-way road with no paint still has a geometric divider; never clear its centre-line uncertainty just because paint is absent. |
| Obstruction | An original complete physical-object inventory or an audited closed-world construction/realization receipt covers the actual loaded map, relevant static environment objects and spawned/despawned non-road-user objects for the stated period. It classifies every relevant object, has no unresolved object types, binds actual execution/source hashes, and agrees with emitted obstruction instances. | Only an empty actor/OpenDRIVE list, requested config, map label, local crop, or incomplete physical-object inventory. Do not claim completeness for environment meshes absent from actor lists or for dynamic objects from a static snapshot. |

Reuse/extend `retained-static-inventory-v1` verification rather than inventing assertions in the Core trace. Verify existing source hashes, actual map identity, scope, period, complete-instance classification and projected counts. For a static receipt, require constancy throughout its declared period; otherwise use supported per-frame evidence. A zero-count receipt permits clearing only that kind within that verified scope, and creates no placeholder region.

**Default for this legacy batch:** if the required centre-line/obstruction proof is not present and cannot be established from retained sources under these gates, keep its uncertainty and report `blocked_missing_inventory_evidence`. Do not manufacture retrospective runtime observations or resimulate to finish an offline task. Implement and test the supported receipt paths, but do not claim the real dataset’s absence cases were fixed without qualifying evidence. This explicit fallback resolves the open evidence question without asking the implementing agent to guess.

| Test | Before / evidence | Expected queries or action |
|---|---|---|
| K1 | Verified one_way_roadway; stale roadway mask | Remove contradicted mask; one-way true, roadway true. |
| K2 | Verified roadway with one_way_roadway unknown | Roadway true; one-way unknown; do not infer the subtype. |
| K3 | Verified roadway, boundary absent | Roadway true; boundary accessor unknown. |
| K4 | Complete zero-obstruction receipt, correct map/scope/period | Remove obstruction masks within scope; emit no obstruction placeholder; no-obstruction query becomes decidable. |
| K5 | No obstruction records but inventory incomplete | Preserve obstruction uncertainty and report the missing evidence. |
| K6 | Two opposing directions, no painted divider | No zero-centre-line claim; preserve/recover source-supported geometric-divider facts without inventing paint width. |
| K7 | Local crop, count/hash mismatch, or unresolved object type | Receipt rejected; no mask clearance from it. |
| K8 | Merge/subdivision/reconstruction after K1/K4 | Positive kinds remain queryable, legitimate unknowns remain unknown, instance counts and scope are preserved. |
| K9 | Kind label unverified and deliberately masked | Preserve/report uncertainty; do not assume the label is a verified fact. |

## 1.6 — symmetric representative steering angle

**Decision:** define `kin.steer_angle` as the arithmetic mean of the measured front-left and front-right wheel angles for a validated two-front-wheel layout. For two-wheel vehicles, use their single measured front wheel. Units are degrees; keep the current Native-to-Core conversion, `Core angle = -Native API angle`, so the Core sign is positive left and negative right. Do not change the sign based on which way the vehicle happens to turn.

The old collector explicitly selects `FL_Wheel`, or `Front_Wheel` for two-wheel actors. The ontology currently says only “front-wheel steering angle”; the wheel choice is an implementation convention, not a requirement to preserve front-left forever. During implementation, document the newly agreed representative-angle convention in the atom/source-method descriptions and maintained Core/split documentation. Keep the same atom ID and numeric Core field. This document update itself does not change those implementations or the ontology.

A left turn puts front-left on the tighter inside circle; a right turn puts it on the wider outside circle. A fixed front-left measurement therefore gives unequal magnitudes for mirrored turns. Averaging removes that wheel-selection bias. It remains a declared arithmetic summary, not an asserted equivalent bicycle-model steering angle.

### Capture and export contract

1. **Validate the reference layout.** Use the API identifiers `FL_Wheel` and `FR_Wheel` for a verified front-wheel pair; use `Front_Wheel` for the validated single-front-wheel/two-wheel layout. Retain the blueprint, layout and actual API wheel identifiers. Do not guess a layout for an unsupported three-/multi-wheel vehicle: report unsupported layout and block a complete-steering claim for that actor.
2. **Acquire actual angles at the same recorded tick.** Query all required wheels on every applicable instrumented vehicle, not just when turning or when a law needs steering. Bind samples to actor ID, frame/time and the original source. An unchanged wheel angle of zero is valid data. A normalized `control.steer` value is never a wheel angle.
3. **Retain raw evidence and a versioned method.** Use a source record such as the fragment below. For a pair, require finite `front_left` and `front_right`; for a single wheel, require finite `front`. Method IDs are `front_wheel_mean_v1` and `single_front_v1`, respectively. These source fields belong in the observation/evidence stream, not as new arbitrary Core keys. The single Core output remains `kin.steer_angle`.
4. **Compute consistently.** Pair: `kin.steer_angle = -(front_left + front_right) / 2`. Single wheel: `kin.steer_angle = -front`. Use the same helper in fresh conversion, participant attachment, saved reconstruction and re-export. Do not average magnitudes, flip one side’s sign, take whichever wheel succeeded, or substitute the old unqualified scalar. Validate actor/frame joins before combining samples.
5. **Export all supported vehicle samples.** For the planned common all-vehicle capture path, the capability must no longer be `subject` once all-vehicle acquisition is validated. Declare the representative method, for example `estimate:arithmetic_mean_of_native_front_wheel_readbacks`, and keep the single-front-wheel special case in method metadata. This labels the operational representative convention, not a claim about driver intent or path curvature. Historical subject-only paths retain their actual scope and method.
6. **Make failures explicit.** Replace silent wheel-angle omission/error swallowing with per-wheel capture status containing actor ID, frame, wheel ID and failure reason (method absent, unsupported layout/identifier, query error, non-finite result or missing sample). Preserve successful raw measurements and other telemetry. No zero defaults, carried-forward values or fallback to one wheel. An unsupported pedestrian/walker is `not_applicable`, not a vehicle measurement failure.
7. **Check complete-steering claims.** Pin the required vehicle/model set before the batch. A recording may be accepted as complete for this new steering profile only when every required vehicle/frame has all required wheel samples and a valid exported result. Missing samples make that claim incomplete and must fail its coverage gate; they must not be silently accepted as normal gaps or cause the actor to be removed from scope after failure. Existing historical records can remain explicitly incomplete; do not rewrite their old acceptance history. One-attempt batch behavior means report failures without retries or scenario debugging.

Illustrative source fragment for one actor/frame (normal actor/frame metadata omitted):

```json
{
  "wheel_angle_method": "front_wheel_mean_v1",
  "wheel_angle_references": {"front_left": "FL_Wheel", "front_right": "FR_Wheel"},
  "wheel_steer_angles_deg": {"front_left": -25.0, "front_right": -20.0}
}
```

The exported Core angle is `+22.5` degrees. A single-front-wheel record uses method `single_front_v1`, references `{"front":"Front_Wheel"}`, and angles `{"front": value}`. Retain the model/API validation and source hashes with the measurement method. CPU mocks establish export/error behavior, not actual vehicle-model API support; the real capture must verify its required readbacks.

### Legacy migration and rerun implications

| Saved evidence | Required action |
|---|---|
| Both same-frame front-wheel readbacks exist and are bound to the correct actor/wheels | Compute the mean offline, version the method, regenerate affected trace hashes/reports and decode again. |
| Only a measured front-left angle exists on a two-front-wheel vehicle | Preserve it as legacy `front_left` source evidence. Do not relabel it as a mean, copy it to the right wheel or mix it unmarked with new means. The new mean field remains unavailable; recapture is needed to obtain it unless the missing same-frame readback exists elsewhere. |
| Verified single-front-wheel evidence exists for a two-wheel vehicle | Reuse it under `single_front_v1` with the existing sign conversion; do not require a second wheel. |
| Only steering commands, motion/turn labels or an unreferenced scalar exist | No measured mean can be recovered. Keep the gap explicit; do not infer a wheel angle from a path or request. |

Keep legacy and new semantics separated by acquisition-method/version manifests and reports. A newly published mean-convention dataset must not include front-left-only scalars as though they were means. Preserve original footage, observations, labels and accepted membership; stage regenerated traces through the normal acceptance gates. This is a measurement-convention migration, not a change in numeric JSON type or an automatic legal-label correction.

### Steering acceptance tests

Tests use Native API signs as inputs and Core signs as outputs. Validate the sign conversion against the pinned capture/adapter convention; do not infer it from a left-turn case name.

| Test | Input / situation | Expected |
|---|---|---|
| S1 | Native pair `[-25,-20]` | Core `+22.5` degrees. Both raw values and method retained. |
| S2 | Mirrored Native pair `[20,25]` | Core `-22.5`; same magnitude as S1. |
| S3 | Pair `[0,0]` | Export known zero, not unknown. |
| S4 | Native single-front angle `-12` on validated two-wheel vehicle | Core `+12`, method `single_front_v1`. |
| S5 | One member of a required pair missing, failing, NaN or infinite | No mean; explicit per-wheel error and incomplete new-profile coverage. Never use the remaining angle or a command. |
| S6 | Wheel values belong to different actors/frames, or wrong wheel references | Reject the join/reference; no combined result. |
| S7 | Legacy front-left-only or command-only record | No mean-convention export from that value; preserve legacy evidence and report recapture/source gap. |
| S8 | Same raw evidence through every export path | Identical angle, units, sign, method and failure handling. |
| S9 | Pedestrian, unsupported vehicle layout, and a required supported vehicle with one failed tick | Pedestrian not applicable; layout explicitly unsupported; failed required tick blocks completeness. Do not silently narrow the required set. |
| S10 | Method/identifier absent or wheel query raises an API error | Error logged with actor/frame/wheel, remaining evidence preserved, no silent omission/default/retry. |

Extend the capture/adapter fixture suites to test both reference layouts, API failures and all-actor export. Extend actual Core decode/accessor tests to read the computed scalar without altering its sign or units. No real-GPU rerun or model calibration is started by this handoff.

## 1.7 — consistent reports and removal of obsolete outputs/code

### Historical cause: investigate, do not assume

The original response reports an external hash-verified archive of 2,410 superseded artifacts and removal of `handoff_status.py`. It does not prove that the shared files in the later transfer were regenerated, covered by that cleanup, or produced by that helper. Locate the frozen delivery's shared files, packaging index and available generation/publication receipts; compare hashes and input signatures with the refactor archive. Record established lineage or `historical_report_lineage_unresolved`. Do not claim a root cause from current traces alone. Missing historical files block historical verification, not CPU fixture implementation.

### Explicit fixes

| Output | Required behavior | Example / acceptance |
|---|---|---|
| `atom-coverage.json` | Recompute from final staged roster, traces, actual manifests and applicability rules. Define unit, denominator, scope and meaning for each metric. | Equivalent metrics must agree; required-lane and all-entity coverage need not match. A stale zero total fails independent recomputation. |
| `road-access.json` | Bind policy evidence to the delivered roster; report typed trace representation separately. Use only approved premise IDs. | Explain 189 policy entries versus 124 explicit premise entries from verified representation rules or flag unresolved. Never insert assumptions merely to match counts. |
| `acquisition-methods.json` and hand signals | Keep `sig.hand_signal` omitted from the unsupported CARLA path's manifest and traces, as agreed in original refactor B4. Explanatory `absent` must carry reason `unsupported_by_source` and path identity. Normalize these representations to the same unavailable-capability status. | Omitted capability plus explanatory absent is consistent. It must not trigger a missing-measurement defect, demand a manifest entry, emit false/no-gesture, or request resimulation. Unsupported is not observed negative. |
| `scope.json` / `recordings.csv` | Preserve authored planned cells; derive delivered membership from the pinned roster. Report planned/delivered/missing sets and counts separately. | Plan 27, delivered 18, missing 9. Never delete missing cells to disguise incomplete coverage. |
| Inventory coverage | Apply section 1.5 evidence gates. Distinguish capability, instance count and per-instance attribute coverage. | Verified complete zero lane-control devices means no missing-device gap. Invalid/missing proof is an evidence gap; an existing device missing an attribute is an attribute gap. No placeholders. |

Unsupported acquisition is a path capability limitation; an unknown supported value is a per-observation evidence limitation. Do not add arbitrary Core fields or change the manifest schema to accommodate explanatory reporting. Preserve legitimate omissions rather than inserting `absent` entries for every omitted atom. A future independently validated source may support gestures under its own truthful manifest; the CARLA-path decision is not a universal ban on the atom.

### Generation, cleanup and publication procedure

1. Discover actual maintained generators, CLI entry points, output locations, documentation links and packaging readers. Do not assume the removed historical helper remains a producer. Inventory current generated reports separately from immutable historical audits, original evidence and archive receipts.
2. Generate into a clean staging directory from final pinned trace/manifest/roster hashes and explicitly declared policy, inventory and planned-scope inputs. Pin generator/Core/adapter versions and hash external inputs. Never reuse old totals, merge an old output tree or silently fall back to cached reports. Missing required inputs produce explicit blocks.
3. Create one authoritative current report index with delivery ID, input signatures, schema/generator versions, relative report paths and SHA256 hashes. Current README links must resolve to that set. Do not claim reports are entirely trace-derived when they use policy or inventory evidence.
4. Before replacement, copy superseded reports/indexes and necessary provenance into an external archive and verify hashes. Remove **all outdated reports from active generated-output locations and the delivery package**, including duplicate variants and unindexed leftovers. Keep historical audits/refactor responses and original evidence identified as history; do not delete them as stale generated reports. No history directory under active `work/` outputs.
5. Remove obsolete report generators, abandoned schemas, fallbacks reading superseded reports, unused tests of removed code, stale imports/CLI hooks and documentation links from maintained code. Check callers first. Keep implementation streamlined; no one-off cleanup modules or dead compatibility code solely for old reports. Archived historical code is outside active implementation.
6. Validate the staged set and install index/reports as one consistent generation using the existing publication mechanism. Failure must preserve the prior published generation rather than install a partial mix. After installation verify hashes/links and enumerate active report outputs against the index. Reject stale, duplicate or unindexed report files. Packaging must select indexed current reports, not recursively sweep old directories. No GPU is required.

### Regression fixtures and completion gates

| Test | Fixture | Expected |
|---|---|---|
| R1 | Wrong zero total for known staged observations | Recomputed equivalent count rejects mismatch; distinct defined metrics are not falsely equated. |
| R2 | CARLA manifest omits hand signal; explanatory absent/unsupported | Consistent; no false gesture value, missing telemetry error or rerun request. |
| R3 | Unsupported path falsely advertises hand-signal acquisition or fabricates false | Source/capability validation fails. A validated different source uses its own path rules. |
| R4 | 27 planned cells, 18 delivered | Report 9 missing; preserve planned scope. |
| R5 | Complete zero inventory, missing receipt, positive device missing attribute | Respectively verified absence, evidence gap, attribute gap. |
| R6 | Policy roster differs from explicit premise membership | Evidence-backed explanation or explicit unresolved result; no unapproved premise insertion. |
| R7 | Stale/duplicate report or broken current README link remains | Publication fails until external archival/removal and link repair. |
| R8 | Input roster/trace/manifest/policy changes while report stays cached | Signature/count checks fail; regenerate affected reports and index. |
| R9 | Same inputs twice; injected generation/publication failure | Reproducible semantic output (declared timestamps excepted); failure preserves prior published generation. |
| R10 | Package includes archived/unindexed report or references removed generator | Package/reference gate fails; archive remains outside active delivery. |

Add these CPU fixtures to maintained report/packaging suites identified during discovery. Final implementation report lists current indexed outputs, archived/removed paths, removed obsolete code/references, input signatures, passed checks and unresolved lineage/representation questions. Historical count verification requires the frozen historical bytes; fixture success alone is not a repaired delivery. No other audit item is implicitly resolved.

## 1.8 / 2.1 — authoritative labels, separate processing statuses and historical repair

### Outcome contract and schema migration

The agreed four outcome labels are **compliant, violation, not applicable, judgment call**. Current `production_verdicts.py` uses `compliant`, `violation`, `not applicable`, `inconclusive`; its reasons include `unresolved_judgment`, `missing_observations`, `uncertain_activation`, and `unsupported_reference_check`. These are not interchangeable. Only unresolved interpretation of legal wording supports judgment-call classification. Missing data, unknown applicability or an unimplemented check cannot be relabelled as legal judgment.

Implement a versioned authoritative record with: case/recording/law identity; nullable outcome label; separate evidence/evaluation status and reason codes; legal judgment classification and supporting statutory phrase/definition references; scenario sweep membership; source/evidence hashes; and classification method/version. Use the existing record location/workflow where possible rather than introducing competing label authorities. Define exact serialized tokens and update all consumers together; this prose's display labels are not permission to insert an unrecognized value into an old schema. An unavailable outcome remains null with explicit status/reason, not a fifth outcome or an invented compliant/not-applicable label. If legal judgment and measurement gaps coexist, retain both independently; a judgment-call classification does not certify evidence completeness.

| Condition | Required interpretation |
|---|---|
| Evidence-backed applicable rule satisfied / violated | Compliant / violation under the declared validated method and assumptions. |
| Evidence establishes rule does not apply | Not applicable; unknown activation is insufficient. |
| Case depends on unresolved legal wording/threshold | Judgment call, with the phrase and unresolved interpretation recorded. Do not infer this from a missing label. |
| Missing required observations | Separate missing-observations status; no forced outcome. |
| Activation cannot be established | Separate uncertain-applicability status; not not-applicable. |
| Evaluation check not implemented | Separate unsupported-evaluation status; not judgment call. |
| Scenario belongs to a parameter sweep | Preserve sweep membership independently; a sweep flag alone does not establish unresolved legal meaning. |

Current `judgment_sweep` is derived from `target_type == 'judgment_sweep'`; legacy paths also have additional heuristics. Inventory those writers before migration. Preserve the scenario-design meaning in a distinct documented field or explicitly retain the existing flag for that meaning. Do not silently repurpose it to mean unresolved law, no verdict, or missing observations. Update consumer expectations and schema versions; ambiguous legacy meanings remain explicitly unresolved until definitions/evidence establish them. Resolve the audit's intended legal-judgment classification separately from sweep membership.

### Shared generation and publication gates

Use one maintained classifier/record validator and one shared presentation mapping for fresh capture, saved reconstruction and delivery packaging. Generate `metadata.json`, law README descriptions, CSV/index entries and aggregate counts from the same pinned authoritative record. No independent classification from case names, label absence, human-written README text or scenario family. Inspect `production_verdicts.py`, `expected_labels.py`, `production_metadata.py`, `recording_store.py` and actual README/package producers; these are starting points, not proof every writer is located.

Publication must compare outcome, processing reasons, legal-judgment classification, sweep membership, source signature and record version across artifacts. Reject disagreement or stale derived output. Publish the validated set together using section 1.7's current-set/index and rollback requirements. A matching README is not evidence the underlying label is correct: validate source support separately.

### Historical repair scope and provenance

1. Freeze the historical roster/index and original label/flag records. Recover original case definitions, expected-label records, evidence references and available previous delivery bytes. Investigate the three cited 257-2 cases and reported 37 flag changes; audit counts remain claims until rerun against the exact historical inputs.
2. Determine both legal-judgment classification and scenario sweep membership from source-backed definitions/evidence. Do not select either metadata or README merely because it is convenient. Missing or contradictory authoritative evidence produces a blocked/unresolved result, not an automatic flip. Never map every old `inconclusive` or null value to judgment call.
3. For each correction, retain before/after values, reason, source paths/hashes and classification version in an external migration receipt. Preserve originals. This is the explicit exception to the handoff's general label-preservation rule; it does not authorize changing labels to match intended outcomes or manufacturing legal conclusions.
4. Stage corrected authoritative records and regenerate affected metadata, READMEs, reports, indexes, receipts and hashes; validate all consumers/references and preserve accepted membership. Do not rewrite footage or Lean traces solely for a label/report repair. If an independently justified trace correction is required, apply the normal source-validation/decode gates and record it separately. Do not resimulate automatically to fill evidence gaps.
5. Archive superseded artifacts outside active outputs and publish only the validated consistent set. Keep reusable classification, schema adapters still needed by supported inputs, generation, validation and regression tests in maintained source. Remove obsolete production branches/readers once their consumers are migrated. All one-time migration/repair scripts, repair inventories, backups and migration receipts live outside the repository; do not commit one-off maintenance modules. Preserve historical audit documents as history.

### Regression fixtures and acceptance

| Test | Input | Expected |
|---|---|---|
| L1 | Valid supported compliant, violation and inactive-rule examples | Correct three outcomes, source-backed method and no invented uncertainty. |
| L2 | Explicit unresolved legal phrase with adequate observations | Judgment call with phrase/reason; independent sweep membership preserved. |
| L3 | Missing observations, unknown activation, unsupported check | Separate correct processing statuses; no forced judgment-call/not-applicable outcome. |
| L4 | Sweep with resolved outcome, non-sweep with unresolved legal wording, legal ambiguity plus missing data | Sweep and legal classification remain independent; concurrent limitations retained. |
| L5 | Legacy inconclusive/null and contradictory original evidence | No blanket conversion; recover supported reason or mark unresolved. |
| L6 | README/metadata/index label, reason, flag or version differs | Publication fails; common regeneration yields identical classification. |
| L7 | Historical correction | Original and before/after source-bound receipt preserved externally; only affected artifacts/hashes regenerated; membership and untouched trace/video bytes unchanged. |
| L8 | Fresh versus saved path with identical evidence | Same authoritative record and presentation; no family/name heuristics. |
| L9 | Stale old-label consumer, obsolete writer or one-time repair module in maintained source | Compatibility/reference checks fail until supported consumers migrate and obsolete/one-time code is removed or relocated. |

Final repair report must distinguish implemented contract, verified historical corrections, unresolved cases and counts actually checked. Fixture success does not prove historical labels repaired. No claim that judgment-call cases have formally established compliance verdicts.

## 2.5 / 3.3 — valid polygons, curved centre-line strips and runtime gates

### Scope and agreed proposal

Core's structure geometry currently has a reference point and a polygon boundary, with no explicit polyline field. A decoded point list is not thereby a valid polygon. The interim proposal is an estimated strip **0.005 m on each side of the centre line (0.01 m total width)**, using the same world-coordinate units as exported geometry. This is the selected planned width, not measured paint width; numerical validity and performance remain to be demonstrated. The audit requests agreement on line-like representations; obtain and record the consumer convention before publication. No polyline/Core schema extension or ontology change is implemented by this document.

Use a retained, verified physical marking outline when available. Otherwise retain original polyline coordinates, actor/map/structure identity, units, source hashes and crop/extent evidence; record strip half-width, construction method/version, join/cap conventions, sampling and simplification tolerances, maximum deviation and validation results in source/report metadata. Identify the resulting geometry as estimated; do not silently downgrade all region geometry or relabel the strip as measured physical paint. Use truthful path/method capability metadata consistent with the existing schema.

### Manifest and measured-boundary precedence

Declare `"st.region_geometry": "estimate:mapped_geometry_with_centreline_buffer_1cm"` in the manifest's atoms using its supported serialization, and verify parser/consumer acceptance before publication. Define the method explicitly: fixed **total width 0.01 m**, symmetric **half-width 0.005 m**, with recorded endpoint caps, corner joins, curve sampling/simplification and coordinate units. The method suffix `1cm` must never mean a 1 cm offset per side. Keep the existing manifest schema; resolve any syntax incompatibility explicitly rather than silently dropping the method.

Where a painted marking's boundary is actually measured, preserve that measured outline instead of replacing it with a fixed-width strip. Where only a geometric centre line is available, use the buffer solely as an estimated geometric representation; it does not establish paint presence or paint width. This centre-line method does not apply to stop lines. The separately approved 5.3 fallback permits a declared 0.35 m total-width estimate only for verified painted stop lines with source-backed line geometry. A shared acquisition-path estimate declaration describes a path that includes estimated geometry, not a claim every region has been buffered or all measured outlines have become estimates. Retain per-region source/method evidence so measured outlines and estimated centre-line strips remain distinguishable without new duplicate trace fields.

### Construction and accuracy

1. Normalize crosswalk rings by removing a repeated final vertex equal to the first under the declared source coordinate convention. Remove redundant consecutive duplicates only when geometry is preserved. Validate the resulting polygon; do not treat arbitrary self-touching/crossing geometry as repaired by this normalization alone.
2. For a connected, non-branching centre line, build one continuous strip polygon, not one region per sampled segment. Preserve structure identity and associations. Do not globally merge distinct centre lines or fabricate connections across gaps, branches or junctions. Unsupported topology is blocked pending a source-backed representation; separate genuine components only with explicit identity/association treatment.
3. Remove exact redundant collinear samples. Sample retained curves adaptively, choosing more vertices at tighter bends and fewer where nearly straight. If only a sampled polyline is retained, bound error relative to that polyline and disclose that unsampled true-curve error is unknown; do not invent an analytic curve or claim centimetre accuracy without source evidence.
4. Define and freeze an explicit maximum geometric deviation tolerance in metres, separately from the strip half-width. Measure the actual generated-strip deviation against the reference geometry under the chosen convention. Do not simplify with an error exceeding the declared limit merely to satisfy runtime. Specify deterministic joins/caps; constrain corner protrusions and validate sharp bends, near-reversals and narrow gaps. Do not use a convex hull that bridges missing areas or silently union/close unsupported geometry.
5. Check finite coordinates, identity/frame conventions, nonzero area and Core's actual simple-polygon predicate on the exact serialized/quantized coordinates. Test distance, overlap and crossing behavior against source geometry and the declared approximation convention. Side distances may decrease by roughly the half-width; corners, caps and curve approximation need their own bounds. Do not claim the 0.5 cm half-width alone bounds total error.
6. On failure, preserve evidence and report `blocked_geometry_representation` with the reason. Do not emit the invalid polygon, silently produce many tiny structures, enlarge the width, coarsen beyond tolerance or substitute point geometry. Core's current missing-boundary distance accessor can fall back to a reference point: explicitly test and prevent a point-distance result being presented as distance to an omitted centre line. Resolve that behavior through a validated representation/accessor policy before publishing any omitted-boundary fallback.

### Performance gate before historical batch conversion

The original B1 issue involved hundreds of extra overlapping roadway structures, wrong roadway identity and wider rule scans. A continuous strip avoids that specific structure proliferation, but high vertex counts still matter. Core's `Geom.selfIntersects` compares edge pairs, so worst-case validation work is quadratic in polygon edge count. Existing caching may reduce repeated checks but is not proof of acceptable complete-recording execution time.

Benchmark the pinned actual evaluator and Core on representative straight, long, gently curved, tightly curved and sharply bent centre lines, including a long recording and a large-map case relevant to B1. Use the same rules, frame roster, toolchain and hardware for comparable before/after timings. For invalid old geometry, do not call a fast undefined result an equivalent functional baseline: report that limitation and include valid comparable fixtures. Record source samples, generated vertices, structure counts, polygon-validation time, full-recording evaluator time, peak memory when available, approximation error and failures. Approximately N samples produce 2N vertices, with extra vertices depending on joins; report actual counts rather than assuming that formula is exact.

Freeze a tested accuracy/runtime profile and explicit acceptance budgets before batch conversion, with benchmark evidence and the chosen consumer convention. There is currently no measured runtime promise or numeric budget in this plan. If acceptable accuracy and runtime cannot both be demonstrated, mark the batch blocked and report the tradeoff; do not invent a passing budget after observing results. Use bounded representative CPU benchmarks during implementation; no GPU resimulation or full collection legal verdict run is authorized by this documentation task. Do not introduce caches or broad Core optimizations absent demonstrated need and separate validation.

### Lean code boundary: production, tests and one-time work

The construction and acceptance requirements above describe behaviors to establish; they do not require an independent production component for every numbered check or G fixture. Keep implementation small and use existing geometry/export/report facilities.

| Location / frequency | Required scope |
|---|---|
| Maintained production code, per export as needed | One shared polygon normalization/strip-construction helper; essential finite/input/reference and actual polygon-validity checks; explicit failure result; normal source/method provenance. Avoid duplicate validation layers and redundant work when existing verified results can be reused safely. |
| Maintained regression tests | A small representative set for straight lines, gentle/tight curves, sharp bends, malformed polygons and shared fresh/saved behavior. Combine G1–G10 expectations into existing fixtures where practical; do not create ten separate frameworks or mirror the implementation with superficial tests. |
| One-time implementation/migration validation | Representative evaluator performance benchmarks, selection of the accuracy/runtime profile, and historical before/after/source-integrity comparisons. Run before batch conversion/publication; do not benchmark full evaluator execution on every future export. |
| Outside the repository | All one-time historical remapping/repair scripts, repair inventories, backups and migration receipts. Use an external operation directory and hash-verified archive; do not add maintenance-only modules to maintained source. |

Keep reusable geometry construction inside maintained source for future exports. Remove obsolete implementations and unused callers/tests after migration. Do not build new benchmark services, reporting subsystems, compatibility layers solely for old outputs, or speculative caching/optimization machinery. The detailed evidence and acceptance checks remain required at the appropriate phase, but should reuse existing gates and reports. Normal per-export provenance is retained in generated artifacts; one-time migration tooling and receipts remain external.

### Historical export repair and regression tests

Reuse retained geometry offline where sufficient. Stage repaired crosswalk/centre-line geometry with original evidence preserved externally and before/after method/coordinate/hash receipts. Regenerate affected traces, occupancy/completeness where geometry changes require it, reports/indexes and acceptance receipts; validate dependent answers rather than reusing old geometry-based proofs. Re-decode every changed trace and check exact Core geometry predicates, references and normal physical/media acceptance requirements. Geometry approximation must not automatically change labels, accepted membership or source footage; any independently justified classification correction follows section 1.8 / 2.1. Keep one-time migration code outside the repository as already specified; reusable normalization, strip construction and validation belong in maintained source.

| Test | Fixture | Required outcome |
|---|---|---|
| G1 | Crosswalk A,B,C,D,A | Normalize to A,B,C,D with same physical outline; Core polygon valid. |
| G2 | Other self-crossing crosswalk | Explicit failure; no convex-hull guess. |
| G3 | Straight sampled centre line with redundant collinear points | One narrow valid polygon, no new per-segment structures; declared 0.005 m side offset and 0.01 m total width, matching the manifest method. Measured marking outlines are preserved instead of buffered. |
| G4 | Gentle and tight curves with known reference geometry | Adaptive sampling meets separately declared deviation bound; source and resulting vertex counts recorded. |
| G5 | Sharp corner, near-reversal, self-near line or branch | Validated deterministic joins/caps with bounded error, or explicit block. No arbitrary bridge or region explosion. |
| G6 | Only sampled line retained, no analytic curve evidence | Error claim limited to retained reference; no unsupported true-curve accuracy claim. |
| G7 | Exact quantized output and distance/overlap probes near sides, bends and endpoints | Actual Core validity and queries match declared approximation; no reference-point substitution on failure. |
| G8 | Large/long recording benchmark | Frozen accuracy/runtime budgets pass on actual evaluator; structures, vertices, elapsed time and failures reported. |
| G9 | Fresh and saved exporters with identical source | Same geometry/method and validation behavior; no family-specific fallback. |
| G10 | Historical geometry replaced | Source preserved, changed outputs decoded, dependent geometry/occupancy receipts recomputed, untouched footage/membership preserved. |

Cover G expectations with a compact representative set in existing geometry/adapter/Core suites; combine fixtures where appropriate. Performance and historical comparison expectations are one-time validation, not per-export runtime checks. Passing decoder tests alone is insufficient. No claim that all historical audit counts or polygons are repaired until checked against the pinned delivery.

## 2.6 — final velocity contract, offline conversion first and one selective rerun

This item refines the general optional rerun plan below for velocity completeness. It plans future execution; it does not resume the paused simulation goal or allocate a GPU under this documentation task.

### One final format and lean maintained implementation

- Keep `kin.velocity` as horizontal world-frame `(vx, vy)` and define `kin.speed` as its Euclidean magnitude `sqrt(vx² + vy²)`. Update ontology prose and maintained Core/source documentation consistently; do not silently retain 3D scalar speed under that atom.
- Add exactly one vertical-velocity scalar to the final Lean trace schema, decoder and accessor; `velocity_z` is a planning placeholder, not an approved atom name. Before implementation freeze the exact field/atom name, units m/s, world-coordinate convention, Native-to-Core vertical sign and schema/version signatures. Retain raw source components and transform provenance. Reconstruct full 3D velocity from the existing horizontal pair and this scalar; do not duplicate vx/vy in a second vector or export redundant full-3D speed solely for this fix.
- The schema may represent absent measurements, but the final selected delivery requires measured finite vx/vy/vz at every required actor/frame. Unknown is not a passing result for required velocity. Freeze actor/frame applicability from the accepted roster before migration: all required recorded road users across subject/participant paths; unsupported or missing acquisition blocks the record rather than narrowing its scope after failure.
- Use one common capture/extraction helper and one export convention for fresh conversion, participant attachment and saved reconstruction. Migrate supported consumers together; retained production code supports the final format only. Remove old speed conventions, legacy-format branches, superseded readers, duplicate velocity outputs and stale tests/docs after callers migrate. Do not add backward-compatibility layers for superseded delivery formats. The global compatibility allowance does not authorize them for this explicitly final-only migration.

### Ordered implementation and execution

1. **Freeze scope and original evidence.** Pin the authoritative accepted roster, original scenario versions/configurations/controllers/seeds, recording/source hashes, labels, actor bindings and required frame intervals. Default historical offline roster remains the 189-recording delivery specified above; do not silently extend it to the paused demo-test campaign. Any future batch uses the explicitly selected accepted roster. Hash-verify external preservation copies before removing/replacing originals from active locations.
2. **Upgrade common capture.** Record simulator-read vx/vy/vz for every required actor at every recorded tick, bound to original frame/time and actor identity. Define synchronous acquisition and coordinate conversion; preserve genuine zero. Never derive vz from speed magnitude, substitute a command, interpolate a missing original measurement, or use a different replay execution to claim original telemetry.
3. **Validate instrumentation before the batch.** Use compact CPU fixtures for finite/zero/missing values, coordinate transforms, actor/frame joins, horizontal speed and the new Lean decoder/accessor. Run a bounded allocated-GPU capture preflight to verify actual readback completeness on the required capture path before starting the selective batch. This validates shared instrumentation, not scenario tuning or repeated case debugging. Fix common instrumentation before the batch; preflight failure blocks batch start. GPU execution uses project m5029_g and the allocation's CPUs/GPU, not login-node compute.
4. **Convert compatible existing recordings offline first.** A record is compatible only if verified same-execution original telemetry supplies all required vx/vy/vz samples, exact actor/frame joins and source/coordinate metadata. Merely having a 3D speed scalar, 2D velocity or estimated position derivatives is insufficient. A record already in the final format needs validation, not a duplicate copy. Keep one-time conversion/remapping tools outside the repo. Output final-format staged traces, recomputed horizontal speed and provenance; preserve footage when the original execution is reused.
5. **Rerun accepted incompatible scenarios once.** Select only roster entries that cannot satisfy that conversion gate. Reuse accepted construction/map/assets/configuration/controllers and recorded seeds. One attempt per selected scenario; no scenario tuning, geometry changes or automatic retries. This is new measured execution, not recovery of old missing telemetry. Preserve identity/lineage and create appropriate new recording hashes/IDs; do not overwrite evidence as though the trajectory were identical. Capture other already planned common telemetry through the upgraded path without unrelated feature expansion.
6. **Finish normal validation.** Check every required actor/frame for finite complete velocity and consistent horizontal speed; decode the changed traces with the final Core and actual manifest; verify references, frame joins, physical execution, media and source hashes. Review vertical motion for falling/invalid setup rather than hiding it by projecting speed horizontally. Re-evaluate source-supported labels and ordinary recording acceptance for reruns; previous acceptance/verdict is not automatically inherited. Failures remain explicit roster-level blockers, with diagnostic artifacts outside active delivery. No retries, silent roster removal, fabricated values or fallback to legacy incompatible recordings.
7. **Publish only final validated outputs.** Regenerate final metadata, READMEs, aggregate reports, indexes and hashes under the existing consistent-publication gates. Every selected entry must be complete and accepted or explicitly blocked; do not claim the full migration complete while blockers remain. Only final validated recordings and essential source/method provenance remain in the active catalog/work outputs/package. Remove superseded active variants and duplicate artifacts after external archival/hash verification; external archives are preservation evidence, not a parallel supported dataset. Keep no obsolete-format implementation or one-time repair tooling in maintained source.

The single-attempt policy cannot guarantee every scenario succeeds. Missing telemetry or physically invalid reruns are explicit incomplete results requiring a later user decision, not permission to debug/retry automatically. Do not launch a full new GPU campaign under the general historical repair instructions; execute this phase only when separately requested.

### Compact acceptance coverage

Extend existing capture/adapter/Core suites rather than creating a new subsystem. Cover: measured 3D zero and nonzero samples; horizontal speed independent of vz; signed vertical conversion; exact actor/frame binding; missing/non-finite component blocking; same evidence through all paths; offline conversion versus recapture classification; final decoder/accessor access to vz; and rejection of stale formats/duplicate active output. Run historical completeness/source comparisons once in external migration tooling, with compact receipts. Validate publication roster completeness and rerun acceptance through existing gates. Required completion inventory lists converted records, single-attempt reruns, blockers, final paths/hashes, externally archived superseded records and removed obsolete code/references. No unsupported promise that original absent telemetry can be reconstructed.

## 2.7 — measured indicators, case suitability and conditional repair

### Evidence check and decision

Freeze the cited roster (audit: 227-1 ×8, 253 ×9) against the authoritative historical delivery before claiming those counts verified. Inspect source-bound original light-state readbacks, actor/frame joins, actual executed controller configuration/schedule and the case definition's intended maneuver/timing purpose. A requested signal state is evidence of controller intent, not a replacement for measured readbacks. Current local artifacts may differ from the historical package.

| Verified finding | Required action |
|---|---|
| Export differs from original measured light flags | Fix the common signal extraction/export path; regenerate affected traces and reports offline with source proof, new hashes and decode. Preserve genuine measured transitions and off states. |
| Signal genuinely stays left and does not invalidate the intended case | Retain the recording, source values and acceptance subject to normal gates; describe behavior accurately. Do not fabricate a later switch-off. |
| Signal genuinely stays left but defeats the case's stated transition/timing purpose | Record `unsuitable_for_intended_signal_timing` with the definition/evidence reference. Specify the required schedule from that case, repair the controller in a separately scoped phase, recapture and validate new execution. Do not silently relabel the case or claim the old video demonstrates a transition. |
| Required original readbacks missing or bindings invalid | Report verification blocked; recapture if this measurement is required. Never infer the state from turn direction, steering, case label or command alone. |

A continuously active indicator is not, by itself, proof of an exporter bug or legal noncompliance. A case about a different property may remain useful, but do not assume signaling is irrelevant without inspecting its activation/context and intended test. Do not introduce a blanket rule that all indicators switch off at turn completion.

### Timing validation and execution boundary

Where timing matters, identify actual measured signal activation and actual observed maneuver onset from source-bound observations under the case's declared maneuver/threshold convention. Commands, planned turn stations and planned distances are not measured onset. If activation predates the capture window, report that its exact start is unobserved; do not equate first recorded frame with activation. Continuous in-window observations may support a lower bound under a documented method, not an invented exact onset. Missing maneuver-onset evidence remains a gap.

Triage these cases before the unchanged-scenario batch in section 2.6 or the optional common batch below. Cases requiring a changed controller schedule must not be knowingly rerun under an incompatible unchanged configuration merely to repeat the same issue. Report them as blocked for that batch and place them in a separate explicitly scoped scenario-repair/recapture plan. No controller tuning, automatic retry or behavior change is authorized by the unchanged-scenario one-attempt policy or this documentation task. Newly repaired runs require normal source/physical/media acceptance and source-backed label review; previous acceptance/labels do not transfer automatically.

### Lean implementation and completion

Reuse common light-readback extraction, existing report facilities and compact tests. Cover measured off/left/right states and transitions; mismatch repair versus genuine always-on preservation; missing/invalid readbacks; activation before the recorded window; observed versus commanded onset; and identification of cases needing separate controller repair. These are representative fixture expectations, not a new timing-validation framework for every case. Keep one-time historical evidence comparison, triage inventories and migration scripts/receipts outside the repository. Remove obsolete export/controller implementations after active callers migrate, preserving required source provenance externally. No speculative controller rewrite or extra output subsystem.

Completion report lists inspected records and evidence, findings/actions, offline export repairs, suitable retained recordings, blocked measurement cases and separately scoped controller-repair candidates. Regenerate affected metadata/READMEs/reports/indexes from the final evidence and preserve original artifacts before replacing active outputs. Do not claim all 17 records defective or repaired without source verification and, where required, validated recapture. The documentation task runs no legal evaluation or GPU simulation.

## 3.2 — approved atom IDs in requirements and reports

The audit reports nonexistent requirement IDs `ru.animal` (ten adapter reports) and `drv.wrong_way` (two reports, including 175 required-field gaps). These counts remain audit claims until checked against the pinned delivery. Resolve the authoritative ontology/variant for that delivery and use the maintained machine-readable atom catalogue or existing ontology tooling as the single allowed-ID source. Do not maintain a second hand-copied allow-list or mistake generated accessor names for ontology IDs.

1. Locate actual requirement producers and consumers, beginning with `atom_contract.py` and report `reconstruction.required_atoms` writers, plus coverage aggregation and publication. Search the invalid strings, aliases, generated mappings and tests; do not assume fixing a display string fixes upstream requirement generation.
2. Correct reusable requirement generation to emit only approved IDs. Investigate each invalid requirement's intended meaning against source law/case dependencies. If existing atoms express it, use a verified dependency mapping with an explanation; wrong-way behavior may be a derived comparison, not a standalone atom. Do not invent replacement IDs or silently equate unrelated concepts. If the ontology cannot express the intended requirement, record an unresolved contract gap outside the required-atom ID list and block claims of complete semantic coverage until resolved.
3. Add one compact shared validation gate for requirement/report IDs using the pinned catalogue. Fail staging/publication with the offending ID, report path and producer when an unknown ID appears. Do not silently filter arbitrary unknown IDs at validation time or convert them into ordinary missing-measurement counts. Reuse existing contract checks rather than add a separate validation subsystem.
4. Regenerate affected historical reports, coverage totals, metadata/index references and hashes from corrected requirements and pinned evidence. Distinguish removed invalid-ID gaps from genuinely resolved measurements; deleting an invalid name does not acquire data. Preserve originals and before/after/source signatures in the external archive. Trace/footage changes and GPU resimulation are unnecessary solely to repair report IDs; any discovered underlying measurement issue is separately scoped.
5. Keep reusable generation changes, catalogue validation and compact regression tests in the repo. Keep all one-time historical correction scripts, repair inventories, backups and migration receipts outside it. Remove obsolete invalid mappings/aliases, unused helpers/tests, stale references and fallback branches after caller checks; no legacy emitter of invalid IDs remains.

Compact tests must cover a valid pinned ID passing, each invalid ID rejected with actionable location, the actual report producer no longer emitting those IDs, and a genuine unsupported requirement remaining explicitly unresolved rather than silently disappearing. Validate regenerated totals/index hashes through existing report gates. Final result lists occurrences actually verified, producer changes, supported dependency mappings or unresolved gaps, regenerated artifacts, removed code/references and external one-time tooling locations. No claim that historical counts are verified from fixture tests alone.

## 3.5 — canonical junction identity and external historical deduplication

### Verified local findings and limits

Read-only inspection of local recording `cb6ec1a81f55` found intersections 19 and 26 with the same square boundary (corners ±7 m) but different start vertices. Lanes 1, 8, 10 and 17 reference 19 through `enters_intersection`. Both copies also exist in `evidence/traffic_spec.before-participant-projection/trace.json`, so they predate that retained stage. Native JSON facts enumerate junction 10 once. An offline call to current `static_map` on the retained OpenDRIVE and native junction boxes emitted one intersection mapped to junction 10. This establishes a surviving legacy duplicate and a current repair gap; it does not establish the original historical writer or independently verify all six audit cases. No Native graphs were unpickled.

`geometry.py:match_regions` explicitly leaves a source unmapped if multiple matching targets exist. `retained_map` uses that matcher, while `adapter.py:reconstruct` invokes roadway consolidation rather than intersection canonicalization. Consequently equivalent legacy intersections remain ambiguous and survive reconstruction. Do not weaken `match_regions` to choose an arbitrary geometry match: its conservative behavior is appropriate for genuinely different coincident objects.

### Maintained source fix

1. Add a small shared canonical-junction identity helper in the existing map/geometry implementation. Source key includes verified map hash, native junction ID and, where necessary, a validated connected-component identity. Retain this binding in existing source/report metadata, not arbitrary Core fields. A junction can have genuine disconnected components: do not collapse distinct components into one polygon or force every source junction to have one region regardless of representability.
2. Apply canonicalization before ambiguous region matching during saved reconstruction and reuse the identity convention in fresh map projection. First verify map/facts hashes and historical bindings. Matching XY alone, nearest position or an unused ID is insufficient identity proof. In this example, one bound native junction plus matching component geometry and approach/source associations supplies a candidate proof; establish it explicitly before merging 26 into 19. Prefer an existing source-bound referenced ID when compatible; otherwise use a deterministic rule. Conflicting attributes, incompatible extents, separate levels or insufficient bindings block the merge.
3. Reuse `roadways.py:apply_replacements` / `compatibility.py:remap_regions` rather than duplicate the remapping implementation. Check coverage of every region-ID field in the final schema: lane enters/connectivity/adjacency, ways, entrance associations, device governs, occupancy pairs, intention targets and sight-along-way references. Deduplicate remapped lists/pairs, preserve actor/device IDs and unknown/completeness semantics, reject cycles/dangling references and conflicting merged attributes. Recompute geometry-dependent receipts if source geometry changes; an identity-only equal-geometry remap does not justify altering measurements.
4. Update source-ID side tables, cached map identity/signatures and reports consistently so the retired ID cannot reappear later in the export. Use existing cache versioning/invalidation only where affected, not a new cache subsystem. Canonicalization must be idempotent and shared across fresh/saved paths. Add compact fixtures for verified duplicates with different polygon start/winding, distinct junctions with equal XY, genuine multiple components, conflicting evidence, repeated reconstruction and all affected reference fields.
5. Locate historical introducing code if retained source history permits; report its lineage or explicitly leave it unresolved. Remove obsolete active intersection-creation/remapping paths if found after caller checks. The demonstrated repair gap can be fixed without pretending the original creation mechanism is proven. No recording-ID-specific patches or blanket geometry-based merging.

### One-time correction outside the repository

Use external operation-directory tooling to inventory the pinned historical roster, establish each source-backed duplicate group and invoke the maintained canonicalization/export path. Audit's six cases are investigation candidates, not automatic merge instructions. Hash-verify original reports/traces in the external backup/archive before replacement; store before/after ID maps and evidence receipts there. Stage final deduplicated traces; validate every frame's references and occupancy, actual Core decoding/query behavior, stable intended geometry/actor/timestamps/labels and updated reports/indexes/hashes. Keep only validated final active recordings; no legacy-output compatibility or parallel duplicate variants. No GPU simulation is required for supported retained-evidence remapping. Missing proof remains blocked, not guessed.

Maintain only reusable identity/canonicalization behavior and compact tests in source. All one-time inventory/deduplication scripts, backups and migration receipts remain outside the repo. Final result distinguishes locally verified example, full-roster results, unresolved origin/bindings, removed obsolete code and external repair locations. This section plans the correction; it does not authorize simulation or claim historical deduplication already performed.

## Sight-distance update — ego reference geometry and law-independent completeness

This section supersedes earlier instructions excluding new sight instrumentation from this handoff. It plans the now requested shared measurement upgrade and optional one-attempt GPU acquisition; it does not itself resume the paused simulation goal. `ontology/ATOMS.md` is revised by this documentation task; implementation, generated/maintained variants and actual manifests remain to be updated through their normal workflows.

### Final measurement meaning and method declaration

Evaluate at the ego's road location each required recorded frame. Use its source-bound measured body geometry as the target, with virtual approaching observer viewpoints along the road at the declared height/reference convention. There is no requirement to spawn a full hypothetical car or to precompute every map location. Treat visibility as reciprocal under the agreed convention; do not add separate reverse eye/body tests. Dependence on ego geometry is an explicitly declared estimate, not a claim that all vehicle sizes yield identical results. Document the occluder set and how the ego/reference body is handled by ray queries; do not silently change static/dynamic obstruction scope.

Use the method declaration **`estimate:vehicle_reference_geometry`** for `st.sight_distance` in the actual supported manifest representation. Verify the manifest parser accepts that syntax and update the shared method description/catalogue consistently; do not invent arbitrary manifest fields or merely relabel unsupported values. The numeric trace field remains `sight_distance` in metres. Retain reference geometry, actor/frame/location joins, observer-height convention, road-distance convention, directions/approach inventory, sample spacing, horizon refinement tolerance, probe/search limits, occlusion results, bounds and source hashes in existing evidence/report structures. The method label is not a replacement for these measurements.

Reuse `visibility.py:sight_distance` and `attach_visibility` plus the maintained capture-side route/ray/horizon code where their behavior satisfies this convention. Current code uses nine measured ego-body samples, virtual incoming observers, conservative sampled bounds, and occupied lane/roadway attachment; inspect the actual capture producer and adapt the smallest common path rather than build a second system. Verify attachment to applicable current road regions and stable frame joins. No new standalone all-pairs visibility system or automatic reinterpretation of `rel.visible` is required.

A censored search supplies a lower bound, not an exact visibility maximum. The existing numeric accessor does not itself encode interval semantics: verify how consumers will interpret the conservative value and retained bound metadata; agree a truthful operational convention before publication. Extend/refine acquisition as necessary for that convention. Never claim metadata alone makes exact-threshold consumers bound-aware. Unknown/incomplete approaches, invalid geometry and insufficient searches fail the completeness gate; do not fabricate a maximum, zero or statutory-threshold value. Sampling between observations is an estimate under the recorded resolution, not proof of continuous visibility at arbitrary precision.

### Mandatory acquisition for every recording and future runs

1. Freeze applicable ego frames/road-location scope and the expected approach inventory before capture. Every selected final Lean recording must include validated sight-distance values on applicable current road-location structures for every required frame, regardless of target law or requested dependency list. Do not claim a value for an unrelated region or remove a failed frame/region from scope. Frames with no supported road location are explicitly blocked/not-applicable only with evidence, not silently passed as complete.
2. Upgrade common capture/export to acquire and export this measurement unconditionally for that scope across scenario families. Future simulations inherit the same policy and final-format validation. Extend the existing shared required-observation/completeness profile; do not create per-law instrumentation switches or parallel pipelines.
3. Validate common instrumentation before batch execution: compact CPU fixtures for geometry/frame identity, reciprocal convention, approach completeness, finite values, bounds and attachment; a bounded allocated-GPU preflight verifies actual ray/route acquisition. Use project m5029_g and the allocation's CPUs/GPU for GPU work. Ordinary velocity telemetry does not constitute sight evidence.
4. Inventory retained captures first. Reuse only compatible source-bound ego geometry/rays/horizons with sufficient approach/search coverage and the same declared meaning; regenerate final traces and manifests offline. Do not infer unseen rays from a similar-looking map or rename unrelated probes.
5. If conversion is unsupported, one GPU simulation/remeasurement of each incompatible accepted scenario may be necessary. Coordinate with section 2.6's selective one-attempt batch so required velocity and sight instrumentation run together where possible, avoiding duplicate reruns. Preserve accepted map/configuration/controllers/seeds; no scenario tuning or automatic retries. New execution must pass normal acceptance and label/source review; missing sight or other required common telemetry blocks completeness. Report failures externally rather than silently emitting incomplete final traces.
6. Publish only final validated active recordings/manifests/reports/indexes and their required provenance. Preserve originals externally with verified hashes first. Update ontology variants/method descriptions/consumer expectations together, remove superseded active sight conventions/branches and keep no backward-compatibility mode solely for old outputs. All one-time historical conversion, investigation and remeasurement orchestration scripts/inventories/receipts stay outside the repo; reusable acquisition/export and compact tests remain in maintained source.

The same law-independent acquisition/export rule governs all other atoms/relations already designated for common coverage in this handoff. Required applicable supported values must be present even when the current law does not read them. Keep capability and applicability honest: unsupported CARLA hand signals stay omitted; pedestrians do not acquire vehicle equipment; Core-derived relations remain provided through validated inputs/accessors rather than redundant exhaustive serialized relations. Do not promise unsupported atoms simply to eliminate unknowns. Required supported measurement failures block final completeness and do not justify invented values or dropping actors/frames.

Acceptance must establish actual method declaration, required frame/road-region coverage, source/approach/bound correctness, and identical shared behavior across fresh/saved paths. Include at least one law that does not read sight distance to prevent dependency-driven omission, plus missing-approach and censored-search failure/interpretation fixtures. Reuse existing test/report infrastructure and one-time representative runtime checks; no new validation framework. Final implementation result lists offline conversions, coordinated one-attempt recaptures, blockers and removed obsolete code, without claiming all existing captures compatible before inventory.

## 3.6 — retain lane governance; separate intersection service and containment

### Contract boundary and scope

Keep lane/directed-approach `dev.governs` associations. Do not broaden them to intersection IDs merely to satisfy the audit's reported earlier 250-4 consumer rule. The exact generated consumer rule was not found in this review; a physical-presence or intersection-control interpretation is not established as legally correct here. Report this as a contract/consumer interpretation issue rather than silently changing the measured device associations.

The `dev.serves_intersection` atom contract is now added to ATOMS.md. It permits multiple served intersections per device. An observed list is complete (unlisted pairs false); an unobserved association remains unknown, and an observed empty list needs complete source proof. Define the final serialized list/observation representation and implement decoder/accessor, language/catalogue integration, maintained ontology variants and consumers together. A Markdown atom addition does not provide runtime support: do not add a fake implemented-accessor entry or emit an unrecognized Core field. No temporary/legacy dual format. Existing `dev.governs` still permits explicitly established junction governance, distinct from service; do not infer it from lane governance or containment.

Meanings must remain distinct:

- Lane/approach governance: whose traffic the device regulates; retain existing verified associations.
- Serves intersection: which junction's traffic regulation the device participates in. Serving one approach is not all-way control, operational status or a common indication for all entrants.
- Physical containment: derived from device position and the intersection's valid boundary polygon. No new containment atom or serialized pair table. Define boundary-touch handling using existing geometry conventions; missing position/boundary is unknown, not false. A reference-point comparison is insufficient.

### Minimal implementation and historical projection

1. Inspect retained device identities, same-map native lane/control associations, approach `enters_intersection` bindings and native junction IDs. Apply section 3.5 canonical junction mapping first so a service relation cannot point to a retired duplicate. Keep original lane governance unchanged except independently supported existing repair work.
2. Where retained bindings establish the device's service relation, project the separate approved intersection association using a small shared helper across fresh/saved export paths. Validate map hashes, device/approach/junction identity and scope. A mere nearby lane or proximity/containment of a pole does not establish service. Devices governing road stretches or movements unrelated to the candidate junction must not be attached by a blanket lane-lookup heuristic. Ambiguous/multiple candidates follow final contract cardinality/evidence rules; do not pick the nearest or smallest ID.
3. Distinguish missing association evidence from a verified complete empty association under the schema implementing this atom contract. Never infer that a device is operative, covers every approach or gives the same signal throughout a junction. Consumer rules must explicitly derive their intended intersection-level condition from device kinds/states, service and approach facts; producer code must not encode an unapproved legal conclusion.
4. Derive physical containment through existing point/polygon facilities when requested. Do not create a duplicate stored relation or a new geometry subsystem. Preserve lane-governance-only outputs until the new contract is actually implemented; do not claim a Markdown atom proposal supplies runtime support.
5. Inventory compatibility offline first. Saved source-backed device/lane/junction bindings normally permit projection without GPU simulation. If required associations cannot be established from retained evidence, report the exact missing binding; targeted recapture may be necessary. No blanket full-roster resimulation. Coordinate any future required recapture with the validated selective one-attempt common batch, without automatic retries or unrelated controller tuning. Missing evidence is not permission to guess service.
6. Regenerate affected historical traces/metadata/reports/indexes with one-time external migration tooling; preserve originals and before/after association maps in the external backup/archive. Re-decode changed traces with the final approved Core/schema, validate references and evidence, and retain only final validated active outputs. Reusable projection/validation and compact regression tests stay in maintained source; remove obsolete intersection-governance workarounds, unused helpers and stale references after caller migration. No backward-compatibility layer or one-time migration modules in the repo.

Compact tests: a device outside the polygon serving a verified approach/junction; a physically contained unrelated device not automatically serving it; one controlled approach not becoming all-way control; valid empty versus missing association; conflicting/ambiguous bindings; canonicalized junction references; same source through fresh/saved paths. Reuse existing suites and source/report gates. Completion records the atom/schema versions, offline successes, evidence-blocked cases, whether targeted recapture was actually necessary, removed obsolete code and external tooling locations. No GPU work starts under this documentation task.

## 4.3 — source-backed signal operability on every export path

### Confirmed code gap and contract

Current ATOMS.md defines `dev.inoperative` as a signal head installed and uncovered but showing no valid indication. This is the measurement contract used here; do not add an unrequested failure-cause diagnosis or require proof of electrical damage. In `adapter.py`, `observed_inoperative(indications, uncovered=None)` already accepts the uncovered fact, but callers in `project_operability` and conversion omit that argument. `project_operability` can then remove an existing value for a dark signal. Search every call and any parallel writer before implementation, rather than fixing only one line.

Local first-frame inspection of `71e2a17317ca` and `bf5ba06672dc` found three traffic signals each with `indications: [dark]`, `uncovered: true` and no `inoperative`. Relevant saved files include `traffic_signal_operational_state.jsonl`, `signal_and_scene_state_history.jsonl` and `signal_reporting_audit.json`. Configuration describes installed heads set Off and frozen. Configuration is intended setup, not sufficient measurement proof. These local checks do not verify all frames, historical transfer bytes or the audit's 1,920/2,799 device-scene counts.

### Shared evidence and projection rules

1. Establish installed traffic-head identity from source-bound native device inventory/capture, not a label or arbitrary trace object alone. Verify actor/device IDs, map/source hashes, frame/time alignment and the source of `uncovered`. A dark indication does not itself prove installation or uncovering. Do not reuse a stale uncovered value across intervals without evidence it applies throughout.
2. Normalize actual readbacks through the existing indication mapping. Missing, Unknown, ambiguous or failed readbacks are not Off/dark. A requested Off/freeze command describes construction intent; original measured state must establish the displayed indication. Reject conflicting same-frame sources or malformed mixtures such as dark plus a valid indication rather than selecting a convenient value.
3. Keep one operability helper and pass verified uncovered evidence consistently at every call site, including fresh conversion, repair/reconstruction and subsequent normalization. Gate use on valid installed-head identity. Missing uncovering is not supplied as false. Preserve the existing return type/trace field unless the maintained contract requires otherwise; no new subsystem.

| Verified evidence | Required result |
|---|---|
| Valid observed red/yellow/green indication, consistent source facts | `inoperative: false`; no hidden assumption that absent observations are a valid indication. |
| Installed head, uncovered true, confirmed dark/no valid indication | `inoperative: true` under current atom definition. |
| Installed head, verified covered, confirmed dark | `inoperative: false` under the installed-and-uncovered definition; do not infer status from an unverified covering flag. |
| Dark with uncovering or installed identity missing | Unknown with explicit evidence reason; blocks a required operability completeness claim. |
| Missing/ambiguous indication | Unknown; never default dark or false. |
| Contradictory covering/visible indication, conflicting bindings or malformed state combination | Explicit validation error/block; preserve evidence, do not silently choose a branch. |

The definition is a per-observation classification, not proof of a lasting mechanical fault. Do not introduce arbitrary persistence thresholds. Evaluate applicability only for signal heads; do not require an inoperative lamp field on unrelated signs. Do not clear verified positive facts during a later projection by forgetting the same evidence argument.

### Capability, historical repair and GPU boundary

Update the shared `dev.inoperative` method description/catalogue to reflect both implemented directions of evidence, replacing the current narrowly named `estimate:valid_observed_native_indication_excludes_inoperability` where it no longer describes the path. Choose and validate one final supported method serialization; do not label unsupported/missing evidence exact or create an incompatible manifest field. Retain per-device evidence/method in existing reports and export every supported applicable value independent of target law.

Inventory source evidence offline for the pinned historical roster, verify all relevant device/frame intervals and regenerate supported operability values through the common exporter. Keep all one-time investigation/correction scripts, repair inventories, before/after maps, backups and migration receipts outside the repo. Preserve originals in the external hash-verified backup/archive. Regenerate affected trace/manifest/report/metadata/index hashes and decode changed traces with the actual final Core/manifest; run source/reference/completeness checks. A corrected activation input does not by itself establish a new legal label or acceptance result; review affected classifications through normal evidence-backed gates.

No GPU rerun is inherently needed if source-bound indication, installation and covering evidence are retained. Missing/unreliable required evidence is an explicit blocker and may require targeted capture; coordinate with the validated selective one-attempt common batch, with no scenario tuning or automatic retries. Do not rerun the whole collection by default or claim the saved files are sufficient before verifying them. For future capture, retain required device identity, actual indication and covering evidence through the same lean path; no silent law-dependent omissions.

### Compact tests and completion

Extend existing signal/adapter fixtures to cover: valid indication false; dark+uncovered true; dark+covered false; missing uncovering/identity; unknown/missing state; conflicting inputs; zero source values where relevant; all actual call paths; and idempotent projection retaining the verified true value. Test matching source evidence across fresh/saved paths and actual Core readback. Reuse existing source-integrity, decoder and report gates rather than adding redundant runtime layers. Remove obsolete inference branches, unused writers/tests and stale method references after caller migration; keep only reusable code and compact tests in maintained source.

Completion reports records/device intervals actually inspected, offline corrections, unresolved evidence, any targeted recapture requirement, final hashes and removed code/external-tool locations. Only final validated artifacts remain active; archive copies are historical evidence, not a supported legacy format. This documentation task performs no historical edits, legal evaluation or GPU simulation.

## 4.4 — historical outside-business assumption projection

### Implementation already performed; historical publication pending

The maintained code in `scenario_pipeline/context_catalogue.py` now extracts explicit boolean `outside_business_district` from context or its `scene_assumptions` and maps it to `asm.way_outside_business_district` in fresh `declared_assumptions` and saved `RetainedContext`. It preserves explicit false, rejects malformed/nonboolean values, detects conflicting declarations, and does not default absence to false. Regression tests were added to `test_retained_context.py`. The retained-context suite (32 tests) and roadway-consolidation suite (12 tests) passed. A real local `61667fd0042d` first scene projected true in memory from hash-bound saved context with no outside-business conflict. These are code/fixture/example checks, not historical batch or full Core decode results. No accepted recording files were changed.

### External one-time repair plan

1. Pin the authoritative November 8 delivery roster and exact 11 law-127-3 recording IDs. Current local collection has 13 such records; do not substitute it for the historical scope. Preserve source/trace/manifest/Core/reading hashes and original labels/membership. Verify the consuming reading declares `asm.way_outside_business_district`; do not assume the local catalogue alone grants approval for every reading.
2. For each candidate, use the existing `Evidence` hash-bound readers to verify authored context, exact source syntax, recording identity and spatial/time scope. Implemented extraction accepts explicit booleans in context/scene_assumptions, not every nested `variable_assignments` wrapper. If a historical source exists only in another representation, explicitly establish equivalence and normalize it with external evidence-bound conversion tooling, or add a small reusable supported-source mapping if future acquisition needs it. Do not derive district status from map appearance, highway status, other-area labels, old `asm.business_district` omission or case names.
3. Reuse common reconstruction/export to stage corrected scenes. Export true or false only where its declaration applies. A whole-episode declaration can be repeated across applicable scenes; location-varying declarations need established frame/location scope and must not be broadcast blindly. Missing/conflicting declarations or existing trace values that contradict the source are blockers requiring resolution, not silent overwrites or default false. Inspect `RetainedContext` issues and fail the required-context gate even if decoding succeeds.
4. Validate every affected frame's assumption identity/value and source scope; check duplicate IDs and preserve unrelated assumptions, actor/device identities, measurements, geometry, timestamps and footage. Re-decode changed traces with the pinned Core/actual manifest and validate against the consuming declarations. Do not infer label changes or automatically inherit changed legal outcomes merely because a previously unknown premise is now present; use the existing source-backed classification/acceptance process for any separate warranted change.
5. Regenerate affected metadata, reports, index entries, hashes and receipts through the normal consistent-report pipeline. External one-time scripts/inventories/repair receipts store original and new values, evidence signatures and blockers. Hash-verify originals in the external backup/archive before replacing active outputs. Retain only final validated active versions, with no legacy output readers or duplicate copies in the delivery. Use maintained mapping/tests only; no migration-only modules in the repo.
6. Report converted, unchanged and blocked historical records separately and list all scenes actually checked. Fixture success and one local example do not establish all 11 repaired. No GPU simulation is required for this context projection; insufficient authored context requires a context decision, not a CARLA measurement.

### Remaining checks and future completeness

The shared mapping fix does not guarantee every capture path supplies the expected context structure or that every applicable premise has been authored. Check the actual fresh-capture integration and saved-path inputs through representative source-bound fixtures; direct helper tests alone do not prove all caller coverage. Require applicable supported legal premises to be explicitly authored with true/false and scope before future scenario acceptance, using existing profile/declaration gates. Do not generate all possible assumptions with false defaults: absent means unknown, and false is also a factual assertion requiring evidence. Unsupported or irrelevant premises are not blanket-required.

Section 4.5 now plans the district-union omission repair for 300-ft cases; do not claim the implemented 4.4 helper fixes that separate mapping. Any additional source-shape/caller gaps found during inventory must be fixed with minimal reusable logic and compact tests, while one-time conversion remains external. Completion inventory identifies code retained/removed, pinned historical results, unresolved contexts and external repair locations.

## 4.5 — explicit authored other-area semantics and district-union false

### Verified local evidence and agreed authoring decision

The following local recordings were checked for their saved authored district declaration:

| Recording prefix | Case |
|---|---|
| `0f83f046d9dd` | C245490-413-2-300-below |
| `acbaa8281c58` | C245490-413-2-300-at |
| `ead2302c8927` | C245490-413-2-300-above |
| `1ce516873ad4` | C329610-413-2-300-below |
| `87cc075d5d86` | C329610-413-2-300-at |
| `6c49b50c5d6d` | C329610-413-2-300-above |

Each local metadata record's `published_record.scene_assumptions` declares `district: other_area` with explicit synthetic-authoring provenance. Representative retained `evidence/delivery/evidence.json` also carries `legal_region_classification: other_area` and states its synthetic classification basis. These observations establish the authored category, not an independently measured statutory land-use finding. No explicit historical complement definition was found; existing tests deliberately omit a negative for bare other-area context. The user has now agreed to define the six cases' context explicitly as **neither business nor residential district throughout the recorded scenario**. Record this as a clarified/new authored synthetic stipulation, not as a falsely recovered historical measurement. Verify these local IDs against the pinned historical delivery before batch repair.

### Authoritative context and one shared final mapping

1. Preserve `district: other_area` in each case's authoritative scenario context and add an explicit definition, scope and provenance establishing neither business nor residential for the recorded scenario. Pin the exact normalized authored representation before implementation, using existing context/declaration facilities rather than a new subsystem. A bare unexplained string from an unrelated historical source is not sufficient negative proof. Future scenario authoring must use this defined final category or an explicit approved boolean premise, with scope.
2. Extend the small shared district mapping in `context_catalogue.py` for fresh `declared_assumptions`, saved `RetainedContext` and any active assumption-repair caller. Established business/residential union membership yields true; the explicitly defined neither-district category yields false. Unknown/missing/unresolved classification yields no fabricated boolean. Check all callers; do not implement a case-ID/law-specific exporter branch or duplicate classification logic. Coordinate the final source shape with capture-side context generation so future cases acquire the explicit meaning, not only the label.
3. Emit `['asm.way_within_business_or_residential_district', false]` in every scene where the six cases' declared context applies. Do not emit retired `asm.other_area`, nor substitute `asm.way_outside_business_district` for the combined premise. Being outside business alone does not exclude residential. Do not automatically add separate outside-business premises under this repair; that mapping remains source/contract scoped under 4.4.
4. Reject/report contradictory authored categories, explicit premise values and existing trace values; do not choose the value that makes a label pass. Existing true classification cannot silently become false from a weaker or unbound source. Verify whole-episode scope before broadcasting; if scope varies, use explicit source-bound intervals/locations. The absence of a context declaration remains unknown, never default false.

### Historical conversion, checks and final outputs

Use external one-time orchestration to normalize the agreed authored context and invoke maintained export/reconstruction on the six pinned originals. No duplicate Lean traces or GPU simulations are needed: the change supplies synthetic context, not a new physical execution. Preserve original footage, telemetry, actor/device IDs, timestamps, geometry and accepted membership. Archive original context/traces externally with verified hashes and record each before/after premise, declaration/provenance and scope in external migration receipts. Do not overwrite historical source evidence as though its original text already contained the clarified definition; bind the new authoring declaration to the exact recording/source signatures.

Stage corrected traces and regenerate affected authoritative metadata, READMEs, reports, coverage counts, indexes and hashes through the final shared pipeline. Validate every affected scene's value and scope, no duplicate/unapproved premise IDs, actual Core decode with the pinned manifest/reading and unchanged physical/media bytes. Review labels affected by changed applicability context under normal evidence-backed classification gates; do not silently inherit, invent or flip them. Keep only final validated active outputs after hash-verified external backup. All one-time conversion/normalization scripts, inventories, backups and migration receipts stay outside the repo. Keep only reusable final mapping/context generation and compact tests; remove obsolete true-only/legacy projection branches after caller migration.

Update existing compact tests that currently treat bare `other_area` as insufficient negative evidence to exercise the newly defined final representation: explicit established union true; explicitly defined other-area false; unspecified/ambiguous category unknown; conflicting declarations rejected/reported; fresh/saved parity and whole-episode scene coverage. Preserve tests against unsupported inference from names and missing data. Where historical source formats differ, normalize with external migration tooling rather than maintain backward-compatibility modes. Validate normal context/adapter suites and actual changed-trace decoding; no new testing framework or permanent migration module.

Completion lists exact historical IDs/scenes checked, normalization declaration/version, final false values, labels reviewed or unresolved, updated artifact hashes, removed obsolete code and external one-time-tool locations. This section is a plan: 4.4's 44 passing tests and sample projection do not prove 4.5 implemented or its historical traces repaired.

## 4.7 — intentional unsupported human direction; no implementation changes

Disposition: **no changes planned**. The audit reports `dev.human_direction` declared `absent`; this means unsupported acquisition, consistent with the established source-capability convention. It does not mean a verified observation that no officer is directing traffic. Omitted capability would likewise not supply such a negative. The audit's reported unknown result in stop-sign rules needing that exception is an expected evidence limitation, not sufficient proof of an exporter defect.

Keep the existing unsupported declaration and traces unchanged for this item. Do not implement human-direction detection, derive a zero inventory, add a false/no-officer assumption, fabricate a device, add inventory receipts or run GPU capture to satisfy 4.7. The earlier proposed inventory-based support extension is explicitly excluded from this plan. Current common-acquisition completeness requirements apply to supported applicable observations and must not turn this unsupported capability into an implicit required measurement.

Existing final-report generation should describe the capability limitation and possible dependent-rule unknowns consistently, without treating it as a missing supported measurement or claiming the exception false. No new reporting subsystem, migration tooling or dedicated runtime/test infrastructure is required for this disposition. Actual human-direction support requires a separate user-requested capability extension. This section is documentation of an intentional limitation, not a claim the consumer rule becomes decidable.

## 5.1 — source-backed ways recovery, exact local roster and conditional GPU work

### Investigation results and boundaries

External one-time investigation files, scripts and checksums are at `/pscratch/sd/m/msoroco/world-model-spec_back/operations/20261114-st-on-way-audit`. No accepted trace or source evidence was modified; no GPU simulation was run. Saved current `adapter_report.json` files identify 15 selected recordings with a required `st.on_way` gap, matching the audit's affected-law list. The current selection has 223 entries, 189 locally available trace files and 34 unavailable; selection-history inspection found no 189-entry snapshot. Do not claim the exact frozen November 8 delivery was reconstructed from that fact. Pin its transfer/index evidence before calling historical roster verification complete.

Using the maintained `atom_contract.observed` applicable kinds (lanes, roadways/subtypes, shoulders, crosswalks, stop lines, medians, intersections, bicycle paths), first scenes contain 133 missing ways associations in these 15 records. This does not reproduce the audit's 349-carrier aggregate: exact bytes, metric and all-frame behavior still need reconciliation. A broader local first-scene inventory also finds unrequired gaps in other recordings (including 450-2/250-4/307-6a); do not silently expand the pinned historical execution roster, but preserve these findings for the global law-independent coverage plan.

| Recording prefix | Case | Missing applicable regions in first scene | Current finding |
|---|---|---|---|
| `968996df2771` | C150916-220-1-compliant | 53 | Unresolved imported-map split source identities |
| `46d0a7663615` | C150916-220-1-violating | 53 | Unresolved imported-map split source identities |
| `cb6ec1a81f55` | C111294-250-1-compliant-attempt | 2 | Offline source-junction/way mapping demonstrated; coordinate 3.5 deduplication |
| `52dfdc83c2a4` | C111294-250-1-violating-attempt | 2 | Offline source-junction/way mapping demonstrated; coordinate 3.5 deduplication |
| `0819c0dc3305` | C124163-227-1-left-turn-permitted-crossing | 3 | Unresolved authored divider/common-way association |
| `7ba1ab4a7268` | C124163-227-1-left-turn-prohibited-section | 3 | Unresolved authored divider/common-way association |
| `4fec4346955e` | C80903-227-1-left-turn-permitted-crossing | 3 | Unresolved authored divider/common-way association |
| `fd59879343ed` | C80903-227-1-left-turn-prohibited-section | 3 | Unresolved authored divider/common-way association |
| `e251930ca4dd` | C124163-median-v1-227-1-through-opening | 3 | Unresolved authored divider/common-way association |
| `c36e1b502857` | C124163-median-v1-227-1-within-divider | 3 | Unresolved authored divider/common-way association |
| `52d9fa3a2c62` | C111294-yield-v1-250-1-no-yield | 1 | Unresolved authored/native junction geometry binding |
| `be743bdb0584` | C111294-yield-v1-250-1-yield | 1 | Unresolved authored/native junction geometry binding |
| `1626aa0d99ff` | C179819-review-posted30-v3-below | 1 | Offline native-road/station mapping demonstrated |
| `e97ed3e5b999` | C179819-review-posted30-v3-at | 1 | Offline native-road/station mapping demonstrated |
| `0d400a1c8b7f` | C179819-review-posted30-v3-above | 1 | Offline native-road/station mapping demonstrated |

Full IDs, missing structure IDs and evidence hashes are in the external inventory/recovery JSON files. Counts here are structures in one scene, not observations summed across frames or proof that every later scene is identical.

Source-bound `retained_static_inventory` plus `retained_map` was exercised on all 15 first scenes. Existing code recovered zero missing pairs; no hash-binding errors were reported for the source files used. This shows current code cannot directly repair them unchanged, not that CARLA must be rerun. Sources include original OpenDRIVE, configs, native map facts, executed construction/runner evidence and highway binding receipts.

- All three posted-speed records have missing roadway boundaries exactly equal to `control_portions.lane_portion` reconstructed from saved native road 1, lane -1, station interval 90–1000 m: zero Hausdorff distance and zero symmetric-difference area. Existing receipts bind native road 1 to highway region 1. This is an offline source-identity projection gap, not missing simulation data.
- For `cb6ec1a81f55` and `52dfdc83c2a4`, missing junction regions 19/26 match recorded native junction 10. Its OpenDRIVE incoming roads are 1,3,4,6; source-bound highway groups map them to regions 31 and 32. Mapping is demonstrable offline once the verified duplicate is canonicalized under 3.5. No nearest-junction guess is used.
- Imported-map 220-1 records include short split strips not recovered by current exact full-region/sample-interval matching. Retained analytic map data exist; investigate source interval/identity provenance and rounding/sampling rather than assume another execution supplies it. A projection limitation is not absence of a simulator observation.
- Six 227-1 records retain authored median polygons and physical divided-road context, but current receipts do not supply the missing median/common-public-way association. Trace the retained executed layout and approved way-group semantics. Do not assign a median to an arbitrary one of several existing native-road highways; a public-way grouping decision is not resolved by a GPU rerun.
- The two yield-v1 junctions did not match the recorded bounding-box comparison used in the bounded offline test. Inspect authored junction boundaries and topology for a source-backed identity mapping; the mismatch does not prove a different physical junction or require simulation.

### Lean permanent fix and historical staging

1. Reconcile the frozen report/trace scope and independently determine missing associations per required frame/entity. Keep all unresolved source identities explicit. Verify existing `ways` values too where a shared fix changes identity/grouping; do not merely pad missing lists.
2. Extend existing shared map projection minimally for verified source intervals, explicit authored control portions, canonical junction topology and evidence-backed divider/way groups. Start in `geometry.py:retained_map`, `partition_source_roads`, `match_regions`, `roadways.py:merge_highways`, `control_portions.py` and actual source writers. Preserve Native road/section/lane/station bindings at creation so future exports do not have to rediscover identity from geometry. Reuse existing source/report metadata and region remapping, not a parallel mapping framework. Canonical junction repair 3.5 and consumer association 3.6 must use consistent IDs.
3. Only assign ways supported by source identity/topology and approved authored groupings. Matching/proximity/containment alone is insufficient; topology and exact geometry can verify an already bound identity but must not invent one. Preserve legitimate multi-way junction membership, private exclusions, unresolved grouping and unsupported geometry. Missing highway polygon does not automatically mean its source identity is unknown.
4. Add compact regression coverage for exact authored speed portions, split source strips, duplicate/canonical junctions, divided-road grouping and ambiguity/conflicting evidence, including fresh/saved parity and idempotent remapping. Keep core validity and complete source checks in existing gates; use one-time all-frame inventory/benchmarks externally rather than new permanent services.
5. Stage corrected historical exports only when evidence supports them. Before replacement archive/hash-verify originals externally. Preserve footage/actors/timestamps/geometry/labels except separately approved evidence-backed repairs; regenerate trace/report/index/metadata hashes and decode changed traces with the pinned Core/manifest. Check every affected frame/reference, and actual Core `st.on_way` answers. Retain only final validated active outputs. Keep one-time inventory/conversion scripts, receipts and backup artifacts outside the repo; remove obsolete mappings/fallbacks after callers migrate.

### GPU decision and user authorization

The user authorizes conditional GPU simulation for this issue **if required simulator evidence cannot be recovered offline**. First classify every unresolved record: (a) existing-evidence projection fix, (b) authored public-way grouping/context decision, or (c) specifically identified missing simulator observation. An unchanged failed projector or unmatched geometry is not proof of (c). For (a), repair the common code offline; for (b), state the exact missing authoring/grouping decision rather than rerun CARLA.

Only (c) justifies targeted recapture: specify the missing observation and how validated common instrumentation will capture it, then run the accepted incompatible scenario once with project m5029_g, using the allocation's CPUs/GPU and relinquishing/renewing allocations as needed. No login-node GPU/CPU simulation, scenario tuning or automatic retries. Coordinate with the selective common capture batch so the same scenario is not unnecessarily rerun twice. Validate new execution, full source bindings, media and source-backed labels; do not assume its trajectory or acceptance equals the original. A capture cannot repair an undefined grouping convention. The unrelated paused demo-test campaign remains paused.

At this investigation checkpoint, five records have demonstrated first-scene offline recovery routes and ten remain unresolved. No specific observation has yet been shown unavailable and necessary, so no GPU allocation was requested. Do not advertise full recovery or complete historical repair until remaining identities and all-frame coverage pass. If evidence investigation establishes category (c), conditional recapture work is authorized as above; failures remain explicit and do not justify invented ways.

## 5.2 — directed approach enters-intersection recovery

### Contract, scope and evidence

Audit claim: missing `enters_intersection` on approach lanes in 49 recordings, based on report gap lists. Identify exact IDs against the pinned historical roster/reports and verify actual trace scenes before presenting that count as independently reproduced. Do not treat all lanes with no field as missing approaches: determine applicability from verified topology. Existing `st.lane_enters` defines an entry relation for a lane or supported directed approach carrier, at most one destination intersection per carrier. A whole two-way carrier reaching different junctions at opposite ends is not a single directed approach. This relation is distinct from `st.on_way`, lane connectivity and geometric overlap.

Inspect retained OpenDRIVE road/section/lane identities, junction connections, source-bound native waypoint/topology facts, actual authored approach bindings and their map hashes. Use original evidence readers without executing saved source or unpickling graphs. Planned routes alone do not establish map topology. Record missing versus conflicting/ambiguous source facts and any unknown approach scope explicitly.

### Minimal reusable projection and remapping

1. Locate existing `geometry.py:static_map` junction connection projection, `retained_map`, `match_regions`, `lane_segments`/`project_lane_segments`, adapter fresh/saved exports and region-reference remapping. Establish native carrier→junction identity before exporting its final region ID; do not rediscover topology from actor movement.
2. Recover verified associations offline using retained topology and established source-region bindings. Apply 3.5 canonical junction identity before final links, and coordinate 5.1/3.6 source maps so ways, intersection service and lane entry reference consistent objects. Preserve genuine junction components and do not attach one approach to all nearby component polygons.
3. Preserve association through verified lane subdivision: directed pieces retain the appropriate entry topology under the existing carrier contract; do not introduce arbitrary duplicate junctions or change physical geometry to make a match pass. Remap all references when replacing IDs. Resolve merged-carrier conflicts explicitly rather than retaining whichever value is processed last.
4. Do not infer entry from nearest intersection, region overlap, velocity/heading, case name or expected legal result. Where a whole two-direction carrier cannot identify one entrance, retain unknown with a reason or use an already justified directed representation under the existing contract. Do not automatically split every roadway or create unnecessary regions. Terminal/non-approach carriers must not be falsely counted as required missing approaches; applicability needs source proof.
5. Use one shared final projection across fresh capture and saved reconstruction. Remove obsolete/law-specific entry heuristics and stale code references after caller migration. Keep compact tests in existing geometry/adapter/Core suites: native connected approach, source-verified non-approach/terminal, two-end ambiguity, canonicalized junction, disconnected components, split/merge remapping and fresh/saved parity. Use actual Core accessor/query checks rather than Python-only replicas.

### Historical outputs and conditional GPU capture

Use one-time external inventory/conversion tooling to stage supported repairs. Preserve original source/traces with verified hashes in the external backup/archive. Verify all affected frame/carrier/junction references, at-most-one entry semantics, approach source scope and unchanged actor/timestamp/untargeted geometry/measurements. Re-decode changed traces with pinned Core/manifest; regenerate final metadata, reports, indexes and hashes. Retain only final validated active outputs, with external before/after identity receipts and explicit blockers. No migration-only modules or legacy compatibility branches in maintained source.

Classify remaining gaps as existing-evidence projection, topology/authoring ambiguity or specifically missing simulator observation. The first is fixed offline; the second needs a source/contract decision and is not solved by rerunning CARLA. For the third, add the exact missing native identity/topology observation to the consolidated per-recording acquisition profile before preflight. **Collect it in the same single GPU execution as all other planned requirements, never a separate 5.2 rerun.** Apply global allocated-resource, no-tuning/no-automatic-retry and full-profile completeness rules. No GPU need is established merely by the audit count or unchanged recovery failure.

Completion reports exact records/carriers/frames checked, offline corrections, evidence-bound source mappings, unresolved applicability/topology, conditional recapture needs, passed Core/source checks and external tooling locations. Current status is plan only; no 49-recording investigation, historical correction or simulation is claimed complete.

## 5.3 — stopping-reference identification and 35 cm estimated painted-line extent

### Final convention and meaning of no change

The user-selected fallback is a symmetric **0.35 m total-width polygon**, centred on the source stop-line reference: **0.175 m each side**, preserving its source-backed length/extent. Use only when a physical painted stop line and its reference geometry are verified but its width/outline is not measured. Preserve measured physical outlines unchanged when available, even if their width differs. This is an estimated outline, not new measured paint evidence and not a command to spawn/render paint in old videos. Do not confuse it with the 0.01 m total-width geometric centre-line method in 2.5 / 3.3.

If the existing correct stopping reference is a crosswalk or another supported boundary, leave that reference unchanged and add no stop-line polygon. No extra conversion is required merely because it determines a stopping place. However, if source evidence establishes an existing exported `stop_line` was actually a different reference, report and correct that misclassification/association explicitly; do not preserve a known erroneous object under a blanket no-change rule. Any such correction requires source proof and normal downstream validation. An unresolved reference branch stays unresolved; physical paint presence alone does not select the applicable branch of a rule.

### Local evidence already inspected

- `8b66dc711065`: saved video approach/holding frames visibly show transverse white approach paint near a stop sign; saved context names native StopLine object 1000 and endpoints as the candidate, but explicitly leaves the applicable legal branch unknown and unmarked-crosswalk geometry unavailable. Identity/camera association and branch evidence must be finalized before treating it as a validated stopping reference. Video appearance does not establish exact 35 cm width.
- `bf5ba06672dc`: saved approach video shows a transverse white stop bar before a crosswalk. Retained `scenario_geometry.json` identifies native StopLine 997, road 655, endpoint coordinates and effectively zero native width. Context describes a clearly marked-line branch but flags physical verification pending, so finalize source/approach/visual alignment rather than accept authored assertions alone.
- Prior 257 examples use constructed physical road-line meshes with retained transforms/body vertices; the 22 current exported rectangular outlines checked have 0.35 m width. They are distinct physical constructions, not proof all imported-map StopLine objects have that measured width.

These are bounded local checks, not verification of all 126 missing-width objects, all six historical recordings, every frame or exact metric width. Image inspection used saved videos only; no CARLA run or source modification occurred.

### Shared implementation and offline historical staging

1. Pin the affected historical roster and enumerate each missing-boundary stop-line ID, source map object/native road, coordinates/extent and approach entrance binding. Verify the applicable reference from retained source topology, construction and existing rule/case hierarchy; do not choose based on nearest mark, a convenient label or missing crosswalk metadata. If the branch is unresolved, preserve that uncertainty independently of geometric representation.
2. Establish paint presence and object identity from verified physical asset/geometry evidence or saved video aligned with the source object and approach. A native `StopLine` name, zero-width map object, control trigger or requested clearly-marked flag alone is insufficient evidence of rendered paint. Off-camera objects are not proven absent; missing evidence is explicitly blocked rather than automatically classified invisible or painted.
3. Preserve a verified measured boundary. Otherwise, for a verified painted line with established endpoints/polyline and unmeasured width, use one shared deterministic polygon helper with total width 0.35 m and half-width 0.175 m. Record caps, joins, coordinate conversion, sampling/simplification and endpoint-extent conventions. Validate actual serialized geometry with Core. Do not extend the known line length arbitrarily or use convex hulls bridging unsupported geometry. Reuse common geometry facilities from 2.5 / 3.3 without conflating method widths.
4. Update `entrance_geometry_fields`/reconstruction behavior so `_unobserved_paint_boundary` does not erase a supported final estimated polygon on every export. Replace that unconditional legacy behavior with this final evidence-gated shared convention, not parallel old/new modes. Inspect all fresh/saved paths and maintain source bindings consistently. Absence of verified paint/extent does not activate the fallback.
5. Declare the final geometry method as estimated in the supported shared manifest representation. Extend the existing geometry method description to cover both 1 cm centre-line buffers and 35 cm stop-line estimates where a path uses both; do not leave `estimate:mapped_geometry_with_centreline_buffer_1cm` as though it describes the new stop-line operation. Freeze an accurately named parser-supported final method before export, and retain per-region method/width/evidence through existing report structures. Measured outlines retain their measured provenance. No arbitrary Core keys, redundant trace geometry or new reporting subsystem.
6. Validate query consequences: the approach-facing edge is nominally 0.175 m before a centre reference on straight segments. Test actual Core distance, footprint overlap and stopping-offset behavior at edges/endpoints and keep line-centre versus boundary conventions explicit. Do not silently translate trajectories, stopping commands or labels to accommodate the strip. Regenerate geometry-dependent occupancy/completeness or receipts when affected, and review any source-backed classification changes through normal gates.
7. Run one-time historical inventory/conversion externally, preserving original evidence/context/traces in the hash-verified external backup/archive. Stage only supported geometry/reference corrections; retain videos, timestamps, actors and untargeted measurements. Re-decode changed traces with final Core/manifest, validate references/all-frame consistency, regenerate metadata/README/report/index/hash outputs and keep only final validated active versions. Unknown reference/paint cases remain explicit blockers, not silently dropped records or invented markings.

### GPU and lean-code constraints

The estimated polygons can be constructed offline from retained evidence; no simulation or duplicate recording is required for that operation. If a specific required observation of paint/reference/width is missing, determine a viable measurement method first. Any required GPU recapture must join the **same single integrated per-recording acquisition** as velocity, sight, steering and other requirements, after common preflight; no independent 5.3 rerun, automatic retries or scenario tuning. Do not add physical paint to a scenario merely to claim its original marking was measured. A separately requested physical marking change is a new construction requiring normal acceptance.

Keep only reusable evidence-gated geometry projection and compact tests in maintained source. One-time inspection/remapping/conversion scripts, inventories, backups and migration receipts stay outside the repo. Remove obsolete erasure/fallback branches and stale tests/docs after caller migration. Compact fixtures cover measured-outline preservation, verified-painted 0.35 m fallback, absent/unverified paint, correct crosswalk reference unchanged, proven misclassification reporting, source conflicts, fresh/saved parity, no later boundary erasure and actual Core boundary queries. Use existing suites and acceptance gates; no new framework.

Completion reports verified reference/paint cases, measured versus estimated polygons, unchanged alternative references, proven classification repairs, unresolved evidence and any integrated-capture needs. This is a plan only; neither all object identities nor historical outputs are repaired by the example checks.

## 5.4 — source-backed highway outline repair within existing Core

### Scope, findings and explicit constraint

Eight local selected recordings contain 24 highway regions missing boundary polygons in inspected first scenes:

| Recording prefixes | Cases | Missing highways per recording |
|---|---|---|
| `8b66dc711065`, `f82eb9859f57` | C111325-450-2 halt compliant/violating | 2 |
| `448b9e51002d`, `fdc101fc9070` | C111331-307-6a compliant/violating | 6 |
| `968996df2771`, `46d0a7663615` | C150916-220-1 compliant/violating | 2 |
| `71e2a17317ca`, `bf5ba06672dc` | C111277-250-4 halt/no-halt | 2 |

The six records outside 307-6a report missing merged outlines for road groups [13,14,15,16,22,466,467,933,934] and [18,19,20,21,254,255,875,876]. The 307-6a records report additional individual-road failures; original refactor evidence names crossing edge strips on native road 13. Exact per-shape causes and full historical artifact/frame equivalence still need investigation. Existing code omits unsupported boundaries rather than fabricate geometry; this does not establish that the source highway itself cannot be represented.

**Use the existing Core single-simple-polygon contract. Do not implement multipart/holed geometry fields, change Core's representation, introduce duplicate geometry formats or propose such an extension as an automatic fallback.** No actual-case demonstration has established that Core is insufficient. If construction remains invalid, investigate and report the specific source/algorithm failure. Do not reinterpret the lack of a passing exporter output as proof that a schema extension is required. Any future claim of Core insufficiency would require concrete source-backed demonstration and a separate user decision; it is outside this plan.

### Permanent shared-code repair: four concrete steps

1. **Reproduce and localize.** Resolve each missing region's native road IDs, lane sections, source map hash, lane-width/lane-offset polynomials, source geometry primitives, station intervals and verified continuation/grouping evidence. Reconstruct intermediate left/right sampled edges with their source stations in external investigation output. For road 13, locate the exact crossing edge pair and surrounding section/geometry transitions. Distinguish a wrong join, insufficient sampling, invalid source interpretation and truly unresolved data. Never infer a physical crossing solely from the generated perimeter.
2. **Fix edge generation and joins.** Work in existing `geometry.py:_static_map`/`reference`/`polynomial` and `roadways.py:merge_highways` as appropriate. Verify correct lane-section selection, width offsets relative to section starts, geometry station offsets, left/right designation, road direction and boundary traversal order. Include lane-section, geometry and relevant width/offset breakpoints, and refine locally where curvature/variation needs it. Verify joins from native endpoint/topology identity; handle verified numeric rounding under a documented tolerance. Do not select arbitrary diagonals, use generic buffer-zero/hull repair, or accept a visually plausible outline unsupported by source edges. Avoid globally densifying every road and increasing runtime unnecessarily.
3. **Build the highway's actual outer extent.** Include verified dividing space inside the same public-way boundary rather than require a drivable-surface union to encode a median as a hole. Current `merge_highways` already has a restricted divided-layout inclusion path; reuse/extend it only with source-backed grouping and edge evidence, not a blanket hull around nearby roads. Preserve medians/dividers as separate features, separate roadway identities and public/private exclusions. Remove internal seams and redundant vertices; keep one highway identity without recreating grade-carrying overlays or segment-object proliferation. Do not fill unrelated land, bridge unproved gaps, join different highways or delete physical distinctions to force a polygon. Unresolved outer-extent/grouping evidence is an explicit blocker, not permission to invent boundaries.
4. **Validate geometry, queries and cost.** Apply existing Core simple-polygon checks to exact serialized coordinates; compare output outer edges and intended divider inclusion with the bound source geometry under declared numeric/sampling tolerances. Validate highway occupancy/distance and reference consistency; recompute dependent receipts/answers where geometry changes. Use compact regression fixtures for reproduced failures and representative full-evaluator runtime checks against the former B1 object/vertex-cost concern. Keep runtime benchmarking one-time acceptance work; normal exports retain essential validity/completeness checks. No arbitrary vertex reduction beyond the accuracy convention and no new benchmark framework.

### Historical traces versus future recordings

The permanent fix belongs in the common map-construction/export path and must apply equally to fresh exports and retained reconstruction. Preserve native identities/station/source bindings at creation so future recordings do not require geometry-only rediscovery. Verify saved/fresh parity and idempotence. Required highway boundary failures must be explicit recording-profile acceptance failures, not silently treated as fully observed geometry. Source/method metadata must describe actual approximation and retained uncertainties.

Historical staging uses that same corrected production code through **one-time scripts outside the repo**. Pin the eight historical IDs/source signatures, hash-verify external backups, stage corrected polygons and necessary dependent occupancy/completeness results, validate all affected frames/references and actual Core decode, regenerate metadata/reports/indexes/hashes, and publish only final validated active outputs. Preserve original footage, actors, timestamps and untargeted measurements; any warranted label review follows existing evidence-backed gates, not automatic changes. Keep one-time diagnostics, conversion inventories, backups and migration receipts external. Remove obsolete construction branches, duplicate readers, unused tests and stale references after caller migration. No backward-compatibility layer or extra road objects solely for the repair.

No GPU simulation is required merely to reconstruct existing source-backed map geometry. Inventory retained evidence before making a per-recording decision. If a specific necessary simulator observation is genuinely missing, add it to the global complete acquisition profile and obtain it in the **same single coordinated run** as other requirements; validate the method before batch start. No separate 5.4 rerun, automatic retry, unrelated scenario tuning or physical geometry change. A still-unresolved source boundary is reported as blocked, not automatically a recapture or Core-extension request.

Completion must report cause and evidence for each omitted region, the shared construction changes, all-frame geometry/query/decode results, representative runtime evidence, unresolved cases, removed obsolete paths and external one-time-tool locations. First-scene inspection establishes the local 24 omissions, not successful repair or proof of every actual highway's representability. This section is a plan only.

## 5.5 — complete signal indications and law-independent observation coverage

### Scope and distinction from 4.3

Audit claim: 7,824 missing signal indications among 19,904 device-scenes in long 307-6a recordings `448b9e51002d` and `fdc101fc9070`. Independently enumerate affected device IDs/frame intervals from the pinned delivery before claiming those counts verified. Unlike the 4.3 helper argument gap, this issue concerns absent actual red/yellow/green/dark observations. A missing field or unknown source state is not Off/dark. Missing state may be an acquisition gap, source-frame/device join failure or exporter omission; establish which before repairing.

### Common acquisition/export correction

1. Inventory every applicable installed traffic-signal head and its recording/frame scope from source-bound native identities, spawn/despawn history and observed map/control inventory. Distinguish world signal heads from individual lamp colors. Trace source actor/device IDs into final device IDs, including position collisions/ambiguous bindings, across every recorded tick. Do not drop heads or narrow scope after readback failure.
2. Inspect retained same-execution signal/device state streams and their hashes, actor IDs and original frame/time joins. Use a verified stable identity join, not nearest position or a stale cached state. Recover supported actual readbacks offline through a small shared projection. Missing/Unknown/ambiguous readbacks remain explicit blockers; a command, intended phase, nearby light or prior frame is not evidence of the current display.
3. Upgrade common capture, where necessary, to read each required head's actual displayed state on the same tick as actor/motion observations. Export valid state consistently through fresh conversion, saved reconstruction, participant/control attachment and re-export. Retain real dark and repeated unchanged indications; no fabricated off, inferred color or carried-forward missing value. Define unsupported/ambiguous API states explicitly rather than silently coercing them to a color.
4. Remove law/required-atom gating that suppresses supported signal-state projection or acquisition. Inspect actual capture/source-packet selection and `repair_scene`/device projection paths: requiring `dev.traffic_signal` in a current-law dependency list must not decide whether a supported same-frame state is exported. Use the shared common acquisition/completeness profile, not per-law patches. Same evidence must yield the same device state across all paths.
5. Derive 4.3 operability only after state recovery, using verified installation/uncovered facts. A known valid color and a dark/uncovered classification are different from unknown state. Keep one maintained signal path; do not implement separate historical traffic-light pipelines for 4.3 and 5.5.
6. Require state completeness at every applicable required signal head/frame for final accepted outputs and future simulations. Missing, malformed or ambiguous values produce actionable capture/export failures with device/frame/source reasons and block full-profile acceptance; decoder success alone is insufficient. A scene with verified zero applicable signal heads needs no fabricated device/state, but an incomplete inventory is not proof of zero.

### Global future-run behavior: full supported set

Apply the same nonselective acquisition/export policy to **every atom/relation already designated for supported common coverage** in this handoff. A scenario's target law, current rule dependency list, expected label or family must not suppress an applicable supported observation. Attempt the full supported set on every fresh simulation and reconstruct/export all supported retained evidence. Preserve measured zero/false/off. Applicability and acquisition limitations remain truthful: pedestrians do not require vehicle controls/lamps, unsupported CARLA hand signals and human direction remain unsupported under agreed exceptions, and evidence-dependent geometry/inventories cannot be fabricated. Core-derived relations remain available through correct complete inputs/accessors instead of redundant all-pairs trace tables. Future capability additions must integrate the same shared profile and validation rather than a parallel per-law path.

### Historical repair, integrated recapture and lean completion

Stage offline recovered states using external one-time inspection/conversion tooling and the maintained common exporter. Preserve original evidence/traces externally with verified hashes. Check every changed device/frame and unaffected identities/timestamps/motion/media, actual Core decoding/accessors, dependent operability results and normal source/reference gates; regenerate final reports/metadata/README/index/hash outputs. Any label effect is reviewed under existing source-backed rules, not silently changed. Keep only final validated active recordings; no legacy compatibility modes or duplicate signal outputs.

If actual required same-frame readbacks cannot be recovered, identify exactly which observation was absent and validate the upgraded common instrumentation before capture. Add it to the consolidated profile and collect it in the **same one simulation per incompatible accepted scenario** as velocity, sight, steering, way/topology evidence and all other approved requirements. No separate 5.5 run, automatic retry, scenario tuning or recording of just the light field. Normal new-execution acceptance and labels must be verified. An unresolved source join should first be fixed offline rather than assumed to require simulation.

Keep reusable readback/join/projection logic and compact tests in existing modules/suites. Cover all supported colors and dark, missing/ambiguous state, conflicting IDs/frame joins, unchanged repeated values, projection for a law with no signal dependency, fresh/saved parity, zero-head inventory and full-profile failure. Remove obsolete selective branches, unused writers/tests and stale references after caller migration. Keep every one-time historical script/inventory/backup/receipt outside the repo. No new validator subsystem or migration module. Completion lists exact inspected device/frame gaps, offline fixes, remaining integrated-recapture requirements, source signatures and final validation results. This planning update does not verify the historical counts, change recordings or start GPU work.

## 5.6 — explicit device/governance applicability and historical link repair

### Device presence is not governance applicability

Identify the audit's exact 16 device IDs across six historical recordings and verify actual missing fields before reproducing the claim. The device applicability table in review notes section 5.6 is normative together with the explicit categories below. A device without applicable vehicle-region governance is **still recorded** with all supported observations when present. Do not omit it merely to avoid a missing-governance check. Conversely, unsupported capabilities are not newly acquired by this item (in particular 4.7 human direction remains unsupported with no changes planned).

| Category | Device/function | Capture/export policy | Governance policy |
|---|---|---|---|
| Required | Vehicular traffic signal, dark/inoperative included | Record every supported present head/state/scope | Source-established regulated approaches/lanes required. |
| Required | Lane-control signal | Record if supported/present | Controlled lanes required. |
| Required | Stop and yield signs | Record if supported/present | Regulated approaches required. |
| Required | Speed-limit signs | Record if supported/present | Applicable supported travel region/portion required. |
| Required | Regulatory signs | Record if supported/present | Applicable supported travel regions required. |
| Required | Regulatory zone signs | Record if supported/present | Source-backed regulated region(s) required. |
| Required | Speed-limit beacon | Record if supported/present | Use verified associated speed regulation's scope; no nearby-sign guess. |
| Required | Railway signal/gate | Record if supported/present | Regulated road approaches required. |
| Required when supported | Human traffic direction | Currently unsupported; preserve absence declaration | If separately supported later, directed approaches required; no extension now. |
| Required | Temporary control directing/restricting/closing traffic | Record if supported/present | Affected supported travel regions required. |
| No vehicle-governance requirement | Pedestrian signal | Record supported device/state; no new acquisition solely for this item | Do not assign crossed vehicle lanes as pedestrian governance. Current vehicle travel-region contract does not supply the pedestrian relation. |
| No governance requirement when purely warning | Crossing warning signal | Record supported device/state | Warning audience/facing direction does not itself establish control. |
| No governance requirement when purely warning/delineation | Temporary device or other existing supported advisory-only device/zone | Record supported observations | No forced lane relation unless its verified function also directs/restricts traffic. |
| Scope unresolved, no automatic requirement | School-bus-mounted signals | Record supported signals if present | No nearest-lane association; moving governance scope needs a separate contract and is not added here. |

Do not invent new warning-device kinds for this table. Classify regulatory versus warning-only function from source-backed device code/legend/control role; mixed-purpose cases with actual regulating function follow Required, and unresolved function is an explicit classification blocker rather than a convenient exemption. Do not erase a valid source-established relation simply because its kind appears in a No category; investigate its contract/role. These categories specify required acquisition/applicability, not a prohibition on all supported observed facts. No separate pedestrian/bus governance subsystem is authorized.

### Shared semantics, acquisition and repair

1. Implement one small applicability helper/policy in existing device/contract logic, shared by fresh capture, conversion, reconstruction and coverage. Maintain the table's distinctions in fixtures, not separate per-law or per-recording implementations. Required supported device observations and governance are attempted regardless of target law.
2. For Required devices establish stable native device/actor identity, actual governed lane/approach or regulatory portion IDs, source map/topology and scope. Inspect original control bindings and actual source evidence before deciding a missing relationship is an exporter omission versus acquisition failure. A required available observation not captured is a bug, not an exemption. Do not infer governance from position, proximity, physical containment, facing direction or intersection-service membership alone.
3. Reuse existing region remapping for lane subdivision, merge/canonical junction changes and final IDs. Keep lane-level governance and the separate `dev.serves_intersection` relation distinct; do not add a whole junction as a substitute for missing governed approaches. Do not use an arbitrary full lane if a verified longitudinal regulatory portion is the true scope.
4. Export supported known governed-region lists. Only complete evidence of an applicable empty relationship supports `governs: []`; unknown/partial evidence must not be presented as a complete empty or complete partial list under the existing semantics. Non-applicable and unsupported scope are report statuses, not invented Core fields or `[]` defaults. Required unresolved relationship blocks final profile completeness. Missing outside-scope governed lanes require an explicit scope/block decision, not a nearest included replacement.
5. Preserve dark/inoperative signal governance where the relation is verified; current light color does not determine lane assignment. Coordinate 4.3/5.5 state/operability repairs so they do not remove independent valid governance links.

### Historical staging and one integrated recapture

Recover verified existing bindings offline through the shared projector and fix lost writer/frame/region joins. Inventory any genuinely missing required simulator observation and validate common acquisition for it before capture. Add all such bindings to the same consolidated recording profile as every other issue; one execution collects everything together, with no separate governance rerun, automatic retries or scenario tuning. A capability/semantic scope question is not solved by GPU simulation. Use allocated resources and normal new-run acceptance if targeted capture is necessary.

Run historical triage/conversion via one-time external tools and preserve original evidence/trace/report hashes in the external backup/archive. Stage verified link corrections and applicability-aware coverage; validate every affected device/frame/region reference and actual Core governance queries/decode. Regenerate final metadata, reports, indexes and hashes without changing unrelated motion/media or automatically modifying labels. Keep final validated active outputs only. All one-time scripts/inventories/backups/receipts remain outside the repo. Maintained source contains only shared policy/projection and compact tests; remove obsolete selective branches, redundant helpers and stale references after caller migration.

Compact existing-suite fixtures cover required signal/sign links, warning-only/pedestrian/bus scope exceptions, mixed regulatory roles, source-backed versus nearest-lane bindings, known-empty versus unknown, dark heads retaining governance, remapped lanes and fresh/saved consistency. Do not add a validation framework. Completion lists exact devices inspected, applicability evidence, offline fixes, unresolved source/scope cases, integrated-capture needs and final hashes/tool locations. This is a plan only; the 16 devices have not yet been individually verified or repaired.

## 5.7 — explicit unconditional one-way legends and shared conditions projection

### Identified current entries and intended correction

| Recording prefix | Case | Device ID | Saved asset evidence |
|---|---|---|---|
| `968996df2771` | C150916-220-1-compliant | 4 | Native `SM_oneWayR_2502_SM_0` object |
| `46d0a7663615` | C150916-220-1-violating | 2 | Native `SM_oneWayR_2502_SM_0` object |
| `e3b7092ebb91` | C150916-one-way-v1-220-1-correct | 1 | `/Game/Carla/Static/TrafficSign/OneWay/SM_oneWayR.SM_oneWayR` |
| `d58b55994437` | C150916-one-way-v1-220-1-wrong | 1 | `/Game/Carla/Static/TrafficSign/OneWay/SM_oneWayR.SM_oneWayR` |

First-scene traces show regulatory-sign code `one_way` without conditions; `scenario_geometry.json` retains native object/asset identities and associations. The agreed correction is `conditions: {}` for all four once source-bound complete unconditional legend/assembly evidence is verified. Retained names alone have been inspected, not every rendered legend or possible supplementary plaque. Do not claim those additional checks already passed or quietly fill contradictory evidence. Verify full historical recording IDs against pinned delivery signatures.

### Permanent final mapping and future exports

1. Reuse existing sign-kind/legend projection to implement one small verified asset-to-legend mapping shared by fresh conversion, retained reconstruction and future capture/export. Bind full asset identity/version and actual device identity, code and assembly evidence. A known standard unconditional sign supplies `{}` without repeated per-instance manual interpretation once its complete assembly is established. Merely matching a filename substring is insufficient proof of no supplementary restriction.
2. For supported regulatory/zone signs: a verified complete unrestricted legend produces empty `conditions`; a verified restricted legend produces its actual supported hours/days/class/duration/etc.; unknown or conflicting legend/plaque evidence produces an explicit gap. Do not infer unconditional from omission, an uninterpreted asset, unknown supplementary plaques or a desired case label. Do not invent condition semantics from case names or actor motion.
3. Export supported conditions on every applicable device/frame regardless of target-law requirements. Preserve code, position, source device identity and governed regions. Maintain the existing conditions schema and decoder; do not add duplicate fields or broaden ordinary stop/yield signs into regulatory conditions requirements. Unsupported device capabilities remain unsupported rather than invented.
4. Retain normal source/method evidence and applicability-aware completeness reporting through existing facilities. Required supported legend gaps block a complete profile, not silently pass with `{}`. Known unconditional assets need only the shared validated mapping plus assembly/source checks, not a new repeated manual workflow or separate validation subsystem.

### Historical repair, tests and cleanup

Use one-time external scripts to invoke the maintained mapping/exporter for the four verified entries across their applicable frame intervals. Preserve originals and assembly/source hashes in the external backup/archive before replacing active artifacts. Stage explicit `{}` without changing other device facts, footage, motion, timestamps or accepted membership. Verify actual Core decoding and condition-query behavior, all-frame references and unchanged unrelated data; review any affected classification under existing source-backed gates rather than automatically changing labels. Regenerate final trace/report/metadata/README/index hashes consistently, then retain final validated active outputs only.

Keep reusable mapping/validation and compact tests in maintained source. Cover standard unconditional asset → `{}`, conditional legend → actual restrictions, unknown/supplementary/conflicting evidence → gap, unrelated stop/yield not given conditions, source identity mismatch, and fresh/saved parity independent of law. Remove obsolete condition writers/defaults, duplicate mappings, unused helpers and stale references after caller migration. All one-time historical correction scripts, inventories, backups and migration receipts remain outside the repo; no legacy-format compatibility or new migration framework.

No GPU simulation is expected if saved asset/legend assembly evidence suffices. If a specifically necessary observation is absent, state it and obtain it only within the single coordinated per-recording acquisition profile after common preflight, alongside all other requirements—not a separate sign rerun. Do not resimulate merely because an exporter omitted an available known legend. Completion distinguishes verified asset/assembly facts, corrected devices/frames, final query/decode checks and any evidence blockers. This section is plan only, not completed 5.7 code or historical repair.

## 5.8 — intentionally unused brake lamps; no changes planned

User disposition: brake lamps were intentionally unused/not enabled in these recordings. Preserve the delivered measured lamp values and distinguish lamp flags from service-brake commands and physical deceleration. The audit's false-while-braking observation is not an instruction to synthesize brake lamps or modify the controller.

**No 5.8 implementation, scenario/controller, historical trace/label or GPU work is planned.** Do not create repair scripts, migration modules or a new lamp-control subsystem for this item. Document intentional lamp non-use in existing final reporting without claiming the audit's 186-recording/70,531-observation counts have been independently reproduced. Do not infer rendered lamp state or complete readback provenance solely from this disposition; missing actual measurements must not become false defaults. General future common capture/export policy continues to retain actual supported light flags on every applicable path, independently of brake commands and target law.

## 5.9 — measured scenario events and sufficient capture windows

### Verify actual evidence before selecting a repair

Audit claims: 253 has 42.7 m of recorded approach against 300 ft (91.44 m); six C245490 413-2 cases have no course change with maximum heading change 6.1 degrees. Pin exact recording IDs, original versus delivered windows, source hashes and case definitions before reproducing those conclusions. No independent whole-case verification has yet occurred for this item.

For 253, establish the case/rule's intended approach/signal observation requirement, applicable context and actual road/path distance convention. Inspect complete original positions, continuous measured indicator states and observed maneuver onset. Determine whether recording began too late, delivery was cropped, or the audit counted a different interval. Do not demand a visible activation transition if an already-on signal and sufficient observed continuity satisfy the stated test; do not infer unrecorded prehistory from its first on sample.

For the six 413-2 cases, inspect complete source trajectories, heading/course, timing and video against the authored maneuver. Distinguish actual course change from steering requests, planned routes or noisy heading. Inspect whether vehicle heading versus travel direction is appropriate to the declared test, and handle low-speed/invalid observations. Do not treat 6.1 degrees or any other universal angle as a fixed legal maneuver threshold. Declare case-specific observed onset/completion criteria and their uncertainty without inventing legal standards.

### Conditional action after verification

| Finding | Required action |
|---|---|
| Required event/approach exists in original capture but delivery omitted it | Re-export the required contiguous interval with consistent video, trace, frame/time mapping and source provenance; no new simulation. |
| Event exists and delivered data suffice, but detector/report is wrong | Fix the existing shared event/coverage check and regenerate affected reports/receipts, preserving actual measurements. |
| Required event never occurred or source window lacks required coverage | Mark unsuitable/incomplete for its stated purpose; prepare evidence-backed controller/window repair separately before coordinated recapture. Do not claim extraction alone repairs it. |
| Evidence cannot establish the event or window | Report exact source gap; recover retained evidence first, then add genuinely required acquisition to the integrated profile. |

Offline re-export must not invent source frames or extend a trace using unmatched footage; bind actual timestamps and observation streams throughout. If extending the recording window changes labels/assumptions/scope validity, review them under normal evidence-backed gates. Preserve source data and distinguish expected intent from observed result. No automatic relabeling to make the requested scenario appear successful.

### Shared acceptance and integrated recapture

Use existing maneuver/recording acceptance facilities to add compact measured case-purpose checks: sufficient approach coverage, supported signal continuity, actual intended maneuver onset/completion and aligned full-window trace/media. Validate those checks on representative saved fixtures before batch execution. No new event-detection framework or general full-collection legal evaluation. Checks are independent of whether the exporter currently needs those fields for a particular law; the common acquisition profile remains complete.

Controller/window changes are not covered by the unchanged-scenario conversion batch. Identify affected scenarios and define the corrected final controller/window in a separately scoped repair plan before scheduling them. Preserve approved targets/maps/physical meaning and make any behavior change explicit; no iterative scenario tuning or automatic retries during the batch. Once repairs and common instrumentation are ready, a future separately authorized execution runs that scenario **once**, capturing the required event/window and all velocity/sight/steering/device/geometry evidence together. No separate 5.9 simulation or rerun merely to collect another field. New execution must pass full-profile, physical/media/source and label acceptance rather than inherit original acceptance.

Keep reusable coverage/event checks and compact tests in maintained modules. Keep all one-time historical inspection, case triage, interval re-export and repair orchestration scripts/inventories/receipts outside the repo. Preserve originals externally with verified hashes; stage corrected outputs, actual Core decode and all-frame reference/source/media checks, regenerate metadata/README/report/index hashes and retain only final validated active outputs. Remove obsolete incorrect detector branches and stale references after caller migration; no legacy duplicate output or migration-only modules.

Completion lists exact records/windows inspected, measured event findings, offline crop/report corrections, separately scoped scenario-repair candidates, integrated-capture needs, final acceptance results and external tooling locations. Do not claim historical audit counts or event absence verified by merely adding the plan. No code, historical recording or GPU execution changes are performed by this documentation update.

## Common capture upgrade and optional single-attempt rerun

The global integrated-recapture rule above governs this phase: one consolidated profile and one execution per recording across all issues, never a batch per missing atom.

This is a separate planned execution phase, not a prerequisite for every offline fix. For velocity migration, section 2.6 takes precedence: convert compatible originals first and rerun only accepted incompatible scenarios once; do not rerun the entire roster by default. First recover existing evidence. A future GPU batch is **one attempt per selected accepted scenario version**, reusing its construction/controller/map/assets/configuration and recorded seeds. Upgrade common instrumentation/export first; unchanged capture commands may repeat old omissions. No scenario tuning, geometry changes, missing-feature additions, automatic retries or case-by-case debugging during that batch. Preserve failed/partial outputs and report them.

| Data to acquire in the one attempt | Planned atom support | Limit |
|---|---|---|
| Every live actor’s identity, blueprint/attributes, transforms, body vertices, 3D velocity/acceleration and time | Supported `ru.*`; `kin.time`, position, heading, extent, velocity, speed, accel_longitudinal | New runs are new recordings; no assumption of identical trajectories or inherited labels. |
| Angular velocity plus timestamped poses/headings | Supported `kin.yaw_rate`, `kin.path_length` with declared methods | Gaps/unsupported conversion remain unknown; enforce sign/units. |
| Supported applied controls plus same-frame front-left/front-right wheel readbacks (single front on validated two-wheel vehicles) | Throttle, service/parking brake; representative steer angle per section 1.6; gear only with an appropriate readback | Retain raw angles/method; both pair members required. No front-left fallback, command substitution or silent error; no vehicle controls required on walkers. |
| Original same-frame vehicle light flags | Supported turn indicator, hazard, brake/position/reverse lamp, headlamp | Do not infer physical lamp rendering or supply unsupported hand/audio observations. |
| Running map/OpenDRIVE, local lane samples/topology, actual device identities/states and affected lanes | Supported lane/road/region and device atoms/associations | No complete geometry, paint, governance or physical-object inventory guarantee merely from a rerun. |
| Source weather and supplied calendar metadata | Supported scene `env.*` measurements/declared estimates | No invented atmosphere-distance, ice, authority or district facts. |
| Bodies, geometry and separately validated collision/visibility instrumentation | Supported geometric relations and occupancy; visibility/sight only under validated methods | Ordinary telemetry alone does not supply sight. The dedicated sight-distance update requires complete applicable sight-distance acquisition; all-pairs visibility, other sight atoms and complete occupancy remain separate evidence requirements. |

Provide geometric queries through the existing Core accessors rather than serializing redundant pair tables unnecessarily: centre distance, surface gap, longitudinal overlap, bearing, same direction, oncoming, and lane-based ordering when its additional evidence is available. Pairwise occupancy needs section 1.1; contact must not silently substitute planar overlap for measured 3D collision. The sight-distance update above authorizes the smallest shared sight-measurement change needed for its mandatory profile; no unrelated physical features or human-gesture acquisition are included.

Before an optional batch, run common capture/export CPU fixture checks. During it, automatically verify frame counts, identity/time joins, source completeness, decode and per-field coverage. Report failures rather than declaring them accepted. “No debugging during the batch” is an execution constraint, not a promise of complete measurements or successful recertification. Simulations remain paused until separately requested.

## Verification, staging and acceptance

### Test execution starting points

Use the repository’s available environment/toolchain; these are CPU commands to run during implementation, not results already obtained. Inspect tests for live dependencies and keep this phase fixture-only.

```bash
# world-model-spec root; PYTHONPATH includes scenario_pipeline
PYTHONPATH=scenario_pipeline envs/scenario-processing-py311/bin/python -m unittest discover -s scenario_pipeline/tests -p 'test_traffic_spec_adapter.py'
PYTHONPATH=scenario_pipeline envs/scenario-processing-py311/bin/python -m unittest discover -s scenario_pipeline/tests -p 'test_signal_observation_contract.py'
PYTHONPATH=scenario_pipeline envs/scenario-processing-py311/bin/python -m unittest discover -s scenario_pipeline/tests -p 'test_native_control_observations.py'
PYTHONPATH=scenario_pipeline envs/scenario-processing-py311/bin/python -m unittest discover -s scenario_pipeline/tests -p 'test_pipeline_capture.py'
# traffic-spec-agent/library
lake build TrafficSpecTests
# traffic-spec-agent root: verify generated ontology consistency
python -m scripts.gen_ontology --check
```

Add O/A/C/F/K/S/R/L/G fixtures to the relevant existing suites; also test conversion/reconstruction round trips and all supported export paths. Core `#guard`/decode tests must exercise the actual accessors, not Python replicas of their logic. Update maintained full/train Core variants consistently under the existing split workflow. Do not hand-edit generated ontology constructors to satisfy fixtures.

### Batch validation and deliverables

| Deliverable / check | Acceptance criterion |
|---|---|
| Pinned baseline | Exact selected recording roster, input/source/manifest/Core hashes and original labels/selection hashes retained. Historical versus current examples clearly distinguished. |
| Shared fixes | Reusable exporter/classification/inventory logic and required Core occupancy change; no recording-ID/law-specific patches. |
| Semantic tests | O/A/C/F/K/S/R/L/G expectations pass in actual Core and adapter paths. Intentional partial-occupancy changes are explicit; complete-list consumers never receive incomplete lists as complete. |
| Staged exports | Every selected input is either exported with a source-bound report or explicitly blocked with a reason. No silent skips, invented facts or changes to original captures/membership. Label/flag changes require section 1.8 / 2.1 evidence and before/after receipts. |
| Content invariants | Actor identities, frame/timestamps, geometry and measurements not targeted by an evidence-supported correction remain unchanged. Every intended change has before/after values and source proof. |
| Decoding and references | Every changed trace is decoded with the pinned updated Core and its actual manifest. Reuse an old receipt only for identical trace/manifest/decoder bytes. References, finite numbers and admitted atom IDs pass. |
| Capability/applicability report | Counts by atom, path, entity kind and frame distinguish known values, known negatives, unknowns, unsupported acquisition, non-applicable cases and export bugs. Partial/complete occupancy counts are separate. |
| Class/kind consistency | No evidence-resolvable class unknowns; no mask contradicts a verified kind; same evidence yields the same result across paths. Remaining specialized/physical-inventory gaps have explicit reasons. |
| Steering convention/completeness | New exports use versioned mean/single-front methods with required raw wheel evidence at every required vehicle/frame. Legacy front-left values remain identified and are never silently relabelled. Every missing required wheel produces an explicit incomplete result. |
| Aggregate reports and cleanup | Section 1.7 R1–R10 pass. One indexed current generation matches pinned delivery and declared evidence inputs. All superseded generated reports are externally archived/hash-verified and removed from active outputs/package; obsolete generators, fallbacks and links are removed. Hand-signal omission remains valid. Decode success does not prove full coverage. |
| Label consistency and repair | L1–L9 pass; one versioned label authority drives metadata/README/indexes, processing limitations remain separate, and historical corrections have external provenance. No one-time repair code remains in maintained source. |
| Polygon validity and performance | G1–G10 pass under the agreed representation and frozen accuracy/runtime profile. Actual serialized polygons pass Core; no tiny-region proliferation, unsupported width claims or point-distance fallback. Historical dependent receipts are regenerated. |
| Global code cleanliness | Global implementation constraint satisfied across every changed component; caller/reference checks pass, obsolete implementations are removed, necessary compatibility is justified, and all one-time repair tooling/artifacts are external. Cleanup inventory supplied. |
| Final velocity migration | Section 2.6 complete: horizontal velocity/speed and measured vertical component accessible in final Lean format; convert originals first, only incompatible accepted scenarios rerun once, every required sample present, normal acceptance passed, final-only active outputs and no legacy compatibility/one-time code. Unresolved entries block completion. |
| Indicator evidence and suitability | Section 2.7 triage completed with source-bound findings; wrong exports repaired, genuine suitable behavior retained, and missing-evidence/controller-repair cases explicitly blocked or separately validated. No fabricated states or controller changes hidden in unchanged-scenario batch. |
| Requirement atom IDs | Every emitted required-atom ID belongs to the pinned ontology; invalid generators/mappings are removed, historical reports/totals regenerated, unresolved semantic needs remain explicit, and one-time correction tooling stays external. |
| Junction identity | Verified duplicate source components map to one canonical ID across fresh/saved paths; legitimate separate junctions/components remain separate, all references validate, historical tooling/receipts are external and final active outputs contain no proven duplicates. |
| Universal sight/common coverage | `estimate:vehicle_reference_geometry` is declared and supported by actual acquisition; every required ego road-location/frame has validated sight distance independently of target law. Other designated common atoms obey the same applicability/capability-aware rule. Failed coverage blocks completion; one-time tooling remains external. |
| Device governance/service | Lane governance preserved; separate intersection association uses the new atom contract and verified source bindings; containment derived from geometry without redundant output. Canonical references validate, blocked evidence is explicit and no blanket GPU rerun occurs. |
| Signal operability | All call paths pass verified uncovered evidence under the installed-head contract; source-backed positive/negative values survive projection, conflicts/missing evidence block required coverage, final method metadata and historical hashes are regenerated with external one-time tooling. |
| Historical district premises | Exact historical roster verified, source-supported values projected with scope, no default false or ignored conflicts, changed traces decoded and reports/hashes regenerated. Code-test success is distinguished from completed historical publication. |
| Other-area district context | Six pinned cases explicitly stipulate neither district; final common mapping exports combined premise false in every scoped scene. No retired other-area atom/default false, trace duplication or GPU rerun; context provenance, decode, reports and external migration receipts verified. |
| Way membership recovery | Frozen scope/count reconciled; source-backed associations validated across required frames, unresolved grouping distinguished from missing observations, only demonstrated missing simulator evidence triggers targeted GPU recapture. External tooling and final-only publication rules apply. |
| Integrated GPU acquisition | One consolidated per-recording profile covers all approved GPU-obtainable requirements before batch start; one execution collects them together. No per-issue reruns, silent profile narrowing or automatic retries; full-profile completeness validated. |
| Approach entry topology | Exact 5.2 scope/applicability verified, source-backed carrier/junction associations survive canonicalization/subdivision, all-frame references and Core queries pass; unresolved topology is explicit and any genuine missing acquisition joins the integrated one-attempt profile. |
| Stop-line geometry/reference | Verified measured outlines preserved; supported painted-line fallback is 0.35 m total width with truthful method metadata and Core query validation. Correct alternative references unchanged; wrong classification corrected only with source proof. One-time tools external; any required recapture integrated. |
| Highway boundary construction | Shared current/future exporter fixes source edges/joins and verified outer extent within existing Core; no representation extension or road-object proliferation. Required final outlines pass Core/source/query/runtime checks; unresolved construction blocks acceptance and one-time tools remain external. |
| Full signal/common coverage | Every required signal head/frame has source-backed state across all export paths regardless of law; operability derived afterward. All designated supported applicable observations obey the same nonselective profile, with missing required evidence blocking acceptance and any recapture integrated once. |
| Device governance applicability | Required device kinds have source-backed links; supported non-governing devices remain recorded with explicit applicability reasons, no fabricated empty/nearest-lane relation. All-frame Core/reference checks and shared fresh/saved policy pass; one-time tooling external. |
| Regulatory conditions | Four verified standard one-way assemblies export `{}` consistently; shared final mapping handles known restrictions and unknown legends honestly on every path. Source/assembly, Core query/decode and final hashes validate; one-time tooling external. |
| Event/window coverage | Pinned 5.9 cases verified against full source capture; cropped evidence/detectors repaired offline, unsuitable scenarios explicitly separated for pre-batch repair. Measured purpose-specific acceptance and any integrated recapture validate new evidence/labels without automatic retries. |
| Handoff result | Code/test summary, source signatures, staged paths, per-item outcomes, unresolved evidence list and precise resume instructions. No claim that all other audit items or the paused simulation campaign are complete. |

No new saved recording becomes accepted solely because these checks pass. Retain the normal recording/case/physical/media acceptance gates for any later publication or new capture.

## Local examples inspected (not historical aggregate verification)

| Recording prefix | Inspected observation | Use |
|---|---|---|
| `8b66dc711065` | First scene: one actor, three occupancy pairs, empty completeness list, missing stop-line/highway boundaries; basic class masks unresolved. Saved construction selects Tesla Model 3, but classification still requires binding that intended actor to the actual recording. | O1/O6 and C1 evidence investigation; not proof all historical pairs are valid. |
| `cc58ed7ec5ab` | Comparable cell’s first scene has longitudinal acceleration and fewer unnecessary basic-class masks. | Cross-path comparison, not a requirement for identical actual vehicles/values. |
| `ae1b4c888fbd` | Current local tracks 35–42 are pedestrians without car-light blocks; motor vehicles have the six exported lamp fields. | Applicability fixture F1; historical delivery byte differences remain to be checked. |
| `0819c0dc3305` | First subject observation lacks steer_angle despite subject capability; saved first motion row has a steering command but no wheel-angle readback. | S7 source investigation; all 672 frames and all 50 cited recordings have not been independently checked. |
| `d58b55994437` | one_way_roadway has roadway in `unobserved_kinds`. | K1 only after source verifies the positive kind. |
| `f80d9ccb8e95` | Four structures retain centre-line/obstruction masks; its two exported lane vectors point the same way. | Inventory/source investigation; no complete physical absence proof was established in this review. |

The audit’s 50-recording, 77,228-user-scene and other aggregate counts remain audit claims until independently rerun against its frozen delivery. Never present these local first-frame checks as whole-delivery validation.
