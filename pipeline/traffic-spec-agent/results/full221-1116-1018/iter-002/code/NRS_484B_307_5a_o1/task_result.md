# NRS_484B_307_5a_o1 — task result

**Final verdict: OK** (9 witnesses, 11 names, composes nothing)

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. No changes after it.

## How the rule is written
- **Class (s2):** `ru_aggregate subject "DEF-NRS-484A-285::traffic"` ∧ `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Selection (s2):** `∃ intersection i, ∃ travel_region c, ∃ traffic_signal s`: `st_lane_enters c i` ∧ `dev_governs s c`.
- **Onset (entry):** `rises (rel_occupies subject i)` ∧ `rel_occupies subject c` at the observation before. "At the observation before" is written `prev φ := (φ ∧ ¬rises φ) ∨ rises ¬φ`, because the language has no previous-observation operator.
- **Recognition (exit):** `rises (¬ rel_occupies subject i)`.
- **s1, some_moment over the act stretch:** `since inPassage (arrowAlone ∧ since inPassage entry)`.
  - `inPassage` holds inside i at an observation that is not a new entry, and at the exit itself.
  - So the arrow must be shown at some observation from this passage's entry to its exit, both ends included. An earlier passage is never reached.
  - `arrowAlone`: `dev_traffic_signal_shows s green_arrow(straight)`, with every other indication of the `SignalIndication` enumeration not shown. This follows the record's "green_arrow(straight) and no other state".
- **Obligation (s3):** `∀ intersection i`: (the same whole selection of c, s, entry, arrow and exit) → ¬(left_turn_through_region ∨ right_turn_through_region ∨ u_turn_through_region)(subject, i).
  - The left and right turns take step = `p.heading_since_step_carla_scene_graph`, turn_min = `p.turn_heading_min` and u_turn_min = `p.u_turn_heading_min`.
  - The u-turn takes step and u_turn_min.

## Choices the node left open
- None that narrows a span. The previous-observation encoding and the passage-bounded `since` only express what the record states, so no narrowing is declared.

## Witnesses
- **Setup:** 20 Hz traces (50 ms, matching the step bound). Approach lane c enters intersection i, and head s governs c.
- **Yaw rates:** set only at the four interior samples, so the integrated change does not depend on which end of each interval holds the rate.
- **Window:** `(50, 400)`. The first scene has no previous observation, so its exit edge is undecided there.
- **Planned witnesses:**
  - forbid: +88°, violated.
  - permit: +2°, compliant.
  - idle: circular_green throughout, not applicable.
  - blind: no yaw rate, unknown.
  - occasion_s1: arrow at entry, then yellow, +90°, violated.
  - occasion_s1_outside: arrow only before entry, not applicable.
- **Added branches:**
  - branch_1: right turn −88°, violated.
  - branch_2: reversal 180°, violated.
  - branch_3: arrow together with circular_red, so not "alone", not applicable.

## Notes
- One stray command of mine (a gate invocation with `--help` piped to `head`) was refused by the permission layer. It was not executed, and it did not count as a gate run.

## Why I finished
The gate returned OK on the first run.
