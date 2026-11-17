# NRS_484B_777_3 — task result

**Final verdict: OK** (10 witnesses, 8 names, composes nothing).

## Gate runs

1. **WITNESS_FAIL** — `blind: expected unknown, got violated`. Masking `rel.longitudinal_overlap`
   only drops a *measured* overlap (`Runtime/Manifest.lean`, `Mask.relation`). Core still computed
   the overlap from position, heading and extent (`Vocab/Atoms.lean`, `rel_longitudinal_overlap`).
   I first tried removing every rider's extent and supplying the gaps and overlaps as measured
   relations.
2. An accidental second invocation of the gate command, `... | head -0`, printed nothing. It may
   have used up one run of the budget. Two other stray commands (`--help` variants) were denied
   and did not run.
3. **WITNESS_FAIL** — the `blind` trace was not admitted: a track in `occupancyObserved` needs a
   footprint (position, heading and extent). Fix: in `blind` only the subject keeps its body and
   its observed occupancy (`occupies = [(1, roadway)]`, `occupancyObserved = [1]`). The two other
   riders have no extent and no observed occupancy, which the rule never reads for them. Their
   pairs' gaps (0.5, 0.5, 1.6 m) and overlaps are supplied as measured relations, which Core cannot
   compute without extents, and the manifest masks the overlap.
4. **OK**.

## Choices the node left open

- **"At least two of the three pairs" within `p.abreast_gap_max`.** I wrote it as
  `gap(s,b) ∧ (gap(s,c) ∨ gap(b,c))`. The user quantifiers range over ordered pairs `(b, c)`, and
  the body gap is symmetric. So the record's third case, `gap(s,c) ∧ gap(b,c)`, is the second case
  with `b` and `c` swapped. The formula is the record's condition exactly, so I declared no
  narrowing.
- **`rel_surface_gap`** is read as its distance (the two-argument measure, with no component), as
  the record says ("body gap").
- **`rel_longitudinal_overlap`** is read on the first member's heading for each pair: (subject,b),
  (subject,c), (b,c).
- **"Moving"** (`not drv_motion_complete_halt` with `p.halt_speed_tolerance`) is applied to the
  subject in the applicability and to `b` and `c` in the obligation, as the record states.
- **s2/s4:** written as `existsRegion roadway` and `not existsRegion bicycle_lane_or_path`. Each
  region is anchored by `rel_occupies` of the subject.
- `narrowings` is empty.

## Witnesses beyond the plan

- **`branch_1` (compliant).** The record puts the s4 exception in the applicability. An episode
  spent entirely in the bicycle lane would therefore be *not applicable*, but the plan expects
  *compliant*. The scene has two parts:
  - At the first instant, the three ride single file on the roadway before the lane begins:
    applicable and compliant.
  - Afterwards they ride three abreast inside the lane: excepted.

  The episode is compliant, and without the exception leaf it would be violated. The plan agent
  may want to know that a pure "inside the lane" scene reads as not applicable.
- **`branch_4` (violated):** three electric bicycles ride abreast. This exercises the
  electric-bicycle aggregate leaves.
- **`branch_5` (compliant):** two bicycles ride abreast with a moped beside them, subject in the
  middle. The moped belongs to no aggregate, so the class leaves of `b` and `c` matter.
- **`branch_6` (not applicable):** the subject is a moped riding abreast with two bicycles. This
  exercises the subject's class.

The electric-scooter aggregate has no included class: it is false or unknown for every class, never
true. Only `branch_5`/`branch_6` can move it, through a false-to-true mutation. The gate accepted
this.

## Why I finished

The gate returned OK.
