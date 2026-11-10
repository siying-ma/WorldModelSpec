# NRS_484B_263_o1 — task result

## Final verdict

`WITNESS_FAIL` (gate run 1 of 6). The only failing witness is `blind`. The node plans it in a way
that cannot be built: no trace can make `rel.surface_gap` the only unknown atom for this rule. The
node is wrong, so I ended the session (see below).

## Gate runs

1. `WITNESS_FAIL`: `blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest
   masks; the manifest masks rel.surface_gap`. Nothing changed after it. The defect is in the
   node, not in my files, as explained below.

(A stray `echo` and a `--help` invocation were also issued by mistake. The second was denied. The
gate was run once.)

## The rule as written

- s1: the class of `x` is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- s2: the rule is judged at an **entry**, `existsRegion controlled_access a. rises (rel_occupies x a)`,
  or at an **exit**, `existsRegion controlled_access a. rises (¬ rel_occupies x a) ∧
  existsRegion highway h. rel_occupies x h`.
- s5: `existsUser y`, with `¬ same y x`, `ru_aggregate y vehicle`, and y on the highway being
  entered. At an entry that is `rel_occupies y a`. At an exit it is `rel_occupies y h ∧
  ¬ rel_occupies y a`. y must also satisfy `drv_motion_moving y [p.motion_speed_tolerance]`.
- s6: `rel_surface_gap x y ≤ kin_speed y × p.immediate_hazard_time_gap`, written as a product so
  no measured atom is a divisor.
- s3 + s4: the obligation is `drv_motion_moving x → ¬ selection(conflict)`. `selection` repeats
  the applicability's whole selection (the same regions, road user and relations). `conflict` is
  `prim_closest_approach_within x y [h] ∧ prim_closest_approach_distance x y [h] <
  p.conflict_centre_clearance`.
- The record decides every choice: "at most" becomes `le`, "below" becomes `lt`, and "the
  highway" is the one being entered. So `narrowings` is empty.

## The witnesses

The map has controlled-access region 10 (y ∈ [0, 10]) and an ordinary highway, region 11
(y ∈ [-30, -2]). Region 11 is the adjoining way at an entry and the crossroad at an exit. There
are three scenes at 0, 1 and 2 s, and `window` is 1000–2000 ms because `rises` looks one
observation back.

- `forbid`, `permit`, `idle`, `branch_1` and `branch_2` are built against the reading's values
  with clear margins.
- `permit` exercises the case where the centres meet within the horizon but at 6 m, which is not
  below 4 m.
- `blind` is the same scene as forbid, but y has no `kin.extent`, as the narrative asks.

## Why I finished: the `blind` scenario of the node cannot be built

The node plans `blind` with `masked: ["rel.surface_gap"]`, and the gate requires every unknown
reason to be a masked atom. For this rule that is unsatisfiable:

1. `rel.surface_gap` is a relation Core **computes** from both footprints (`Vocab/Atoms.lean`,
   `rel_surface_gap`, which needs position, heading and extent of both x and y).
   - Masking it (`Runtime/Manifest.lean`, `Mask.relation`) drops only a supplied measured value.
   - With both footprints present, the gap is still computed and decided.
   - Supplying a measured value that Core can compute is itself refused.
2. So the gap can be unknown only if x's or y's footprint is undefined, for example with
   `kin.extent` absent, as the narrative says.
3. But `TraceLint.checkTrace` requires every occupancy-observed track to have a position, heading
   and extent. A track without a footprint therefore has an unobserved occupancy, and
   `rel_occupies` reads unknown for it.
4. The rule needs that same occupancy at the same observation:
   - for x, through `rises (rel_occupies x a)`;
   - for y, through `rel_occupies y a` or `rel_occupies y h` (s2/s5, the record's selection).
5. The verdict is therefore unknown for `absent_atom:rel_occupies` as well. That is what the gate
   reported, and no other construction avoids it.

**What the plan agent must change:** re-plan the `blind` scenario so its masked atom can be the
only unknown one for this rule. One way is to mask `kin.speed`:

- s6 (`kin_speed y`) and both `drv_motion_moving` calls then read only `kin.speed`.
- Occupancy and closest approach read position, heading, extent and velocity, which stay
  observed.
- The narrative becomes "As forbid, but speeds are not observed, so whether y's proximity is an
  immediate hazard is unknown."

Another way is to mask an atom the record reads only where it decides. The other five witnesses
and the rule need no change.
