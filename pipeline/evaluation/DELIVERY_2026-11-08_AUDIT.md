# Audit of the 2026-11-08 demo-train delivery

For: the data producer. From: the WorldModelSpec pipeline team, 2026-11-11.

**Scope:**
- the delivery `demo-train-20261108T223214Z`: 329 ZIP parts, 189 accepted demo-train recordings;
- your response `DATA_ISSUES_FOR_MAURICIO_2026-11-05_concise_response.md`.

**Method:** every count was taken by a script on the delivered files. All 189 traces, manifests and
adapter reports match the sha256 in their `metadata.json`. All 189 traces decode and are admitted
by Core. Recording ids are given by their first 12 hex digits. "Example" names the smallest case
that shows the issue.

**Contract we check against:** the pipeline's ontology (`ATOMS_train.md`) and Core's decoder are
authoritative. In short: a trace carries every atom the parser can produce, for every entity in the
scene, whatever law the recording is labelled for. The manifest lists that parser's capability: one
parser or export path, one manifest. A field may be omitted in three cases only:
- the parser cannot produce it, and the manifest says `absent` or `estimate`;
- the ontology gives the entity no value;
- the value is genuinely unknown, marked with `unobserved_*`.

A membership known to be false is never marked unknown.

Before the issues, one note on the transfer. `package-index.json` arrived with mode 600 (readable
only by its owner), so we could not run `restore.py`. We rebuilt the chunked files from
`.transfer-chunks/` instead, and kept a file only if its sha256 matched the one in `metadata.json`.
Please make the index group-readable for the next delivery.

---

## 1. The delivery contradicts itself

| # | Issue | Count | Example | Request |
|---|---|---|---|---|
| 1.1 | `occupancy_observed` is `[]` in every scene, yet `occupies` pairs are written, so Core reads `rel.occupies` as unknown for every road user | 8 recordings (450-2 ×2, 307-6a ×2, 220-1 ×2, 250-4 ×2), 4,846 scenes, 30,386 pairs ignored. The other 181 recordings list every road user in every scene | 450-2 `8b66dc711065`: 629 scenes, 6,078 pairs, no user observed | Declare occupancy observed wherever the pairs are computed |
| 1.2 | The same field is present or absent depending on the scenario family, even within one law and one cell | `kin.accel_longitudinal` (declared `exact`) is missing in 50 recordings. It is missing in whole families C245490 and C329610 across 223-1b, 413-2, 600-1e, 400-2a/b. In six cells the "attempt" or "compliant/violating" recordings lack it while the "-v1" recordings have it: 450-2 C111325, 307-6a C111331, 220-1 C150916, 113-2 C110763, 250-1 C111294, 227-1 C124163 | 450-2 C111325: `halt-compliant-attempt` has no acceleration, `crosswalk-v1-450-2-stop` has it | Write every capable field in every export path, or give the paths separate manifests |
| 1.3 | Vehicle class masks differ by family within one cell | 50 recordings, 77,228 user-scenes | 450-2 C111325: `cc58ed7ec5ab` clears `pedestrian, child, bicycle, motorcycle, bus, truck` on a car; `8b66dc711065` track 24 lists all of them as unobserved | See 3.1 |
| 1.4 | Declared `exact` (or observed) but missing | `sig` block missing on 26,400 user-scenes (600-1a, 10 recordings); `classes: null` on 13,200 user-scenes (600-1a, 6); lane markings missing on 6,071 left and 5,848 right lane blocks (18 recordings, mostly the imported maps of 220-1, 250-4, 450-2); lane direction missing on 202 and width on 20 lane blocks; 152 structures without a boundary (126 stop lines, 24 highways, 2 sidewalks) while `st.region_geometry` is observed | 600-1a `ae1b4c888fbd` tracks 35–42: no `sig` at all | Supply the values, or declare the atom `absent` or `estimate` for that source |
| 1.5 | Declared observed, yet listed `unobserved` on (nearly) every structure | 31 recordings; `st.obstruction` on 446 structures in 17 recordings; `st.roadway` (`exact`) on 32 structures in 4 | 413-2 `f80d9ccb8e95`: `centre_line` and `obstruction` unobserved on all 4 structures of a map that has neither. 220-1 `d58b55994437`: `roadway` unobserved even on a `one_way_roadway`, whose kind refines roadway | Clear marks wherever a generated map's inventory is complete |
| 1.6 | Declared `subject`, yet absent for the subject | `kin.steer_angle`: the same 50 recordings as 1.2 | 227-1 `0819c0dc3305`: 672 scenes, no steer angle | Supply it, or declare it `absent` |
| 1.7 | Shared files disagree with the traces or with each other | (a) `atom-coverage.json` reports `demo_train: 0` for all 54 atoms, while the same file's `required_lane_coverage` reports 82/10/10/27. (b) `road-access.json` lists all 189 recordings, but only 124 traces carry `asm.public_highway`. (c) `acquisition-methods.json` lists `sig.hand_signal` as `absent`, while the manifest does not list it at all. (d) `scope.json` names 27 cells, 9 of which have no recording in `recordings.csv`. (e) A report calls the `lane_control_signal` inventory complete and lists the same atom as a required-field gap | — | Regenerate these from the delivered traces |
| 1.8 | A law README contradicts its metadata | 3 recordings | 257-2 `stopping-reference-v1-0001…0003`: the README says "Unresolved (judgment call)", while `metadata.json` says `judgment_sweep: false`, `expected_label: inconclusive` | Make the two agree |

