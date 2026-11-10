# NRS_484B_270_4 — task result

**Final verdict: OK** (5 witnesses, 5 names, composes NRS_484B_270_3_o2)

## Gate runs

1. **WITNESS_FAIL** — forbid, permit and blind were unknown for `window_truncated:since` and
   `window_truncated:until`. These came from the composed rule NRS_484B_270_3_o2: the 3-scene
   traces never recorded x entering or leaving the bicycle lane, so subsection 3's past and
   future searches ran off both ends of the trace.
   Change: rebuilt the witnesses. x is now first seen in the general lane g, moves into b, and the
   trace ends with x off b (in i/e for forbid, back in g for permit). Every trace is padded 60 s
   at both ends with `Build.pad`.
2. A second gate run by mistake: I piped the command through `head`, so its output was thrown
   away. Nothing changed between runs 1 and 2.
3. **OK**.

3 of the 6 runs were used.

## How the rule is written

- s2: the class of `x` is `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- s4: `drv_motion_moving x p.motion_speed_tolerance` ∧ ∃ b of kind `bicycle_lane_or_path`,
  `rel_occupies x b`. This is in the applicability.
- s1: `ruleApplies "NRS_484B_270_3_o2" [("x","x")]` is conjoined into the applicability, because
  the composition is `as: condition`.
- s3: the obligation is ¬∃ i of kind `intersection`, `rises (rel_occupies x i)`. This is the
  record's own narrowing: x entering the intersection, which is where any passage through it
  begins.

## Choices left open

None beyond the record. I added no narrowings and no extra branch witnesses. The gate found no
vacuous leaf.

## Witness geometry

- b runs y ∈ [0, 2] and g runs y ∈ [2, 5]; both go from x = -120 to x = 0.
- Intersection i covers [0, 20] × [-10, 10]. Lane e continues past it.
- x moves at 10 m/s (the tolerance is 0.2 m/s), sampled every 1 s.
- Occupancy is given explicitly in each scene.
- Every scene declares asm.vehicle_disabled, asm.performing_official_duties and asm.emergency
  false.
- branch_1 adds a `humanDirection` device that governs b, with role police officer and indication
  proceed.

## Why I finished

The gate returned OK.
