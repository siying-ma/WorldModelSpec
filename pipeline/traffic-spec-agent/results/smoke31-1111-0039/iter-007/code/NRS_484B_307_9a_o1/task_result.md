# NRS_484B_307_9a_o1 — task result

## Final verdict: WITNESS_FAIL (the node is wrong: its composed exception is unknown for every vehicle under the run's reading)

The rule builds and passes the static checks (no CHECK_FAIL, UNCLAIMED_ATOM, UNUSED_CLAIM, UNANCHORED_VARIABLE or
DECLARATION_MISMATCH was reported in any run). `permit`, `idle`, `branch_1`, `branch_2` and `branch_4` pass.
`forbid`, `branch_3`, `branch_5` (expected violated) and `blind` (expected unknown through `dev.traffic_signal`)
come out unknown, with reasons only:

```
aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped,
aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter
```

These are the aggregates of the composed exception `NRS_484B_307_9b_o1`. They are read through
`.not (.ruleApplies "NRS_484B_307_9b_o1" [("x","x")])`, which the node's `as: exception` requires.

## Gate runs

1. **WITNESS_FAIL.** The first witnesses had a constant yaw rate but a fixed heading, and the adapter rejected the turning
   traces (heading/yaw inconsistency). `forbid`, `blind` and `branch_5` (ru.bus) were unknown for the 9b aggregates.
   *Change:* built consistent kinematics. The heading turns 2.5° per 40 ms scene along a 36-scene arc, with cos/sin
   computed exactly in Q by Taylor series. Positions follow the arc, and occupancy is stated per scene to match the
   footprint. As a probe, the violated/unknown witnesses got different vehicle classes.
2. **BUILD_FAIL.** A fold over a 4-tuple in the witness `trig` helper did not elaborate.
   *Change:* rewrote it as structural recursion (`trigGo`).
3. **WITNESS_FAIL.** Turning traces now accepted. Probe results: trailer_or_combination, school_bus, motor_vehicle and
   transit_bus were all unknown for the 9b aggregates. truck (permit) and taxicab (branch_4) passed, but only because
   their obligation held.
   *Change:* used ru.truck for all planned bus witnesses.
4. **WITNESS_FAIL.** truck is also unresolved.
   *Change:* probed fire_apparatus, tour_bus_or_limousine, commercial_motor_vehicle and taxicab.
5. **WITNESS_FAIL.** All four are unresolved.
   *Change:* restored the planned ru.bus.
6. **WITNESS_FAIL** on the final files, as above. The budget is spent.

Eleven of the fourteen classes included in DEF-NRS-484A-320::vehicle were tried: bus, truck, trailer_or_combination,
school_bus, transit_bus, motor_vehicle, fire_apparatus, tour_bus_or_limousine, commercial_motor_vehicle, taxicab, and
motorcycle (branch_1). Every one other than motorcycle leaves `NRS_484B_307_9b_o1`'s engagement unknown for the
aggregate reasons above. motorcycle passes branch_1 as planned. emergency_vehicle and official_vehicle were not tried.
The class is the only scene fact that could decide it: no other unknown reason is reported, so 9b's own applicability
is not false in these scenes.

## What is wrong, and what the plan must change

- **Span b2 (composition `NRS_484B_307_9b_o1` as exception) / scenarios forbid, blind, branch_3, branch_5.** The node
  plans these with "x (ru.bus, a vehicle of no class paragraph (b) names)" and expects violated (or unknown only through
  the masked signal). Under the run's reading, a bus — and every other ordinary vehicle class tried — is *unresolved*
  under DEF-NRS-484A-135::motorcycle, DEF-NRS-484A-125::moped, DEF-NRS-484B-017::electric_bicycle and
  DEF-NRS-484B-018::electric_scooter. So `ruleApplies NRS_484B_307_9b_o1` is unknown for x, and this rule's
  applicability is unknown at every passage it would judge. The rule can never return violated for a vehicle, so the
  four planned verdicts are unreachable.
- **Fixes for the plan / reading:**
  - (a) The reading of those four aggregates (or of the 9b_o1 class formula) must decide ordinary vehicle classes such
    as ru.bus or ru.truck as excluded. A bus is not a motorcycle, moped, electric bicycle or electric scooter by those
    definitions.
  - (b) Alternatively, 9b_o1's applicability must be decidedly false in the situations 9a's scenarios describe.
  - (c) Failing either, the 9a scenarios must name a class the reading decides outside paragraph (b), or expect unknown.
- This is not something to repair in this rule. Inlining 9b's content or dropping the exception is forbidden, and
  substituting a class does not help because no vehicle class tried decides it.

## The rule as written (choices)

- **b3 (class):** `ru_aggregate x "DEF-NRS-484A-285::traffic" ∧ ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **b5 / b4 / b1 (applicability):**
  - Some intersection i has `drv_motion_leaving_region x i` at the observation.
  - In addition, `since (¬entering x i ∧ (rel_occupies x i ∨ leaving x i)) (entering x i ∧ facing(display))`.
  - `facing(display)` is: some `travel_region` c with `rel_occupies x c` and `st_lane_enters c i`, and some
    `traffic_signal` s with `dev_governs s c ∨ dev_governs s i` that shows `circular_red` together with
    `green_arrow(left)` or `green_arrow(right)`.
  - The `¬entering` conjunct pins the search to the latest entry, as the record states, and keeps the selection
    decided (false) after an entry under another display.
- **b2:** `¬ruleApplies NRS_484B_307_9b_o1 {x↦x}`.
- **b6 (obligation):**
  - For every intersection i: the whole selection again ⇒ one of two branches holds.
  - Left branch: the same `since` with a green left arrow, and `drv_motion_heading_change_since_entry(x, i;
    p.heading_since_step_carla_scene_graph) ≥ p.turn_recognition_angle`.
  - Right branch: the same with a green right arrow, and the heading change `≤ −p.turn_recognition_angle`.
  - Where both arrows were displayed, either movement complies.
- No narrowing of my own was needed. The record's narrowing on b6 is not restated.

## Witness notes

- The step bound is 50 ms and the witnesses sample every 40 ms.
- `window` = 40–3080 ms excludes scene 0. Scene 0 has no observation before it, so leaving/entering are unknown there.
- Occupancy is stated per scene. The footprint lies across c and i at the entry (scene 9).
- The class is set once (`subjectClass`) to the planned ru.bus.

## Gate behaviour worth noting

A witness whose obligation holds reads compliant even when the applicability is unknown. In run 3, permit and branch_4
therefore passed with a class that leaves 9b unresolved; they gave no evidence about the class.

## Why I finished

The gate budget (6 runs) is spent. The remaining failures come from the node: its composed exception is unknown for
every vehicle class tried under the run's reading. They do not come from the rule's formulas or the witness geometry.
