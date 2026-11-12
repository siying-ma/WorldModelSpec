# NRS_484B_257_1_o1 — task result

## Final verdict

`OK` (14 witnesses, 20 names, composes nothing).

## Gate runs

1. `OK`. This was the first run, made after writing the rule and the witnesses in one pass. Nothing changed after it.

(One stray shell command, `python -m harness gate --help`, was tried by mistake before the gate run. It was denied by the permission layer and did nothing. It was not a gate run.)

## How the rule is written

- **Class (g3):** `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- **Applicability (g1, g2, the event):** ∃ intersection `i`, ∃ `travel_region` `c` such that:
  - `st_lane_enters c i`;
  - ego enters `i` from `c`: `occ i ∧ rises (occ i ∨ ¬occ c)`. With `occ i` holding now, this is exactly "now in `i`; before, on `c` and not in `i`";
  - a stop sign or a yield sign governs `c`;
  - and not the exception. The exception is: ego is in `DEF-NRS-484A-285::traffic`, and either a `human_direction` of role `police_officer` governs `c` or `i`, or a `traffic_signal` governing `c` or `i` is not `dev_inoperative`.
- **Place (g5/g6/g7):** the place is chosen in this order:
  1. the stop line marking `c` (`st_entrance_of s c`);
  2. otherwise, where no stop line marks `c`, the crosswalk marking `c`;
  3. otherwise, where neither marks `c`, `i` itself (the entrance end of `c`).

  Ego is "at" the place when its body distance is ≤ `p.stop_point_tolerance` and `prim_region_offset_along ego place c` ≥ 0. At the crosswalk and at `i`, ego's footprint must also not overlap the place.
- **Act (g4):** ego on `c`, at the place, and either:
  - `drv_motion_at_rest`; or
  - where no stop sign governs `c`, `drv_motion_decelerating` at some observation of the `.path` window `p.yield_slowing_distance` behind.
- **Search:** `since (¬act) (approachStart ∨ rises (occ i))`.
  - The approach start is: ego on a carrier the place marks (for the line and the crosswalk, a travel region `c2` with `st_entrance_of place c2`; for `i`, `c` itself), farther from the place than the tolerance, and with a positive offset along `c`.
  - The judged entry is itself a rise of `occ i`, so the search is read from the observation before the entry. The duty is `¬ rises (occ i ∨ ¬search)`; at an entry this equals the negation of the search's value at the previous observation.
  - The start of the recording ends nothing: `since` carries the unobserved past as unknown.
- **Obligation:** ∀ `i`, ∀ `c`: (selection → duty). The selection is restated whole: `c` enters `i`, the entry, and the sign on `c`.

## Choices the node left open

- **"At the observation before" the entry:** the language has no `prev` operator. I expressed it through `rises` over a disjunction, as above. This is exact, not a narrowing.
- **Previous-entry bound:** handled exactly as described in the search, by reading the search from the observation before the entry. Not a narrowing.
- **"On a carrier the place marks" for the third place (entrance end of `c` at `i`):** read as `c` itself. The entrance end belongs only to `c`.
- **The obligation does not repeat the exception.** The exception only decides whether the rule is engaged. Repeating it in the obligation would add leaves that no witness can move.
- **No narrowings declared.** Every formula follows a reading the record states.

## Witnesses

| Witness | Expected | Scene |
|---|---|---|
| forbid | violated | stop line, ego runs the stop |
| permit | compliant | stop line, ego halts at the line |
| idle | not applicable | no signs |
| blind | unknown | `dev.governs` masked |
| history_boundary | unknown | the recording starts inside the stopping zone |
| branch_1 | compliant | yield sign, ego slows |
| branch_2 | not applicable | an officer governs `i` |
| branch_3 | violated | yield sign, constant speed |
| branch_4 | violated | a dark signal governs `i`; an operating signal and an officer govern only the crossing lane |
| branch_5 | compliant | crosswalk place, ego halts |
| branch_6 | violated | crosswalk place, ego runs |
| branch_7 | compliant | intersection-edge place, ego halts |
| branch_8 | violated | intersection-edge place, ego runs |
| branch_9 | violated | ego halts, enters, backs out within the zone, and enters again; the second entry's search ends at the first entry |

## Why I finished

The gate returned `OK` on the first run.
