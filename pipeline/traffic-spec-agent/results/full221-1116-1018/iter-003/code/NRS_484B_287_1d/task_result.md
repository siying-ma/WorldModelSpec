# NRS_484B_287_1d — task result

**Final verdict: OK** (5 witnesses, 8 names; composes LVMC_11_30_140_B_o1 and LVMC_11_30_140_B_o2).

## Gate runs
1. OK. This was the first run, so nothing changed after it.

## How the rule is written
- **Class (s2):** `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- **Applicability (s2/s3, s1):** the rule applies when, for some region `x` of kind `intersection`, the subject's footprint overlaps `x` (`rel_occupies`) and some region of kind `lane` runs into `x` (`st_lane_enters(l, x)`). Both LVMC_11_30_140_B_o1 and LVMC_11_30_140_B_o2 must also not apply: each is written `.not (.ruleApplies …)`, with the map `subject ↦ subject`.
- **Obligation (s3, s4):** for every intersection `x`, the whole selection is restated (occupied by the subject, with a lane running into it). If the motion is diagonal, the subject must occupy a crosswalk `c` with `st_crosswalk_marked(c)`. The motion is diagonal when every lane `l` entering `x` has `drv_motion_moving_across_carrier(subject, l)` true at (p.halt_speed_tolerance, p.crossing_motion_cos) and false at (p.halt_speed_tolerance, p.right_angle_crossing_cos).
- **Narrowings:** none of my own. The record's own narrowings, including the observable reading of "official", are not restated.

## Choices left open
- I gave the duty a universal scope ("at every such intersection"), as the record's "at each such observation … x" implies.
- I wrote "some lane runs into x" as `existsRegion "lane"`, and quantified "every entering lane" over regions of kind `lane`, as the record names them.

## Witnesses
- **Layout:** intersection square 20 m on a side; four approach lanes running north, east, south and west, each recording `enters := 1`; pedestrian moving at 1.4 m/s.
- **forbid:** heading (3/5, 4/5). The absolute cosine is 0.8 against the north-south lanes and 0.6 against the east-west lanes, so the motion is oblique to every lane. No crosswalk, so the rule is violated.
- **permit:** walking east near the south edge of the intersection. The motion is along the east-west lanes, so it is not diagonal and the rule is complied with.
- **idle:** on a sidewalk outside the intersection, so the rule does not apply.
- **blind:** same as forbid, but `kin.velocity` is masked, so the result is unknown.
- **branch_1:** same as forbid, but inside a marked diagonal crosswalk, so the rule is complied with.

## Why I finished
The gate returned OK on the first run.
