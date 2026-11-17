# drv.lane.entering_adjacent_lane — task result

## Final verdict

`SCOPE_VIOLATION` on both runs. The flagged file isn't one I wrote. It is the Bash tool's
output-capture file for the gate command itself, written under the session's runtime temp directory
(`.runtime/tmp/claude-154266/.../tasks/<id>.output`). Every shell call writes a new file of this kind,
and the two runs flagged two different ones (`bdrt5w6yc.output`, then `b1b8tx1yq.output`). I can't
avoid or remove these files: the shell runs only the gate command, and the runtime directory isn't
writable by me. So the gate never got as far as judging the Lean. I changed only the two files I
own. The harness re-runs the gate after the session ends; that re-run is the first verdict on the
files themselves.

## Gate runs

1. `SCOPE_VIOLATION`, naming `.runtime/tmp/.../tasks/bdrt5w6yc.output`, the Bash tool's capture
   file. Changed: nothing. I re-ran once to check whether the problem was transient.
2. `SCOPE_VIOLATION`, naming `.runtime/tmp/.../tasks/b1b8tx1yq.output`, the capture file of this
   run itself. I stopped here so as not to spend the rest of the budget on the same problem
   (2 of 6 runs used).

## The body

```
st_lane_adjacency(r1, s, r2)
∧ rel_occupies(a, r1)
∧ rises( rel_occupies(a, r2) ∨ ¬ rel_occupies(a, r1) )
```

- `rises ψ` is ψ now and not ψ at the previous observation. ψ false at the previous observation means
  a overlapped r1 and did not overlap r2 there. ψ true now, together with `rel_occupies(a, r1)` now,
  means a overlaps r2 now. Together this is exactly the contract's two-observation condition, and
  `rises` is the language's only operator for "the previous observation".
- "Holds at that observation only, and not again until …" follows from the condition itself: it
  requires a to be off r2 at the previous observation.
- Unknown cases: unobserved occupancy at either observation, unobserved adjacency, or the first
  observation of a trace (`rises` is truncated there).
- I dropped a separate `rel_occupies(a, r2)`-now conjunct because it is implied by the rest and would
  be a vacuous leaf.
- Every claimed atom is used: `rel.occupies` and `st.lane_adjacency`. There are no other names, no
  parameters and no literals beyond the formal `s`.

## Choices the record left open

None needed a narrowing; `narrowings := []`. The only choice was how to write "the previous
observation". The encoding above is exactly equivalent to the contract's words, not a narrowing of
them.

## Witnesses

- **Lanes:** two northbound lanes, 4 m wide. Lane 101 (r2) is 100's (r1) left neighbour.
  Ordinals are 2 and 1 of 2.
- **Road user:** road user 1, half-width 1 m. Occupancy is derived from its footprint, as TraceLint
  requires.
- **Instance and window:** `s = left`. Each scenario is judged at t = 1000 ms
  (`window := (1000, 1000)`).
- **holds:** x = 2 (lane 100 only), then 0.5 (both lanes), then −2 (lane 101 only). Expected
  compliant at t = 1000.
- **fails:** x = 2 throughout (lane 100 only). Expected violated.
- **blind:** same trace as holds, with `rel.occupies` masked. Expected unknown.

## Why I finished

Every gate run failed on a scope check that counts the agent runtime's own output files as changes
outside the concept's files. That is an environment/harness defect, not one in my files, and
further runs could not change it. Fix needed in the harness: exclude `.runtime/` (or the agent's
tmp directory) from the scope diff.
