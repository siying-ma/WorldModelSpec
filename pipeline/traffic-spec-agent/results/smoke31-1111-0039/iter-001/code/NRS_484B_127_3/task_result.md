# NRS_484B_127_3 — task result

**Final verdict: UNEXPRESSED** (c4, `no_atom`). Every other check passes: with the c4 declaration
left out, the same files return `OK` (9 witnesses).

## Gate runs (4 of 6)

1. `WITNESS_FAIL`: `blind` came out violated. The manifest mask drops only a *measured*
   `surfaceGap`, and Core still computed the gap from the two bodies.
   Fix: in `blind`, the lead car (track 2) has no observed body outline, so the gap cannot be computed.
2. `WITNESS_FAIL`: the adapter check rejects a track whose occupancy is observed but which has no outline.
   Fix: track 2's occupancy is unobserved in `blind`, and its in-lane order (ahead of x) is supplied
   as a measured relation. Core cannot compute that order there, because the occupancy is unobserved.
3. `OK`: c4 not written and nothing declared about it. This run confirmed that everything else is sound.
4. `UNEXPRESSED`: declared `no_atom` on c4. This is the final state.

## How the rule is written

- **c1:** binder class `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- **c2:** `existsRegion highway r` with `rel_occupies x r`.
- **c3:** `asm.outside_business_district`.
- **c4:** not written; declared `no_atom` (see below).
- **c5:** the node's residue.
- **c6/c7:** for every road user y that satisfies all of these:
  - it is a `DEF-NRS-484A-320::vehicle` or a `DEF-NRS-484A-050::combination_of_vehicles`;
  - `rel_ahead_behind_in_lane y x` holds;
  - `rel_same_direction y x [p.same_direction_cosine]` holds.

  The duty is: `rel_surface_gap x y longitudinal ≥ p.entering_combination_length + p.entry_time_headway·speed(x) + p.entry_time_headway·speed(x)`.

### Choices the node left open

- **"y other than x"** is not written as `same`, because x is never ahead of itself. A `same` test would be a leaf that does no work.
- **The two headways** are written as two separate terms, as the record states them.

### Witnesses

- **Planned:** forbid, permit, idle, blind, branch_1.
- **Added:**
  - `branch_2`: a bicycle ahead, which is neither a vehicle nor a combination. Expects compliant.
  - `branch_3`: the car ahead in the lane is turned 53° off the lane, so it is not travelling the same way. Expects compliant.
  - `branch_4`: the column is on a lane that is not on the highway. Expects not applicable.
  - `branch_5`: a 60 m gap, longer than the 22.4 m entering length but short of length plus the two headways. Expects violated.

## Why c4 is `no_atom` — what the plan must change

- **Span c4 ("in a caravan or motorcade")** decides when the rule applies. The record carries the
  gap `ru.procession_member` on it. Its own justification says the nearest atoms
  (`rel.ahead_behind_in_lane`, `rel.same_direction`) "do not tell a caravan from ordinary
  traffic".
  - Written with those atoms, the rule binds every motor vehicle following another outside a
    business district. At 25 m/s it would have to keep 122.4 m.
  - Leaving the span out silently does the same.
  - So the atoms do not carry the words, and `no_atom` files the plan's gap.
- **The record contradicts itself.** Its applicability's nearest reading needs "some other motor
  vehicle … ahead of x". Its `branch_1` has the lead car, with nothing ahead, bound and compliant.
  - With the applicability as stated, `branch_1` would come out not applicable.
  - The obligation's "belongs to x's caravan" is the same unwritten membership.
- **What the plan should do:** admit an atom like the proposed `ru.procession_member` (with a group
  attribute), and use it in both the applicability (x is a member) and the obligation (y is a
  member of x's group). Alternatively, withdraw c4 as a gap; the rule should not run as an
  ordinary following-distance rule.
- **Once the atom exists:** the rule and witnesses here only need the membership conjuncts added.
  The `branch_1` lead car would then be bound as a member with no member ahead.

## Why I finished

The gate returned `UNEXPRESSED` on the `no_atom` declaration I made on purpose. That is the route
the instructions give for a gap span whose nearest atoms do not carry its words. Further gate runs
cannot change this; it now needs the plan or repair session to act on c4.
