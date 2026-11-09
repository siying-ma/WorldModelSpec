# drv.motion.turning — coding session result

## Final verdict

`OK` — "3 witnesses, 1 names, reads 1 atom(s)".

## The body

```lean
def body : Formula :=
  .cmp (.abs (.quantity "prim_heading_change" [aU] [pWindow])) .ge pHeadingChangeTolerance
```

The one element of the record, "the magnitude of its heading change over the window behind the
observation", is `prim.heading_change` — the signed heading change in degrees over the window
behind the observation, integrated from `kin.yaw_rate`. `Term.abs` is the contract's *magnitude*
(so a bend in either hand counts and the body states no direction), `.ge` its *at least*, and the
primitive's own window parameter takes this concept's `window` formal unchanged. No other name is
read: no onset, no steer angle, no curvature, no lane, no signal. Where the primitive is unknown
(window truncated, sampled too sparsely, a yaw rate missing) the concept is unknown, never false.

## The witnesses

One instance, `drv.motion.turning@w`, with figures of the witness's own: `window = 2 s`,
`heading_change_tolerance = 5°`. All three traces are nine scenes 0.5 s apart (t = 0 … 4000 ms),
track 1 a van (half-extents 2.5 × 1.0 × 1.2 m), one region holding its positions.

- `holds` (compliant): a left swing round intersection region 10 at 5 m/s, steady yaw rate 20 °/s,
  heading turning 10° per scene on an arc of radius ≈ 14.3 m; the integrated heading change over
  every covered window is 40° ≥ 5°.
- `fails` (violated): the same van reversing straight west along roadway region 20 (gear −1,
  velocity opposite its heading), yaw rate 0.4 °/s, so 0.8° over the window — under a degree, below
  the tolerance.
- `blind` (unknown): the corner manoeuvre with `kin.yaw_rate` absent from the manifest; the
  primitive integrates that atom, so it is unknown wherever the window is otherwise decidable.

## Gate runs

1. `WITNESS_FAIL` — "blind: unknown for [window_truncated:prim_heading_change], not for an atom the
   manifest masks". The 2 s lookback is truncated at every trace's first four instants, so the
   blind episode carried a truncation reason beside the masked atom.
   **Change:** gave the `blind` scenario the same instant range as the other two,
   `window := some (2000, 4000)`, where the window behind is covered; there the only reason it is
   unknown is the masked yaw rate.
2. `OK`.

## Choices the record left open

- **Formal-parameter values (the witness's, not the concept's).** `window = 2 s` — long enough for
  a junction turn to register at 0.5 s sampling and (at a 0.5 s gap) within the primitive's
  sampling adequacy bound of half the window; `heading_change_tolerance = 5°` — the order of a
  yaw-rate source's resolution, well under any turn a road asks for.
- **The instants the witnesses speak about.** A 2 s window behind is truncated at the start of any
  finite trace — at the first observation it is truncated whatever padding is added, since nothing
  is observed before it. So each scenario names `[2000, 4000] ms`, the instants whose window is
  covered. This is a property of the witness, not a narrowing of the contract.
- **The reversing van's slight yaw.** The narrative says "under a degree", not zero; I wrote
  0.4 °/s with the heading turning 0.2° per scene, which keeps the trace consistent with the
  trace-lint rule that a non-zero yaw rate must move the heading.
- **No narrowings declared on the concept.** The contract fixes the quantity (the primitive's
  magnitude), the window (the concept's own formal, passed through) and the sense of the bound
  ("at least", so the tolerance itself counts as turning); nothing was left open to choose among.
  The header comment records the writing element by element.

## Why I finished

The gate returned `OK` on the second of six runs: the body says what the record's single element
says over the record's formals, the three scenarios reach `compliant`, `violated` and `unknown`
for the intended reasons, and the blind witness is unknown because the yaw rate it masks is the
atom that decides it. Nothing in the record is wrong, so there is nothing to report back to the
plan agent and no dependency defect to file.
