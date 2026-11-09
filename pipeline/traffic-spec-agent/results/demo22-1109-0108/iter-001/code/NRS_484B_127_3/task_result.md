# NRS_484B_127_3 — coding session result

**Final verdict: `OK`** (9 witnesses, 9 names, composes nothing, 2 narrowings declared by the coder).

## Gate runs (3 of 6 used)

| # | verdict | what changed after it |
|---|---|---|
| 1 | `UNUSED_CLAIM` (all nine claimed names) | the baseline skeleton, run before writing anything. Wrote the whole rule (binder class, applicability, obligation, two narrowings) and all nine witnesses. |
| 2 | `WITNESS_FAIL` — `blind`: "its trace is not one the adapter can produce: track N is in occupancy_observed but lacks a position, a non-zero heading or an extent, so its footprint is undefined" | rebuilt the `blind` scene only (see below). Nothing else was touched: the rule, the other eight witnesses, the build, the static check, the claims, the parameters and the adequacy rule had all already passed at this run. |
| 3 | `OK` | — |

### How `blind` had to be built

`Mask.relation` drops only a **supplied** `surfaceGap`; `rel_surface_gap` then falls back to the
footprints, so masking `rel.surface_gap` cannot remove a gap a scene's bodies let Core compute. A
scene whose bodies have no extents, however, is not admitted while its tracks are in
`occupancy_observed`. The witness therefore reads as a source that instruments the subject's own
vehicle and sees only the places and headings of the others: the subject has its extent and its
occupancy observed (so `rel.occupies` and the highway condition stay decided), the other four
bodies have position, heading and speed but no extent, occupancy is declared for the subject
alone, and the spaces between the bodies and which body is ahead of which are **supplied**
measurements — neither of which Core can compute in that scene, so supplying them is permitted.
Masking `rel.surface_gap` then takes the spaces away and the duty is unknown for that atom and no
other.

## Choices the node left open, and what I chose

Both are declared as `narrowings` on the rule (`kind := "reading"`) and explained in the rule's
header.

1. **s5 — "each such vehicle or combination of vehicles".** Written as every member of the
   subject's file that lies ahead of or behind it in the same lane (`rel_ahead_behind_in_lane` in
   either order, since the atom means "a is ahead of b") and within the file's reach of it (the
   space between the bodies at most `p.caravan_max_member_gap`, the reach the file concept uses).
   The record's narrowing says "immediately ahead of and behind"; the language has no operator for
   "immediately", and the space to a member further along a file is always larger than the space to
   the nearest one, so the bound on every in-reach member states the same duty and never a weaker
   one. A formula that excluded the further members (a nested "no member between them") would be a
   sub-formula no witness can move, which is why it is not written.
2. **s6 — "any other vehicle or combination of vehicles" whose length is read.** Every road user of
   the scene that is neither the subject nor a member of the subject's file; where several are
   present, the space must hold each of them, which is exactly the greater length the
   operationalization's convention names (its "max", written as a conjunction so that a scene with
   no such road user stays decided instead of going unknown on an empty aggregate).
3. **The factor of two** in `p.entry_vehicle_length + 2 × p.entry_clearance_headway_time × speed` is
   written as the headway term twice, fore and aft, because no figure of the rule file's own — not
   even a factor — may enter a formula. Noted in the header, not as a narrowing: it is syntax, not
   a reading.

Everything else follows the record: the binder's class is `ru_aggregate` with the aggregate id; the
applicability is `not standstill ∧ (∃ highway the subject occupies) ∧ vehicle_file ∧
asm.outside_business_district`; the obligation is the gap bound of s6 over those members; s4 is
carried as the record's residue and nothing reads it.

## Two places where the plan's witness declarations do not fit the plan's own reading

Neither blocked the gate — both were resolved inside the geometry, which is the witness's own — but
the plan agent should see them.

1. **`permit` cannot be the narrative's scene.** The narrative asks for the five cars "at the same
   speed" (20 m/s) with "about 70 m" of space. Under this reading's values a moving file at 20 m/s
   owes `6 + 2 × 1.5 × 20 = 66 m`, which is beyond `p.caravan_max_member_gap = 50 m`, the reach
   within which `drv.interaction.vehicle_file` counts a road user as travelling in the subject's
   file. At 20 m/s compliance and membership of the file are mutually exclusive: every compliant
   file is not a file. The `permit` witness is therefore built at 8 m/s with 40 m of space (bound
   30 m, kept by a clear 10 m); the rule file's header and the witness's doc comment say so. The
   substantive point for the plan: with these values the duty is satisfiable only below about
   14.7 m/s, so either the reach or the gap-acceptance convention is mis-scaled for highway speeds.
2. **`branch_2` expects `compliant` for a narrative that is `not_applicable`.** A halted file is
   below the standstill tolerance, so by the record's own applicability ("is moving") the rule does
   not engage and that instant's verdict is `notApplicable`, not `compliant`. The planned verdict is
   kept as the declaration requires, and the trace is a queue rolling to a halt: at the first
   instant the file is still being driven (1 m/s, 14 m of space, bound 9 m — compliant), at the two
   later instants it stands still 6 m apart and the rule does not reach it. The episode is
   `compliant` because one instant is compliant and none is violated, and the scene still shows what
   the narrative is about. If the plan meant a purely halted scene, its expected verdict should be
   `not_applicable`.

## One claim that can never decide anything

`s5` claims `ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles`, and the obligation writes it
as the second limb of the member's class disjunction, as the record maps it. In this run's reading
that aggregate has **no included classes** (every vehicle class is `unresolved`), so the atom is
never true: for a motor vehicle it is `unknown` and the disjunction is decided by the first limb,
and for anything else it is `unknown` or false. It can only ever turn a decided-false member class
into `unknown`; no witness can be decided by it. The atom is written, not deleted, as instructed.
For the plan agent: either the reading must classify some class as included under
`DEF-NRS-484A-050::combination_of_vehicles` (a towed combination is one road user drawn by another,
which the ontology represents as `ru.trailer_or_combination`), or the claim on s5 adds nothing and
the span should rest on the motor-vehicle aggregate alone.

## Witnesses

| name | verdict | what it exercises |
|---|---|---|
| `forbid` | violated | five cars, 20 m/s, 6 m of space; bound 66 m |
| `permit` | compliant | five cars, 8 m/s, 40 m of space; bound 30 m |
| `idle` | not applicable | five pedal cycles: the binder's class is decided false |
| `blind` | unknown | the forbid file with `rel.surface_gap` masked (see above) |
| `branch_1` | not applicable | one car alone: the file's minimum member count is not reached |
| `branch_2` | compliant | the file rolls to a halt: the standstill limb of s1 |
| `branch_3` | violated | a 24 m combination abreast in the left lane: `kin.extent` of a body that is no member of the file decides the bound (30 m of space, 39 m owed) |
| `branch_4` | not applicable | the forbid file inside a business district: `asm.outside_business_district` declared false |
| `branch_5` | violated | a 12 m bus 60 m ahead in the same lane, beyond the file's reach: the reach that separates a member of the file from a road user that could enter the space decides the verdict (25 m of space, 27 m owed) |

`branch_3`, `branch_4` and `branch_5` are this session's, added so that the read length of an
entering body, the business-district condition and the file's reach each move a decided witness.

## Why I finished

The gate returned `OK` on the third of six runs: the two files build, the static check and the
claim, parameter, anchoring and adequacy checks pass, and all nine witnesses reach their declared
verdicts. Three runs of budget are left and unspent, with nothing left to fix: the two items above
are the plan's to decide, not defects of the formulas, and the session's own choices are on the
rule's record as narrowings.
