# NRS_484B_270_2a_o2 — task result

**Final verdict: OK** (13 witnesses, 17 names, composes nothing; 1 coder narrowing)

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. No further changes.

## The rule
- Class: `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
- Applicability: `existsUser r` over r's whole selection:
  - r is not the subject and belongs to one of the three aggregates (bicycle, electric bicycle, electric scooter).
  - `rises (drv_interaction_overtake_pass subject r [p.overtake_window, p.overtake_same_direction_cos])`.
  - At some observation of the window behind (`¬holdsFor W ¬…`), r's `kin_speed > p.halt_speed_tolerance` and `rel_same_direction` holds.
  - At some observation of the window behind at which the two are side by side (`rel_longitudinal_overlap ≥ 0`), r occupies a lane whose `st_lane_adjacency_count` is greater than the literal one.
- Obligation: `forallUser r (selection → excuse ∨ (vehicle(subject) ∧ duty))`.
  - **duty:** `holdsFor W` of (side by side → the subject occupies the `st_lane_adjacency_left` neighbour of a lane r occupies ∧ the subject occupies no lane r occupies).
  - **excuse:** at the pass's start (`atLast W`, where ψ = `rel_bearing … "ahead"` ∧ overlap < 0 ∧ same direction), some lane r occupies meets one of these conditions:
    - it has no left neighbour;
    - its left neighbour is governed (`dev_governs`) by a `temporary_traffic_control` device;
    - its left neighbour is occupied by a road user u, other than the subject and r, whose `rel_surface_gap` to the subject is less than `kin_speed(subject) × headway`. The headway is a `Term.cond` chain: ice/snow → ice headway; wet road or precipitation → wet headway; otherwise dry headway.
- Literal "one" (a6) is written `.lit (Units.ratio 1 1) .count`. Units has no count constructor, and the gate accepted this form.

## Choices the node left open
- **a8 (declared narrowing, kind `reading`):** "the rider's lane" at the pass's start is read as *some* lane the rider occupies. The left lane counts as missing, closed or unsafe if it is so beside some lane the rider occupies.
- The surface gap is compared as the gap's distance (`rel_surface_gap` with no component), following the record's "nearer the subject's body".
- `ru_aggregate subject DEF-NRS-484A-320::vehicle` ("the vehicle", a7) is a conjunct of the duty, outside the window.

## Witnesses
- **Setup:** an eastbound carriageway with 20 one-second observations. Every witness has `window = [10 s, 19 s]`, so each look-back window is fully covered.
- **The pass:** the bicycle is ahead until t = 14 (the pass's start), side by side at t = 15, and behind from t = 16 (recognition).
- **idle deviates from the narrative:** the overtaken vehicle is a **moped**, not a car. In the run's reading, `motor_vehicle` is *unresolved* for both `DEF-NRS-484B-017::electric_bicycle` and `DEF-NRS-484B-018::electric_scooter`. That would make a car's rider class unknown and the verdict unknown rather than not applicable. A moped is decided false for all three aggregates.
  - Also from the reading: `DEF-NRS-484B-018::electric_scooter` includes no class, so no witness can make that aggregate true. The planner may want to look at this.
- **Branches added to exercise leaves:**
  - branch_3: the rider is in the leftmost lane, so there is no left neighbour (compliant).
  - branch_4: temporary traffic control governs the left lane (compliant).
  - branch_5 / branch_6 / branch_7: a car in the left lane at a gap that is safe under a shorter headway but unsafe under the wet / rain / ice headway (compliant).
  - branch_8: the same car on a dry road, so the lane is safe (violated).
  - branch_9: the bicycle is stationary (not applicable).

## Why I finished
The gate returned `OK` on the first run.
