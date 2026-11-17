# NRS_484B_603_1_o2 — task result

**Final verdict: OK** (14 witnesses, 12 names, composes nothing). 4 of 6 gate runs used.

## Gate runs
1. **GATE_TIMEOUT** (stack overflow, twice). The stopping-distance comparison was written multiplied
   through by 2a, with `2a = surfaceDecel + surfaceDecel` used on both sides. That made four copies
   of the nested `Term.cond` in one comparison. I rewrote it as `v² ≤ (gap − v·t_r + gap − v·t_r) · a`,
   which is equivalent and selects the deceleration only once.
2. **WITNESS_FAIL** — blind came out violated. `Mask.scene` for `rel.surface_gap` drops only a
   *measured* gap; Core still computes one from the two footprints. I rebuilt blind so that no gap
   can be computed: the pedestrian's extent was left unobserved.
3. **WITNESS_FAIL** — admission rejects a track whose occupancy is observed but whose footprint is
   undefined. I moved the unobserved extent to the subject car and removed the car from
   `occupancyObserved`. The rule never reads the subject's own occupancy, because
   `.not (.same u subject)` short-circuits for u = subject. Without footprints Core cannot compute
   `rel.contact`, so I supplied it as a measured relation (false).
4. **OK**.

## How the rule is written (choices left open)
- The class and the applicability are both `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
  The record's applicability is the subject's class alone. s15/s16 are read inside the obligation's
  `forallUser`, so a scene with no such road user complies (branch_1).
- **s15/s16:** `forallUser u`, excluding the subject with `same`. The highway condition is
  `existsRegion highway r, rel_occupies u r`, written over the highway kind as the record names it,
  with no class restriction on u.
- **s14:** conflict is `prim_closest_approach_within` (p.conflict_horizon) ∧
  `prim_closest_approach_distance` ≤ p.conflict_centre_clearance. Where there is a conflict, the
  subject must meet one of: at rest (kin.speed ≤ p.halt_speed_tolerance), or decelerating
  (kin.accel_longitudinal ≤ −p.speed_decrease_decel_min), or the s17 bound. Separately, contact with
  u while kin.speed > p.halt_speed_tolerance violates.
- **s17:** D = v·t_r + v²/(2a) ≤ rel_surface_gap, where the gap is the distance (no component). It is
  written as `v² ≤ 2·(gap − v·t_r)·a` because a divisor may not read an atom; this is equivalent for
  a > 0, so it is not a narrowing. The deceleration a comes from one `Term.cond`: ice/snow, else
  wet road or precipitation, else dry.
- **Narrowings:** none.
- **Witnesses:** I added branch_3 to branch_10 to exercise each leaf:
  - rest with contact
  - wet, precipitation, ice and dry surfaces
  - clearance exceeded
  - other user off the highway
  - no approach within the horizon

## Notes
- After run 2 I tried running the gate with `--help`. The tool denied it, and I ran nothing other
  than the gate command after that.
- One harness behaviour later sessions should know: masking `rel.surface_gap` (or another computed
  relation) has no effect on a scene with full footprints. A blind witness for a computed relation
  has to remove the kinematics the relation is computed from, within the adapter's admission rules.

## Why I finished
The gate returned OK.
