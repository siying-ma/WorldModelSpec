# NRS_484B_270_4 — task result

## Final verdict

**WITNESS_FAIL**, on `blind` only. `forbid`, `permit`, `idle` and `branch_1` pass. I believe the
node is wrong: its `blind` scenario cannot be satisfied (see below).

## The rule as written

- class of x (s2): `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- applicability: `drv_motion_moving x [p.motion_speed_tolerance]` ∧ ∃ b : bicycle_lane_or_path,
  `rel_occupies x b` (s4) ∧ `ruleApplies NRS_484B_270_3_o2 {x ↦ x}` (s1, `as: condition`).
- obligation (s3): ¬ ∃ i : intersection, `rises (rel_occupies x i)`. This is the record's entry:
  x overlaps i here and did not at the observation before.
- No choice beyond the record's own narrowings, so `narrowings` is empty.

## Gate runs

1. **WITNESS_FAIL**: forbid, permit and blind were unknown for `window_truncated:since` and
   `window_truncated:until`. These operators are not in this rule, so they come from the composed
   `NRS_484B_270_3_o2`. Its look-backs and look-aheads stayed undecided where x was on b at the
   first and last instants. **Fix:** every trace now starts with x on the general lane g and ends
   with x off b (back on g, or wholly in i).
2. A mistaken extra invocation. I ran the gate command with an appended `| head -0; true`, which
   discarded the output. This broke the "exactly this command" rule and probably cost one run of
   the budget. My error.
3. **WITNESS_FAIL**: forbid, permit, idle and branch_1 pass. Blind was still unknown for
   `window_truncated:since/until` and not only for the masked atom. **Change:** in blind, x is at a
   standstill at the first and last instants, to test whether 270_3_o2's temporal operand includes
   motion.
4. **WITNESS_FAIL**: same blind failure, so the operand does not read speed. **Change:** blind kept
   only region b, to test whether the operand ranges over the lane or intersection regions.
5. **WITNESS_FAIL**: same blind failure. I then put blind back to "as forbid", as the narrative
   says.

(I also tried a second, combined shell command. It was denied and did not run.)

## Why blind cannot pass: a defect in the plan

The blind scenario masks `rel.occupies`. `rel_occupies` (`Core/Vocab/Atoms.lean:439`) is unknown
for a track whose occupancy is not observed, at every instant. The composed `NRS_484B_270_3_o2`
evaluates `since`/`until` over an operand that reads x's occupancy. The tests above ruled out
three ways that operand might be decided by something else: x's speed, the presence of the
intersection, and the presence of the general lane.

So with occupancy masked, that operand is unknown back to the start of the trace and on to its
end in any trace. The episode then always carries `window_truncated:since/until`. `Scenario.run`
does not accept that reason on a witness without a declared history boundary, and padding cannot
bound an unknown operand.

**What the plan agent must change:** give blind a masked atom that this rule reads and the
composed rule's temporal operands do not. For example, mask `kin.speed`: `drv.motion.moving` is
then unknown while the occupancy-based parts of 270_3_o2 stay decided, as in forbid. Or, if the
plan keeps `rel.occupies` masked, it must make sure 270_3_o2's `since`/`until` operands are bounded
by an atom other than occupancy. I could not check which of these 270_3_o2 allows, because its file
is outside my access.

## Why I finished

The only failing witness is one I believe the node makes impossible: two different scenes did
not change the failure. I have one gate run left. I could not see the composed rule, so I had no
remaining test with a real chance of success. The files are left with the rule as the record
states it and every witness built from its narrative.
