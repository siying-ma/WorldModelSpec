# drv.motion.standstill — coding session result

## Final verdict

**OK** — `3 witnesses, 1 names, reads 1 atom(s)`, on the first gate run (1 of 6 budgeted runs used).

## Gate runs

| # | Verdict | What changed after it |
|---|---------|-----------------------|
| 1 | `OK` | Nothing: the session finished. |

Before the run I checked Core rather than guessing an arity: `Language/Semantics.lean:274` matches
`"kin_speed", [x]`, so the measure takes exactly one argument (the `[t, none, none]` row in
`atomArgSorts` is the maximal shape for the `kin_*` family, not a required arity).

## The body

```lean
def body : Formula :=
  .cmp (.measure "kin_speed" [aU]) .le pSpeedTolerance
```

One comparison, over the single track formal `u` and the single formal parameter
`speed_tolerance`, reading the one claimed atom `kin.speed` and nothing else.

- `kin.speed` is the magnitude of velocity in m/s — exactly the quantity the definition's
  "complete cessation from movement" bounds. `kin.velocity` is not read: the contract speaks of
  movement, not of its direction.
- `.le`: "at most", and the contract's own gloss "a sampled reading **at or below** it", make the
  bound non-strict.
- No window, no region, no control state: the body judges the single observation, so none of
  `holdsFor`/`since`, `rel.occupies`, `kin.engine_running`, `kin.parking_brake` or
  `kin.service_brake` appears — the contract's "Not a stand-in for" list excludes all of them.
- Where `kin.speed` is unobserved the comparison is unknown, not false, which is what the `blind`
  witness turns on.

## Choices the record left open

**None that required a narrowing**, so `narrowings := []`. The contract fixes the quantity (the
magnitude of velocity), the direction and strictness of the bound ("at most", "at or below"), and
the source of the magnitude (the caller's parameter, never a figure in the concept file). Nothing
was left for me to decide in the body, and nothing in the contract needed an atom or an operator
the surface lacks, so there is no `no_atom`/`no_operator` declaration either. The residue (the
definition's scope clause) stayed verbatim as the harness wrote it.

Choices that were mine are the **witness's figures only**, which the concept file does not carry:

- `speed_tolerance` = **0.2 m/s**, written `Units.micrometresPerSecond 200000` (the integer
  `metresPerSecond` constructor cannot express a sub-1 m/s resolution). Any small positive speed
  separates the three narratives; 0.2 m/s is a plausible source resolution for a standing body and
  sits well clear of both witness speeds (0 and 2 m/s).
- Geometry: one 10 m square intersection about the origin (the "junction" of all three narratives)
  and one car, track 1 = `u`, half-extents (2 m, 1 m, 0.75 m), heading north, three observations
  1 s apart. The intersection is present for faithfulness to the narratives; the body reads no
  region, so no region formal and no `regions` entry exist.
- `holds`: car at rest at (0, −6) m, speed exactly 0 at all three observations → 0 ≤ 0.2 →
  compliant.
- `fails`: car rolling north from (0, −6) m by 2 m per observation at 2 m/s → 2 ≤ 0.2 is false →
  violated.
- `blind`: the same rolling approach with `kin.speed` masked by the manifest, so the one deciding
  atom is unobserved → unknown. No lookback operator is in the body, so no padding and no `window`
  are needed.

## Why I finished

The gate returned `OK` on the first run: the concept builds and checks, the body uses every claimed
name and only claimed names, every variable is a formal, the only magnitude is the formal parameter,
and the three witnesses deliver compliant / violated / unknown as the record's scenarios expect. The
record needed no repair — its single element maps cleanly onto `kin.speed`, and the contract's
exclusions are honoured by what the body does *not* read. Nothing was left out, and no dependency
defect arose (the concept calls no other concept; the catalogue is empty).
