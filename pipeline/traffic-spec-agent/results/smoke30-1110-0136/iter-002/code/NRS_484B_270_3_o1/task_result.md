# NRS_484B_270_3_o1 — task result

## Final verdict

`WITNESS_FAIL` — `branch_2: expected violated, got not_applicable`. Every other witness passes
(forbid, permit, idle, blind, branch_1, branch_3, and an added branch_4).

## Gate runs

1. A stray run. I mistakenly piped the gate command (`… | head -0`), which may have used a run
   without showing any output. This was my mistake: the shell is only for the bare command.
2. Skeleton, before I edited it (another run I didn't need): `UNUSED_CLAIM` (every claim unused, as expected).
3. First full rule and witnesses: `WITNESS_FAIL branch_2` (static pedestrian in b beside a
   sidewalk obstruction gave not_applicable).
   - Change: branch_2 became an evolving detour. The pedestrian walks on the sidewalk, reaches
     an obstruction region (`obstructionKind := sidewalkFixture`, `ways := [sidewalk]`) and
     walks on in b beside it.
4. `WITNESS_FAIL branch_2` again.
   - Change: the pedestrian now hugs the obstruction. Its footprint overlaps b, the sidewalk
     and the obstruction, and I stated that occupancy explicitly.
5. `WITNESS_FAIL branch_2` again.
6. Another stray run. I invoked the bare gate command by mistake (with a 1 s timeout, so it
   moved to the background). It failed with exit code 1; I didn't read its output.

## The rule as written

- **Class of x:** `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- **Applicability:** x is moving (`drv_motion_moving x` with p.motion_speed_tolerance), and
  there is a bicycle lane or path b with `rel_occupies x b`, and there is a road user y with:
  - `¬ same y x`;
  - `rel_occupies y b`;
  - y is protected: a bicycle, an electric bicycle or an electric scooter (by the aggregates), or
    a pedestrian (by the aggregate) for whom `ruleApplies NRS_484B_297_6_o2 {x ↦ y}` holds.
- **Obligation:** for every bicycle lane or path b occupied by x, and every y that matches the
  same selection, there is no conflict. A conflict is
  `prim_closest_approach_within x y h ∧ prim_closest_approach_distance x y h < clearance`.
- **Choices:** none beyond the record's, so there are no narrowings. The composition sits on the
  pedestrian limb only, since s8 qualifies "a pedestrian". The obligation repeats the
  applicability's whole selection of b and y, as the record requires.

## Why branch_2 fails, and what needs to change

Branch_2's verdict depends only on whether `NRS_484B_297_6_o2` applies to the pedestrian. Its
other parts were all decided true:
- x is a motor vehicle, is moving and is on b;
- the pedestrian is on b, is not x, and its pedestrian aggregate is true;
- the bicycle, electric bicycle and electric scooter aggregates are decided false for a pedestrian;
- the conflict geometry keeps the bounds with a clear margin.

So the gate's `not_applicable` means the composed rule decidedly does not apply in my scenes. I
tried three scenes:
- a static pedestrian beside an obstruction;
- a detour from the sidewalk around an obstruction on that sidewalk;
- the same detour with the pedestrian's body overlapping the sidewalk and the obstruction.

I may not read other nodes' files, so I can't see which fact 297_6_o2's applicability needs for
"a pedestrian on a detour around a sidewalk obstruction".

**Request to the plan or repair session:** either state, in this node's branch_2 narrative, the
scene facts `NRS_484B_297_6_o2`'s applicability requires (atoms, regions, any declared intention
or history), or check that 297_6_o2's applicability actually describes the pedestrian that this
node's s7/s8 refer to. If 297_6_o2 is the "no sidewalk provided" limb, or needs something like a
declared intention, then branch_2's narrative (and possibly the composition's target) is wrong.
The rule itself does not need to change.

## Why I finished

I used up the gate budget: six invocations, two of them my own mistakes. The remaining failure
depends on another rule's applicability, which I'm not allowed to read.
