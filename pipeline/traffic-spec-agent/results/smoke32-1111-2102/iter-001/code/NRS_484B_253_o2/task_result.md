# NRS_484B_253_o2: task result

## Final verdict

**WITNESS_FAIL**: the node is wrong at **f10** (the `NRS_484B_253_o1` compliance composition).
`forbid`, `blind` and `branch_3` cannot reach violated or unknown. `permit`, `idle`, `branch_1`
and `branch_2` pass.

## Gate runs

1. **UNUSED_CLAIM** (every claim). I ran this by mistake on the harness skeleton before writing
   anything. Then I wrote the rule and seven witnesses (the six planned ones plus `branch_3`).
2. **WITNESS_FAIL**: `forbid`, `blind`, `branch_2` and `branch_3` came out unknown, from
   `absent_atom:st_lane_enters` and `st_lane_direction`.
   - Cause: the intersection region is itself a `travel_region`, so it was a candidate for `ct`.
     The `since` condition held trivially for it, while its lane relations were unknown.
   - Fix: the entry event became `occupies t ct ∧ ¬ occupies t i`. This states the record's
     "entered i from c_t" and decides `ct = i` false.
   - I also moved ego farther and faster, and kept t at rest until it turns.
3. **WITNESS_FAIL**: `branch_2` now passes. `forbid`, `blind` and `branch_3` come out
   **not_applicable** (decided).
   - With ego 76 m short of the intersection at 30 m/s, every applicability leaf holds at the
     turn instant except t's compliance with NRS_484B_253_o1.
4. **WITNESS_FAIL**, the same. This was a diagnostic: I put ego 263 m out at 100 m/s, still
   meeting t's projected path about 2.67 s ahead (inside the 3 s horizon, centres under 0.1 m
   apart).
   - t still fails o1 at that observation.
   - So o1's "so close … as to constitute an immediate hazard" does not depend on distance. It
     follows the same conflict test as this node's standard.
   - I then restored the realistic `forbid` geometry (30 m/s, 76 m).

Two of the six runs are unused. I stopped because the remaining failure is the node's, and no
change of witness can reach it.

## Why the node is wrong

- **f15 is symmetric.** The obligation (f14/f15) is "ego at rest or not in conflict with t", and
  the conflict test is `prim.closest_approach_within` / `prim.closest_approach_distance` between
  ego and t. Both are symmetric in their two road users.
- **The condition removes every violating case.** The applicability requires that t "has
  complied with NRS_484B_253_o1 (t as its ego) at every observation since it entered i". That
  includes the judged observation, at which t is turning (so not at rest).
- **o1 uses the same test.** As the gate shows, o1 treats an oncoming vehicle in such a conflict
  as an immediate hazard regardless of its distance. So at any observation where ego is in
  conflict with the turning t, t is in conflict with ego and not at rest, and has not complied
  with o1.
- **Result.** f10 removes exactly the observations at which this duty could be broken. The rule
  can never be violated, and `forbid` as narrated ("waited while no oncoming vehicle was close
  and now turns left … their projected closest approach lies within p.conflict_horizon below
  p.conflict_clearance") cannot be built.

**What the plan must change.** "Having so yielded" is past: t yielded *before* it made the turn.
f10 should require compliance with NRS_484B_253_o1 at every observation from t's entry into i
**up to the onset of the turn** (the observations before `drv.motion.turning_left` rose for t),
not at the judged observation. Alternatively, the record could give o1's immediate-hazard
standard a reading that a vehicle approaching from far off at speed does not meet. Either way,
the applicability text and the `forbid` narrative have to agree on which one. I did not write
either fix in Lean, because that would repair the blueprint.

## Choices the node left open

- **No narrowing declared.**
- **"approaching the intersection" (f13).** The record says ce "does not overlap i, or enters i
  from it". Taken together, the two cases are just ego occupying ce, a carrier that enters i. I
  wrote only `rel_occupies(ego, ce) ∧ st_lane_enters(ce, i)` and added no leaf for the split.
- **"since it occupied its approach carrier" (f11).** I wrote this as
  `since (¬ rises (occupies t ct)) signal`: a signal at some observation since the latest
  stretch on ct began. This form is decided false when t never signals (`branch_1`), where a
  plain "once" would stay unknown at the trace head.
- **"entered i from c_t" (f2/f10).** I wrote `since (occupies t i ∧ o1) (occupies t ct ∧
  ¬ occupies t i)`.
- **The obligation repeats the applicability's whole selection** (i, ce, t, ct with every
  relation, intention and composition) with the conflict conjoined, as rule 3c requires.
- **`branch_3` (violated)** was added to exercise the `sig_hand_signal` leaf: indicator off,
  arm signal left.

## Why I finished

The node is wrong at f10. As composed, the condition makes the duty impossible to violate, so the
planned `forbid`/`blind` witnesses cannot reach their verdicts. Gate run 4 shows this does not
depend on the witness's distances. The plan agent must re-read f10 as described above.
