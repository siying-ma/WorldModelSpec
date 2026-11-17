# NRS_484B_777_1_o1: task result

## Final verdict

**UNANCHORED_VARIABLE** on the files as left: the rule states the record faithfully. **The node is wrong** in three places (below). With a temporary, undeclared anchoring of exception (b), the gate's next verdict was **WITNESS_FAIL**, and only on the planned branches 1–5. Each of those five failures comes from the plan itself.

## Gate runs (4 of 6 used)

1. **UNUSED_CLAIM** (every claim). I ran this by mistake on the untouched skeleton. Nothing changed after it.
2. **UNUSED_CLAIM** again: a second accidental run on the skeleton. The gate command was embedded in an exploratory shell call.
3. **UNANCHORED_VARIABLE** on the full rule and witnesses: the quantified variables `i` (intersection) and `d` (driveway/alley entrance) of exception (b) are not tied to the subject. `intent` does not count as an anchor.
   - Change after it: for one diagnostic run only, I tied `i`/`d` to the subject. The tie required the region to lie (`st_on_way`) on a highway that a roadway the subject occupies lies on.
4. **WITNESS_FAIL** with that diagnostic tie in place:
   ```
   branch_1: expected compliant, got not_applicable
   branch_2: expected compliant, got not_applicable
   branch_3: expected compliant, got not_applicable
   branch_4: expected compliant, got not_applicable
   branch_5: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
   ```
   These passed: forbid (violated), permit (compliant), idle (not applicable), blind (unknown, masked `st.region_geometry` only), and my added branch_6 and branch_7.
   - Change after it: I reverted the tie. It narrows an exception span, which is not permitted, so the files carry the record as written. That leaves the gate at run 3's verdict.

## What the plan agent must change

1. **s5 / s2, the target region of `int.left_turn` is unanchored.** The record reads exception (b) at "some intersection or driveway/alley entrance r". Nothing ties r to the subject: the only relation is the declared intention, and the gate does not accept that as an anchor. The record must state how the region relates to the subject. One option is the intersection or entrance on the highway of the occupied roadway (`st_on_way`), which is the tie I used for the diagnostic run. Another is the one the roadway or lane the subject occupies leads into, or one within a stated distance ahead (`st_region_geometry_distance` with a parameter). Each needs the claims and parameters it uses. I could not choose one myself: a narrowing on an exception span is forbidden.

2. **Branches 1–4 plan `compliant` for situations in which an exception holds.** The record's applicability says "and none of the exceptions holds there". These branches are therefore not applicable, not compliant:
   - branch_1: exception (a) holds vacuously.
   - branch_2: exception (c), narrow lane.
   - branch_3: exception (c), a parked car ahead on the right.
   - branch_4: exception (b), a declared left turn.

   Either change the planned verdicts to `not_applicable`, or, if the reading intends exceptions to excuse rather than disengage, move them into the obligation (`exceptions ∨ near-right`) and say so in the applicability and obligation. Branch_1's narrative ("the duty binds the subject alone and is decided") contradicts its own "exception (a) holds vacuously".

3. **branch_5: an electric scooter can never be decided a member of the subject class.**
   - The admitted aggregate `DEF-NRS-484B-018::electric_scooter` includes no class, and lists `ru.electric_scooter` as unresolved. The other two subject aggregates do not include it either. So a scooter's class is `unknown (aggregate_unresolved)`, and no scene with a scooter subject can be `violated`.
   - The same probably holds for NRS_484B_785_1a's engagement of a scooter.
   - Fix: drop branch_5 or re-plan it as `unknown`, or resolve the electric-scooter aggregate's reading (a representation decision outside this node).

## Choices the node left open (as written)

- **Exception (a):** "nearby" uses `rel_surface_gap` without a component (the distance) ≤ `p.nearby_traffic_reach`. "Traveling" is `kin_speed > p.halt_speed_tolerance`. The compliance composition is `.rule "NRS_484B_785_1a" [subject↦subject]`.
- **Exception (c), objects:** "from zero to the reach" is inclusive at both ends, `0 ≤ offset_along ≤ reach`. The carrier is a roadway the subject occupies.
- **Exception (c), road users:** the bearing selectors are `"x"` (longitudinal, > 0) and `"y"` (lateral, ≤ 0), because Core's `rel_bearing` measure takes components x/y.
- **Obligation:** −offset − width/2 ≤ gap is written doubled, −2·offset − width ≤ 2·gap, so that no literal 2 enters the rule. It is wrapped in `definedWhen` over the existence of a right edge on the occupied roadway's highway, as the record requires. "With r a roadway the subject occupies" is existential, the same selection as the applicability.
- No narrowings were declared.

## Witnesses added

- **branch_6** (not_applicable): a declared left turn at a driveway entrance, to exercise exception (b)'s second limb.
- **branch_7** (not_applicable): debris 10 m ahead on the right, to exercise exception (c)'s object limb.

## Why I finished

The node is wrong. Its s5 selection cannot be anchored without narrowing an exception span. Its planned verdicts for branch_1–4 contradict its own applicability, and branch_5 is unreachable under the admitted aggregate. No change limited to the two files can reach OK without departing from the record, so I stopped with 2 gate runs unused.
