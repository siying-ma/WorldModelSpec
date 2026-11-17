# NRS_484B_560_7b — task result

**Final verdict: OK** (13 witnesses, 20 names, composes nothing).

## Gate runs
1. `UNUSED_CLAIM` — run on the skeleton as the harness wrote it, before I had edited anything (every
   claimed name was reported unused).
2. A second invocation went out by mistake. It was a malformed `… 2>&1 | head -0; true` form of the
   gate command, I issued it in error, and it printed nothing. It may have used one run of the budget.
   (Two other malformed commands were denied and never ran.) Neither file had changed between run 1
   and this one.
3. `OK` — after writing the rule and the witnesses below. Nothing changed after it.

## How the rule is written
- b1: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- b3 (applicability): `existsRegion railway_crossing c (rises (rel_occupies subject c))`. The
  obligation selects the crossing again the same way: every railway crossing whose occupancy rises
  here.
- b2 (obligation): for every `travel_region` r the subject occupies at the entry, and every device d of
  each kind that `dev_governs d r`:
  (i) railway signal or gate: the lights are not flashing, and the gate is not lowering, down or raising;
  (ii) traffic signal: it does not show `circular_red`;
  (iii) human direction with role `police_officer`: the indication is not `stop`;
  (iv) yield sign: for every user q, `ru_rail_vehicle q → ¬(prim_closest_approach_within ∧ prim_closest_approach_distance ≤ p.conflict_centre_clearance)`,
  with both primitives over `p.conflict_horizon`;
  (v) stop sign: the halt search, written `rises (¬ since onApproach halt)`, where
  `onApproach = ¬occ(c) ∧ st_region_geometry_distance(subject,c) ≤ p.railroad_crossing_approach_reach` and
  `halt = drv_motion_complete_halt(subject; p.halt_speed_tolerance) ∧ onApproach`.

## Choices the node left open
- **How to search back from the observation before the entry.** The language has no "previous"
  operator. Core's `since` includes the current observation. At the entry the subject overlaps c, so
  the `since` formula is false there, and `rises(¬χ)` at the entry is exactly χ at the previous
  observation. The search ends where the record says. It ends at an observation farther than the
  reach (the approach start). It also ends at an observation on the crossing, because any previous
  entry after a halt puts an occupied observation between that halt and this entry. I added no other
  boundary. When the recording starts inside the reach with no halt, the `since` truncation makes the
  result unknown.
- **Narrowings:** none declared. Every condition is the record's own.

## Witnesses
The planned witnesses are `forbid`, `permit`, `idle`, `blind`, `branch_1` to `branch_4` and
`history_boundary`. I added four more so that every leaf moves a witness:
- `branch_5`: lights flashing with no gate (violated).
- `branch_6`: lights dark with the gate lowering (violated).
- `branch_7`: circular red (violated).
- `branch_8`: a yield sign with a train closing to about 0.9 m within 0.42 s (violated).

## Why I finished
The gate returned OK.
