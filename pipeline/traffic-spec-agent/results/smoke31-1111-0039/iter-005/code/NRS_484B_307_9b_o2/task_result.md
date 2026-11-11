# NRS_484B_307_9b_o2 — task result

**Final verdict: OK** (10 witnesses, 12 names, composes nothing)

## Gate runs

0. By mistake, my first shell call put the gate command inside a compound command (`… | head -0; ls …`). Its output was thrown away, so it may have used one gate run from the budget before any file was edited.
1. **VACUOUS**: three obligation leaves were not exercised: `dev_governs(s, i)` and the two turn comparisons of the heading change (right turn under a left arrow, left turn under a right arrow). The turn branches were compliant, and in a compliant witness these leaves only sit in the antecedent of an implication, so flipping them changed nothing. What changed: branch_3 and branch_4 now expect violated (only one rise, then the opposite turn), and I added branch_5 (violated: s governs i only, one rise).
2. **OK**.

## How the rule is written

- **Class (c2, c4):** `ru_aggregate` of x for each of the five admitted aggregate ids, joined by "or". Trimobile (c3) is the node's residue.
- **Applicability (c1, c5, c6):** for some intersection i, x leaves i at the observation (`drv_motion_leaving_region`). Read back through `since` (over `rel_occupies(x,i) ∨ leaving`) to x's latest entry (`drv_motion_entering_region`), the selection must hold at that entry:
  - some travel region c that x occupies, with `st_lane_enters(c,i)`;
  - some traffic signal s that governs c or i and shows `circular_red` with `green_arrow(d)`.
  
  The arrow side d is split into a left disjunct and a right disjunct, because the passage allowed at the leaving depends on it. The passage is read from `drv_motion_heading_change_since_entry` with step `p.heading_since_step_carla_scene_graph`:
  - straight: |change| < `p.turn_recognition_angle`;
  - left turn: change ≥ the angle;
  - right turn: change ≤ −(the angle).
- **Obligation (c9):** for every intersection i and every pair (d, m) with m ∈ {straight, the side opposite d}: if x leaves i with passage m, then at the entry, for every c and every s meeting the same selection (restated whole), two things hold:
  - `count` of rises of (`circular_red` ∧ `green_arrow(d)`), counted since the latest run of `drv_motion_halted(x) ∧ rel_occupies(x,c)` began, is `gt 2`. The 2 is the node's own bound on the count operator.
  - At every observation of that latest halt run, s shows neither `circular_green` nor `green_arrow(m)`. This is written as `since(¬wait, wait ∧ since(wait ∧ ¬permits, ¬wait))`.
  
  If the halt run reaches the start of the recording, both parts are unknown.

## Choices the node left open

- **`.not (.same c i)` in the selection.** The intersection is itself a travel region, and x always occupies it at the entry. `st_lane_enters(i, i)` is unknown, because an intersection never carries `lane.enters_intersection` (TraceLint forbids it). By the contract of `st.lane_enters`, an intersection is not an approach to itself. Without this guard, a compliant case where s governs i would always come out unknown. I wrote the same guard in the applicability and in the obligation so the two selections stay identical. I did not declare it as a narrowing: the selection is part of a trigger span, and the guard only states what the contract already excludes.
- **Where the count and the "no change" check are read.** Both are read at the entry observation, as the record says. The count therefore also includes rises between the end of the wait and the entry.
- No narrowings were declared.

## Witnesses

Common setup: one scene every 50 ms; approach lane c enters intersection i, with exit lanes to the north, east and west. Occupancy is stated from x's footprint. Every witness's window runs from the second scene to the last.

| Witness | Expected | What happens |
|---|---|---|
| forbid | violated | one rise, then straight through |
| permit | compliant | three rises, then straight through |
| idle | not applicable | x is a pedestrian |
| blind | unknown | indications not observed, and `dev.traffic_signal` masked |
| branch_1 | violated | three rises, but `circular_green` shown during the wait |
| history_boundary | unknown | x is halted from the first scene; one rise |
| branch_2 | compliant | s governs i only; three rises |
| branch_3 | violated | left arrow, one rise, then a right turn |
| branch_4 | violated | right arrow, one rise, then a left turn |
| branch_5 | violated | s governs i only; one rise |

## Access notes

A `grep` over Core was denied: compound shell commands need approval and this session has none. I read the Core files with the Read tool instead (`Semantics.lean`, `Temporal.lean`, `TraceLint.lean`, `Manifest.lean`, `Builders.lean`, `Atoms.lean`).

## Why I finished

The gate returned OK on the second counted run.
