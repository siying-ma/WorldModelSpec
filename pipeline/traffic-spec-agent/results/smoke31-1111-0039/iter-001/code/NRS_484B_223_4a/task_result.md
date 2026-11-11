# NRS_484B_223_4a — task result

**Final verdict: OK** (9 witnesses, 11 names, composes nothing).

## Gate runs (5 of 6 used)

1. `UNUSED_CLAIM` — run by mistake on the untouched skeleton (every formula still `.tt`); it only
   listed the claimed names. Nothing changed after it.
2. Unintended second run: I wrapped the gate command in a pipe meant as a no-op, but it executed
   the gate again on the same skeleton. Its output was discarded and nothing changed. Both wasted
   runs were my mistake; I also ran one `grep` over Core before switching to the Read tool.
3. `WITNESS_FAIL` — the turning witnesses (permit, blind, branch_3, branch_4) were not traces an
   adapter could produce: their headings did not follow the yaw rate. The rate at a scene is held
   over the interval before it. **Change:** I rebuilt every motion from a heading index in 4.5°
   steps. One index step between scenes 50 ms apart is ∓90 deg/s. Headings come from a cosine
   table in millionths, positions are integrated at 0.5 m per step (10 m/s), and occupancy is
   computed from each body's footprint against the region polygons.
4. `VACUOUS` — obligation leaf `st_turn_lane_side N right` (the obligation's copy of the "single"
   check) moved no witness. **Change:** I added `branch_5` (violated). On a T-junction approach the
   left neighbour of the single right turn lane is a *left* turn lane, and the car moves back into
   it. If the leaf is dropped, L stops counting as single in the obligation and the witness would
   turn compliant.
5. `OK`.

## How the record is written

- Class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability (d1, d2): some `turn_lane` region L meets all of the following:
  - it has side right;
  - it lies on (`st_on_way`) some `highway` region;
  - no `turn_lane` region of side right is its left or right neighbour (`st_lane_adjacency` "left" / "right");
  - x occupies it now or did earlier (`since tt (rel_occupies x L)`).
- Obligation (d4): for every L selected the same way, and every `intersection` I that L enters
  (`st_lane_enters`), neither of these holds:
  - (a) `rises (not occ L)`, with x in the `lane` that is L's left neighbour and not in I;
  - (b) `rises (not occ I)`, with `since tt (rises (occ I) ∧ occ L)`, and
    `drv_motion_heading_change_since_entry(x, I; p.heading_since_step_carla_scene_graph) > −p.turn_recognition_angle`.
- No narrowings of my own: every reading is the record's. Residues, operationalizations and
  other declarations are left as the skeleton had them.

## Choices the node left open

- I wrote "occupied at an earlier observation" as `since tt` (now or earlier). "Having begun to
  overlap I at an observation at which it occupied L" is `since tt` over the entry edge
  `rises (occ I) ∧ occ L`.
- Witnesses judge the instants from 50 ms on (`window`). At the first scene, `rises` and `since`
  have no predecessor, so they are truncated and unknown.
- Extra witnesses beyond the plan's six:
  - `branch_3` (compliant): the car leaves L into I while its body still overlaps the through
    lane's end, then turns right. This exercises "not occupying I" in (a). For this, the through
    lane polygon runs 2 m into the intersection.
  - `branch_4` (compliant): the car leaves L to the right into a side street. This exercises the
    left-neighbour and occupancy leaves of (a).
  - `branch_5` (violated): described in gate run 4 above.

## Why I finished

The gate returned OK on both files as they stand. Nothing in the node needs repair.