## 2. The data contradicts the response

| # | Response says | Data shows | Request |
|---|---|---|---|
| 2.1 | "Labels and judgment flags are preserved" (D) | No label changed, but **37 `judgment_sweep` flags went from `true` to `false`**: 413-2 ×15, 227-1 ×8, 450-2 ×4, 223-1b ×3, 257-2 ×3, 250-4 ×2, 407 ×2. The flag now nearly equals "has no label": of the 107 recordings without a verdict (null or `inconclusive`), 104 are `true` and 3 are `false`; of the 82 with a verdict, 81 are `false`. The exception is 257-1 `stop-action-v1-0001`, labelled `violation` with the flag `true` | State what `judgment_sweep` means now and what rule set it. We need "the label depends on an open statutory word whose threshold the pipeline chooses", for example "near the crest" or "with safety", as distinct from "no label" |
| 2.2 | A3: masks are kept only where the inventory is incomplete; `child` is cleared when pedestrian is observed false | 1.3 and 1.5: known-false memberships are masked on generated maps | Apply A3 in every export path |
| 2.3 | "Occupancy still uses the complete measured union when available" | 1.1: the union is written but declared unobserved in 8 recordings | — |
| 2.4 | B4: "one canonical source capability manifest … represents acquisition paths" | 1.2, 1.4, 1.6: two export paths with different capabilities share one manifest that declares `exact` | One manifest per export path, or equal capability |
| 2.5 | Verification: "valid representable boundaries" | Core rejects 96 of 110 crosswalk boundaries (6 recordings: the first vertex is repeated as the last, so the ring touches itself) and 544 of 638 centre lines (426 zero-area, 118 self-touching) as polygons | See 3.3 |
| 2.6 | B5: "all 68,198 planar-norm differences are accounted for by retained vertical velocity" | No delivered field carries a vertical velocity, so this cannot be checked. Over all 189 recordings, 593 user-scenes have speed more than 0.1 m/s above the planar norm, 448 of them with planar velocity exactly 0, in recordings of 13 laws. Example: `64594c77e2ae` (113-2), ego, speed 0.49, 0.98 and 1.47 m/s at 50, 100 and 150 ms, which is 9.8 m/s² × t | Recompute speed as the planar norm, or deliver the vertical component |
| 2.7 | A1: turn-indicator values are measured light flags | The ego shows `left` in every frame of 227-1 ×8 and 253 ×9, from the first frame to the last: long before the turn and after it is completed (every one of these 17 egos does turn left, by 88–181°). In 413-2 and 223-1b, by contrast, the indicator switches on during the recording | Confirm these are measured. A blinker set at spawn would make "signalled in time" true by construction |

Checked and found to hold: the three 253 plan-expiry times (13.8, 28.7, 20.7 s); the
`229e5896ffbd` curved-lane partition; the 22/443 split of stop lines with and without area; one
shared manifest (v11); highway regions in every recording; non-ego yaw rate on every user; removal
of the three shortcut assumption ids.

## 3. The data does not meet the contract, or names atoms that do not exist

