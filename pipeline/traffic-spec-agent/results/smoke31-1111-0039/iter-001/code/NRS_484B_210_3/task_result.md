# NRS_484B_210_3 — task result

**Final verdict: OK** (9 witnesses, 7 names, composes nothing). Three gate runs out of the six allowed.

## Gate runs
1. **WITNESS_FAIL**: `blind` expected unknown and got violated. Masking `rel.bearing` drops only a
   measured bearing (`Runtime/Manifest.lean`, `Mask.relation`). `rel_bearing` falls back to the
   kinematic frame (`Vocab/Atoms.lean`, `relFrame`), so with both positions observed the side was
   still decided.
   **Change:** in `blind`, the other car has no observed position. Its heading, speed and extent are
   still observed. The overlap along the subject's heading is supplied as a measured relation; Core
   cannot compute it without that position. Once the bearing is masked, the side cannot be known.
2. **WITNESS_FAIL**: the trace admission rejected track 2: it was in `occupancyObserved` but had
   no footprint.
   **Change:** in `blind`, `occupancyObserved := [1]`, so only the subject's occupancy is observed.
3. **OK.**

## How the rule is written
- **Class of x (f1):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (f3):** two alternatives joined by `or`:
  - x occupies (`rel_occupies`) a `shoulder` region whose `st_shoulder_paved` is false;
  - x occupies a `road_edge` region whose `st_road_edge_paved` is false.

  Each region has its own `existsRegion` over the kind and is tied to x by `rel_occupies`.
- **Obligation (f2):** there is no user y such that all of these hold:
  - y is not x (`same`);
  - y is in the same vehicle aggregate;
  - `drv_interaction_passing_on_right(x, y)` holds, with `[p.same_direction_cosine, p.overtaking_speed_margin]` (the order of the concept's formal parameters).

## Choices left open
None beyond the record. `narrowings` stays empty: the record's own narrowings (the two agency
readings and the side-by-side phase) are not restated. Everything else is taken directly from the
record's applicability and obligation.

## Witnesses
The planned ones are `forbid`, `permit`, `idle`, `blind` and `branch_1`. I added branches so that
every leaf is exercised:
- **`branch_2`** (violated): the alternative where x is on a road edge with an unpaved surface beyond it.
- **`branch_3`** (compliant): the car passed is a bicycle, so y is not in the aggregate.
- **`branch_4`** (not applicable): the shoulder is paved.
- **`branch_5`** (not applicable): the surface beyond the road edge is paved.

## Why I finished
The gate returned OK. I found nothing wrong with the node, and no concept defect to report.
