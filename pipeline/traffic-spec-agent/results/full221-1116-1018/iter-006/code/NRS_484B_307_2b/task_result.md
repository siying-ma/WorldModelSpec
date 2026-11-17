# NRS_484B_307_2b — task result

## Final verdict

**UNANCHORED_VARIABLE** (node defect, s1/s3). Gate runs used: 3 of 6.

## Gate runs

1. **UNANCHORED_VARIABLE**: "the quantified variable `d` shares no atom with a binder, nor with a
   variable that does … tie it in the formula through `rel_occupies`,
   `st_region_geometry_distance`, `dev_governs` or a relation to a binder".
   At this point the rule was written as the record maps it. `d` ranges over the scene's
   traffic signals. It is tied to `subject` only by the s3 facing comparisons, which read
   `dev_position(d)` together with the subject's `kin_position` and `kin_heading`:
   v·h > 0, (v·h)² ≥ cos²·|v|², and |v|² ≤ reach².
2. **UNANCHORED_VARIABLE**, same message. This was a probe to see whether the checker missed reads
   nested under `.mul`. I added the implied conjunct |dx| ≤ reach (`.abs (.sub …)`), which follows
   from |v|² ≤ reach².
3. **UNANCHORED_VARIABLE**, same message. Second probe: I wrote the implied bound with the device
   read bare on one side of each comparison: `dev_x ≤ pos_x + reach` and `dev_x ≥ pos_x − reach`.

Both probe conjuncts are now removed. The rule file holds the record's reading only.

## Why the node is wrong (what the plan agent must change)

- **Spans s1 and s3.** s1 quantifies a traffic signal `d`. s3 relates it to the pedestrian only
  through `dev.position` versus `kin.position`/`kin.heading`.
- **Why the gate rejects it.** Three runs show that a comparison of device position against
  subject position is not an anchoring relation for a device. That holds whatever shape the
  comparison takes. The gate's message names `dev_governs` as the device anchor, and the node does
  not claim `dev.governs`.
- **What can be done here.** Among the claimed names, `rel_occupies` relates road users and regions
  only. No claimed atom can tie `d` to the subject, so it cannot be fixed in this session.
- **What the plan must change:** tie the signal to the subject through a claimed anchoring atom.
  The natural choice is `dev.governs(d, l)` on the lane `l` the subject crosses (or on the
  roadway), which the s4 `rel_occupies` already anchors. The facing comparison of s3 stays as a
  further condition on that governed head. Alternatively, the planner can confirm a reading under
  which a device is anchored by position comparisons, and the gate's anchoring rule must then
  accept it. In that case I'm reporting a discrepancy between the prompt's rule 3b ("a comparison
  that reads both") and the gate's behaviour on devices.

## How the rule is written (ready once anchoring is resolved)

- **s2:** `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- **s1:** `existsDevice traffic_signal d`, with `dev_traffic_signal_shows(d, circular_green)` and
  `not shows(d, s)` for every other state the contract lists. Those are circular_yellow,
  circular_red, flashing_red, flashing_yellow, dark, unknown, and each of the four arrow kinds in
  each of the four directions.
- **s3:** the facing comparisons on squares, exactly as the record states them.
- **s4:** the subject occupies some roadway `r`, and occupies some lane `l` for which
  `drv_motion_moving_across_carrier(subject, l; p.halt_speed_tolerance, p.crossing_motion_cos)`
  holds.
  - Choice: no claimed atom relates a lane to its roadway, so "a lane of a roadway" is written as
    the subject occupying both, as the element lists.
- **s5 (obligation):** `existsRegion crosswalk x, rel_occupies(subject, x)`.
- **s6:** `not ruleApplies` for each of the six compositions, mapping subject to subject.
- **Narrowings:** none.

## Witnesses (built, not yet judged by the gate)

- **Geometry:** an east–west roadway with two lanes. The pedestrian walks north across it at
  1.3 m/s. A signal head is about 25 m straight ahead.
- **Crosswalk:** placed at the pedestrian's path for `permit` and `branch_1`, and 30 m away for
  the others.
- **`idle`:** the head shows circular_red.
- **`blind`:** the head position is unobserved, and `dev.position` is masked.
- **`branch_1`:** a pedestrian signal at (0, 9) governing the crosswalk and lanes shows
  dont_walk_steady.
- **`branch_2`** (added): the head shows circular green with a green left arrow, so it is not
  "alone", and the expected verdict is not_applicable.

## Why I finished

The node is wrong. Its only tie between the quantified signal and the subject is a position
comparison, which the gate does not accept as anchoring, and the node claims no anchoring atom for
a device. Rule 3b says to report this rather than work around it.
