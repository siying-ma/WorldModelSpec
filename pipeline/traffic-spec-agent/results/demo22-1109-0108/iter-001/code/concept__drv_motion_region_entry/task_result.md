# drv.motion.region_entry — coding session

**Final verdict: `OK`** (3 witnesses, 1 name, reads 1 atom), reached on the first of 6 budgeted
gate runs.

## The body

```lean
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []
def body : Formula := .rises overlaps
```

Element by element:

- *"comes to overlap a structure region at the observation"* → `rel_occupies u r`: the road user
  formal's footprint overlaps the region formal. The region's kind is the caller's, so the body
  holds no structure kind and no region quantifier — `r` is read directly, as the record's formal.
- *"did not overlap it at the observation before"* → the `rises` of that same reading. `rises φ`
  is φ here and not at the previous observation, which is exactly the event of the overlap having
  begun: no direction, no carrier, no speed, no place within the region, and not the standing state
  of lying inside.

No other atom, no concept, no parameter, no literal: the record claims one atom and the body reads
it twice under one operator.

## The witnesses

One instance (`drv.motion.region_entry@w`, nothing to fill: no literal formal, no nat, no
parameter, no bounds). All three traces share the geometry: region 100 is a square junction polygon
(x, y ∈ [-10 m, 10 m]); track 1 is a car (half-extents 2 m × 1 m × 1 m) heading north at 10 m/s
along x = 0; three scenes one second apart at t = 0, 1000, 2000 ms; occupancy is derived from the
geometry.

| scenario | northings (t = 0, 1000, 2000) | window | expected |
|---|---|---|---|
| `holds` | −15 m, −5 m, 5 m — clear, then inside | 1000–1000 | compliant |
| `fails` | −5 m, 0 m, 5 m — inside throughout | 1000–2000 | violated |
| `blind` | as `holds`, with `rel.occupies` masked | 1000–1000 | unknown |

## Choices the record left open

- **Windows, not padding.** The event looks back one observation, so at a trace's first scene it is
  truncated (`Build.pastOps` lists `rises`). Padding cannot help here: a repeated first scene is an
  instant at which the event is false, which would make `holds` violated. So each witness names the
  instants it speaks about with `window` — a single instant for `holds` and `blind` (the event is
  true, resp. unknown, only where the overlap begins), and t = 1000–2000 for `fails`, where the car
  is already inside at both. No `boundary` is declared: the plan declares none, and the windows keep
  the truncated first scene out, so `blind` is unknown for the masked atom alone.
- **The junction as the region.** The narratives say "junction polygon", so region 100 is of kind
  `intersection`; nothing in the body reads the kind, so the choice is the witness's convenience
  only.
- **No narrowing declared.** The contract states the reading in full ("it overlaps the region at the
  observation and did not overlap it at the observation before"), and the record's element
  justification names `rises` for the second span. Nothing was left to choose in the body, so
  `narrowings` stays empty.

## Why I finished

The gate returned `OK` on the first run: the concept checks, the body reads only the claimed atom
and every claimed name, no leaf is vacuous, and the three witnesses reach compliant, violated and
unknown for the reasons their narratives give. Nothing in the record needed repair, so there is no
`dependency_defect.json` and no further run was spent.
