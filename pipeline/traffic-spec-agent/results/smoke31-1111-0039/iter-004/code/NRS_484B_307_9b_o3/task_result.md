# NRS_484B_307_9b_o3 — task result

**Final verdict: OK** (6 witnesses, 14 names, composes nothing). Gate runs used: 3 of 6.

## Gate runs

1. **WITNESS_FAIL**: the trace lint rejected every turning witness. Headings stayed the same between scenes while the yaw rate was non-zero. I gave each scene a distinct heading vector along the turn, and stated the entry scene's body so it straddles the lane and the intersection (lint derives occupancy from footprints).
2. **WITNESS_FAIL**: `blind` came out unknown because of `absent_atom:st_lane_enters`, not because of the masked `dev.governs`. The carrier quantifier over `travel_region` also ranges over the intersection `i` itself, which x always occupies at its entry. `st_lane_enters(i, i)` is unrecorded there, so it is unknown. I added `¬ same(c, i)` beside `st_lane_enters(c, i)` in the approach selection, in both applicability and obligation.
3. **OK**.

## How the node is written

- **Class (c2, c4)**: the five admitted aggregates, joined by "or" and named by id.
- **Applicability (c1, c5, c6)**: some intersection `i` that x leaves at the observation (`drv_motion_leaving_region`).
  - x's latest entry into `i` is read with `since (¬entering) (entering ∧ …)`. At that entry, x occupies a carrier `c ≠ i` with `st_lane_enters(c, i)`, and a traffic signal governing `c` or `i` shows `circular_red` together with `green_arrow(d)`.
  - The passage, measured by `drv_motion_heading_change_since_entry` with step `p.heading_since_step_carla_scene_graph` against `p.turn_recognition_angle`:
    - straight through: |Δ| < angle
    - the turn opposite the arrow: Δ ≤ −angle for d = left, Δ ≥ angle for d = right
- **Obligation (c11)**: for every intersection `i` selected again the same way (leaving, plus entry under red with a green arrow of either direction), a left turn (Δ ≥ angle) means that at the entry, through every approach carrier `c` x occupies, no device governing `c` or `i` prohibits it. Prohibiting devices:
  - a regulatory sign `no_left_turn` whose conditions hold for x (`prim_conditions_hold`)
  - a signal head showing `red_arrow(left)`

  A right turn is handled the same way with `no_right_turn` and `red_arrow(right)`. A straight passage engages neither implication.

## Choices the node left open

- **Which carrier "c x entered through" means:** I took every travel region x occupies at the entry that enters `i`, using a universal. This way the rule never picks the approach that favours x.
- **`c ≠ i`:** this is stated, not a narrowing. An approach carrier is never the intersection it enters, so no carrier is removed. It only stops the intersection, which the `travel_region` quantifier covers, from leaving `st_lane_enters` unknown on every real trace.
- **No narrowings declared:** the record's own c11 reading already covers the closed set of prohibitions.

## Witnesses

All six run on the same map: intersection 1 (20 m square) and a northbound approach lane 2 entering it. Each has 10 scenes at 50 ms, the window is k = 1…9, and the yaw rate is ±300 deg/s during the turn (±90° at the leaving).

| Witness | Expected | Scene |
|---|---|---|
| `forbid` | violated | motorcycle, left arrow, right turn, `no_right_turn` sign governing lane 2 |
| `permit` | compliant | bicycle, left arrow, right turn, no prohibition |
| `idle` | not applicable | motorcycle, left arrow, left turn |
| `blind` | unknown | as `forbid`, `dev.governs` masked |
| `branch_1` | compliant | moped, left arrow, straight through, `no_right_turn` sign |
| `branch_2` (added) | violated | motorcycle, signal governing `i` shows red + `green_arrow(right)`, x turns left, a second head governing `i` shows `red_arrow(left)` |

`branch_2` exercises the right-arrow branch, the red-arrow prohibition, and signal control of the intersection itself.

## Note for planning

`st.lane_enters` read on an intersection region is unknown, not false (the accessor reads lane info, which an intersection does not carry). Any rule that quantifies carriers over `travel_region` will hit this, because the intersection itself is in range.

## Why I finished

The gate returned OK.
