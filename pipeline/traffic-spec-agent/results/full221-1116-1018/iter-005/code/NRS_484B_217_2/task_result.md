# NRS_484B_217_2 — task result

**Final verdict: OK** (15 witnesses, 25 names, composes NRS_484B_413_2). Used 4 of 6 gate runs.

## Gate runs
1. `UNUSED_CLAIM` on the skeleton, before any edit. I meant this as a baseline check.
2. `UNUSED_CLAIM`, an accidental duplicate of run 1, sent in the same batch as a file read. Nothing had changed between the two runs.
3. `WITNESS_FAIL`: the trace check rejected forbid, idle, blind and branch_5/6/7/9. In those traces `path_length` grew by less than the straight-line distance between consecutive positions. The left-turn witnesses were not reported. Fix: the three-scene traces now use 11 m per second of path, and the drift traces add 3.8 m between 2.5 s and 3 s.
4. `OK`.

## How the rule is written
- **Class (s2):** `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability (s3):**
  - The subject occupies a highway `h` that has a centre line `c` on it (`st_on_way c h`).
  - The subject is in a no-passing zone, shown either way:
    - by a sign: it occupies a `travel_region` that a `zone_sign` governs, with kind `no_passing` and not an end sign;
    - by a marking: it occupies a `lane` whose left marking is solid or double_solid yellow.
  - A solid_broken left marking (any colour, as the record says) makes the zone unknown. This is written as `definedWhen (¬ solid_broken) ff`, using the three-argument form of `st_lane_marking`, which the evaluator accepts.
- **Obligation:** for every highway `h` the subject occupies and every centre line `c` on `h`, either the subject is not crossing, or it is excused.
  - **Crossing:** `2·offset < width − 2·tol`. This is the record's "offset below half the width minus the tolerance", doubled on both sides so the formula needs no divisor.
  - **Excuse:** `signalledFirst ∧ noImpediment ∧ (E3 ∨ E4)`. The signal and the no-impediment test are shared by both exceptions, so I wrote each once, outside the disjunction. This is logically the same as the record.
    - `signalledFirst = since crossing (signalLeft ∧ ¬crossing)`: the signal was on at the last observation before the crossing began. `signalLeft` is the indicator showing left or the hand signal meaning left.
    - `noImpediment`: no other road user that belongs to DEF-NRS-484A-285::traffic and is oncoming (or behind and heading the same way) has a closest approach within the horizon below the clearance.
    - **E3:** within the turn window ahead, the subject occupies some highway `h2` other than `h` and no longer occupies `h`.
    - **E4:** `int.left_turn` is declared at an intersection or driveway/alley entrance on `h`, the NRS_484B_413_2 composition holds, and the crossing is safe.
      - Composition: `atLast time W subject (ruleApplies 413_2) (rule 413_2)`, or else `holdsFor time W subject (¬ruleApplies 413_2)`, which covers the case where 413_2 never engages in the window.
      - Safe: no other road user is in contact with the subject or in a closest-approach conflict with it.
- **Narrowings:** none. Every choice above is the record's own wording. The one place I read an ambiguous phrase: "the last observation at which NRS_484B_413_2 engages (ruleApplies, its rise of a course departure)". I took the `atLast` anchor to be `ruleApplies` itself, reading "rise" as describing what 413_2's applicability already is.

## Witnesses
- The nine planned witnesses all use the planned verdicts.
- I added six branches so that every leaf of the formula changes at least one decided verdict:
  - **branch_6:** an E3 crossing with an oncoming conflict (violated).
  - **branch_7:** an E3 crossing with a following conflict (violated).
  - **branch_8:** an E4 turn with a pedestrian in conflict who is neither oncoming nor following, so only the safety test fails (violated).
  - **branch_9:** an E3 crossing signalled by hand only (compliant).
  - **branch_10:** an E4 turn with a body in contact but no closing approach (violated).
  - **branch_11:** an E4 turn at an intersection instead of a driveway (compliant).
- The E4 traces are padded 11 s after the turn. Without that, E3's look-ahead window would stay uncovered and those violated witnesses would come out unknown.
- I did not read NRS_484B_413_2's file. The branch_1 and branch_4 scenes follow its narrative: the heading leaves the lane direction while the vehicle is still in its lane, the business district assumption is true, and the indicator is on for 125 m in branch_1 against 10 m in branch_4. The gate accepted both.

## Blocked action
I tried to rename an identifier (`from?` → `onFrom`) with `sed`. The permission check denied it because only the gate command may run in the shell, so I made the same change with the Edit tool.

## Why I finished
The gate returned OK.
