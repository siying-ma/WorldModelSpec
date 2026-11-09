# drv.motion.left_turn — coding session

## Final verdict

**OK** (gate run 2 of a budget of 6): `3 witnesses, 2 names, reads 2 atom(s), narrowings declared by the coder: 1`.

## The body

```lean
def onset : Formula := .cmp (.measure "kin_yaw_rate" [aU]) .gt pOnsetYawRate
def headingChange : Term := .headingSince "u" pHeadingStep onset
def body : Formula := .cmp headingChange .ge pTurnAngle
```

Element by element, over the formals and the one claimed atom only:

- *"its rate of change of heading to the left first rose above the onset yaw rate"* → `onset`:
  `kin.yaw_rate` is signed, left positive, so "to the left … above the onset yaw rate" is the plain
  strict comparison of the signed rate with the parameter. `Term.headingSince` counts from the
  definite rise of this formula, which is the observed onset.
- *"the heading change accumulated since that onset"* → `headingChange`: the same atom integrated
  by the language's own construct since that onset, counted from zero there, with the heading step
  as the step bound (the declared time formal used directly, as required).
- *"reaches at least the turn angle … to the left"* → the body: `≥ turn_angle`, inclusive.

The contract's three sentences on the extent and the history need nothing further, because they are
`headingSince`'s own semantics: the comparison becomes true at the observation at which the
accumulated change first reaches the angle, stays true at later observations while it still holds it
(a later rate of zero adds nothing), restarts at the next definite onset, and is **unknown, never
false**, where no onset is observed with the onset formula known at every observation since (a turn
already under way at the first observation, or an unknown rate that could hide the onset), where an
interval from the one ending at the onset is wider than the heading step, or where a rate since the
onset is missing.

## Gate runs

| # | verdict | what changed after it |
|---|---------|------------------------|
| 1 | `WITNESS_FAIL` — all three traces rejected by the trace lint: *"track 1 keeps the heading it had at t=…, but its yaw rate turns it 15° over the interval (the rate at a scene is held over the interval before it)"* | The body was not at issue: my scenes held the heading constant across an interval with a non-zero yaw rate. Rebuilt the three traces so that every observation's heading is the previous one turned by that observation's rate — east, 15°, 30°, 45°, 60° in `holds`; 6°, 12°, 18°, 12°, 6°, east in `fails`; 45° through 180° in `blind` — and left the heading parallel only where the rate is zero. Positions follow the headings at 5 m an observation. |
| 2 | `OK` | — |

## Choices the record left open

1. **Declared as a narrowing** (`kind := "reading"`, on the span *"the observation at which its rate
   of change of heading to the left first rose above the onset yaw rate"*): the onset is read as the
   **latest** definite rise of `kin.yaw_rate > onset_yaw_rate` before the judged observation, not the
   first of the recording. The contract's own later words — *"until a later onset starts the count
   again"* — direct this, and it is what `Term.headingSince` takes as its start.
2. *"above the onset yaw rate"* is written strictly (`.gt`) and *"reaches at least the turn angle"*
   inclusively (`.ge`); both are dictated by the words, so neither is declared as a narrowing.
3. **Witness figures** (the witness's own, not the concept's): heading step 500 ms = the spacing of
   the observations, onset yaw rate 5 deg/s, turn angle 45 deg; one car, ten observations half a
   second apart, no region and no device, since the concept states the turning of the body only.
4. **`holds` names a window** (t = 2500 … 4500). It must: the first observation of any trace can
   never be an onset (a rise needs a false value before it), so the concept is unknown there and
   false between the onset and the angle being reached — both of which the contract prescribes. The
   window is exactly the observations the narrative speaks about: the angle first reached (t = 2500,
   a second and a half after the onset at t = 1000) and still held to the end. `fails` needs no
   window (a violation anywhere decides the episode); `blind` covers the whole trace, every
   observation of which is unknown for the masked `kin.yaw_rate`.

## Why I finished

The gate returned `OK` on the second run: the two files build, the body passes the static checks and
claims exactly the record's one atom, and the three witnesses reach `compliant`, `violated` and
`unknown` (the last for the masked atom alone) on built scenes. Nothing in the record is wrong — the
contract's extent and history clauses map onto `Term.headingSince` without approximation — so there
is no defect to report and no reason to spend further runs.
