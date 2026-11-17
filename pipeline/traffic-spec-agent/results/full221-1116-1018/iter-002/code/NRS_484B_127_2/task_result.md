# NRS_484B_127_2 — task result

## Final verdict: OK

(gate output: `OK — 12 witnesses, 10 names, composes nothing`)

## Gate runs
1. `UNUSED_CLAIM`. I ran this on the harness's skeleton by mistake, before writing anything, so every claim was still unused. This used one run of the budget.
2. `OK` with the rule and 12 witnesses written. Nothing changed after this run.

## How the rule is written
- **Class (g1):** the subject is a truck or a combination of vehicles, using `ru_aggregate` with `DEF-NRS-484A-305::truck` or `DEF-NRS-484A-050::combination_of_vehicles`.
- **Applicability:**
  - **g1 width:** `kin_extent(subject,"width") ≥ Units.inches 80`.
  - **g6 lane count:** the subject occupies no lane (`existsRegion "lane"`, `rel_occupies`) whose `st_lane_adjacency(r,"count")` is at least 2.
- **Obligation:** `∀ b ≠ subject`, if the g2 trigger holds then one of g3, g5 or g4 below gives way to compliance:
  - **g2 (trigger):** b is a truck or combination of full width ≥ 80 in, and b is the subject's immediate leader. That means `rel_ahead_behind_in_lane(b, subject)` (Core reads the first argument as the one ahead), and no other road user c is ahead of the subject and behind b in a lane.
  - **g3 (conditions permit):** fails, i.e. `¬ holdsFor time p.truck_space_open_time` of (immediate leader ∧ neither vehicle is `drv_motion_complete_halt` with `p.halt_speed_tolerance`).
  - **g5 (overtaking exception):** `within time p.overtake_window` there is some o that is a vehicle or a combination with `drv_interaction_overtake_pass(subject, o)` (`p.overtake_window`, `p.overtake_same_direction_cos`).
  - **g4 (the space):** `rel_surface_gap(subject,b,"longitudinal") ≥ Units.feet 500`.
- **Count literal:** "two" is written `Units.ratio 2 1` with unit `.count`, because Units has no count constructor. The gate accepted it.

## Choices the node left open
- I added no narrowings. The record's own narrowings (g1, g3, g4) cover the readings.
- I excluded the subject from the quantified b and c with `same`. This only makes the record's "other road user" explicit.

## Witnesses
The 8 planned scenarios have their planned verdicts. I added 4 more so that every leaf moves at least one witness:

| Witness | Scene | Expected | Leaf it exercises |
|---|---|---|---|
| `branch_5` | a combination follows a combination at 60 m | violated | the combination aggregate for the subject and for b |
| `branch_6` | a car runs between the two trucks | compliant | the between-check in the trigger |
| `branch_7` | the subject passes a bicycle on the shoulder | violated | the vehicle/combination class of the vehicle passed |
| `branch_8` | a car between the trucks left 5 s ago | compliant | the between-check inside the g3 window |

Windows are set where both the 30 s look-back and the 10 s look-ahead are covered by the trace.

## Note on g5
The combination aggregate in g5 is logically redundant: `DEF-NRS-484A-320::vehicle` already includes `trailer_or_combination`. I kept it because the node claims it, and the gate did not flag it.

## Why I finished
The gate returned OK on the second run.
