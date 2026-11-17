# NRS_484B_287_1e — task result

**Final verdict: UNANCHORED_VARIABLE** (node defect, reported; session ended with 3 gate runs unused)

## Gate runs

1. `UNUSED_CLAIM`. This was the untouched skeleton: I ran it by mistake while also listing Core, before I had written anything.
2. `UNANCHORED_VARIABLE`. The pedestrian-signal variable `d` "shares no atom with a binder". The obligation was
   `forallDevice pedestrian_signal d (faces d → ¬ forbids d)`. `faces d` is the record's three
   comparisons over `dev_position(d) − kin_position(subject)` and `kin_heading(subject)`.
3. `UNANCHORED_VARIABLE` again, with the equivalent form `¬ existsDevice d (faces d ∧ forbids d)`. Moving the tie from the antecedent to a
   positive conjunct did not help, so polarity was not the cause. I put the `forallDevice` form back because it follows the record more closely.

## What is written

- Class: `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- s1: `¬ruleApplies LVMC_11_30_140_B_o1` and `¬ruleApplies LVMC_11_30_140_B_o2`, with map subject ↦ subject.
- s2: there is an intersection x with `rises(rel_occupies(subject, x))`. At least one lane l0 has `st_lane_enters(l0, x)`.
  Every lane l with `st_lane_enters(l, x)` satisfies `moving_across_carrier(subject, l; halt, crossing_cos)`
  and does not satisfy `moving_across_carrier(subject, l; halt, right_angle_cos)`. There is a crosswalk c with
  `rel_occupies(subject, c)` and `st_crosswalk_marked(c)`.
- s4: for every pedestrian head d that the subject faces, d does not show `dont_walk_steady` and does not show `dont_walk_flashing` without a countdown.
  The subject faces d when all of these hold: h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², and |Δ|² ≤ reach².
- I added no narrowings: the record leaves no choice open.
- The witnesses build: a square intersection; two north-south lanes entering it; a diagonal marked crosswalk; a pedestrian walking at heading (0.6, 0.8) and entering at the third instant; and a head 25 m straight ahead. Six scenes vary the head's state and countdown. In `idle` the pedestrian walks due east.
  The gate never reached the witness stage, so these scenes are untested.

## Why I finished — the node is wrong (span s4)

s4 picks out the head that "pertains to the crossing movement" only through a comparison:
`dev.position` against the subject's `kin.position` and `kin.heading`. The gate's anchoring check rejects this. It
ties a device to a binder only through an atom that reads both of them, such as `rel_occupies`,
`st_region_geometry_distance`, `dev_governs` or a relation atom. A comparison of two separate measures does not count as such an atom. The node claims no atom of that kind for the device, so with these
claims `d` can never be anchored (rule 3b: "If the node claims no anchoring atom, the node is
wrong: report it").

**What the plan agent must change:** give s4 an anchoring relation for the head. The most natural one
is `dev.governs`: the heads that pertain to the crossing are those that govern the crosswalk
the pedestrian occupies. That crosswalk is the marked crosswalk c already selected by `rel_occupies(subject, c)` in s2,
and it would be re-selected in the obligation (rule 3c). The facing comparison could then be dropped, or kept to choose
among the governing heads. Otherwise the plan must confirm that the gate accepts a
position/heading comparison as an anchor. If it should, the gate's anchoring check does not
accept the shape the record states, which is three comparisons over `dev_position − kin_position` and `kin_heading`.
