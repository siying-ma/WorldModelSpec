# NRS_484B_450_1c — task result

**Final verdict: OK** (11 witnesses, 17 names, composes nothing).

## Gate runs
1. `OK` on the first run. The rule and witnesses were written in one pass; nothing changed afterwards.

## The rule
- Class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability (c8): `existsRegion intersection i (rel_occupies x i)`.
- Obligation: `¬(stopped(x, p.motion_speed_tolerance) ∧ ¬c3 ∧ ¬c4 ∧ ¬c5 ∧ ¬c6)`.
  - c3: some road user z, not x, that is a member of `DEF-NRS-484A-285::traffic` and meets one of two tests:
    - **Predicted conflict:** `prim_closest_approach_within x z` over `p.conflict_time_horizon` holds, and `prim_closest_approach_distance` is below `p.conflict_centre_clearance`.
    - **Queued ahead:** `rel_bearing x z "ahead"` holds, and `rel_surface_gap x z` is below `p.queue_standstill_gap`.
  - c4: `asm.halt_required_by_law`.
  - c5: a `human_direction` device with role `police_officer` and indication `stop` governs a `travel_region` that x occupies.
  - c6: a device governs a `travel_region` that x occupies, and is one of these:
    - a `traffic_signal` showing `circular_red`, `red_arrow(any direction)` or `flashing_red`;
    - a `stop_sign`;
    - a `yield_sign`.

## Choices the node left open
- **Where the exceptions go:** I put them in the obligation, not the applicability. The record's obligation says "violated where x is halted and none of the exceptions holds", and the planned branch scenarios expect `compliant`, not `not_applicable`. The skeleton's applicability docstring listed c3–c6; I followed the record.
- **"A travel region x occupies or i":** written as the travel regions x occupies. The intersection i is a region x occupies, and `intersection` refines `travel_region`, so this already covers i with its whole selection. A separate disjunct for i would add nothing.
- **"Longitudinal component positive":** written with the `rel_bearing` Boolean selector `"ahead"`, which is exactly that test (bearing.1 > 0).
- **`rel.surface_gap`:** read without a component, which gives the gap distance, as the record says ("within the queue standstill gap of x's body").
- **Red arrow:** all four arrow directions are accepted, since the record says "a red_arrow" without naming one.
- **Narrowings:** I declared none.

## Witnesses
These go beyond the planned six:
- `branch_3`: queue ahead, a 2 m gap.
- `branch_4`: the assumption is declared true.
- `branch_5`: a signal showing circular red.
- `branch_6`: a stop sign.
- `branch_7`: a yield sign.

Each has one exception limb as the only thing that excuses the halt, so every leaf moves a decided witness.

## Why I finished
The gate returned OK on the first run.
