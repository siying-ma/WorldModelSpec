# NRS_484B_270_2b_o2 — task result

**Final verdict: OK** (7 witnesses, 11 names, composes nothing)

## Gate runs (4 of 6 used)

1. `WITNESS_FAIL` — blind: expected unknown, got violated. Core computes `rel.surface_gap` from the
   footprints whenever no gap is supplied (`Mask.scene` blanks a computed relation only through its
   kinematics), so masking the atom alone left the gap decided.
   Change: rebuilt the blind scene with the rider's extent unobserved and the projection overlap supplied.
2. (run by mistake) A stray invocation of the gate command with its output discarded. I did not see
   its verdict, and the files had not changed since run 1.
3. `WITNESS_FAIL` — blind: the adapter admission rejects a track whose occupancy is observed but whose
   footprint is undefined.
   Change: the car (subject) has the unobserved extent instead of the rider. Only the rider's occupancy
   is observed, because the rule never reads the subject's. The overlap (1→2) is supplied as a measured
   relation, since Core can't compute it without the car's footprint. The gap is then neither supplied
   nor computable, so it is unknown with reason `rel_surface_gap`, which the manifest masks.
4. `OK`.

## How the rule is written

- Subject class (b4): `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: `existsUser r (selection r)`. `selection r` is the conjunction of:
  - `rises (drv_interaction_overtake_pass subject r [p.overtake_window, p.overtake_same_direction_cos])` (b1)
  - `not (same subject r)`
  - membership of one of the three admitted aggregates (b2)
  - "some observation of the window" (`not (holdsFor .time p.overtake_window subject (not …))`) of
    `kin_speed r > p.halt_speed_tolerance ∧ rel_same_direction subject r [cos]` (b3)
  - "some observation of the window" of `rel_longitudinal_overlap ≥ 0 ∧ ∃ lane l. rel_occupies r l ∧ st_lane_adjacency l "count" = 1` (b6)
- Obligation: `forallUser r (selection r → holdsFor .time p.overtake_window subject (overlap ≥ 0 → rel_bearing subject r "right" ∧ rel_surface_gap subject r ≥ cond(3 ft ≥ p.bicycle_pass_safe_gap, 3 ft, p.bicycle_pass_safe_gap)))`.
  - The selection is written again in full, through the same function.
  - "The larger of 3 ft and the clearance" is one comparison over `Term.cond`.
  - Witness `branch_3` (gap 0.95 m: above 3 ft, below the reading's 1.0 m) exercises the selection.
    Without it, the 3 ft bound could never decide a verdict under this reading.

## Choices the node left open

- b3: "moving" and "heading aligned" are read at one common observation of the window, as the record's
  applicability sentence states. This is not a narrowing: it is the record's own wording.
- b11/b12 compositions (`unless`, scoped to b12): b12 is the node's residue (scope none). The
  authorization relaxes 484B.213/217 and leaves this duty unchanged, so b12 has no formula and the five
  compositions have nothing to restrict. No `.ruleApplies` is written, and the gate accepted this
  ("composes nothing"). If the plan meant these compositions to have an effect, it must give b12 a formula.
- No narrowings declared.

## Reading defects observed (reported, not repaired)

- **`DEF-NRS-484B-018::electric_scooter` includes no class.** `ru.electric_scooter` itself is
  *unresolved*, so no observed road user is ever a member: an electric scooter's membership is always
  unknown, and so is every pass of a scooter. The planned `branch_1` narrative ("overtakes an electric
  scooter on the scooter's right") therefore can't be decided. The `branch_1` witness uses an
  **electric bicycle** (included in its aggregate) to exercise the same leaf (the rider on the
  subject's left, so the bearing condition fails). The reading should classify `ru.electric_scooter`
  as included under DEF-NRS-484B-018.
- **A car's membership of the e-bike and e-scooter aggregates is unknown.** `ru.motor_vehicle` is
  unresolved for both, so a car being passed makes the applicability unknown, never decidedly false.
  The `idle` witness ("overtakes another car") therefore uses a **moped**, which the reading excludes
  from all three aggregates.

## Why I finished

The gate returned OK on run 4.
