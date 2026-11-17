# LVMC_11_40_140_o1 — task result

## Final verdict: OK
Gate output: 13 witnesses, 8 names, composes nothing.

## Gate runs
1. By mistake I ran the gate command once with a pipe after it (`… 2>&1 | head -0; true`).
   That broke the "exact command" rule. It ran against the harness skeletons, before I changed
   anything, and its output was thrown away, so I never saw that verdict. It probably used one
   run of the budget.
2. `OK`: the first run on the finished rule and witnesses. No changes followed.

## How the rule is written (also in the rule file's header)
- **e1**: the class is `ru_aggregate` over the three admitted aggregate ids, joined by `or`.
- **e2**: `asm.business_or_residence_district`, checked at the observation where the subject
  enters the sidewalk.
- **e5**: the entry onto a sidewalk region s is `rises (rel_occupies subject s)`.
- **e3** has three alternatives:
  - (i) the subject is in an alley or a driveway/alley entrance at the entry, or was at the
    observation before. Written as `AD ∨ rises ¬AD`.
  - (ii) at the observation before, the subject was in no highway region. Written as
    `rises H`. When H holds at the entry, this is exactly "no highway region before". When H
    does not hold at the entry, alternative (iii) is already true at the entry, so the whole
    `or` gives the same result as the record's wording.
  - (iii) `until (rel_occupies subject s) (¬H)`.
- **e4**:
  - The stopping zone is: not on s, and `st_region_geometry_distance(subject, s) ≤
    p.stop_point_tolerance`.
  - The search is `since Zone (Zone ∧ drv_motion_complete_halt(subject; p.halt_speed_tolerance))`.
    It ends at the approach start or at the previous time the subject occupied s. It is unknown
    when it reaches the start of the recording, or when the distance or occupancy is unobserved.
  - The search is read at the observation before the entry, written `rises ¬search`. At the
    entry the search is decided false because the subject occupies s.
- **Rule 3c**: the obligation repeats the applicability's full selection of s, under a
  `forallRegion sidewalk`.
- **Narrowings**: none. Every choice above follows the record's applicability and obligation.

## Witnesses
- The six planned witnesses have the planned verdicts.
- I added `branch_2` to `branch_8` so that every leaf changes some decided witness:

| Witness | Verdict | What it exercises |
|---|---|---|
| `branch_2` | violated | Leaving an alley, through the alley-at-the-previous-observation leaf (electric bicycle) |
| `branch_3` | violated | Entering an alley across the sidewalk |
| `branch_4` | violated | Entering a driveway across the sidewalk |
| `branch_5` | violated | Leaving a building, through `rises H` |
| `branch_6` | violated | Entering a building, through `until` |
| `branch_7` | violated | Re-entry after an earlier entry; the earlier halt does not count |
| `branch_8` | not applicable | A pedestrian, so all three class aggregates are false |

- `idle` and `blind` set `window` so that the first instant is left out. At that instant
  `rises` cannot be read (`windowTruncated rises`), because the scooter (idle) and the bicycle
  (blind) are already on a sidewalk.

## Deviation from the `blind` narrative
- The planned narrative is "no halt recorded". With geometry masked, a recording with no halt
  can never be unknown only because geometry is missing:
  - If the search reaches an earlier time the subject occupied s, there is no halt before it,
    so the verdict is decided: violated.
  - Otherwise the search runs back to the start of the recording, and the result also carries
    `windowTruncated since`. The gate rejects that reason on a witness with no history
    boundary.
- So in the blind scene the bicycle:
  1. starts on the sidewalk;
  2. turns into the driveway;
  3. stands still once where it turns round (the masked geometry cannot tell whether that point
     is in the zone);
  4. comes back out with no further halt.
- The result is unknown only because of `st.region_geometry`.
- Recommendation for the planner: the blind narrative should allow a recorded halt whose place
  relative to the zone cannot be read.

## Why I finished
The gate returned `OK`.