| # | Issue | Count | Example | Request |
|---|---|---|---|---|
| 3.1 | A known-false membership is marked unknown: a CARLA vehicle actor lists `pedestrian, child, bicycle, motorcycle, bus, truck` among 20 unobserved classes. Core then reads "is a pedestrian" as unknown for that car, so any yield-to-pedestrian reading is unknown | 77,228 user-scenes, 50 recordings | 223-1b `010f0658528b` track 57, t = 50 ms | Clear every class the vehicle blueprint decides |
| 3.2 | **Reports name atoms that are not in the ontology** | `ru.animal` in the required atoms of 10 adapter reports (600-1a); `drv.wrong_way` in 2 (220-1), with a "required field gap" of 175 | 220-1 report: `reconstruction.required_atoms` contains `drv.wrong_way` | Use only ids from the ontology (`ATOMS_train.md`) |
| 3.3 | Boundaries that are not simple polygons: crosswalk rings closed by repeating the first vertex; centre lines written as zero-area point lists | 96 crosswalks (6 recordings); 544 centre lines (154 recordings) | 450-2 `8b66dc711065` crosswalk 668: 5 vertices, the last equals the first | Drop the repeated closing vertex. For line-like kinds, wait for our convention (an estimated thin polygon or an omitted boundary) |
| 3.4 | Declared-fact ids the pipeline reading does not declare | The traces write 7 ids. 5 are not in the reading's `declarations`: `asm.public_highway` (124 recordings), `asm.synthetic_proper_stop_sign_authorization` (257-1 ×9, 257-2 ×10), `asm.synthetic_through_highway_roads_3_4` (257-1 ×9), `asm.synthetic_non_through_highway` (257-2 ×10), `asm.public_authority_posting` (600-1c ×3) | — | Write only ids the reading declares, or propose new ones to us with their meanings. These ids do not change any verdict today, because Core ignores ids no rule reads. But an id that names road numbers (`…roads_3_4`) is scene-specific, and that is not a fact type |
| 3.5 | One source junction drawn twice, and no carrier enters the copy. In 5 of the 6 recordings the ego occupies both copies at once | 6 recordings (113-2 ×2, 250-1 ×2, 250-4 ×2) | 250-1 `cb6ec1a81f55`: intersections 19 and 26 share one 196 m² square | Emit each junction once |
| 3.6 | `governs` targets lanes only, never the intersection | All 19 stop-sign recordings (257-1, 257-2); both 250-4 recordings (each signal governs 29 or 54 lanes, none of the ten intersections) | 250-4: "an intersection controlled by a traffic-control signal" is decided false. Under one of our earlier runs' rules, both labelled recordings came out `not applicable` | Our side: we will state which region `governs` names. Until then, please also list the intersection a device controls |
| 3.7 | Intent `source` values outside the guide's vocabulary | `controller:declared_native_straight_paths`, `controller:identity_bound_interaction_paths`, `controller:authored_bezier_pure_pursuit` | — | Cosmetic. We will widen the guide to a `controller:<method>` form |

## 4. An atom the law states explicitly is missing

| # | Law and its words | Atom | Delivery | Effect on this delivery |
|---|---|---|---|---|
| 4.1 | 407: "cannot be seen by the driver of any other vehicle approaching from either direction **within 500 feet**". 450-2, 250-4 and 257-1: stop "where the driver **has a view of approaching traffic**" | `st.sight_along_way`, `st.sight_distance` | Declared `absent`; 0 of 189 traces carry either. Reason given: "No validated end-to-end source implementation"; `HANDOFF.md` adds "excluded as instructed" | Under the rules of our recent runs: 407 can never be judged violated (4 of its 6 labels are violations); 600-1a's reasonable-speed bound can never be judged compliant; the fallback stopping point of the stop-sign laws is unknown |
| 4.2 | 223-1b: "the appropriate turn **signal**"; 413-2: "a **signal** of intention to turn". Our rules read such a signal as a turn indicator or a hand signal | `sig.hand_signal` | Not listed in the manifest; 0 user-scenes carry it | "Turn indicator or hand signal" can be true (the indicator is on) but never false. So no violation can be decided: not the 5 violated labels of 413-2, nor any violation of 223-1b or of 253, which reaches the same atom through 413-2. Compliant cases stay decidable where the indicator is on throughout the window |
| 4.3 | 250-4: "a traffic-control signal which is installed and has its vehicular signals uncovered, but is **inoperative**" | `dev.inoperative` | Declared `estimate:valid_observed_native_indication_excludes_inoperability`, but absent in all 2,799 device-scenes of both 250-4 recordings, while the signals show `dark` with `uncovered: true` in 1,920 of them | The law's own trigger is unknown (separately from 3.6) |
| 4.4 | 127-3: "upon any highway **outside of a business district**" | `asm.way_outside_business_district` (declared in our reading) | 0 of 11 127-3 traces | 127-3 cannot be decided where the rule reads the premise |
| 4.5 | 413-2: "not less than the last 100 feet traveled in a **business or residential district** and … 300 feet … in **any other area**" | `asm.way_within_business_or_residential_district` | Present (`true`) in the 9 "100-" recordings; **omitted** in the 6 "300-" recordings | Core reads omitted as unknown, not false, so the 300-ft branch is never decided. Write the premise as `false` where the scene is "any other area" |
| 4.6 | 400-2a: "nearest the **centerline**" | `st.centre_line` | Present, but 544 of 638 boundaries are rejected (3.3) | Distance to the centre line is unknown in 400-2a/b |

