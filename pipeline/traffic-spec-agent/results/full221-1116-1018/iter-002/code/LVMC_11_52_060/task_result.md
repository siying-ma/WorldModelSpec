# LVMC_11_52_060 — task result

**Final verdict: OK** (5 witnesses, 11 names, composes nothing)

## Gate runs
1. `OK`: first run, on the files as first written. Nothing changed afterwards.

(One stray shell command, `echo skip`, was run by mistake. It was not a gate run and touched nothing.)

## How the rule is written
- **Binder class (s1, s3):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` or `ru_aggregate subject "DEF-LVMC-11-02-170::trailer"`.
- **Applicability (s5):** `drv_motion_parked(subject; p.halt_speed_tolerance, p.parking_min_duration)`, and some region of kind `highway` that `rel_occupies` holds for. s4 is a residue with no formula.
- **Obligation (s5, with s1 and s2 through kin.extent):** for every highway h the subject occupies, every road edge c with `st_on_way c h` whose `st_region_geometry_distance` is at most that of every road edge on h (the curb the vehicle stands at), and every travel region r the subject occupies, this must hold:
  `dist(c) + length·|hx·dy − hy·dx| + width·|hx·dx + hy·dy| ≤ Units.feet 15`.
  The heading comes from `kin_heading`, the direction from `st_lane_direction` of r, and the length and width from `kin_extent`.

## Choices left open
None beyond the record's own narrowings, so the rule declares no narrowing of its own. Where a choice came up, I followed the record:
- I used "every" over the occupied highways, the nearest curbs and the occupied travel regions, as the record states.
- If two road edges are equally near, both are judged.

## Witnesses
The street is highway 10, with a curb on each side (road edges 20 and 21, both on highway 10) and two lanes (31 eastbound, 32 westbound). Each trace has 61 scenes 10 s apart, and the judged window is 200–600 s, so the 180 s parking look-back stays inside the trace.
- **forbid:** a truck at right angles to the curb, projecting 10.2 m.
- **permit:** a parallel-parked car, projecting 2.1 m.
- **idle:** a car moving at 12 m/s.
- **blind:** the forbid scene with st.region_geometry masked.
- **branch_1:** a trailer (trailer_or_combination) at right angles to the curb, projecting 8.1 m.

## Why I finished
The gate returned OK on the first run.

## Observation (not a defect report)
The admitted aggregate `DEF-LVMC-11-02-170::trailer` has no included class, so its `ru_aggregate` disjunct can never be true. A trailer is classed as a member through the vehicle aggregate, where `trailer_or_combination` is included. The gate did not flag this disjunct as vacuous.
