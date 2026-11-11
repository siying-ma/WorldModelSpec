# NRS_484B_769: task result

## Final verdict: OK

## Gate runs
1. `OK`: 9 witnesses, 5 names, composes nothing. This was the first run, so nothing changed after it.

(Before that run I tried one shell command that was not the gate: a `--help` probe chained with an `ls`. The permission layer denied it and nothing ran. It used no gate run.)

## How the rule is written
- **Class (s1):** `ru_aggregate` of `x` with each of the three admitted aggregate ids, joined by `or`.
- **Applicability (s2, s3):**
  - `existsRegion roadway r (rel_occupies x r)`. The `st.roadway` claim is carried by the quantifier's kind, and `rel_occupies` anchors `r` to `x`.
  - This is conjoined with "x gives a signal": the indicator is left or right, or the arm signal is not `no_signal`.
- **Obligation (s3, s4, s5):** three conditions, all required:
  - the arm signal is not `no_signal`;
  - if the indicator is left, the arm signal is `left` or `re_enter`;
  - if the indicator is right, the arm signal is `right`.
- **s5:** the right-arm form is carried by the same `right` meaning as NRS 484B.420's upward posture. The record says the source decodes the meaning only.

## Choices left open
None beyond the record's own narrowings, so `narrowings` is empty.

## Witnesses
- **Planned scenarios:** forbid, permit, idle, blind, branch_1, branch_2 and branch_3, all as planned.
- **Added branch_4 (compliant):** left indicator with the `re_enter` arm signal.
- **Added branch_5 (violated):** left indicator with the `stop_or_slow` arm signal.
- These two exercise the left-indicator limb of the obligation, which no planned scene reaches.

## Why I finished
The gate returned `OK` on the first run.
