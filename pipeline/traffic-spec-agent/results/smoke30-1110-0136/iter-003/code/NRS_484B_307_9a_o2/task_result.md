# NRS_484B_307_9a_o2 — task result

## Final verdict

**OK** — 8 witnesses, 13 names, composes NRS_484B_307_9b_o1..o4.

## Gate runs

1. **Before the witnesses were written (my mistake).** I ran the gate command wrapped as
   `… | head -0; echo skip`. This broke the "exact command only" rule, and its output was thrown
   away. The rule file was written by then, but the witness file was still the harness skeleton.
   It probably used one run of the budget.
2. **WITNESS_FAIL.** `blind` was unknown for `absent_atom:st_lane_enters`, which is not the masked
   atom. The cause: the carrier quantifier `c2` (kind `travel_region`) also ranges over the
   intersection. The intersection has no lane record, so `st_lane_enters(c2, i)` is undecided for
   it. In `forbid` the false `st_entrance_of` settles that case; with the entrance masked, nothing
   does.
3. **A repeat run with nothing changed (my mistake).** It printed the same WITNESS_FAIL. A second
   wrapped command (`--help … | head -0`) was refused by the permission system and did not run.
4. **OK**, after adding `¬same c2 i` to the crosswalk's carrier condition.

In total I ran the gate 4 times (2 of them by mistake). One more wrapped attempt was refused and
did not run.

## How the node is written

- **Class:** `ru_aggregate(x, DEF-NRS-484A-285::traffic)`.
- **"Vehicular" (a3):** `¬ru_aggregate(x, DEF-NRS-484A-165::pedestrian)` in the applicability.
- **a1/a4:** x occupies an intersection `i`, and has occupied it at every observation since its
  entry. The entry is the rise of `rel_occupies(x, i)`. At the entry, some `traffic_signal` shows
  `circular_red` and a `green_arrow` (any of the four directions). That signal governs either:
  - a `travel_region c` with `st_lane_enters(c, i)` that x occupied, outside `i`, at the
    observation before the entry, written `since (occ x i) (occ x c ∧ ¬occ x i)` and read at the
    entry; or
  - `i` itself.
- **a2:** `¬ruleApplies` for each of 9b_o1..o4, with x mapped to x.
- **a6:** the obligation restates the whole selection of `i` (`forallRegion intersection i`,
  `underArrow i → …`). While x is moving (`drv_motion_moving`, `p.motion_speed_tolerance`), x is
  not in predicted conflict with:
  - any pedestrian-aggregate user in a crosswalk `w` recorded (`st_entrance_of`) as marking a
    `travel_region c2 ≠ i` that enters `i`; or
  - any traffic-aggregate user other than x occupying `i`.

  Predicted conflict means `prim_closest_approach_within` over `p.conflict_time_horizon` and
  `prim_closest_approach_distance` below `p.conflict_centre_clearance`.

## Choices the node left open

- **`¬same c2 i`.** This adds no restriction the record lacks: under the `st.lane_enters`
  contract an intersection is never a carrier, so a carrier that enters `i` is never `i`. It only
  keeps that relation decided for the intersection. I explained it in the header and declared no
  narrowing.
- **A green arrow of any direction.** I wrote the four `green_arrow(dir)` spellings as
  alternatives, following "at least one green_arrow(dir)".
- **No narrowings declared.**

## Witnesses

| Witness | Expected | Scene |
|---|---|---|
| `forbid` | violated | Car turns left on red with a left arrow; the pedestrian in the crosswalk on the west leg is about 0.8 m away at predicted closest approach. |
| `permit` | compliant | Car halts inside the intersection, then turns with about 6.7 m closest approach. |
| `idle` | not applicable | Signal shows circular_green. |
| `blind` | unknown | The crosswalk's entrances are not observed, and `st.entrance_of` is masked. |
| `branch_1` | compliant | No other road user. |
| `branch_2` | violated | The signal governs the intersection itself. |
| `branch_3` | violated | A standing car inside the intersection is in predicted conflict. |
| `branch_4` | not applicable | The subject is a pedestrian. |

## Why I finished

The gate returned OK.
