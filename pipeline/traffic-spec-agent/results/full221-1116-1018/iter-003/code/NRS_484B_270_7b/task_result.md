# NRS_484B_270_7b — task result

**Final verdict: OK** (8 witnesses, 10 names, composes nothing)

## Gate runs

1. `UNUSED_CLAIM` — run by mistake on the harness skeleton before any edit (every claim unused).
   Changed nothing on that basis.
2. `WITNESS_FAIL` — blind: expected unknown, got compliant. Cause: masking `rel.surface_gap`
   only drops a *measured* gap. Core still computed the gap from the bodies' footprints
   (position, heading, extent).
3. A gate invocation I issued by mistake as a background job with a 1 ms timeout. It was killed
   before it reported anything. It may still have counted against the budget.
4. `WITNESS_FAIL` (same as run 2) — another accidental invocation, on unchanged files.
5. `WITNESS_FAIL` — I rebuilt blind without body extents and supplied overlap, contact and gap.
   The admission check rejected the trace on two counts:
   - the tracks were in `occupancyObserved` without a footprint;
   - with a gap supplied, Core computes `rel.contact` from it, so contact must not be supplied.
   Fix: set `occupancyObserved := []` (the rule reads no occupancy) and stopped supplying the
   gap. Only `longitudinalOverlap` and `contact` are now supplied, and Core cannot compute
   either on that scene.
6. `OK`.

Runs 1, 3 and 4 were my errors in issuing commands, not gate behaviour.

## How the rule is written

- **Class (y1):** `ru_aggregate` for DEF-NRS-484A-025::bicycle, DEF-NRS-484B-017::electric_bicycle
  or DEF-NRS-484B-018::electric_scooter.
- **Applicability:** `.tt`. The node has no trigger or condition span.
- **Obligation (y2, y3):** for every road user `m` that is not the subject and is a member of
  DEF-NRS-484A-130::motor_vehicle, where `drv_interaction_overtake_pass(subject, m)` holds
  (`p.overtake_window`, `p.overtake_same_direction_cos`):
  `since (safe ∧ ¬aheadAligned) (aheadAligned ∧ safe)`.
  - **`aheadAligned`:** the dot product of (m.position − subject.position) with the subject's
    heading is > 0, `rel_longitudinal_overlap < 0`, and `rel_same_direction` holds. This is the
    contract's definition of the act's beginning.
  - **`safe`:** all three of the following hold:
    - no `rel_contact` with m;
    - `rel_surface_gap` (distance) ≥ `p.bicycle_pass_safe_gap`;
    - no road user u other than the subject and m has `prim_closest_approach_within` together
      with `prim_closest_approach_distance < p.conflict_centre_clearance` over
      `p.conflict_horizon`.

## Choices the node left open

- **How to write "safe from the beginning to the recognition".** I put `¬aheadAligned` in the
  left operand of `since`. On decided values this is the same as
  `since safe (aheadAligned ∧ safe)`, because the beginning is by definition the latest
  aligned-ahead observation. Its advantage is that the search stops at that observation, so
  nothing before the pass's beginning is read and no truncation reason leaks in from the start
  of the trace. This is a writing choice, not a narrowing, so no narrowing is declared.
- **Witness geometry.** Each trace is padded 10 s before and 2 s after, and `window` names the
  eight instants each witness speaks about.
- **The blind witness has no body extents.** On this source the gap between bodies is the masked
  atom, and Core would otherwise compute it from the extents.

## Why I finished

The gate returned OK.
