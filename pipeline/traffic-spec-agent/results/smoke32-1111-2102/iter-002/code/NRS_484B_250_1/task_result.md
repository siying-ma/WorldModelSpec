# NRS_484B_250_1 — task result

## Final verdict

**Not judged in-session.** The sixth gate run returned `BUDGET_EXHAUSTED` before the last edits were judged. The last verdict judged on real content was `WITNESS_FAIL` (branch_9 only); every other witness passed and the earlier VACUOUS leaves were resolved. The harness re-runs the gate on the files as they stand.

## Gate runs

1. **Accidental run (my mistake).** I issued a malformed Bash command that ran the gate on the untouched skeleton. Its output was discarded, but it used one run.
2. **`UNUSED_CLAIM`** (skeleton, still all `.tt`). I ran this while meaning to read a Core file, so it was also a wasted run. Afterwards I wrote the rule and seven witnesses.
3. **`WITNESS_FAIL`**:
   - branch_2 expected violated, got compliant. Its violation was at an approach instant, but the narrative says NRS_484B_250_4_o1 applies to ego's *entry*. Fix: moved the conflict to the entry instant (the forbid motion plus an inoperative, dark signal governing the intersection).
   - branch_3 declared an intent for a vehicle absent from the scene. Fix: intents are filtered to the users present.
   - branch_6's yaw rate was inconsistent with its headings. Fix: b now turns south→east between 0 s and 1 s at 90 deg/s, with headings consistent.
   - Added branch_4 (yield sign governs the intersection), branch_5 (operating signal governs ego's approach) and branch_7 (opposing approach on a different highway, no left turn → violated).
4. **`VACUOUS`**: the device-exception leaves and `ruleApplies NRS_484B_250_4_o2` *in the obligation's repeated selection of i* were exercised by no witness. Fix: added branch_8 and branch_9. Each has a narrow second crossing 50 just south of 10; at 1 s ego's body spans lane 31 (approach to 50), crossing 50 and lane 11 (approach to 10). 50 is controlled (branch_8: stop sign on lane 31; branch_9: yield sign on intersection 50 itself) and b is in conflict inside 50. 10 is uncontrolled and empty, so the expected verdict is compliant.
5. **`WITNESS_FAIL`**: branch_8 and branch_9 traces not admitted, because highway 4 was a point while occupancy was stated explicitly. Fix: highway 4 is now a rectangle, and the occupancy lists include it.
6. **`WITNESS_FAIL`**: branch_9 unknown (`absent_atom:st_lane_enters`). The cause: an intersection region is itself a `travel_region` and carries no entrance record, so `st_lane_enters(50, 10)` is unknown. With the yield sign governing 50, "a device governs a carrier entering 10" became unknown.
   - Fix in the rule: c, c_b and the device's carrier are required not to be intersections (`¬st_intersection`, an atom claimed by e2, e5 and e7). This replaced my earlier `same(c, i)` / `same(c_b, i)` guards.
   - Fix in the witnesses: branch_3 now also contains crossing 50, so that the guard on c in the applicability is exercised. Ego inside 10 at 2 s would otherwise make the pair (50, c=10) unknown.
7. **`BUDGET_EXHAUSTED`**: these last edits are unjudged.

## Choices the node left open

- **"Entering i from c at the judged observation" (e2):** `rises(occupies ego i) ∧ since(occupies ego i, occupies ego c)`. Together this means ego is in i now, was not in i at the previous observation, and occupies c now or did then.
- **"Has entered … from c_b" (e5):** `occupies b i ∧ since(occupies b i, occupies b c_b)`, the past operator the record names.
- **Carriers are never intersections:** c, c_b and the carrier a device governs carry `¬st_intersection`. This follows `st.lane_enters`'s contract (a carrier is a lane, roadway, shoulder, …). It is needed because Core reads `st_lane_enters` as unknown on an intersection region. It is explained in the rule header and is not declared as a narrowing: it states nothing narrower than the words.
- **One region across formulas (3c):** the obligation repeats the whole selection (`selected` = approaches ∧ ¬(controlled ∧ ¬applies o1 ∧ ¬applies o2)) for every selected (i, c), as the record states the duty at each.
- **Opposed directions:** the dot product of the two `st_lane_direction` vectors (x and y components) is below `−p.opposite_direction_tolerance`.
- **Left turn (e9/e10):** `intent int.left_turn` of ego or b at i, or `drv_motion_turning_left` of ego or b. Every scene declares `int.left_turn = false` for the vehicles present, so the intent leaves are decided.
- **No narrowings declared.**

## Points for review

- **Repeated device exception:** the obligation's copy of the device exception can only matter when ego approaches two intersections at once. branch_8 and branch_9 build that deliberately: a 3 m-deep crossing, with ego's body spanning both approaches.
- **o1/o2 can only be tested together:** I could not read NRS_484B_250_4_o1 or _o2. branch_2 relies on o1 applying when an inoperative, dark signal governs the intersection at ego's entry, which run 4 showed is the case. In the applicability, o1 and o2 sit side by side, so a scene where only o2 applies may be needed. If the harness's re-run reports `ruleApplies NRS_484B_250_4_o2` as VACUOUS, the next session needs such a scene, built from o2's own contract.

## Why I finished

The gate budget (6 runs) is spent. Two of the runs were wasted by my own mistaken commands. The last judged run failed only on branch_9; both files are now edited to address it, and the harness re-runs the gate on them.
