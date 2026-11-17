# NRS_484B_127_1 — task result

**Final verdict: OK** (11 witnesses, 7 names, composes nothing). 3 of 6 gate runs used.

## Gate runs
1. `WITNESS_FAIL` — blind: expected unknown, got violated. Masking `rel.surface_gap` only drops a
   *measured* gap; Core still computed it from the footprints. Change: the blind scene's source
   observes no body extents and supplies the gap as a measured relation.
2. `WITNESS_FAIL` — blind trace not admissible: tracks with no footprint cannot be
   occupancy-observed. Change: only the followed car (track 2) lacks an extent and occupancy;
   the source supplies `aAheadOfB` (2 ahead of 1) and `surfaceGap` (1→2, 15 m) measured, neither
   computable by Core in that scene; the manifest drops the gap.
3. `OK`.

## Rule
- Binder class (f1): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`. Applicability `.tt`
  (no trigger or condition span).
- Obligation (f2, f3): `forallUser other (ru_aggregate other vehicle ∧ rel_ahead_behind_in_lane other subject
  → rel_surface_gap(subject, other, "longitudinal") ≥ bound)`, where
  bound = `cond(ice_or_snow, B(H_ice,D_ice), cond(wet_road ∨ precipitation, B(H_wet,D_wet), B(H_dry,D_dry)))`
  and B(H,D) = v_s·H + (v_s² − v_o²)/(D + D).

## Choices the node left open
- `2·D` is written `D + D`: the node declares no literal 2, and the divisor reads parameters only.
- The bound is selected by `Term.cond` around the whole bound, so each division has a parameter-only divisor.
- 'another' is not a separate term. `rel_ahead_behind_in_lane` is false for the subject against
  itself, so the quantifier never judges the subject as its own leader.
- No narrowing was declared; the record's own narrowings cover the reading.

## Witnesses beyond the plan
branch_3 (wet road, 60 m gap → violated), branch_4 (rain only, 60 m → violated), branch_5 (leader
faster, 35 m → compliant, exercising the leader's speed), branch_6 (car close behind a bicycle →
compliant, exercising the vehicle class of the other), branch_7 (close car in the adjacent lane →
compliant, exercising the in-lane relation).

## Why I finished
The gate returned OK.
