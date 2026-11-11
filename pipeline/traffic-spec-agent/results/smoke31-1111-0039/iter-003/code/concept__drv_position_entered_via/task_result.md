# drv.position.entered_via — task result

## Final verdict

`WITNESS_FAIL` (blind only). I stopped because the record is wrong. The body and the holds and fails witnesses are not the problem.

## Body

`since occR (rises occR ∧ occC)`, where `occR = atom rel_occupies [x, r]` and `occC = atom rel_occupies [x, c]`.

- **Overlap of r since the beginning:** the first argument of `since`.
- **The beginning:** `rises occR`, meaning r is overlapped here and was not at the observation before.
- **c at the beginning:** `occC`, read at that same observation.
- **Beginning not through c:** the search goes past it to the observation before, where r is not overlapped, so the result is false.
- **Overlap already under way at x's first observation:** the result is unknown, because the observation before x's first is unobserved. That is what the contract says.

The contract settles every part of this, so I declared no narrowings.

## Witnesses

- **Shared setup:** road user 1 heads east along y = 0. Region r (100) is a lane, x ∈ [10, 20]. Observations come every 1 s, and each scenario is judged at t = 2000 (window (2000, 2000)).
- **holds:** c (101) is x ∈ [0, 12], so it overlaps r. x is at px = 5, then 11, then 15, which gives c only, then c and r, then r only.
- **fails:** c2 (102) is x ∈ [0, 12]. c (101) lies beside x's path at y ∈ [2, 6]. x makes the same moves, which gives c2 only, then c2 and r, then r only.
- **blind:** the holds trace with `rel.occupies` masked.

## Gate runs (2 of 6 used)

1. **Run 1 — `WITNESS_FAIL`:** "blind: the witness declares a history boundary the plan does not". I had set `boundary` on blind because its narrative says it is unknown "for the search reaching that boundary". I removed it.
2. **Run 2 — `WITNESS_FAIL`:** "blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks".

## Why I finished — the record is wrong

The record contradicts itself on the **blind scenario**:

- Its narrative and the record's `act.history` both declare a history boundary at x's first observation. The narrative says the verdict is unknown "for the masked atom and for the search reaching that boundary".
- The plan does not register a history boundary for this scenario. The gate rejects a witness that declares one (run 1).
- Without a boundary, the witness may be unknown only for masked atoms (run 2).

No correct body or scene can satisfy both. The body reads only `rel.occupies`, and the manifest masks it at every observation. So any search for the beginning of the overlap is undecided all the way back to the trace start, and it always carries `window_truncated` from `since` and `rises`. A body that never reached past the trace start would not be the contract's search, which runs back to x's first observation.

**What the plan agent must change:** declare the history boundary (x's first observation) on the `blind` scenario of `drv.position.entered_via`, so the witness may carry `boundary`. The record's act already states that boundary. The alternative is to rewrite the blind narrative and expectation so it does not depend on the search reaching the boundary, but with this body's only atom masked I see no blind scene that avoids it. The body needs no change.
