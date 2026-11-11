# NRS_484B_307_9b_o1 — task result

**Final verdict: OK** (11 witnesses, 17 names, composes nothing; 1 coder narrowing declared). Two gate runs out of six were used.

## Gate runs
1. **WITNESS_FAIL**: every decided witness came back `not_applicable`. The gate evaluates the scene's occupancy as built. `Build.scene` derives it from the reference point, so at x's entry its body was never recorded on both the approach lane and the intersection, and the carrier selection at the entry failed.
   - **Fix:** each witness scene now supplies occupancy from the body footprint. This is the closed-set overlap of `footprint` and the region outline that the admission's `completeOccupancy` derives, so a body across the lane's end and the intersection occupies both.
2. **OK.**

## How the rule is written
- **Class (c2, c4):** the disjunction of the five admitted aggregates (`ru_aggregate x <id>`). c3 is the node's residue.
- **Applicability (c1, c5, c6):**
  - Judged at x's leaving of an intersection i.
  - `since inside (entering ∧ ∃c approach)`: x has stayed on i since an entry at which it occupied a travel region c with `st_lane_enters c i`. At that entry a traffic signal governing c or i showed circular_red together with green_arrow(d).
  - The arrow's direction is a literal, so the passage is written once for each of left and right:
    - Straight: `|heading change since entry| < p.turn_recognition_angle`.
    - Opposite a left arrow: `≤ −angle`.
    - Opposite a right arrow: `≥ angle`.
  - The step is `p.heading_since_step_carla_scene_graph`, passed to `drv.motion.heading_change_since_entry`.
- **Obligation (c8):**
  - The entry and its carriers are selected again in full: leaving, the `since` chain, the entry, and the same `approach` relations with a green arrow of either direction.
  - The place, in the record's order:
    - A stop line marking c.
    - Else (no stop line marks c) a crosswalk marking c.
    - Else (neither) the intersection itself.
  - The search is `since (¬approachStart ∧ ¬leaving) haltAt`.
    - `haltAt` is: halted (p.speed_resolution), on c, within p.stop_point_tolerance of the place, offset along c ≥ 0, not overlapping i, and for a crosswalk not overlapping the crosswalk.
    - `approachStart` is: on c, off the place, offset > 0, distance > tolerance.
  - When several carriers are selected:
    - The duty holds if every carrier's search finds the halt.
    - It fails if no carrier's search does.
    - It is unknown where they differ (`every ∨ definedWhen(¬some, ff)`), as the record states.

## Choices the node left open
- **Narrowing, c8 (declared):** where no mark is recorded, "before entering the intersection" is read against the intersection region's outline. The distance and the offset along c are taken to region i.
- **The search's other end (header only):** the record says the search also ends at "x's previous entry into i". I wrote this as the leaving of i that followed that entry. Between that entry and that leaving x overlaps i, so no halt can count there, and the verdict is the same.
- **`¬same(c, i)` in the carrier selection (header only):**
  - An intersection is not an approach carrier.
  - The intersection x occupies at its entry has no recorded `st_lane_enters`, so that atom reads unknown there.
  - That would leave every carrier selection under `∀c` unknown when the signal governs the intersection.
- **Witness branches added:**
  - Crosswalk only: compliant (`branch_1`) and violated (`branch_2`).
  - No mark: compliant (`branch_3`) and violated (`branch_4`).
  - Right turn under a left arrow, with the signal governing the intersection: violated (`branch_5`).
  - Left turn under a right arrow: violated (`branch_6`).
  - Together these exercise every leaf.
- **Witness windows:** each witness speaks from t = 1 s; history_boundary speaks from 50 ms. At a trace's first observation no entry or leaving can be read.

## Why I finished
The gate returned OK on both files.
