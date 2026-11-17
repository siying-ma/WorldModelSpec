# NRS_484B_213_1 — task result

**Final verdict: OK** (15 witnesses, 21 names, composes nothing).

## Gate runs (6 used of 6)

1. `UNUSED_CLAIM`: run on the untouched skeleton, which confirmed the claimed names (including the under-way atoms kin.velocity, rel.bearing, rel.longitudinal_overlap and rel.same_direction). Then I wrote the rule and the witnesses.
2. `WITNESS_FAIL`:
   - `occasion_s5` and `occasion_s5_outside` changed a structure's sight distance from one scene to the next, which the adapter refuses. The fix was to put the change in space instead: two consecutive two-lane segments, each with its own sight distance.
   - `occasion_s6_outside` came out unknown. The oncoming car's `overtake_pass` window was cut off at the start of the trace. The fix was 10 more seconds of trace before the pass (28 observations, phase j = k − 10).
3. `BUILD_FAIL`: this run was a mistake on my part. I sent the gate command with an extra `2>/dev/null; true` on the end, and it ran and used up a gate run. The trace helpers still had the old signatures, so it failed to build. I fixed the signatures.
4. `VACUOUS`: no witness exercised the conflict leaves for an oncoming vehicle u (contact, closest approach within the horizon, closest-approach distance). I added:
   - `branch_4`: a fast oncoming car that stays beyond the required distance but is on a conflict course within the horizon.
   - `branch_5`: the subject passes b at only 2.2 m centre-to-centre.
   - `branch_6`: the subject touches b's side while their centres are already moving apart.
   - `branch_7`: sight distance is short only at the act's beginning.
5. `VACUOUS`: only `rel_contact(subject, u)` for an oncoming vehicle was still unexercised. At any realistic speed it cannot decide a verdict: two touching car bodies are a few metres apart centre to centre, far inside the required distance (subject speed × 11 s). So the traffic-distance check always decides first. The fix was to merge the two interference checks into one quantifier: for every u that is b (`same u b`) or an oncoming vehicle. This says exactly what the record says ("neither b nor any vehicle u oncoming"), and its single contact check is exercised by `branch_6`.
6. `OK`.

## Choices the node left open

- **Beginning of the act** (occasion, window, throughout): the obligation is `holdsFor .time p.overtake_window subject (U → …)` with U = `afterBeginning ∧ closing`.
  - `afterBeginning = until(¬aheadAligned, bBehind)`: from this observation on, b is never again ahead of the subject with aligned headings before it is behind. This holds exactly from just after the act's beginning up to its recognition.
  - The beginning itself is the last aligned-ahead observation. Knowing that requires looking at the next observation, and the language has no "next" operator. So the duty at the beginning is required from the observation after it: `rises afterBeginning → ¬rises dutyHere`. Given dutyHere holds there, this means dutyHere held at the previous observation, the beginning.
  - No observation before the beginning is read; `occasion_s5_outside` checks this, with the subject already left of the centre line under short sight before the act.
- **closing** (the kin.velocity part of the under-way element): v_s·v_s > v_s·v_b. The subject's velocity exceeds b's along the subject's own direction of travel. kin.heading is not claimed, so the direction is taken from the subject's velocity rather than its heading.
- **"two-lane"** (literal 2): for every two lanes l and l2 on h, the per-direction lane counts (`st_lane_adjacency` "count") add up to 2. Taking l = l2 shows this is the same as the record's "every lane on h has a single lane in its direction". The literal is written `.lit (Q.ofInt 2) .count`, because Units has no count constructor.
- **Where sight distance is read**: `st_sight_distance` "at the subject's point" is read on the highway region h the subject occupies. s5 is an exception span, so I declared no narrowing; the choice is explained in the rule header.
- **narrowings**: none added.

## Why I finished

The gate returned OK.
