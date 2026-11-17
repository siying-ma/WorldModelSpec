# LVMC_11_52_070 — task result

**Final verdict: OK** (8 witnesses, 11 names, composes nothing)

## Gate runs
1. `OK`. This was the first run, so nothing changed after it.

## How the rule is written
- **Subject class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (t1–t3):** some travel region `r` meets two conditions:
  - the subject occupies `r`;
  - at least one of these holds:
    - a regulatory sign with code `angle_parking` governs `r`;
    - the subject also occupies a parking space whose `|angle|` is greater than `p.parking_space_angle_resolution`.
- **Obligation (t4):** `drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration)` implies both of these:
  - the subject is in `DEF-NRS-484A-285::traffic`;
  - for every travel region selected by the same full selection (written again in the obligation, per rule 3c), heading · `st_lane_direction` > 0. This uses the x/y components of both vectors, compared with a literal zero.

## Choices the node left open
- **Where the claimed `DEF-NRS-484A-285::traffic` aggregate goes.** I wrote it as the subject's membership, joined by AND to the direction test. Under the run's classification every vehicle is also traffic. So this conjunct carries the claimed word without making the duty stricter or looser. I declared no narrowing.
- **No other choices.** The record states the selection, the quantifier over every selected region, the positive dot product and the standing window.

## Witnesses
All traces sample every 10 s. Verdicts are judged from 70 s on, so the 60 s parked window is fully covered at every judged instant.
- **Planned witnesses:**
  - `forbid` (violated): sign and 45° bay, car facing against the lane.
  - `permit` (compliant): same scene, car facing with traffic.
  - `idle` (not applicable): parallel bay at 0°, no sign.
  - `blind` (unknown): `kin.heading` masked.
  - `branch_1` (compliant): a 20 s halt between moving phases.
- **Added witnesses:**
  - `branch_2` (violated): bay alone, no sign.
  - `branch_3` (violated): sign alone, no bay.
  - `branch_4` (not applicable): a `no_parking` sign on the occupied lane, an `angle_parking` sign governing only the unoccupied opposite lane, and an angled bay that is not occupied.

## Why I finished
The gate returned `OK` on the first run.
