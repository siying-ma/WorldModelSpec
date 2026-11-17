# NRS_484B_307_4a_o2 — task result

## Final verdict: OK

`OK — 8 witnesses, 14 names, composes nothing`

## Gate runs

1. **UNUSED_CLAIM**: run on the harness skeleton before I edited anything. It lists every claimed name as unused, which is expected for the placeholders. This run did nothing useful and spent one of the budget's runs.
2. **(verdict not seen)**: my mistake. I ran the gate command a second time with `| head -0` appended. That is not the exact command I was told to run, and the output was thrown away. The files were still the unedited skeleton, so the verdict would have been the same as run 1. It probably counted against the budget.
3. **BUILD_FAIL** (rule line 144): I had written `Term.measure` with three arguments (`[]` for params), but it takes only two. I fixed that. As a precaution I also renamed the helper definitions in both files to prefixed names so they cannot clash with names from the opened `TrafficSpec` namespace.
4. **OK**.

## How the rule is written

- **Binder `subject`**: member of `DEF-NRS-484A-285::traffic` and of `DEF-NRS-484A-320::vehicle` (`ru_aggregate`, both required).
- **s1**: a device `d` of kind `traffic_signal` is "green turn arrow alone" when:
  - it shows `green_arrow(dir)` for one `dir` among left, right and u_turn;
  - it shows none of the other 22 indications of the enumeration (each tested with `dev_traffic_signal_shows` and negated).
- **s2**: there is an intersection `i`, a `travel_region` `c` with `st_lane_enters(c, i)`, and `dev_governs(d, c)`. The subject faces the signal when either:
  - it occupies `c`; or
  - it occupies `i`, and `since(occupies(subject, i), occupies(subject, c))` holds.
- **Obligation**: `i`, `c` and `d` are bound again with the applicability's whole selection, and the duty applies at every selection (`forallRegion` / `forallDevice` … `implies`). For every user `u` that is not the subject (`same`):
  - `u` is protected if either:
    - (s7, s8) it is a pedestrian occupying a crosswalk `x` that marks the entrance (`st_entrance_of`) of a carrier `c2` entering `i`; or
    - (s9, s10) it is a member of traffic occupying `i`.
  - The subject must not do the following to a protected `u`: move faster than `p.halt_speed_tolerance` while either:
    - `prim.closest_approach_within` over `p.conflict_horizon` holds and `prim.closest_approach_distance` is below `p.conflict_centre_clearance`; or
    - `rel.contact` holds.
- **Narrowings**: none. The only open choices were the record's own (the "lawfully" and "adjacent crosswalk" narrowing on s6), and they are written as the record states them.

## Witnesses

- **Shared layout**:
  - intersection 1 (20 × 20 m);
  - lane 2, northbound, enters 1 and is governed by signal 10;
  - crosswalk 3, marks the entrance of lane 2;
  - lane 4, eastbound on the west leg, enters 1;
  - crosswalk 5, marks the entrance of lane 4.
- **forbid** (violated): the subject turns west at 6 m/s. The pedestrian is in crosswalk 5, and the centres come to about 1.0 m of each other in about 1.5 s.
- **permit** (compliant): the subject stands at 0 m/s while the pedestrian crosses, then turns once the pedestrian has left the crosswalk.
- **idle** (not_applicable): the signal shows `circular_red`.
- **blind** (unknown): the same scene as forbid, with `dev.traffic_signal` masked.
- **branch_1** (compliant): the subject turns alone. This exercises the `same` leaf.
- **branch_2** (violated, added): the subject is in contact with another vehicle in the intersection that has the same velocity, so there is no closest approach. This exercises `rel.contact` and the "traffic occupying `i`" limb.
- **branch_3** (violated, added): the subject is still in lane 2 and the pedestrian is in crosswalk 3. This exercises the "occupies `c`" limb and the crosswalk-marks-the-entrance path.
- **branch_4** (not_applicable, added): the signal shows `green_arrow(left)` together with `circular_red`, so the arrow is not "alone".

## Why I finished

The gate returned OK on run 4. Nothing in the node needed reporting as a defect.
