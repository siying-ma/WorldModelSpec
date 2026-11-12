# drv.interaction.overtakes — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 3 atoms), after 4 of 6 gate runs.

## Body

```
whollyBehind := behind(a,b) ∧ ¬behind(b,a)
whollyAhead  := behind(b,a) ∧ ¬behind(a,b)
aligned      := rel_same_direction(a,b; alignment)
body := rises(whollyAhead) ∧ since(aligned, whollyBehind)
```

- `rises(whollyAhead)` is true only at the observation where a becomes wholly ahead of b. That is the recognition, and the concept holds there only.
- `since(aligned, whollyBehind)` needs a wholly-behind observation j, with the headings aligned at every observation after j up to and including the recognition. At j itself the headings are aligned because `drv.position.behind` reads `rel.same_direction`. Wholly behind and wholly ahead can't hold together, so j comes strictly before the recognition, and the latest such j is the observed beginning.
- Suppose no wholly-behind observation comes first and the headings are aligned from the start of the recording. Then `since` runs back to the trace start and returns `windowTruncated` (unknown, never false), as the contract's history clause requires.

## Gate runs

1. **WITNESS_FAIL**: `blind` came out compliant. Masking `rel.longitudinal_overlap` only blanks a *measured* overlap, and Core still computed it from position, heading and extent.
   - Change: the blind trace now comes from a source that reports no body extents, so Core can't compute the overlap, and it supplies the overlap as a measured relation.
2. **WITNESS_FAIL**: the adapter rejected tracks that have no footprint but are marked as occupancy-observed.
   - Change: the measured scenes set `occupancyObserved := []`. The body doesn't read occupancy.
3. **WITNESS_FAIL**: `blind` was unknown for `window_truncated:since` as well as for the masked atom. "Wholly behind" was unknown at every instant, so `since` reached back to the trace start.
   - Change: added a first instant (t = 0) where a is merging into the left lane at about 28° (cosine 15/17 < 9/10). The headings aren't aligned there, so `since` is decided false at t = 0, and the only unknown left is the masked atom.
   - This instant was added to all three traces; recognition moved to t = 4000 ms.
4. **OK**

## Choices the record left open

None in the body; there are no narrowings. "Aligned at every observation from that one to the recognition" is what `since` says directly. Choices on the witness side:
- Alignment tolerance: cosine 9/10.
- Headings parallel once a is in the left lane.
- No regions, because the concept says nothing about lanes.
- `blind` uses the source-measured overlap, as described under run 1.

## Why I finished

The gate returned OK.
