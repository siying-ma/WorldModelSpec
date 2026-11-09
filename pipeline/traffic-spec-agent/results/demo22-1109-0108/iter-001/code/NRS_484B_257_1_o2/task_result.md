# NRS_484B_257_1_o2 — coding session result

**Final verdict: `OK`** (16 witnesses, 26 names, composes nothing, 2 coder narrowings).

## Gate runs (budget 6, used 2)

| run | verdict | what changed after it |
|---|---|---|
| 1 | `VACUOUS` — five leaves moved no decided witness: `dev_governs [o, l]` and `dev_governs [sg, j]` in the applicability; `dev_governs [y, l]`, `st_region_geometry_distance [u, j] ≤ speed·headway` and `rel_contact [v, u]` in the obligation | Added `branch_10` (a van whose body reaches into the junction from the through carrier strikes the car while the two hold the same velocity: privileged by the headway bound alone, since their centres never approach, and the duty broken by the contact alone — this makes both the headway leaf and the contact leaf decide); added `branch_11` (an officer directing the traffic of the approach carrier) and `branch_12` (a signal governing the junction), so that each of the four officer/signal × junction/carrier governance leaves decides a witness; moved `branch_5` (the surface-gap conflict, violated) onto a yield-governed approach, so that the yield-sign limb of the obligation's carrier selection decides a verdict as the stop-sign limb already did in `forbid`, `branch_1` and `branch_10` |
| 2 | `OK` | nothing |

The rule and the witnesses built, checked and matched their expected verdicts on the first run;
only the adequacy of the witness set was short.

## How the node's spans are written

The per-span account is in the rule file's header. In brief:

- **s1** → the binder's class, `ru_aggregate` with `DEF-NRS-484A-320::vehicle`.
- **c2** → `movingInJunction`: `rel_occupies` on a region the `intersection` quantifier ranges
  over, and `kin_speed` above `p.standstill_speed_tolerance`. That junction is the region every
  other span speaks of, and the obligation re-selects it with the same relations.
- **c1** → `actedOnApproach`: a rising edge of the act since the start of the subject's latest run
  of occupying the carrier it approached through (`Formula.count`), so the search into the past
  ends at the beginning of that approach, exactly as the record's applicability states, and is
  unknown exactly where that approach begins before the recording. The act is `haltOrSlowed`: the
  place the first sentence names, in its order (the stop line marking that carrier's entrance,
  else a crosswalk marking it, else the point where the view along a way of the junction reaches
  `p.intersecting_way_view_distance`), together with `drv.motion.standstill` or, under a yield sign
  and no stop sign, a speed at or below `p.yield_sign_slowed_max_speed`. The carrier is selected by
  `st_lane_enters` into that junction and by a stop or yield sign governing it.
- **e1** → `controlledHere`, conjoined negated: an officer (role `police_officer`) or a
  traffic-control signal governs the junction or the approach carrier, and traffic of
  `DEF-NRS-484A-285::traffic` occupies the region so governed.
- **ob1/st1** → the obligation: for every junction the subject occupies, for the carrier the
  condition selected, and for every way of that junction its own carrier does not lie on (the
  crossing, through highway), every road user of the aggregate other than the subject that has
  entered the junction from a carrier on that highway and lain within it since
  (`drv.motion.region_entry` with `rel_occupies` under a past `since`), or that occupies such a
  carrier and is within the headway bound or in conflict, is granted precedence: no `rel.contact`
  and no closest approach below `p.yield_min_clearance`.

## Choices the node left open (and the two declared narrowings)

1. **ob1 — how the clearance is measured** (declared narrowing, `reading`). The primitives compute
   the closest approach on the two *centres*, while the convention names the clearance *between the
   nearest points of the bodies* and gives `rel.surface_gap` for it. I read "the closest approach
   below the clearance" as the disjunction: the centre distance at the closest approach within
   `p.yield_conflict_horizon` below `p.yield_min_clearance`, or the present nearest-point gap below
   it. `branch_1` decides on the first limb, `branch_5` on the second.
2. **st1 — the two figures are alternatives** (declared narrowing, `reading`). The
   operationalization's convention reads the two figures "in the same breath"; the node's own
   `obligation` states them with "or" ("its distance to the junction at most its speed times
   p.yield_headway_time, **or** its closest approach ... below p.yield_min_clearance"). I followed
   the obligation and wrote a disjunction, which is also the wider (more protective) reading.
3. **The place at a mark** (c1, a trigger span, so carried, not narrowed): the record gives both
   `st.region_geometry` ("the distance between the body and the mark that the stop-point tolerance
   bounds") and `prim.region_offset_along` ("the side along st.lane_direction"). I wrote the two
   jobs the record assigns them: body-to-mark distance at most `p.stop_point_tolerance`, and the
   signed offset to the mark along the carrier's direction at or above zero (the mark not behind
   the body). `branch_8` shows the offset leaf doing work: a car standing inside the junction has
   its body touching the stop line but has passed it.
4. **"such through highway"** (the record's own `observable_reading` on ob1, not restated): written
   as a way of the junction (`st_on_way`, `st_highway` quantifier) that is *not* a way the
   subject's own governed carrier lies on — the crossing highway at whose entrance the subject's
   sign stands. Read with `forallRegion`, not `existsRegion`, so the duty is owed on every such
   highway and no favourable way is picked.
5. **"traffic is being controlled"** (e1, a trigger span, carried): read as traffic of the aggregate
   occupying the region the device governs, quantified over the scene's road users (the subject
   itself counts as traffic where it is). The alternative — reading the governance alone, with no
   traffic present — would not use the aggregate atom the element claims.
6. **`st.lane_direction`** (claimed by c1) is read where the record puts it: inside
   `prim.region_offset_along`, whose contract names it as the direction the offset is measured
   along. No formula reads it directly.

## Witnesses

16: the four planned (`forbid`, `permit`, `idle`, `blind`), the two planned branches, and ten of
mine. Every scene is built on one map (a northbound minor approach with a stop or yield line, an
eastbound through carrier, a junction, and the two highway regions), documented at the top of the
witness file. The added branches exercise: the crosswalk place limb (`branch_3`), the view-point
place limb (`branch_4`), the nearest-point conflict limb on a yield-governed approach
(`branch_5`), the officer and signal limbs of the exception on both the junction and the carrier
(`branch_6`, `branch_7`, `branch_11`, `branch_12`), the "moving across or within" condition
(`branch_8`, a car standing inside the junction), the aggregate on the other road user
(`branch_9`, a pedestrian in the junction), and the headway bound with contact (`branch_10`).
No witness is unknown through a truncated window: every course spends an observation off the
approach carrier before reaching it, so the search back over the approach begins inside the trace.

## Why I finished

The gate returned `OK` with the two files as they stand, every claimed name used, every planned
scenario present with its planned verdict, and the readings I chose recorded as narrowings on the
rule. The node needed no repair: nothing in it was wrong, nothing unexpressible, and no concept it
calls computed anything its contract excludes (so no `dependency_defect.json`). Four gate runs of
the budget are unused.
