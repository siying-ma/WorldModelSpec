# drv.motion.u_turn — coding session result

## Final verdict

**OK** (first gate run; 3 witnesses, 4 names, reads 4 atoms, 2 narrowings declared). Budget spent:
1 of 6 gate runs.

## Gate runs

| # | verdict | what changed after it |
|---|---------|-----------------------|
| 1 | `OK` | nothing — the body and the three witnesses were written in one pass before the run, and the run accepted them. |

## The body

```
reversed ∧ uponWay
  reversed := |headingSince u heading_step (|kin_yaw_rate u| > onset_yaw_rate)| ≥ reversal_angle
  uponWay  := ∃ region w of kind highway. rel_occupies u w
```

- **"the magnitude of its rate of change of heading first rose above the onset yaw rate"** →
  `onset`, the standing condition `|kin_yaw_rate u| > onset_yaw_rate`; the onset the count runs
  from is this condition's *definite rise*, which is what `Term.headingSince` anchors to.
- **"the magnitude of the heading change accumulated since that onset"** →
  `.abs (.headingSince "u" (.param "heading_step") onset)`, the formula language's own construct,
  integrated from the same atom with the heading step as its step bound (the declared time formal
  passed directly, as required). A halt, a rearward movement or steering the other way between the
  onset and the reversal does not end the count: the operator's count is unaffected by the
  condition turning false, and only a later definite rise starts it again — which is the contract's
  own extent. Unobserved is unknown: with no observed onset (or a missing yaw rate since one) the
  term is unknown, so the concept is unknown and never false.
- **"while the road user's footprint overlaps a way"** →
  `existsRegion (.lit "highway") "w" (rel_occupies u w)`; `w` is anchored to the track formal `u`
  through `rel_occupies`, so the way read is the one the body is on.

All three claimed names are used (`kin.yaw_rate`, `st.highway` through the quantifier's kind,
`rel.occupies`) and nothing else is read but the clock the integration itself reads
(`kin.time`, which `headingSince` always reports). All three formal parameters are used; no
magnitude is the file's own.

## What the record left open, and what I chose (both declared as narrowings)

1. **"…first rose above the onset yaw rate".** The count is anchored to the **latest** rise of the
   onset condition, not to the first of the recording. The contract's extent fixes this ("the count
   runs on until the angle is reached **or a later onset starts it again**"), and it is exactly what
   `headingSince` computes; "first" is read as the first rise of the run the count belongs to.
2. **"while the road user's footprint overlaps a way".** Read at the observation the concept speaks
   about — the one at which the angle is reached, and each later one at which the accumulated
   change still holds it — not as a condition required at every observation from the onset onwards.

## Figures the witnesses chose (the witness's own, not the contract's)

- Instance: `heading_step` 2 s, `onset_yaw_rate` 4 deg/s, `reversal_angle` 150 deg (below a half
  turn). Every trace is sampled at 1 s, so every interval — the one ending at the onset included —
  is within the heading step.
- Geometry: the city street as one highway region (region 10, 120 m × 28 m); the `fails` trace adds
  the side street as a second highway region (region 11). Track 1 is a motor vehicle 4.8 m × 1.8 m.
- `holds` is windowed to 7–9 s and `fails` to 1–6 s: these are the observations the record's
  narratives speak about. Before the recognition the body is false (the angle not yet reached) or
  unknown (no onset yet observed), which is what the contract says of those observations, so an
  unwindowed episode would not be the verdict the narrative states. `blind` needs no window: with
  `kin.yaw_rate` absent the body is unknown at every observation.

### One construction choice worth flagging to the plan agent

The `holds` narrative has the car **halt** and reverse mid-manoeuvre. Under the operator the
contract names, an observation at which the yaw rate magnitude falls back to or below the onset
yaw rate, followed by a later rise, is "a later onset" and starts the count again — so a sampled
dead stop would restart the count and lose the accumulated angle. I therefore built the pause as
the manoeuvre a three-point turn actually is: the car creeps at 2 km/h and then backs up a metre
with the wheel reversed, which keeps the body rotating counter-clockwise at 10 deg/s, so the yaw
rate magnitude stays above the onset rate and the count runs on from the single onset at t = 1 s
to the 170 deg reached at t = 7 s. This is a witness-construction choice, not a reading of the
body: the contract and the body agree that a halt in itself does not end the count, and that a
later onset starts it again. If the plan wants a witness in which the count survives an *observed*
sub-threshold stop, no formula over `headingSince` can give it, and the record would need a
different element for the accumulation.

## Why I finished

The gate returned `OK` on the first run: the body says what the record's three elements say over
the formals and claimed names only, every claim is used, no leaf is vacuous, and the three
witnesses reach `compliant`, `violated` and `unknown` as the record's narratives state. There was
nothing left to repair, so I stopped with 5 gate runs unspent.
