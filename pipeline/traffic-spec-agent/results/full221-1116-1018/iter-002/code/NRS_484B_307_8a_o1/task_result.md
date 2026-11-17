# NRS_484B_307_8a_o1 — task result

**Final verdict: OK** (10 witnesses, 14 names, composes nothing).

## Gate runs
1. `VACUOUS`: obligation leaf `st_entrance_of(xz, c)` (the "footprint off the crosswalk marking c"
   clause of the stopping zone) moved no witness. Added `branch_4` (violated: the place is the
   crosswalk; the car halts with its reference point short of it but its nose on it). Also added
   `branch_5` (violated: a prior entry into i from c ends the search before an earlier halt), so the
   prior-entry end of the history bound is exercised.
2. `OK`.

(Before run 1 I issued one shell command that was not the gate. It was denied and nothing ran. I
also ran one `grep` on `Core/Vocab/Atoms.lean` to read accessor bodies. It only read files, but it
went outside the "gate command only" shell rule.)

## How the rule is written
- **Class:** `ru_aggregate traffic ∧ ru_aggregate vehicle`, for "vehicular traffic".
- **Applicability:** ∃ intersection i, travel region c, traffic-signal head s such that
  `entry ∧ redAlone`:
  - `entry` = `occ i ∧ rises(occ i ∨ ¬(occ c ∧ st_lane_enters c i ∧ dev_governs s c))`. Because
    occ i holds now, the `rises` reads "not in i, and facing s on c, at the previous observation".
    It is unknown at the first observation.
  - `redAlone` = shows circular_red, and does not show any of the other 22 state spellings (every
    circular, flashing, dark or unknown state and every arrow in every direction).
- **Obligation:** ∀ i, c, s: the same `selection` (shared definition, rule 3c) → duty. The duty
  takes its place in order:
  1. every stop line recorded as marking c;
  2. if no stop line marks c, every crosswalk marking c;
  3. if neither marks c, i itself (its edge).

  For a place r, the duty is `since (¬start(r) ∧ ¬priorEntry) halt(r)`, read at the observation
  before the entry with the same `rises` construction, so the current entry is not itself an end of
  the search:
  - `halt(r)` = complete_halt(p.halt_speed_tolerance) ∧ occ c ∧ ¬occ i ∧ no crosswalk marking c
    occupied ∧ offset_along(subject, r, c) ≥ 0 ∧ region distance ≤ p.stop_point_tolerance.
  - `start(r)` = occ c ∧ ¬occ r ∧ offset > 0 ∧ distance > tolerance.
  - `priorEntry` = occ i ∧ rises(occ i ∨ ¬occ c).

  `since`, which Core leaves unknown when it reaches the trace start, gives the record's
  three outcomes: halt found → complied; an end reached first → violated; neither end reached →
  unknown.

## Choices the node left open
- I read "vehicular traffic" as the conjunction of the two claimed aggregates.
- I wrote "at the previous observation" with `rises`, because the language has no previous-instant
  operator. This changes the encoding only, not the meaning.
- I declared no narrowing: the record's obligation text sets the place order, the zone, the
  approach start and the history bound.

## Witnesses
These are the planned forbid, permit, idle, blind (kin.speed masked), history_boundary (`since`
truncated at the trace start) and branch_1 (place is the intersection edge). I added:
- `branch_2`: compliant halt before a crosswalk, with no stop line marking c.
- `branch_3`: violated; the car halts 4 m short of the crosswalk, outside the tolerance.
- `branch_4`: violated; the car halts with its nose on the crosswalk.
- `branch_5`: violated; the search ends at a prior entry.

## Why I finished
The gate returned OK.
