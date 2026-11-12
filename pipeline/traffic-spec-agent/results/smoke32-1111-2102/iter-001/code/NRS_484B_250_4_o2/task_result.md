# NRS_484B_250_4_o2 — task result

## Final verdict

**OK** (gate run 1 of 6): 9 witnesses, 17 names, composes nothing.

## Gate runs

1. `OK`. Nothing changed after it.

One process note: before run 1, I mistakenly issued a shell command other than the gate (the gate
command with `--help` appended). The sandbox denied it and it never ran. It did not use a gate run.

## How the rule is written

- **Class (a4, a10):** `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- **Selection of `i` and `c` (a1, a2, a3, a9):**
  `st_lane_enters c i ∧ since (occupies ego i) (entry ∧ signalInoperative)`, where:
  - `stopped := since (occupies ego c) (at_rest ego ∧ occupies ego c ∧ place)`
  - `entry := occupies ego i ∧ rises (¬ stopped)`. Here `stopped` held at the observation before
    and fails now, which happens only once ego no longer occupies `c`.
  - `place` follows the a6/a7/a8 cascade:
    - a stop line marking `c` (`st_entrance_of`), with the body within `p.stop_point_tolerance`
      (`st_region_geometry_distance`) and `prim_region_offset_along ≥ 0`;
    - otherwise, a crosswalk marking `c`, not occupied, within the tolerance, with offset `> 0`;
    - otherwise, outside `i`, within the tolerance of `i`, with offset `> 0`.
  - `signalInoperative`: some traffic signal head governs `c` or `i`, and every head that governs
    `c` or `i` is inoperative.
- **Applicability:** `∃ i:intersection, ∃ c:travel_region, selection`.
- **Obligation:** `∀ i, ∀ c, selection → ∀ b, (vehicle b ∧ b ≠ ego ∧ precedence) → (at_rest ego ∨ ¬conflict)`.
  - The selection is restated whole, so `i` and `c` mean the same regions in both formulas.
  - `precedence` (a13): b occupies `i`, or b occupies some `cb ≠ c` that enters `i`, where:
    - b has occupied `cb` since a rest on it (`since`);
    - `sinceRise(b at rest on cb) > sinceRise(ego at rest on c)`, so b's rest began earlier than
      ego's halt.
  - `conflict`: `prim_closest_approach_within(h) ∧ prim_closest_approach_distance(h) < p.conflict_clearance`.

## Choices the node left open

- **Side of the place along `c`:** for the stop line, ego's reference point is on or short of the
  line (`≥ 0`, "at" the line). For the crosswalk and the intersection, the region is strictly ahead
  (`> 0`, "before entering" / "outside i"). This writes the record's "side read along c". Spans a9
  and a13 are conditions, so I declared no narrowing on them.
- **"The onset of ego's halt on c":** read as the start of ego's latest run at rest while occupying
  `c`. Applicability already requires that halt to be the stop at the place.
- **"Every head governing c or i":** read over every head the scene has. A head governing other
  regions does not count.
- **`dev.traffic_signal`:** carried as the device quantifier's kind. The `uncovered` attribute is
  not read separately: the contract of `dev.inoperative` already makes an inoperative head
  installed and uncovered, so a separate leaf could never be exercised by a consistent scene.
- **`st.lane_direction`:** read through `prim_region_offset_along`, which reads it as its
  contract states. The gate accepted this as a use of the claim.

## Witnesses

- **Planned witnesses:** forbid, permit, idle, blind, branch_1, branch_2, branch_3, all with their
  planned verdicts.
- **Two added witnesses:** these reach the a7 and a8 limbs of the stop cascade.
  - `branch_4` (violated): a crosswalk marks `c` and no stop line does. The dark head governs only
    the intersection.
  - `branch_5` (violated): nothing marks `c`, so ego halts at `c`'s entrance end.
- **Branch-reach details:**
  - A stop line and a crosswalk marking b's approach `cb` are always present. This lets the
    "if there is none" negations be exercised.
  - An operating head on a far lane is always present. This lets the "every such head" scope be
    exercised.
  - In `forbid`, ego moves off the line before entering. In `branch_1`, the conflict comes one
    observation after entry. These make the two `since` scopes do work.

## Why I finished

The gate returned `OK` on the first run.