| 4.7 | 257-1 and 257-2: "Except when traffic is being **controlled by a police officer**" | `dev.human_direction` | Declared `absent` | Depends on how a rule writes the exception. Under one earlier rule the officer limb was decided false through `governs`. Under our latest run's rule, the absent atom is the deciding unknown on all 4 plain labels of 257-1 |

Rows 4.1, 4.2 and 4.7 show why we ask for every atom the parser can produce. Whether a missing atom
blocks a law depends on how that law's rule is written, and the rule may be rewritten in any run.

One smaller point: `asm.way_within_city_limits` appears in no trace. 113-2's rule reads it only
inside a disjunction, so this delivery is unaffected.

## 5. Data that is missing or incomplete

| # | Missing | Count | Laws affected |
|---|---|---|---|
| 5.1 | `ways` on a carrier (`st.on_way`) | 349 carriers, 15 recordings | 220-1, 227-1 (blocks every observation), 250-1, 600-1c |
| 5.2 | `enters_intersection` on an approach lane | 49 recordings (by your reports' own gap lists) | 450-2, 250-1, 250-2, 250-4, 253, 257-1, 257-2, 307-6a, 400-2a/b |
| 5.3 | Stop-line boundary (paint width not measured) | 126 of 148 stop lines, 6 recordings | 450-2, 220-1, 250-4 (our convention pending) |
| 5.4 | Highway boundary | 24 regions, 8 recordings (imported maps) | 450-2, 220-1, 250-4, 307-6a |
| 5.5 | Signal `indications` in some frames | 7,824 of 19,904 signal-scenes, both long 307-6a recordings | 307-6a |
| 5.6 | `governs` on a device | 16 devices, 6 recordings | 450-2, 220-1, 307-6a |
| 5.7 | `conditions` on regulatory signs | 4 signs (0 of 90 devices carry `conditions`) | 220-1 ("signposted for one-way traffic") |
| 5.8 | Brake lamp: `false` while the ego brakes | 186 recordings, 70,531 user-scenes | none today. It is declared `exact`, so please confirm it is measured |
| 5.9 | Scenario coverage: the event is not in the recording | 253: 42.7 m of approach, against the statute's 300 feet; 413-2 C245490 ×6: no course change at all (6.1° maximum) | 253, 413-2 |
| 5.10 | Plain labels and contrast pairs | No plain label for 127-1, 127-2, 127-3, 250-2, 253, 600-1a (87 recordings); 257-1's 4 plain labels are all compliant | training cannot align these laws |

## 6. Priorities

1. **Now, by offline re-export:**
   - occupancy declaration (1.1);
   - class and kind masks (1.3, 1.5, 3.1);
   - closed crosswalk rings (3.3);
   - duplicate junctions (3.5);
   - the 413-2 "other area" premise written as `false` (4.5);
   - invented atom ids removed (3.2);
   - fields declared `exact` that are missing (1.2, 1.4, 1.6).
2. **After our decisions:** stop-line and line geometry, `governs` target, `no_signal` for hand
   signals, and the ids in 3.4.
3. **Requires new computation or recording:** sight (4.1), `dev.inoperative` on dark signals
   (4.3), scenario coverage and contrast pairs (5.9, 5.10).

We will send the full atom list for a single generator upgrade after our 221-law discovery run. The
items above are the fixes for this delivery.
