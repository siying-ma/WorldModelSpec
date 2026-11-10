# NRS_484B_270_3_o2 — task result

## Final verdict: OK (11 witnesses)

The `blind` witness doesn't match the plan's narrative exactly. See "Deviation on `blind`" below.

## Gate runs

1. **WITNESS_FAIL** on `blind`: "unknown for [window_truncated:since, window_truncated:until],
   not for an atom the manifest masks". All other witnesses passed this run.
   - Cause: exceptions (a) and (c) are read over "x's current stay on b", written as
     `since`/`until` with `rel_occupies x b` as the continuing operand. With `rel.occupies`
     masked, the stay cannot be seen to start or end. The search therefore reaches both ends of
     the trace, and the unknown also carries a truncation reason. That is real: the stay might
     have begun before the recording. No faithful writing of the stay avoids it.
   - Change: the `blind` scenes also declare `asm.emergency` true. The exceptions are then decided
     true, applicability reduces to "x is on no bicycle lane", and the verdict is unknown only
     because of the masked occupancy.
2. **OK**: 11 witnesses.
3. **OK**: re-run after comment-only edits to the witness header and the `blind` doc comment.

## Deviation on `blind`

The plan says: "As forbid, but rel.occupies is not observed". My `blind` is forbid's geometry
with the mask, but it also declares an emergency (`asm.emergency` true). Without the mask it would
be not applicable, not violated. The mask still decides it: on b the rule does not apply, off b it
is complied with.

A blind that is exactly "as forbid" cannot meet the gate's requirement that the unknown come only
from the masked atom. The record's own stay-based exceptions (s5, s7) look back and ahead over the
same occupancy, so masking it also truncates them. **For the plan agent:** either accept this
variant (blind = forbid + a declared exception), or plan a blind that masks an atom the stay does
not depend on. If the reviewer wants the plan's wording kept to the letter, this node goes back to
planning.

## How the rule is written

- **x's class:** `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- **Applicability:** for every bicycle lane or path `b`: if x occupies `b`, none of these
  exceptions holds:
  - (a) `since onLane (onLane ∧ E) ∨ until onLane (onLane ∧ E)`. This means x was on a driveway
    or alley earlier in the stay (exiting) or will be later in it (entering). `E` means x occupies
    a region of kind `driveway_or_alley_entrance` or of kind `alley`.
  - (b), (d), (f): the declared assumptions.
  - (c) `since onLane (rises onLane ∧ C)`. This reads C at the observation where the stay began.
    C: some road user `z` that is not `x`, is in the aggregate `DEF-NRS-484A-285::traffic`, does
    not occupy `b`, and has `prim_closest_approach_within x z [p.conflict_time_horizon]` with
    `prim_closest_approach_distance` below `p.conflict_centre_clearance`.
  - (e) some `human_direction` device with role `police_officer` governs (`dev_governs`) a
    `travel_region` that x occupies.
- **Obligation:** x occupies no `bicycle_lane_or_path`.
- **Choices the node left open:** none beyond its own narrowings, so `narrowings` is empty.
  - The stay is the run of observations at which x occupies b.
  - "Before or after in the stay" counts the current observation too, as `since` and `until` do.

## Witnesses

| witness | expected | what it shows |
|---|---|---|
| forbid | violated | 50 m along b; x enters and leaves b inside the trace |
| permit | compliant | stays in the general lane |
| idle | not applicable | crosses b into a driveway (until) |
| blind | unknown | see deviation above |
| branch_1 | not applicable | an officer governing b |
| branch_2 | not applicable | conflict at entry: closest approach 1 m in 1 s |
| branch_3 | not applicable | comes out of an alley across b (since; alley) |
| branch_4 | not applicable | `asm.vehicle_disabled` true |
| branch_5 | not applicable | `asm.performing_official_duties` true |
| branch_6 | not applicable | `asm.emergency` true |
| branch_7 | violated | conflict arises mid-stay, not at entry (exercises `rises`) |

The look-backs and look-aheads are decided because x is off b at both ends of each trace. Each
scenario's `window` limits judgement to the instants x is on b.

## Why I finished

The gate returned OK on the files as they stand. The one remaining problem is that the plan's
`blind` scenario, as written, cannot be met. It is reported above for the plan agent.
