# drv.position.entered_via — task result

## Final verdict

`WITNESS_FAIL` (blind), from a defect in the record's `blind` scenario. The body, `holds` and `fails`
pass.

## Body

```
inR  := rel_occupies(x, r)
inC  := rel_occupies(x, c)
body := since inR (rises inR ∧ inC)
```

`since φ ψ` = `ψ ∨ (φ ∧ since'(prev))`, with the unobserved past (before the first observation)
counted as unknown. ψ marks the observation where the overlap of r began: the overlap rose there
and x also overlapped c. φ asks for the overlap of r at every observation after that, up to the
judged one. A rise needs a non-overlap just before it, so no later rise can fall inside a run of
`inR`; the rise that `since` finds is therefore the beginning of the *current* overlap. If the
overlap is already under way at the first observation, `rises` and `since` are truncated, so the
result is unknown, as the contract says. No reading was left open, so there are no narrowings.

## Witnesses

r = intersection [8,30]×[0,4]; c = lane [0,10]×[0,4] (in `fails`, c is moved to y∈[10,14] and the
lane c2 = 102 takes its place). x moves east with its reference point at x = 5, 9, 20 at t = 0, 1,
2 s. Every scenario is judged at t2 (`window` = [2000, 2000]).
- holds → compliant ✔
- fails → violated ✔
- blind → cannot pass (see below)

## Gate runs

1. `WITNESS_FAIL` — `blind: unknown for [window_truncated:rises, window_truncated:since], not for
   an atom the manifest masks`. The manifest was `Build.manifest ["rel.occupies"]`, as the record
   declares. After this I tried a scene-level gap instead (next run).
2. `WITNESS_FAIL` — `blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest
   masks`. Here the manifest masked nothing and x's occupancy was left unobserved only at t1, which
   is exactly the narrative. The result was unknown for the absent atom alone, but the gate requires
   the deciding atom to be masked *by the manifest*. After this I restored the record's mask
   `["rel.occupies"]`.

## The record is wrong: the `blind` scenario

**Element:** scenario `blind` (`masked: ["rel.occupies"]`, narrative: "rel.occupies of x and c is
not observed at t1, the observation at which x's overlap of r began").

**Why it cannot be met:** the gate accepts a `blind` unknown only if every reason for it comes from
an atom the manifest masks. A manifest mask blanks the atom at *every* observation
(`Mask.scene "rel.occupies"` clears `occupancyObserved` in every scene). This concept reads only
`rel.occupies`, and it reads it in a search into the past (`since`/`rises`). With the atom blanked
everywhere, that search reaches the first observation and also carries
`window_truncated:since/rises`. Any faithful body has the same problem, because the contract itself
makes the result depend on the overlap's beginning, and the beginning is unobservable once
`rel.occupies` is gone everywhere. A gap at t1 alone, as the narrative describes, cannot be written
as a manifest mask; written in the scene, the gate does not count it as masked (run 2).

**What the plan agent must change:** the `blind` scenario. Either:
- declare it as a history-boundary witness. The contract states "an overlap already under way at
  x's first observation" is unknown, so a scenario where x is already inside r at the trace start,
  with `boundary` declared, exercises the contract's own unknown case; or
- give it a masking the gate can attribute that does not blank every observation of the only atom.
  Today no manifest form can do this, so the first option is the practical one.

## Why I finished

The record is wrong: its `blind` scenario cannot be satisfied by any body that is true to the
contract (shown by runs 1 and 2). Per the procedure, I stopped and am reporting it rather than
working around it. I used 2 of 6 gate runs.
