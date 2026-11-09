# NRS_484B_227_1_o1 — coding session result

**Final verdict: `OK`** (8 witnesses, 11 names, composes nothing, 1 narrowing declared).

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing; the session finished on it |

Budget: 1 of 6 runs used.

## What each span became

- **s1 (subject/trigger).** `clsV` is `ru_aggregate v "DEF-NRS-484A-320::vehicle"` — the admitted
  aggregate id, not its classes. "driven upon" is `moving`, the negation of
  `drv.motion.standstill` with `p.standstill_speed_tolerance` (the plan's observable reading of
  agency, not restated as my narrowing). "a divided highway" is `uponDividedHighway`: a `st.highway`
  region `w` whose footprint the vehicle overlaps (`rel.occupies`), with `dividedWay` on it — a
  `st.median_or_divider` tied to `w` by `st.on_way`, and two `st.roadway` regions of `w`, each tied
  by `st.on_way` and distinct by `same`, which is the definition's division of the way into two or
  more roadways by a physical barrier.
- **s2 (duty).** `rightHandRoadway`, over a roadway `rw` of that same way the vehicle's footprint
  overlaps: `drv.position.direction_component` of the vehicle along `rw` above
  `.neg p.wrong_way_speed_tolerance`, and `prim.region_lateral_offset` of a dividing section of that
  way from the vehicle at least `p.lateral_offset_resolution`. The obligation re-states the whole
  selection of the way (occupancy, `st.highway`, `dividedWay`), so `w` denotes the region the
  applicability selected; a vehicle on the other roadway, the shoulder or the median overlaps no
  such roadway and violates the duty.
- **s3 (sibling).** No element maps it; the rule says nothing about it, as the node directs.
- **s4 (exception).** `.not exceptionOn` conjoined into the applicability: the vehicle's footprint
  overlaps either a dividing section of that way carrying the opening attribute
  (`st_median_or_divider_opening`, the atom's own crossover attribute) or an `st.intersection` of
  that way, each tied by `st.on_way` and `rel.occupies`. "established by a public authority" is the
  feature's presence (the plan's observable reading).

## Choices the node left open

1. **Which dividing section's side the duty reads** — declared as a narrowing on s2
   (`kind := "reading"`). The node's obligation says "that divider"; a barrier is mapped as a run of
   sections (a crossover or junction interrupts it), so I read the side of *some* dividing section of
   that way, not of every one.
2. **"two or more roadways"** written as two `st.roadway` regions of the way made distinct by
   `.same` under a negation — the record's own words, so no narrowing.
3. **The quantifier over the way** — existential in both formulas, matching the record's
   applicability ("overlaps a highway on which …"); the obligation repeats that same selection
   rather than quantifying universally over ways.
4. **The `blind` scene's geometry.** The node's narrative calls it "the forbid scene" with
   `st.lane_direction` absent. In the forbid geometry the recorded barrier alone decides the duty:
   its offset is negative (the divider is on the car's right), so the right-hand-roadway conjunct is
   *false* with or without the designation, and the verdict would be violated, not unknown. I
   therefore built `blind` on the nearside roadway — the barrier recorded 4 m to the car's left,
   velocity recorded — with the designated direction of travel masked, which is exactly the
   narrative's reason ("which roadway is the right-hand one for the car's travel cannot be read")
   and yields unknown. This is a witness-geometry choice, not a reading of the law.
5. **Two added branch witnesses**, needed because the planned scenes never reach two leaves:
   `branch_3` (not applicable — the car stands motionless on the opposite roadway, exercising the
   standstill limb of s1) and `branch_4` (not applicable — the car runs along the opposite roadway
   but within an intersection established where the barrier is broken, exercising the second limb of
   the s4 exception).

## Witness margins against the reading

Lateral offset ±4 m on the roadways and +10 m on the shoulder, against
`p.lateral_offset_resolution` = 0.5 m; direction component ±25 m/s against
`p.wrong_way_speed_tolerance` = 0.5 m/s; the standing car reads 0 m/s against
`p.standstill_speed_tolerance` = 0.1 m. Every divider carries `opening := some false` where the
scene has no crossover, so the exception is decided false rather than unobserved in `forbid`,
`permit`, `blind` and `branch_2`; `idle` has no `median_or_divider` region at all, so the
divided-highway conjunct is decided false.

## Why I finished

The gate returned `OK` on the first run: the rule builds, checks, uses every claimed name and no
other, every quantified region is anchored to the binder through `rel.occupies`/`st.on_way`, and all
eight witnesses reach their expected verdicts. Nothing in the node struck me as wrong, so there is
nothing for a repair session to change beyond the one narrowing recorded on the rule and the
`blind`-scene note above.
