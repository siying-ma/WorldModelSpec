# NRS_484B_407 — task result

**Final verdict: OK** (10 witnesses, 10 names, composes nothing)

## Gate runs (3 of 6 used)
1. `UNUSED_CLAIM` — the skeleton as the harness wrote it, before any edit. I ran this by mistake while meaning to read a Core file.
2. `UNUSED_CLAIM` — the skeleton again, also a stray run (same mistake). Nothing had changed.
3. `OK` — after I wrote the rule and all ten witnesses.

Two other shell calls were also mistakes. A directory listing of Core ran. A `--help` probe of the gate was denied by permissions. Neither changed any file.

## Rule
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Under way (U): `|kin_yaw_rate(subject)| > p.turn_yaw_rate_tol`.
- s3: there is a roadway region the subject occupies (`rel_occupies`) whose `st_curvature` is greater than `p.curvature_resolution`.
- s4: there is a crest region whose `st_region_geometry_distance` from the subject is at most `p.crest_near_reach`.
- s5: there is a roadway region the subject occupies whose `st_sight_distance` is less than `Units.feet 500`.
- Applicability (occasion, window boundary, `some_moment` for s3, s4 and s5): `¬ holdsFor time p.vehicle_turn_window subject ¬(U ∧ ((s3 ∨ s4) ∧ s5))`. One observation has to carry U and the whole condition together.
- Obligation: `¬ drv_motion_u_turn(subject; p.vehicle_turn_window, p.u_turn_heading_min, p.turn_yaw_rate_tol)`.

## Choices the node left open
- **"At its place" for s5:** `st_sight_distance` is read from a region, so I took the roadway region the subject occupies. It uses `rel_occupies` and the roadway kind, both already claimed by s3. I don't count this as a narrowing, since s5 is a condition span. The rule file's header explains it.
- s3 and s5 each use their own roadway quantifier. Where the subject straddles two roadway regions, either one can satisfy each span.
- No narrowings are declared.

## Witnesses
- **Shared setup:** a 23 s trace sampled every second. The subject turns at 30 °/s from t = 12 to 17 s (180°), and the reversal is recognized at t = 18 s.
- **Window:** every witness names t = 11–22 s, so the 10 s window behind each instant is covered.
- **permit:** the subject follows the bend at 6 °/s, which is above the yaw tolerance. The rule is engaged, there is no reversal, so the result is compliant.
- **occasion layouts:** the change of region is placed so that only the middle of the turn lies on the curve, the crest reach or the short-sight region.
- **"outside" layouts:** the subject passes that region with zero yaw, at least five seconds before the turn.
- **Turn path:** a U-turn returns toward where it started, so it can't run straight along the road. In `occasion_s3` it is therefore the middle of the turn (t = 13–15 s), not strictly its second half, that lies on the bend. The turn still begins on the straight, which is what the occasion tests.

## Why I finished
The gate returned OK.
