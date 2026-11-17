# drv.interaction.overtake_pass — task result

**Final verdict: OK** (3 witnesses, 5 names, reads 5 atoms), on gate run 3 of 6.

## Gate runs
1. **WITNESS_FAIL**: in `blind` I had supplied a measured `longitudinalOverlap` while the trace
   still had extents. The gate checks the unmasked trace, where Core can compute that overlap.
   Change: the blind source no longer observes extents (`kin.extent` none), so Core can't compute
   footprints and the measured overlap is the source's own.
2. **WITNESS_FAIL**: the trace was not one an adapter could produce. Tracks were in
   `occupancyObserved` without a footprint. Change: blind scenes set `occupancyObserved := []` and
   `occupies := []`, so that source does not observe occupancy either.
3. **OK**.

## Body
- `lon` = a's heading (`kin_heading`, normalised, x/y) · (b's position − a's position) (`kin_position`).
  Only its sign is read, against a zero literal.
- `apart` = `rel_longitudinal_overlap a b < 0`.
- `ahead` = `lon > 0 ∧ apart`; `behind` = `lon < 0 ∧ apart`.
- `aheadAligned` = `ahead ∧ rel_same_direction a b [same_dir_cos]`.
- `pending` = `since (¬behind) aheadAligned`: b has been ahead with headings aligned, and has not been behind since.
- body = `rises behind ∧ rises (¬pending) ∧ atLast time window aheadAligned tt`.
  - `rises behind` is the recognition: b is behind a here and was not at the previous observation.
  - Where b is behind, `pending` is false, so `rises (¬pending)` is `pending` at the previous
    observation. This writes "not again until b has again been ahead of a and then comes to be
    behind it".
  - `atLast … tt` is true where b was ahead with headings aligned at some observation of the
    window behind; the last such observation is the onset. Conduct before the window is not read.

## Choices the record left open
None that needed a narrowing; every part of the body comes from the contract's own words.

Witness choices (all figures are the witness's own):
- window = 6 s, same_dir_cos = 9/10.
- dt = 1 s. b is halted at (100,0). a follows, moves to the adjacent lane at t=4 s while b is still
  ahead, is alongside for 3 s, and has b 3 m behind at t=8 s.
- `holds` and `blind` are judged at 8000 ms; `fails` is judged at 9000 ms, after a has halted alongside.
- In `blind`, kin.position is masked. Overlap is measured by the source, which observes no extents.
  This keeps the only unknown reason on the masked atom: if Core computed the overlap, it would
  also become unknown with its own reason, and the gate rejects that reason as not coming from the
  masked atom.

## Why I finished
The gate returned OK.

Session note: I ran two commands that this session does not allow, and both were denied without
running: a `grep` prefixed with `cd`, and a `--help` call on the gate. Later I read Core with plain
`grep` and the Read tool. The gate itself was run 3 times, as recorded above.
