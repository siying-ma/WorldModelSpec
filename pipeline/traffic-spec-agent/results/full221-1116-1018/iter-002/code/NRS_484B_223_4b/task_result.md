# NRS_484B_223_4b — task result

**Final verdict: OK** (6 witnesses, 7 names, composes nothing). Used 3 of the 6 gate runs.

## Gate runs
1. **WITNESS_FAIL** on `permit`. The adapter's consistency check found that the heading stayed fixed while the yaw rate said it turned (the rate at a scene is held over the interval before it). My first turn was a constant −90 deg/s with a fixed heading.
   - Change: removed the heading and velocity vectors on the turning trace.
2. **WITNESS_FAIL** on `permit`. Without a heading, the track's footprint is undefined, but its occupancy is observed.
   - Change: rebuilt the turn as two exact −45° steps, so every heading is a rational vector: north → (1,1) → east, with a yaw rate of −900 deg/s at k = 13 and 14. Total heading change since entry is −90°.
   - Also rewrote every witness so its stated occupancy matches the footprint geometry (4 m × 1.8 m body, 0.5 m per 50 ms step), and added a second northbound exit lane N′ for a straight passage out of L.
3. **OK**.

## How the rule is written
- **Class (s2):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Occasion:** a passage through an intersection `x` (`existsRegion "intersection"`).
  - Onset: `rises (rel_occupies subject x)`.
  - Recognition (the exit): `rises (not (rel_occupies subject x))`.
- **s1 (at_recognition):** checked at the exit. There is a `turn_lane` region `l` with `st_turn_lane_side l right` and `st_lane_enters l x`.
- **s3 (some_moment over the act stretch):** `since (not entry) (rel_occupies subject l)`. The footprint overlapped `l` at some observation from the latest entry (included) up to the exit. Any overlap before that entry doesn't count, so the stretch is exactly onset to recognition of this occurrence.
- **s4:** at the exit, `rises (drv_motion_right_turn_through_region subject x)` with step `p.heading_since_step_carla_scene_graph`, turn_min `p.turn_heading_min` and u_turn_min `p.u_turn_heading_min`.
- **Obligation:** repeats the whole selection of `x` (exit, plus a right turn lane entering `x` occupied during the passage) and requires s4 for every intersection so selected (`forallRegion … implies`).

## Choices the node left open
- **Where `l` is bound:** I quantify the lane at the exit (s1 is read at recognition). Its occupancy is then searched over the passage with `since` (s3 is read at some moment). This is not a narrowing.
- **Recognition:** the concept holds only at the exit, so its `rises` is its recognition (rule 6b).
- **No narrowings of my own.** The record's agency reading on s3 is not restated.

## Witness notes
- **Window:** every witness sets `window = [50, 1350] ms`. At the first scene the exit's `rises` has no previous observation and is unknown there; nothing of the passage happens at that scene.
- **`occasion_s3`:** the narrative says the subject is in "only X" after its entry. In the built scene its rear stays in the plain through lane T until it clears the approach, because a 4 m body can't leave the approach lanes within one 50 ms step. It never overlaps L after the entry, which is the fact the scenario tests.

## Why I finished
The gate returned OK.
