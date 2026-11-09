# drv.motion.reverse_travel — coding session

**Final verdict: `OK`** (`3 witnesses, 2 names, reads 2 atom(s)`), on the first of six gate runs.

## Gate runs

| # | verdict | what changed after it |
|---|---------|-----------------------|
| 1 | `OK` — 3 witnesses, 2 names, reads 2 atom(s) | nothing; the session finished |

Before running the gate I read Core to fix two things the surface left open: that
`kin_velocity`/`kin_heading` take a track and a component selector `"x"`/`"y"`
(`Language/Semantics.lean:262-273`, with `kin_heading` normalised through `Geom.unit`), and what
`Evidence/TraceLint.lean:250-322` demands of a written trace (a footprint for every observed track,
a boundary for every structure where occupancy is observed) — hence scenes with the car fully
built and no structures at all.

## The body

```
cmp (kin_velocity(u,x)·kin_heading(u,x) + kin_velocity(u,y)·kin_heading(u,y))
    ≤ neg (param reverse_speed_tolerance)
```

The one element, "the component of its velocity along the direction its body points", is the scalar
product of the velocity vector with the direction the body points; since a formula reads
`kin.heading` normalised, that product is the signed speed along the heading in m/s, negative
rearward. `kin.speed` and `kin.gear` are not read, as the record's justification directs. Nothing of
duration, place, gear, signal or turn enters the body.

## What the record left open, and what I chose

- **Nothing in the contract required a narrowing**, so `narrowings := []`:
  - *The bound's strictness* is dictated — "at most the negative of the reverse speed tolerance" is
    `.le` against `.neg` of the parameter, so a rearward component of exactly the tolerance holds.
  - *The direction of the comparison* (rearward = negative component) follows from the element's own
    reading of velocity against heading.
  - *The residual inexactness of the normalised heading* (Core reads it as the unit vector times a
    factor in [1, 1 + 2·10⁻⁶)) is Core's reading of the atom, not a choice of mine; it is recorded in
    the file header. For the axis-aligned headings of the witnesses the factor is exactly 1.
- **Figures chosen for the witnesses** (the witness's own, none of them in the concept file):
  - `reverse_speed_tolerance := 0.2 m/s` (200 000 µm/s) — a plausible resolution floor for a
    source's velocity estimate; it keeps both decided scenarios clear of the boundary.
  - speed 1.5 m/s in all three scenarios, as the narratives state; car half-extents
    2.25 × 0.90 × 0.75 m; three instants a second apart at t = 0, 1000, 2000 ms.
  - `holds`: heading east, velocity 1.5 m/s west (component −1.5 m/s), position moving west 1.5 m
    per second. `fails`: heading east, velocity 1.5 m/s east (component +1.5 m/s). `blind`: the
    `holds` manoeuvre with `kin.velocity` absent from the manifest, so the heading is read and the
    component cannot be formed.
  - No structures and no devices: the concept reads neither, and a region would have to be given a
    boundary and a representation it plays no part in. The parking bay of the narratives is therefore
    only in the motion, not in the map.

## Why I finished

The gate returned `OK` on the first run: the body says what the contract says over the two claimed
atoms and the one formal parameter, every claimed name is read, and the three witnesses reach
`compliant`, `violated` and `unknown` as the record's scenarios expect. There is nothing left to
repair and no defect in the record to report.
