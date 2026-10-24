# Parameter selection: a worked example (NRS 484B.600(1)(a) on carla_new M023)

This note shows how the value of a reading parameter, not the structure of a rule, can decide a
verdict, and what that implies when the operator reviews a proposed value. It is evaluation
material: it lives in `pipeline/evaluation/`, which no pipeline phase reads, and nothing in the
pipeline may be changed because of what it shows. In particular, a parameter value is never chosen
to make this case come out one way or the other; see "How to use this example" at the end.

## The rule and its parameters

The rule is run smoke18's accepted node `NRS_484B_600_1a`, the basic speed rule: "It is unlawful
for any person to drive or operate a vehicle of any kind or character at a rate of speed greater
than is reasonable or proper, having due regard for the traffic, surface and width of the
highway, the weather and other highway conditions." Its Lean source is
`library/TrafficSpec/Rules/NRS_484B/NRS_484B_600_1a.lean` while smoke18's library is active
(`init --fresh --snapshot smoke18` moves it to
`results/smoke18/library_snapshot/TrafficSpec/Rules/NRS_484B/NRS_484B_600_1a.lean`).

The obligation is the conjunction of four limbs. The one that matters here is the sight limb
(`withinSightDistance`, lines 161–166 of that file):

> For every lane the subject occupies, the required distance is at most that lane's sight
> distance (`st_sight_distance`).

The required distance is the subject's stopping distance (the accepted concept
`drv.motion.stopping_distance`):

    stopping = v · t_r + v² / (2 · a)

where `v` is the subject's speed, `t_r` the reaction time and `a` the deceleration the surface
affords. Ice or snow selects `p.decel_ice`, else a wet road or precipitation selects
`p.decel_wet`, else `p.decel_dry`. On a lane narrower than `p.narrow_lane_width`, the stopping
distance is multiplied by `p.narrow_lane_margin`.

The values in smoke18's reading are all proposals by the planner that the operator has not yet
reviewed:

| Parameter | Value | The convention the planner cited |
|---|---|---|
| `p.reaction_time` | 2.5 s | the brake reaction time of the stopping-sight-distance design model |
| `p.decel_dry` | 3.4 m/s² | the deceleration that model assumes on a dry paved surface |
| `p.decel_wet` | 2.5 m/s² | a wet-pavement deceleration |
| `p.decel_ice` | 1.0 m/s² | an icy or snow-covered surface |
| `p.narrow_lane_width` | 3.0 m | the width below which a lane counts as narrow |
| `p.narrow_lane_margin` | 1.25 | the factor applied to the stopping distance on a narrow lane |

The stopping-sight-distance design model (2.5 s and 3.4 m/s²) describes a design envelope: the
sight a road must offer so that a slow-reacting driver on a poor surface can still stop. It is
deliberately conservative.

## The case

carla_new case M023 was built as a slow approach, about 16 mph, to a bend of 17 m radius with
about 100 ft of sight, followed by a U-turn. The dataset ships no labels; the setup suggests the
approach is reasonable.

The monitor reports 600-1a `violated` from 64.20 s to 64.30 s and nowhere else. Running each of
the four limbs on its own shows that only the sight limb fires:
- the traffic and headlamp limbs are compliant throughout;
- the visibility limb is never decided, because the recording carries no visibility.

The frames around the violation (subject in lane 1; the trace's own sight distance for that lane;
required distance on a dry surface):

| Time | Speed | Sight distance of the lane | Required (dry) | Result |
|---|---|---|---|---|
| 64.1 s | 6.83 m/s (15.3 mph) | 25.31 m (83 ft) | 23.94 m | compliant |
| 64.2 s | 7.05 m/s (15.8 mph) | 24.69 m (81 ft) | 24.93 m | violated |
| 64.3 s | 6.93 m/s (15.5 mph) | 24.06 m (79 ft) | 24.40 m | violated |
| 64.4 s | 6.58 m/s (14.7 mph) | 23.59 m (77 ft) | 22.83 m | compliant |

