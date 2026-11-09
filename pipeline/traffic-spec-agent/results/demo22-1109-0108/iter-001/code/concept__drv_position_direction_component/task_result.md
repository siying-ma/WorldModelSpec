# drv.position.direction_component — coding session

## Final verdict

**OK** — `3 witnesses, 2 names, reads 2 atom(s)`, 1 narrowing declared. One gate run of the six in budget.

## Gate runs

| # | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing; the session finished |

Before running the gate I read Core to settle three things the surface left implicit:
`Language/Semantics.lean` (vector-valued measured atoms take a component literal: `evalMeasure`
matches `"kin_velocity", [x, k]` and `"st_lane_direction", [r, k]`, with `comp` accepting `"x"` and
`"y"`), `Language/RuleEval.lean` (`dummyArgs` checks the arguments actually written, so the
two-argument form is the right arity, and `Scope`/`Concept.asRule` give the region formal no binder),
`Evidence/TraceLint.lean` (a designated direction is carried only by a travel structure — a one-way
roadway is one — and must be non-zero; boundaries need three distinct vertices and a non-zero area),
and `Vocab/Atoms.lean` (`Geom.unit`, to check the normalisation is exact for the direction I chose).

## The body

```
vx·dx + vy·dy   with   vx,vy = kin_velocity u ("x","y")   dx,dy = st_lane_direction r ("x","y")
```

Both claimed atoms are read and nothing else is. `u` and `r` are the formals; the body binds no
variable of its own and quantifies over no region, which is what makes the quantity "geometric only":
it never says the road user is on `r`. Unknown comes for free — a product is unknown where either
factor is, so the sum is unknown exactly where the velocity is unobserved or the region carries no
designated direction (a centre turn lane, a place no carrier covers, a zero vector). No `definedWhen`
guard is written because it would only restate that.

## Choices the record left open

1. **The projection as a two-component sum** (declared as the narrowing on the span "The component,
   in metres per second, of a road user's velocity along the designated direction of travel of a
   structure region"). The contract names a component along a direction without saying how it is
   formed. The atoms are vector-valued and a formula reaches their components only through the
   component literals `"x"` and `"y"`, so the scalar projection is written `vx·dx + vy·dy` in the
   world frame. The world is planar, so no height term exists to leave out.
2. **No parameter for "near zero".** The contract's "near zero where it stands or moves across it" is
   a description of the value, not a bound the quantity applies; the record declares no formal
   parameter and no literal, and the body compares nothing. A caller that wants a dead band states it
   with its own bounds. (This is a reading of the contract's own words — the quantity is the value,
   the caller sets the interval — not a narrowing of the writing.)
3. **The witness's own figures** (none of them the concept's): region 100 a one-way roadway, the
   rectangle (−60,−60)–(60,60) m, carrying the designated direction `(3, 4)` m — off-axis on purpose,
   so both components of the projection do work, and exact under the atom's normalisation (divided by
   its larger component it is (3/4, 1), of length exactly 1.25 m, so the vector read is exactly the
   unit vector (0.6, 0.8)). Track 1 is a car, half-extents (2, 1, 1) m, at 8 m/s over three
   observations a second apart. `holds` heads (3/5, 4/5), giving velocity (4.8, 6.4) m/s and a
   projection of exactly +8 m/s; `fails` heads the other way, giving exactly −8 m/s; `blind` is the
   `holds` scene with `st.lane_direction` declared absent. The instance's bounds are [+4, +12] m/s,
   which admit travel with the designation at 8 m/s and exclude −8 m/s.

## Residues and supersession

The record declares none of either, and I changed neither; `id`, `contract`, `definition`, `args`,
`params`, `residues` and `supersedes` are the skeleton's.

## Why I finished

The gate returned `OK` on the first run: the concept builds and passes its static check, the body
uses exactly the two claimed atoms over the formals only, and the three witnesses reach
`compliant` / `violated` / `unknown` as the record's narratives say. Nothing in the record is wrong,
so there is no defect to report and no reason to spend more of the budget.
