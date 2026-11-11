# NRS_484B_263_o2 — task result

## Final verdict

`WITNESS_FAIL` — `blind: expected unknown, got violated; the manifest masks rel.surface_gap`.

The rule and the other five witnesses (`forbid`, `permit`, `idle`, `branch_1`, `branch_2`) pass;
`blind` is the only witness the gate reports. The failure is the node's planned `blind` scenario,
which Core cannot produce (see "The node is wrong" below).

## Gate runs

1. `UNUSED_CLAIM` — I ran it by mistake on the untouched skeleton, so every claimed name was unused.
   After this run I wrote the rule and the witnesses.
2. `WITNESS_FAIL` (`blind` got violated) — masking `rel.surface_gap` did not make the gap unknown:
   `Mask.scene` drops only a *measured* gap, and `rel_surface_gap` falls back to computing it from
   the two footprints (`Vocab/Atoms.lean`, `Runtime/Manifest.lean`: "The computed relations are
   blanked through the kinematics they would be computed from only when the source lacks those
   too"). After this run I left y's extent unobserved in the `blind` trace.
3. `WITNESS_FAIL` — the adapter-admission check rejected that trace: "track 2 is in
   occupancy_observed but lacks a position, a non-zero heading or an extent, so its footprint is
   undefined". After this run I tried a diagnostic mask (`rel.surface_gap` + `kin.speed`) to see
   whether any later check fails.
4. `WITNESS_FAIL` — "the manifest masks ['kin.speed', 'rel.surface_gap'], the node masks
   ['rel.surface_gap']", so the mask is fixed by the plan. After this run I reverted `blind` to the
   faithful scene (the `forbid` trace with `rel.surface_gap` masked).
5. `WITNESS_FAIL` — `blind: expected unknown, got violated`. This is the final state.

## The rule as written

- Class of x: `ru_aggregate x DEF-NRS-484A-320::vehicle`.
- Applicability (s2): `existsRegion controlled_access a (entering_region x a ∨ leaving_region x a)`.
- Obligation (s6, s4, s7, s8): `forallRegion controlled_access a ((entering_region x a ∨
  leaving_region x a) → forallUser y ((¬ same y x ∧ ru_aggregate y vehicle ∧ ru_aggregate y traffic
  ∧ rel_occupies y a ∧ drv_motion_moving y [p.speed_resolution] ∧ prim_closest_approach_within x y
  [p.immediate_hazard_gap]) → rel_surface_gap x y ≥ kin_speed y × p.merge_time_headway))`.
- The obligation repeats the applicability's whole selection of the region (rule 3c). The duty is
  stated for every region selected.

## Choices the node left open

- `rel_surface_gap` is read with no component selector, so it is the distance between the nearest
  points. That is the contract's default read, so it is not a narrowing.
- The s4/s7 conditions restrict the obligation's quantifier over y, as the record's `obligation`
  text places them. They are not added to the applicability, matching the record's
  `applicability` text.
- No narrowings of my own (`narrowings := []`).
- Witnesses set `window := (1000, 2000)`, because entering and leaving need the observation before.
  `branch_2` (violated) is added to exercise the exit limb (`drv_motion_leaving_region`).

## The node is wrong

**Scenario `blind` (masked `rel.surface_gap`) cannot be unknown in any admissible trace.**

- The rule reads `rel.occupies` for both x (entering or leaving, s2/s6) and y (s4).
- The admission check requires every occupancy-observed track to have a footprint: position,
  non-zero heading and extent.
- `rel.surface_gap` is computed from exactly those two footprints when no measured gap is supplied.
- Masking `rel.surface_gap` alone drops only a supplied measurement, so the computed gap stays
  decided.
- Making it unknown would mean leaving x's or y's occupancy unobserved. That makes `rel_occupies`
  unknown too, and the gate counts that as a stray reason the manifest does not mask.

**What the plan must change:** mask an atom whose absence does leave the decisive leaf unknown, for
example `kin.speed`. That makes both `drv_motion_moving y` and the `kin_speed y × headway` bound
unknown, while the `forbid` geometry otherwise stays violated. Alternatively, mask
`rel.surface_gap` together with the kinematics it is computed from, if the plan's masking rules
allow that.

The rule's formulas need no change for this.

## Why I finished

The only remaining failure comes from the node's planned `blind` mask, which Core's masking and
admission rules make impossible to produce. Per the role, a blueprint defect is reported, not worked
around in Lean or by changing the planned mask. Five of the six gate runs were used.