At 64.2 s: 7.05 m/s × 2.5 s = 17.62 m covered before braking, plus 7.05² / (2 × 3.4) = 7.31 m
of braking, gives 24.93 m against 24.69 m of sight. The rule is short by 0.24 m.

The trace's sight distance near the bend is 79–83 ft, not the 100 ft of the setup. That is one
reason the setup's expectation and the rule disagree.

### Why this instant is decided although data is missing

The recording does not say whether the road is icy, and gives no lane widths, so the surface
branch and the narrow-lane margin are unknown. Core decides the limb only where every branch
gives the same answer:
- **64.2–64.3 s:** even the most lenient branch (dry, normal lane, 24.93 m) exceeds the sight,
  so the limb is violated whatever the surface or width.
- **60.3–64.1 s:** the dry branch passes but the icy branch (40–42 m) fails, so these frames are
  unknown, not compliant.

A missing fact never reads as compliant.

## What decides the verdict: the parameters

The rule's structure is the same for every value; the verdict at 64.2 s turns on two numbers.

| `p.reaction_time` | `p.decel_dry` | Required at 64.2 s | Against 24.69 m |
|---|---|---|---|
| 2.5 s | 3.4 m/s² | 24.93 m | violated |
| 2.0 s | 3.4 m/s² | 21.41 m | compliant |
| 1.5 s | 3.4 m/s² | 17.88 m | compliant |
| 1.0 s | 3.4 m/s² | 14.36 m | compliant |
| 2.5 s | 4.5 m/s² | 23.15 m | compliant |
| 1.5 s | 4.5 m/s² | 16.10 m | compliant |

At this frame the break-even reaction time is 2.465 s (with 3.4 m/s²), and the break-even
deceleration is 3.52 m/s² (with 2.5 s). The proposed values sit just past both edges.

The margin is also small against the measurement:
- the sight distance is sampled in steps of about 0.16 m, and the bracket at 64.2 s is
  [24.69, 24.84] m;
- the required 24.93 m exceeds even the top of that bracket, but by only 0.09 m.

## What this shows about choosing a parameter

1. **A design value is not automatically a conduct value.** The 2.5 s reaction time and the
   3.4 m/s² deceleration size roads for an unfavourable driver. Used as the bound of "a rate of
   speed greater than is reasonable", they mark as unlawful an ordinary attentive driver who
   approaches a bend at 15.8 mph with 81 ft of sight. Whether that is the intended meaning is
   the operator's decision. It is a legitimate choice for a deliberately strict reading of an
   open standard, where other rules (following distance, for example) judge specific conduct.
2. **Ask what population the value describes.** A design envelope (a slow-reacting driver, a
   poor surface) and a typical attentive driver (a reaction time nearer 1.5 s, firmer braking)
   are both defensible conventions. They give opposite verdicts here. The convention a
   parameter cites should say which one it is, and the operator's review should confirm that is
   the one the rule should use.
3. **Look at the margin, not only the verdict.** A violation of 0.24 m over two frames, inside
   measurement steps of 0.16 m, is a knife-edge result. The value of a parameter matters most
   exactly where the law's word ("reasonable") is vaguest. A review that changes a value by a
   tenth of a second can flip such cases, which is why the value has to rest on its convention.
4. **Missing data and parameter values are separate questions.** Here the instant is decided
   only because every surface branch agrees; elsewhere the same rule is unknown. Filling in the
   surface or the lane width changes which frames are decided; changing a parameter changes
   which way they go.

## How to use this example

- Use it to understand what a parameter review decides, and to read a proposal's convention
  critically. Do not use it to pick a value: choosing `p.reaction_time` so that M023 comes out
  compliant would fit a parameter to evaluation data, which is exactly what keeping the
  evaluation outside the pipeline forbids.
- A value is reviewed on its cited convention: which population, which source, design or
  conduct. Once set, the evaluation reports what that value implies, M023 included.
