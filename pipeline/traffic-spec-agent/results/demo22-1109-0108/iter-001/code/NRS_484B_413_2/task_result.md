# NRS_484B_413_2 — coding session result

**Final verdict: `OK`** (3 gate runs of 6 used; 12 witnesses, 6 planned names, composes nothing,
1 coder narrowing).

## The rule, span by span

- **binder `v`** — `ru_aggregate v "DEF-NRS-484A-320::vehicle"`: the admitted aggregate id, not the
  classes the posted definition covers.
- **s3 (the occasion)** — `applicability := .rises (.derived "drv_motion_turning" [v]
  [p.turn_recognition_window, p.heading_change_noise_floor])`. The concept is the node's element for
  "changing the course of a vehicle"; "prior to" is read, as the record states, from the observation
  at which that change is first recognized. Parameters in the catalogue's order (window, tolerance).
- **s1 + s2 (the duty and the length s2 selects)** —
  `and (asm → gaveSignalOver 100 ft) (¬asm → gaveSignalOver 300 ft)`, where
  `gaveSignalOver d = and (yaw_rate > 0 → holdsFor .path d "v" (ind left ∨ arm left))
  (yaw_rate < 0 → holdsFor .path d "v" (ind right ∨ arm right))`.
  The hand is read at the judged observation from the sign of `kin.yaw_rate` (left positive),
  *outside* the window, so the window asks for the hand of the course change being judged and not
  for a hand read at each past observation. `kin.path_length` is read as the measure of the
  `.path` windows, as the element's justification states.
- **s4** — residue, verbatim from the node; no weather atom is read.

## Choices the node left open

1. **Two conditionals instead of one `cond` length.** The record says the length is "selected by a
   condition on that declaration". A window's length must be a *constant* term
   (`Rule.check`/`Term.isConstant` excludes `.cond`), so the selection is written as
   `asm → (100 ft duty)` conjoined with `¬asm → (300 ft duty)`. This preserves the record's
   three-valued requirement: where the trace declares the district neither way both conditionals are
   undecided and the verdict is unknown.
2. **The hand at a zero yaw rate** — declared as the session's one narrowing on s1 (an obligation
   span): the hand is read from the *sign* of `kin.yaw_rate`, so at an observation whose rate of
   change of heading is exactly zero neither hand is read and the duty is not stated there. A signal
   on the other hand does not satisfy the duty, as the record's own narrowing requires.
   No other narrowing is declared; the record's own narrowings are not restated.

## Witnesses

All twelve share one geometry (documented in the witness header): one lane, one motor vehicle
(track 1 ↦ `v`), 26 observations 0.5 s apart, 10 m/s, 5 m of travelled path per observation. The
course change is one observation long and is carried by `kin.yaw_rate` = ±32.52 deg/s at
observation 25, with the heading there the exact unit vector (24/25, ±7/25) and the position the
previous one advanced exactly 5 m along it — so `drv.motion.turning` rises at observation 25
(16.26 deg of heading change against the reading's 5 deg floor) and nowhere else. Every scenario
names `window = 10 000 … 12 500 ms` (observations 20 … 25), because the recognition window and the
windows of travelled path are truncated at the start of any finite trace; no witness is unknown for
truncation.

Beyond the six planned names, six `branch_<n>` witnesses exercise the leaves the planned scenes do
not reach: the duty has four combinations (district / no district × left / right hand) and two
alternative signals in each, so each combination needs a scene in which both alternatives are false
and one in which the district declaration decides the length:

| witness | district | hand | signal | expected |
|---|---|---|---|---|
| `forbid` | yes | right | none | violated |
| `permit` | no | left | left indicator throughout (410 ft) | compliant |
| `idle` | no | — (straight) | none | not_applicable |
| `blind` | yes | left | both signal atoms masked | unknown |
| `branch_1` | no | left | right indicator throughout | violated |
| `branch_2` | yes | left | arm signal left throughout | compliant |
| `branch_3` | no | right | none | violated |
| `branch_4` | yes | left | none | violated |
| `branch_5` | yes | left | left indicator over the last 50 m (164 ft) | compliant |
| `branch_6` | no | left | left indicator over the last 50 m | violated |
| `branch_7` | no | right | right indicator throughout | compliant |
| `branch_8` | yes | right | arm signal right throughout | compliant |

`branch_5`/`branch_6` are the pair that makes the district declaration itself decisive: the same
50 m of signal keeps the 100 ft bound in a district and breaks the 300 ft bound outside one, each by
a clear margin (164 ft > 100 ft, 164 ft < 300 ft).

## Gate runs

1. **`WITNESS_FAIL`** — "its trace is not one the adapter can produce: track 1 keeps the heading it
   had at t=…, but its yaw rate turns it -10° over the interval (the rate at a scene is held over
   the interval before it)". The first traces stated the bend through the yaw rate alone and kept
   the subject on a straight line heading east. *Changed:* the bend was reduced to a single
   observation and the scene now states the turn it carries — the heading rotated by the yaw rate
   over the half second behind, the position advanced along that heading.
2. **`WITNESS_FAIL`** — "path_length grows by 5 m since t=12000, less than the straight-line
   distance between its two positions": the micrometre rounding of a 10° rotation pushed the chord
   1.6 µm past 5 m. *Changed:* the turn now uses the exactly representable unit heading
   (24/25, 7/25) with the yaw rate `Units.millidegrees 32520`, so the chord, the position, the
   velocity and the path increment are exact (5 m) and only the yaw rate carries a rounding of
   0.0002°.
3. **`OK`**.

## Why I finished

The gate returned `OK`: the rule builds, checks, declares what the node declares, uses every
claimed name and no other, carries no bare literal, and all twelve witnesses reach their expected
verdicts — the four planned ones for the reasons the plan names (the `blind` witness unknown only
for the two atoms its manifest masks). The node needed no repair: every span it carries is written
with the atoms and the concept it claims, and nothing in it had to be read against its words.
