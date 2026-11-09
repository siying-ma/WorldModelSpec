# NRS_484B_250_4_o2 — coding session result

**Final verdict: `OK`** (14 witnesses, 24 names, composes nothing, 3 coder narrowings), on the
second of six permitted gate runs.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `VACUOUS` — obligation leaves 15, 16, 17 (the crosswalk limb of the halt place) and 20, 21 (the view-point limb) were exercised by no decided witness | The applicability's copies of those limbs were exercised by `branch_3` (crosswalk) and `branch_4` (view point), but both are *compliant* witnesses: flipping a leaf of the obligation's re-selection of the junction only switches the duty off, which cannot change a compliant verdict. Added `branch_9` (violated: no stop line marks the approach, the halt is made before the crosswalk, then entry at 8 m/s) and `branch_10` (violated: neither mark, the halt is made where the sight along the crossing way reaches the view distance, then entry at 8 m/s). In those, switching the duty off turns a violation into compliance, so every limb of the obligation's guard moves a decided witness. |
| 2 | `OK` | nothing |

## How the node is written (summary; the rule file's header has it per span)

* **t1** is the entry observation: `drv.motion.region_entry` of the subject into a region of kind
  `intersection`, with a device of kind `traffic_signal` uncovered (`dev.traffic_signal`),
  inoperative (`dev.inoperative`) and governing that region (`dev.governs`), all read at that
  observation, as "is inoperative at the time the vehicle enters the intersection" states.
* **c1** carries the halt with its full qualification: `drv.motion.standstill` on a
  `travel_region` the subject occupies whose entrance end is that junction (`st.lane_enters`), at
  the place the sibling sentence names in its own order — the stop line marking that carrier, else
  (no stop line marking it) at or before the crosswalk marking it, else (neither) a point from
  which `st.sight_along_way` along a way the junction lies on reaches
  `p.intersecting_way_view_distance`. "At or before the mark" is the sign of
  `prim.region_offset_along` along the carrier's direction plus the body-to-mark distance of
  `st.region_geometry` under `p.stop_point_tolerance`.
* **The history bound** is the record's own: `count` of halts at the place since the latest run of
  "the subject is on that approach carrier" began — the start of that approach, and nowhere else.
  No window length and no invented boundary is used; where that run reaches past the recording the
  count is unknown, exactly as the record says the condition then is.
* **st1/ob1**: the speed bound `kin.speed ≤ p.cautious_proceed_max_speed`, and precedence for every
  other road user of the aggregate that halted at an entrance of this junction or lies within it:
  no entry while it lies within (`drv.motion.region_entry`), no contact (`rel.contact`), and, where
  the centres approach within `p.yield_conflict_horizon` (`prim.closest_approach_within`), no
  closest centre approach (`prim.closest_approach_distance`) and no present body clearance
  (`rel.surface_gap`) below `p.yield_min_clearance`.

## Choices the node left open (declared as narrowings on `ob1` / `st1`)

1. **`ob1` — "have previously completed a stop"** is read as a standstill of that road user, on a
   carrier whose entrance end is this junction, at some observation of the recording **up to and
   including** the judged one. The language has no previous-observation operator, and the two
   readings differ only for a road user standing at an entrance at the judged observation, which
   has come to the halt the words describe; the wider reading is the one that protects it.
2. **`ob1` — the clearance** of `p.yield_min_clearance` is read on both measurements the record
   names together: the centre distance at the predicted closest approach, and the clearance between
   the nearest points of the two bodies at the observation. Precedence is denied where either falls
   below the bound while the centres approach within the horizon. (`prim.closest_approach_distance`
   is a centre distance; the parameter's convention speaks of the clearance between the nearest
   points of two bodies, so both are read.)
3. **`st1` — the duty's scope** is every observation from the qualified entry at which the
   subject's footprint still overlaps the junction region (the entry continued by unbroken
   occupancy, `since`), which is how "from that entry on, while the subject is moving across or
   within the intersection" reads on a trace; the duty is not read once the footprint has left the
   junction.

Other readings of `c1`/`t1` (the three-limbed place of the halt, the primitive for the side, the
distance under the stop-point tolerance, the sight along a way the junction lies on) are the
record's own mapping, not mine, so they are not restated as narrowings. Two implementation details
worth a reviewer's eye, neither a narrowing of the words:

* The approach carrier is required to be a region other than the junction itself
  (`¬ same l i`): a carrier whose entrance end is a junction is not that junction, and without it a
  junction region (a `travel_region` with no lane record) would leave `st.lane_enters` unobserved
  and the condition unknown rather than decided.
* `definedWhen (subject occupies the junction) (…)` scopes the lookback to the observations at
  which the subject is in the junction. It changes no verdict (the conjunction with the same
  occupancy already decides those instants), and it keeps the unknown reason of a masked occupancy
  the masked atom itself rather than the truncation of a lookback that cannot be read at all.

## Witnesses (14)

Planned: `forbid` (violated: entry at 8 m/s while a van that halted at the opposite entrance lies
within the junction), `permit` (compliant), `idle` (not applicable: the car rolls through its
approach without ever halting, decided false), `blind` (unknown: `rel.occupies` masked, unknown only
for that atom), `branch_1` (compliant: waits at the stop line until the van has left),
`branch_2` (violated: low speed, but the centres would pass 0.77 m apart within the horizon).

Added, so that every limb of the duty and of the halt place moves a decided witness:
`branch_3` (crosswalk limb), `branch_4` (view-point limb), `branch_5` (contact alone — both bodies
at rest in contact, so nothing closes and only `rel.contact` decides), `branch_6` (body clearance
alone — 1.2 m between the bodies while the centre approach stays clear of the bound),
`branch_7` (speed alone, empty junction), `branch_8` (entry while a road user lies within the
junction alone), `branch_9`/`branch_10` (the crosswalk and view-point limbs in a violated scene, so
the obligation's re-selection of the junction is exercised too).

`branch_2`'s scene places the van moving in off its carrier as the car enters rather than already
inside the junction: with the van inside at the entry observation, the "no entry while it lies
within" limb decides the episode on its own and the closest-approach limb the plan wrote this
witness for would move nothing. The situation the narrative names — a low speed and a closest
approach under constant velocities below the clearance within the horizon — is what the scene shows.

## Why I finished

The gate returned `OK` with the rule stating every span the node carries, every claimed name used,
no bare literal, and all fourteen witnesses reaching their planned verdicts. Nothing in the node
appeared wrong: its elements, operationalization and parameters were sufficient to write t1, c1, s1,
st1 and ob1 as mapped, so no `no_atom`, `no_operator` or node defect is reported, and no concept
computed anything its contract excludes (`dependency_defect.json` is not written).
